extends Node

const PACKAGE_INDEX_PATH := "res://packages/index.json"
const Manifest := preload("res://app/runtime/cartridges/cartridge_manifest.gd")
const Registry := preload("res://app/runtime/cartridges/cartridge_registry.gd")
const Installer := preload("res://app/runtime/cartridges/cartridge_installer.gd")
const Loader := preload("res://app/runtime/cartridges/cartridge_loader.gd")
const Trust := preload("res://app/runtime/cartridges/cartridge_trust.gd")
const Paths := preload("res://app/runtime/cartridges/cartridge_paths.gd")

var _registry := Registry.new()
var _installer := Installer.new()
var _loader := Loader.new()
var _builtins: Dictionary = {}
var _active_context: Dictionary = {}


func _ready() -> void:
	bootstrap()


## Loads built-in cartridges and the user registry.
func bootstrap() -> void:
	Paths.ensure()
	_registry.load()
	_load_builtin_cartridges()


func list_builtin() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _builtins.keys():
		result.append(Dictionary(_builtins[key]).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)
	return result


func list_installed() -> Array[Dictionary]:
	var records: Array[Dictionary] = list_builtin()
	for record in _registry.all():
		records.append(record)
	return records


func get_cartridge(cartridge_id: String) -> Dictionary:
	if _builtins.has(cartridge_id):
		return Dictionary(_builtins[cartridge_id]).duplicate(true)
	return _registry.get_record(cartridge_id)


func install_from_file(path: String, source_trust: String = Trust.UNTRUSTED, allow_replace: bool = false) -> Dictionary:
	var existing_ids: Array[String] = []
	for record in list_installed():
		existing_ids.append(String(record.get("id", "")))
	var inspected: Dictionary = _installer.inspect(path)
	if not bool(inspected.get("ok", false)):
		return inspected
	var manifest: Dictionary = Dictionary(inspected.get("manifest", {}))
	var cartridge_id := String(manifest.get("id", ""))
	if _builtins.has(cartridge_id):
		return {"ok": false, "error": "built_in_conflict", "message": "Built-in cartridges cannot be replaced."}
	var was_mounted := _loader.is_mounted(cartridge_id)
	var result: Dictionary = _installer.install_from_file(path, source_trust, allow_replace, existing_ids)
	if bool(result.get("ok", false)):
		_registry.set_record(Dictionary(result.get("record", {})))
		result["restart_required"] = was_mounted
		_cleanup_download(path)
	return result


func inspect_file(path: String) -> Dictionary:
	var result: Dictionary = _installer.inspect(path)
	if bool(result.get("ok", false)):
		var manifest: Dictionary = Dictionary(result.get("manifest", {}))
		result["operation"] = install_operation(manifest)
	return result


func install_operation(manifest: Dictionary) -> String:
	var cartridge_id := String(manifest.get("id", ""))
	if _builtins.has(cartridge_id):
		return "blocked"
	var installed: Dictionary = _registry.get_record(cartridge_id)
	if installed.is_empty():
		return "install"
	var comparison := _compare_versions(String(manifest.get("version", "0")), String(installed.get("version", "0")))
	if comparison > 0:
		return "update"
	if comparison < 0:
		return "downgrade"
	return "reinstall"


func uninstall(cartridge_id: String, remove_data: bool = false) -> bool:
	var record: Dictionary = get_cartridge(cartridge_id)
	if record.is_empty() or bool(record.get("built_in", false)):
		return false
	var result: Dictionary = _installer.uninstall(record)
	if not bool(result.get("ok", false)):
		return false
	_registry.remove_record(cartridge_id)
	if remove_data:
		PocketStorage.clear_package_store(cartridge_id)
	CosmeticsManager.ensure_active_available()
	return true


