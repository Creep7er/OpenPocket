extends RefCounted

const ROOT := "user://profile"
const COSMETICS_DIR := "user://profile/cosmetics"
const PATH := "user://profile/rewards.json"

var _data: Dictionary = {"format_version": 1, "unlocked": {}}


func load_data() -> void:
	DirAccess.make_dir_recursive_absolute(COSMETICS_DIR)
	if FileAccess.file_exists(PATH):
		var file := FileAccess.open(PATH, FileAccess.READ)
		if file != null:
			var parsed: Variant = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY and int(Dictionary(parsed).get("format_version", 0)) == 1:
				_data = Dictionary(parsed)
	else:
		_save()


func unlock(cartridge: Dictionary, reward: Dictionary) -> bool:
	var source_id := String(cartridge.get("id", ""))
	var reward_id := String(reward.get("id", ""))
	var scoped_id := source_id + ".reward." + reward_id
	var unlocked := Dictionary(_data.get("unlocked", {}))
	if unlocked.has(scoped_id): return false
	var relative_path := String(reward.get("definition", reward.get("asset", "")))
	if relative_path.is_empty() or relative_path.is_absolute_path() or relative_path.contains(".."): return false
	var source_path := String(cartridge.get("_base_path", cartridge.get("resource_root", ""))).path_join(relative_path)
	if not FileAccess.file_exists(source_path): return false
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null: return false
	var destination := COSMETICS_DIR.path_join(scoped_id.validate_filename() + "." + relative_path.get_extension().to_lower())
	var output := FileAccess.open(destination + ".tmp", FileAccess.WRITE)
	if output == null: return false
	output.store_buffer(source.get_buffer(source.get_length()))
	output.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(destination))
	if DirAccess.rename_absolute(ProjectSettings.globalize_path(destination + ".tmp"), ProjectSettings.globalize_path(destination)) != OK: return false
	unlocked[scoped_id] = {"source_cartridge": source_id, "unlocked_at": Time.get_datetime_string_from_system(true), "type": String(reward.get("type", "theme")), "asset_id": reward_id, "name": String(reward.get("name", reward_id)), "path": destination, "sha256": FileAccess.get_sha256(destination), "version": String(cartridge.get("version", ""))}
	_data["unlocked"] = unlocked
	_save()
	return true


func all() -> Dictionary:
	return Dictionary(_data.get("unlocked", {})).duplicate(true)


func _save() -> void:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null: return
	file.store_string(JSON.stringify(_data, "\t"))
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH))
