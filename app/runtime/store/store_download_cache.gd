extends RefCounted
class_name StoreDownloadCache

const Paths := preload("res://app/runtime/cartridges/cartridge_paths.gd")


static func paths_for(item: Dictionary) -> Dictionary:
	Paths.ensure()
	var file_name := _safe_name(String(item.get("id", "cartridge"))) + "-" + _safe_name(String(item.get("version", "latest"))) + ".pctrg"
	var final_path := Paths.download_path(file_name)
	return {"part": final_path + ".part", "final": final_path}


static func cleanup(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	var downloads := ProjectSettings.globalize_path(Paths.DOWNLOADS_DIR)
	var target := ProjectSettings.globalize_path(path)
	if target.begins_with(downloads):
		DirAccess.remove_absolute(target)


static func commit(part_path: String, final_path: String) -> bool:
	cleanup(final_path)
	var source := ProjectSettings.globalize_path(part_path)
	var destination := ProjectSettings.globalize_path(final_path)
	return DirAccess.rename_absolute(source, destination) == OK


static func _safe_name(value: String) -> String:
	var output := ""
	for character in value.to_lower():
		output += character if character in "abcdefghijklmnopqrstuvwxyz0123456789._-" else "_"
	return output.left(96)
