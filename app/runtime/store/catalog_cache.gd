extends RefCounted

const ROOT := "user://store"
const PATH := "user://store/catalog_cache.json"


func load_cache() -> Dictionary:
	if not FileAccess.file_exists(PATH): return {}
	var file := FileAccess.open(PATH, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}


func save_cache(catalog: Dictionary, metadata: Dictionary) -> bool:
	DirAccess.make_dir_recursive_absolute(ROOT)
	var payload := {"catalog": catalog, "metadata": metadata, "saved_at": Time.get_datetime_string_from_system(true)}
	var file := FileAccess.open(PATH + ".tmp", FileAccess.WRITE)
	if file == null: return false
	file.store_string(JSON.stringify(payload, "\t"))
	file.close()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(PATH))
	return DirAccess.rename_absolute(ProjectSettings.globalize_path(PATH + ".tmp"), ProjectSettings.globalize_path(PATH)) == OK
