extends "res://app/runtime/store/store_provider.gd"

const CATALOG_PATH := "res://store/mock_catalog.json"
const CartridgePaths := preload("res://app/runtime/cartridges/cartridge_paths.gd")

var _catalog: Dictionary = {}


func fetch_catalog() -> Dictionary:
	_catalog = _read_catalog()
	return {"ok": true, "error": "ok", "items": Array(_catalog.get("cartridges", []))}


func fetch_details(cartridge_id: String) -> Dictionary:
	var catalog_result: Dictionary = fetch_catalog()
	if not bool(catalog_result.get("ok", false)):
		return catalog_result
	for item in Array(catalog_result.get("items", [])):
		var entry: Dictionary = Dictionary(item)
		if String(entry.get("id", "")) == cartridge_id:
			return {"ok": true, "error": "ok", "item": entry}
	return {"ok": false, "error": "not_found", "item": {}}


func download(cartridge_id: String, version: String) -> Dictionary:
	var details: Dictionary = fetch_details(cartridge_id)
	if not bool(details.get("ok", false)):
		return details
	var item: Dictionary = Dictionary(details.get("item", {}))
	if not version.is_empty() and String(item.get("version", "")) != version:
		return {"ok": false, "error": "version_not_found", "path": ""}
	var source := "res://store/".path_join(String(item.get("download", "")))
	if not FileAccess.file_exists(source):
		return {"ok": false, "error": "download_missing", "path": source}
	CartridgePaths.ensure()
	var destination := CartridgePaths.download_path(source.get_file())
	var read_file := FileAccess.open(source, FileAccess.READ)
	var write_file := FileAccess.open(destination, FileAccess.WRITE)
	if read_file == null or write_file == null:
		return {"ok": false, "error": "io_error", "path": ""}
	write_file.store_buffer(read_file.get_buffer(read_file.get_length()))
	return {"ok": true, "error": "ok", "path": destination, "item": item}


func search(query: String) -> Dictionary:
	var lower_query := query.to_lower()
	var items: Array = Array(fetch_catalog().get("items", []))
	if lower_query.is_empty():
		return {"ok": true, "error": "ok", "items": items}
	var filtered: Array[Dictionary] = []
	for item in items:
		var entry: Dictionary = Dictionary(item)
		var haystack := (
			String(entry.get("name", "")) + " " +
			String(entry.get("id", "")) + " " +
			String(entry.get("author", "")) + " " +
			String(entry.get("category", "")) + " " +
			" ".join(PackedStringArray(Array(entry.get("tags", []))))
		).to_lower()
		if haystack.contains(lower_query):
			filtered.append(entry)
	return {"ok": true, "error": "ok", "items": filtered}


func _read_catalog() -> Dictionary:
	if not FileAccess.file_exists(CATALOG_PATH):
		return {"schema_version": 1, "cartridges": []}
	var file := FileAccess.open(CATALOG_PATH, FileAccess.READ)
	if file == null:
		return {"schema_version": 1, "cartridges": []}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return {"schema_version": 1, "cartridges": []}
	return Dictionary(parsed)
