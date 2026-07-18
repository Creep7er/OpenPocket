extends RefCounted

const Paths := preload("res://app/runtime/cartridges/cartridge_paths.gd")

var _records: Dictionary = {}


func load() -> void:
	Paths.ensure()
	_records.clear()
	if not FileAccess.file_exists(Paths.REGISTRY_PATH):
		save()
		return
	var file := FileAccess.open(Paths.REGISTRY_PATH, FileAccess.READ)
	if file == null:
		return
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	for key in Dictionary(parsed).keys():
		var record: Dictionary = Dictionary(Dictionary(parsed)[key])
		var cartridge_id := String(record.get("id", key))
		var expected_path := Paths.package_dir(cartridge_id)
		record["id"] = cartridge_id
		record["install_path"] = expected_path
		record["content_path"] = expected_path.path_join("content.pck")
		record["manifest_path"] = expected_path.path_join("cartridge.json")
		record["broken"] = not FileAccess.file_exists(String(record["content_path"])) or not FileAccess.file_exists(String(record["manifest_path"]))
		if bool(record["broken"]):
			push_warning("Preserving broken cartridge registry entry for repair: " + cartridge_id)
		_records[cartridge_id] = record
	save()


func save() -> void:
	Paths.ensure()
	var file := FileAccess.open(Paths.REGISTRY_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write cartridge registry")
		return
	file.store_string(JSON.stringify(_records, "\t"))


func all() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for key in _records.keys():
		result.append(Dictionary(_records[key]).duplicate(true))
	result.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return String(a.get("name", "")) < String(b.get("name", ""))
	)
	return result


func set_record(record: Dictionary) -> void:
	var cartridge_id := String(record.get("id", ""))
	if cartridge_id.is_empty():
		return
	_records[cartridge_id] = record.duplicate(true)
	save()


func has(cartridge_id: String) -> bool:
	return _records.has(cartridge_id)


func get_record(cartridge_id: String) -> Dictionary:
	return Dictionary(_records.get(cartridge_id, {})).duplicate(true)


func remove_record(cartridge_id: String) -> void:
	if _records.erase(cartridge_id):
		save()
