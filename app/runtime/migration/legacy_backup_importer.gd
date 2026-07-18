extends Node

const MAX_BACKUP_SIZE := 16 * 1024 * 1024
const MAX_JSON_SIZE := 2 * 1024 * 1024
const ALLOWED_DATA := ["settings.json", "profile/achievements.json", "profile/rewards.json"]
const ID_MAP := {
	"org.openpocket.snake": "org.popugonet.popugvpocket.snake",
	"org.openpocket.pong": "org.popugonet.popugvpocket.pong",
	"org.openpocket.notes": "org.popugonet.popugvpocket.notes",
	"org.openpocket.breakout": "org.popugonet.popugvpocket.breakout",
}


func inspect(path: String) -> Dictionary:
	var absolute := ProjectSettings.globalize_path(path)
	if not FileAccess.file_exists(absolute):
		return _result(false, "backup_missing")
	var size := FileAccess.open(absolute, FileAccess.READ).get_length()
	if size <= 0 or size > MAX_BACKUP_SIZE:
		return _result(false, "backup_size_invalid")
	var reader := ZIPReader.new()
	if reader.open(absolute) != OK:
		return _result(false, "invalid_zip")
	var parsed: Dictionary = {}
	var skipped: Array[String] = []
	for entry in reader.get_files():
		if entry in ALLOWED_DATA:
			var bytes := reader.read_file(entry)
			if bytes.size() > MAX_JSON_SIZE:
				reader.close()
				return _result(false, "legacy_json_too_large")
			var value: Variant = JSON.parse_string(bytes.get_string_from_utf8())
			if typeof(value) != TYPE_DICTIONARY:
				reader.close()
				return _result(false, "invalid_legacy_json")
			parsed[entry] = Dictionary(value)
		else:
			skipped.append(entry)
	reader.close()
	if not parsed.has("settings.json"):
		return _result(false, "settings_missing")
	return {"ok": true, "error": "", "data": parsed, "skipped": skipped}


func import_backup(path: String, settings_only: bool) -> Dictionary:
	var checked := inspect(path)
	if not bool(checked.get("ok", false)):
		return checked
	var backup_result := _backup_current_data()
	if not bool(backup_result.get("ok", false)):
		return backup_result
	var data: Dictionary = Dictionary(checked.get("data", {}))
	var settings := _sanitize_settings(Dictionary(data["settings.json"]))
	PocketStorage.save_settings(settings)
	if not settings_only:
		if data.has("profile/achievements.json"):
			_write_json("user://profile/achievements.json", _map_scoped_ids(Dictionary(data["profile/achievements.json"])))
		if data.has("profile/rewards.json"):
			_write_json("user://profile/rewards.json", _map_scoped_ids(Dictionary(data["profile/rewards.json"])))
	for entry in Array(checked.get("skipped", [])):
		print("[LegacyImport] skipped unsafe or unknown entry: " + String(entry))
	return {"ok": true, "error": "", "backup_path": backup_result.get("path", ""), "skipped": checked.get("skipped", [])}


func _sanitize_settings(source: Dictionary) -> Dictionary:
	var safe: Dictionary = {}
	for key in ["volume", "sound_enabled", "theme", "scanlines", "keyboard_hints", "debug_info", "developer_mode"]:
		if source.has(key): safe[key] = source[key]
	var packages: Dictionary = {}
	for old_id in Dictionary(source.get("packages", {})):
		var new_id := String(ID_MAP.get(String(old_id), ""))
		if not new_id.is_empty(): packages[new_id] = Dictionary(source["packages"][old_id]).duplicate(true)
	if not packages.is_empty(): safe["packages"] = packages
	return safe


func _map_scoped_ids(value: Dictionary) -> Dictionary:
	var text := JSON.stringify(value)
	for old_id in ID_MAP:
		text = text.replace(String(old_id), String(ID_MAP[old_id]))
	var parsed: Variant = JSON.parse_string(text)
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func _backup_current_data() -> Dictionary:
	var root: String = "user://migration-backups/" + Time.get_datetime_string_from_system().replace(":", "-")
	if DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(root)) != OK:
		return _result(false, "backup_create_failed")
	var current_files: Array[String] = ["settings.json", "profile/achievements.json", "profile/rewards.json"]
	for relative: String in current_files:
		var source: String = "user://" + relative
		if not FileAccess.file_exists(source): continue
		var target: String = root.path_join(relative)
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(target.get_base_dir()))
		if DirAccess.copy_absolute(ProjectSettings.globalize_path(source), ProjectSettings.globalize_path(target)) != OK:
			return _result(false, "backup_copy_failed")
	return {"ok": true, "error": "", "path": root}


func _write_json(path: String, value: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file != null: file.store_string(JSON.stringify(value, "\t"))


func _result(ok: bool, error: String) -> Dictionary:
	return {"ok": ok, "error": error}