func verify(cartridge_id: String) -> Dictionary:
	var record: Dictionary = get_cartridge(cartridge_id)
	if record.is_empty():
		return {"ok": false, "error": "not_found"}
	if bool(record.get("built_in", false)):
		return {"ok": true, "error": "ok", "trust": Trust.BUILT_IN}
	var content_path := String(record.get("content_path", ""))
	var expected_sha := String(Dictionary(record.get("content", {})).get("sha256", "")).to_lower()
	if not FileAccess.file_exists(content_path):
		return {"ok": false, "error": "content_missing"}
	var actual_sha := FileAccess.get_sha256(content_path).to_lower()
	return {
		"ok": expected_sha == actual_sha,
		"error": "ok" if expected_sha == actual_sha else "checksum_mismatch",
		"expected": expected_sha,
		"actual": actual_sha,
	}


func launch(cartridge_id: String) -> Dictionary:
	var record: Dictionary = get_cartridge(cartridge_id)
	if record.is_empty():
		return {"ok": false, "error": "not_found", "entry_scene": ""}
	var developer_mode := bool(PocketStorage.get_setting("developer_mode", false))
	var result: Dictionary = _loader.prepare_launch(record, developer_mode)
	if bool(result.get("ok", false)):
		_active_context = {
			"id": String(record.get("id", "")),
			"version": String(record.get("version", "")),
			"trust": String(record.get("trust", Trust.UNTRUSTED)),
			"capabilities": Manifest.required_capabilities(record),
		}
	return result


func active_context() -> Dictionary:
	return _active_context.duplicate(true)


func resolve_entry_scene(record: Dictionary) -> String:
	return String(record.get("entry_scene", ""))


func is_mounted(cartridge_id: String) -> bool:
	return _loader.is_mounted(cartridge_id)


func _cleanup_download(path: String) -> void:
	var global_downloads := ProjectSettings.globalize_path(Paths.DOWNLOADS_DIR)
	var global_path := ProjectSettings.globalize_path(path)
	if global_path.begins_with(global_downloads) and FileAccess.file_exists(path):
		DirAccess.remove_absolute(global_path)


func _compare_versions(left: String, right: String) -> int:
	var a := left.split(".")
	var b := right.split(".")
	for index in range(3):
		var av := int(a[index]) if index < a.size() else 0
		var bv := int(b[index]) if index < b.size() else 0
		if av != bv:
			return 1 if av > bv else -1
	return 0


func _load_builtin_cartridges() -> void:
	_builtins.clear()
	var seen_ids: Dictionary = {}
	for package_dir in _read_package_index():
		var package_manifest_path := package_dir.path_join("manifest.json")
		var package_manifest: Dictionary = _read_json(package_manifest_path)
		if package_manifest.is_empty():
			continue
		var cartridge_path := package_dir.path_join("cartridge.json")
		var cartridge: Dictionary = _read_json(cartridge_path)
		if cartridge.is_empty():
			cartridge = Manifest.from_package_manifest(package_manifest, package_dir)
		var cartridge_id := String(cartridge.get("id", ""))
		if cartridge_id.is_empty() or seen_ids.has(cartridge_id):
			push_warning("Skipping cartridge with empty or duplicate id: " + package_dir)
			continue
		seen_ids[cartridge_id] = true
		cartridge["trust"] = Trust.BUILT_IN
		cartridge["built_in"] = true
		cartridge["install_path"] = package_dir
		cartridge["_base_path"] = package_dir
		if not String(cartridge.get("entry_scene", "")).begins_with("res://"):
			cartridge["entry_scene"] = package_dir.path_join(String(cartridge.get("entry_scene", "main.tscn")))
		_builtins[cartridge_id] = cartridge


func _read_package_index() -> Array[String]:
	var index: Dictionary = _read_json(PACKAGE_INDEX_PATH)
	var package_entries: Array[String] = []
	for entry in Array(index.get("packages", [])):
		package_entries.append("res://packages/".path_join(String(entry).strip_edges().trim_prefix("/")))
	return package_entries


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		push_warning("JSON file not found: " + path)
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("Invalid JSON: " + path)
		return {}
	return Dictionary(parsed)
