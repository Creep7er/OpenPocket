extends RefCounted

const Paths := preload("res://app/runtime/cartridges/cartridge_paths.gd")
const Manifest := preload("res://app/runtime/cartridges/cartridge_manifest.gd")
const Trust := preload("res://app/runtime/cartridges/cartridge_trust.gd")

const MAX_ARCHIVE_SIZE := 64 * 1024 * 1024
const MAX_EXTRACTED_SIZE := 128 * 1024 * 1024
const MAX_FILES := 512
const MAX_PATH_LENGTH := 180
const MAX_DEPTH := 12
const RUNTIME_VERSION := "0.4.0"


func inspect(path: String) -> Dictionary:
	var archive_size := _file_size(path)
	if archive_size <= 0 or archive_size > MAX_ARCHIVE_SIZE:
		return _result(false, "limit_exceeded", "Archive size is outside MVP limits.")
	var reader := ZIPReader.new()
	var open_error := reader.open(path)
	if open_error != OK:
		return _result(false, "invalid_archive", "Cannot open .pctrg archive.")
	var files: PackedStringArray = reader.get_files()
	if files.size() > MAX_FILES:
		reader.close()
		return _result(false, "limit_exceeded", "Archive contains too many files.")
	var seen: Dictionary = {}
	var total_size := 0
	var manifest_text := ""
	var content_bytes := PackedByteArray()
	for entry in files:
		var entry_path := String(entry)
		var path_check: Dictionary = _validate_entry_path(entry_path)
		if not bool(path_check.get("ok", false)):
			reader.close()
			return _result(false, "unsafe_path", String(path_check.get("error", "")))
		if seen.has(entry_path.to_lower()):
			reader.close()
			return _result(false, "invalid_archive", "Duplicate file path.")
		seen[entry_path.to_lower()] = true
		if entry_path.ends_with("/"):
			continue
		var bytes: PackedByteArray = reader.read_file(entry_path)
		total_size += bytes.size()
		if total_size > MAX_EXTRACTED_SIZE:
			reader.close()
			return _result(false, "limit_exceeded", "Extracted content exceeds MVP limits.")
		if entry_path == "cartridge.json":
			manifest_text = bytes.get_string_from_utf8()
		elif entry_path == "content.pck":
			content_bytes = bytes
	reader.close()
	if manifest_text.is_empty() or content_bytes.is_empty():
		return _result(false, "invalid_archive", "cartridge.json and content.pck are required.")
	var parsed: Variant = JSON.parse_string(manifest_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return _result(false, "invalid_manifest", "cartridge.json is not an object.")
	var manifest: Dictionary = Dictionary(parsed)
	var validation: Dictionary = Manifest.validate(manifest)
	if not bool(validation.get("ok", false)):
		return _result(false, "invalid_manifest", String(validation.get("error", "")))
	var cartridge_id := String(manifest.get("id", ""))
	var expected_root := "res://cartridges/" + cartridge_id + "/"
	if not String(manifest.get("entry_scene", "")).begins_with(expected_root):
		return _result(false, "invalid_manifest", "Entry scene must use the cartridge's unique resource root.")
	var compatibility: Dictionary = _validate_runtime(Dictionary(manifest.get("runtime", {})))
	if not bool(compatibility.get("ok", false)):
		return compatibility
	if content_bytes.size() < 4 or content_bytes.slice(0, 4).get_string_from_ascii() != "GDPC":
		return _result(false, "unsupported_format", "content.pck is not a Godot resource pack.")
	var expected_sha := String(Dictionary(manifest.get("content", {})).get("sha256", "")).to_lower()
	var hash := HashingContext.new()
	hash.start(HashingContext.HASH_SHA256)
	hash.update(content_bytes)
	var actual_sha := hash.finish().hex_encode().to_lower()
	if expected_sha != actual_sha:
		return _result(false, "checksum_mismatch", "content.pck checksum mismatch.")
	var result := _result(true, "ok", "")
	result["manifest"] = manifest
	result["archive_size"] = archive_size
	result["file_count"] = files.size()
	result["content_sha256"] = actual_sha
	return result


func install_from_file(path: String, source_trust: String, allow_replace: bool, existing_ids: Array[String]) -> Dictionary:
	Paths.ensure()
	var inspected: Dictionary = inspect(path)
	if not bool(inspected.get("ok", false)):
		return inspected
	var manifest: Dictionary = Dictionary(inspected.get("manifest", {}))
	var cartridge_id := String(manifest.get("id", ""))
	if existing_ids.has(cartridge_id) and not allow_replace:
		return _result(false, "duplicate_id", "Cartridge already installed.")
	var staging_dir := Paths.staging_dir(cartridge_id)
	var final_dir := Paths.package_dir(cartridge_id)
	_delete_dir(staging_dir)
	DirAccess.make_dir_recursive_absolute(staging_dir)
	var extract_result: Dictionary = _extract_archive(path, staging_dir)
	if not bool(extract_result.get("ok", false)):
		_delete_dir(staging_dir)
		return extract_result
	var backup_dir := final_dir + ".backup"
	_delete_dir(backup_dir)
	if DirAccess.dir_exists_absolute(final_dir):
		var backup_error := DirAccess.rename_absolute(final_dir, backup_dir)
		if backup_error != OK:
			_delete_dir(staging_dir)
			return _result(false, "install_failed", "Cannot prepare existing cartridge for update.")
	var rename_error := DirAccess.rename_absolute(staging_dir, final_dir)
	if rename_error != OK:
		_delete_dir(staging_dir)
		if DirAccess.dir_exists_absolute(backup_dir):
			DirAccess.rename_absolute(backup_dir, final_dir)
		return _result(false, "install_failed", "Cannot move cartridge into packages.")
	_delete_dir(backup_dir)
	var record: Dictionary = manifest.duplicate(true)
	record["trust"] = source_trust
	record["built_in"] = false
	record["installed_at"] = Time.get_datetime_string_from_system(true)
	record["install_source"] = "file"
	record["archive_sha256"] = FileAccess.get_sha256(path).to_lower()
	record["content_sha256"] = String(inspected.get("content_sha256", ""))
	record["enabled"] = true
	record["install_path"] = final_dir
	record["content_path"] = final_dir.path_join("content.pck")
	record["manifest_path"] = final_dir.path_join("cartridge.json")
	record["archive_size"] = int(inspected.get("archive_size", 0))
	return {"ok": true, "error": "ok", "message": "", "record": record}


func uninstall(record: Dictionary) -> Dictionary:
	if bool(record.get("built_in", false)):
		return _result(false, "blocked", "Built-in cartridges cannot be uninstalled.")
	var install_path := String(record.get("install_path", ""))
	if install_path.is_empty() or not install_path.begins_with(Paths.PACKAGES_DIR):
		return _result(false, "not_found", "External cartridge install path not found.")
	_delete_dir(install_path)
	return _result(true, "ok", "")


func _extract_archive(path: String, target_dir: String) -> Dictionary:
	var reader := ZIPReader.new()
	var open_error := reader.open(path)
	if open_error != OK:
		return _result(false, "invalid_archive", "Cannot open .pctrg archive.")
	for entry in reader.get_files():
		var entry_path := String(entry)
		var path_check: Dictionary = _validate_entry_path(entry_path)
		if not bool(path_check.get("ok", false)):
			reader.close()
			return _result(false, "unsafe_path", String(path_check.get("error", "")))
		if entry_path.ends_with("/"):
			DirAccess.make_dir_recursive_absolute(target_dir.path_join(entry_path))
			continue
		var destination := target_dir.path_join(entry_path)
		DirAccess.make_dir_recursive_absolute(destination.get_base_dir())
		var out := FileAccess.open(destination, FileAccess.WRITE)
		if out == null:
			reader.close()
			return _result(false, "io_error", "Cannot write " + entry_path)
		var bytes: PackedByteArray = reader.read_file(entry_path)
		out.store_buffer(bytes)
	reader.close()
	return _result(true, "ok", "")


func _validate_entry_path(path: String) -> Dictionary:
	var normalized := path.replace("\\", "/")
	if normalized.length() > MAX_PATH_LENGTH:
		return _result(false, "unsafe_path", "Path is too long.")
	if normalized.begins_with("/") or normalized.begins_with("//"):
		return _result(false, "unsafe_path", "Absolute paths are rejected.")
	if normalized.contains(":"):
		return _result(false, "unsafe_path", "Drive letters are rejected.")
	var parts := normalized.split("/", false)
	if parts.size() > MAX_DEPTH:
		return _result(false, "unsafe_path", "Path is too deep.")
	for part in parts:
		if part == ".." or part == ".":
			return _result(false, "unsafe_path", "Traversal paths are rejected.")
	return _result(true, "ok", "")


func _file_size(path: String) -> int:
	if not FileAccess.file_exists(path):
		return 0
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return 0
	return file.get_length()


func _validate_runtime(runtime: Dictionary) -> Dictionary:
	var minimum := String(runtime.get("min_version", "0.3.0"))
	var maximum_value: Variant = runtime.get("max_version", null)
	if _compare_versions(RUNTIME_VERSION, minimum) < 0:
		return _result(false, "incompatible_runtime", "OpenPocket runtime is older than cartridge minimum.")
	if maximum_value != null and not String(maximum_value).is_empty():
		if _compare_versions(RUNTIME_VERSION, String(maximum_value)) > 0:
			return _result(false, "incompatible_runtime", "Cartridge does not support this OpenPocket runtime.")
	return _result(true, "ok", "")


func _compare_versions(left: String, right: String) -> int:
	var a := left.split(".")
	var b := right.split(".")
	for index in range(3):
		var av := int(a[index]) if index < a.size() else 0
		var bv := int(b[index]) if index < b.size() else 0
		if av != bv:
			return 1 if av > bv else -1
	return 0


func _delete_dir(path: String) -> void:
	if not DirAccess.dir_exists_absolute(path):
		return
	var dir := DirAccess.open(path)
	if dir == null:
		return
	for file_name in dir.get_files():
		DirAccess.remove_absolute(path.path_join(file_name))
	for dir_name in dir.get_directories():
		_delete_dir(path.path_join(dir_name))
	DirAccess.remove_absolute(path)


func _result(ok: bool, error: String, message: String = "") -> Dictionary:
	return {"ok": ok, "error": error, "message": message}
