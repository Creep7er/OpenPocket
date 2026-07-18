extends RefCounted

const PROFILE_DIR := "user://profile"
const PATH := "user://profile/achievements.json"
const BACKUP_PATH := "user://profile/achievements.backup.json"


func load_data() -> Dictionary:
	DirAccess.make_dir_recursive_absolute(PROFILE_DIR)
	var primary := _read(PATH)
	if not primary.is_empty():
		return primary
	var backup := _read(BACKUP_PATH)
	return backup if not backup.is_empty() else {"format_version": 1, "achievements": {}}


func save_data(data: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(PROFILE_DIR)
	var temporary := PATH + ".tmp"
	var file := FileAccess.open(temporary, FileAccess.WRITE)
	if file == null:
		return false
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
	var target := ProjectSettings.globalize_path(PATH)
	var backup := ProjectSettings.globalize_path(BACKUP_PATH)
	if FileAccess.file_exists(PATH):
		DirAccess.remove_absolute(backup)
		DirAccess.rename_absolute(target, backup)
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), target) == OK


func _read(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY or int(Dictionary(parsed).get("format_version", 0)) != 1:
		return {}
	return Dictionary(parsed)
