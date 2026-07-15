extends RefCounted


func fetch_catalog() -> Dictionary:
	return {"ok": false, "error": "not_implemented", "items": []}


func fetch_details(_cartridge_id: String) -> Dictionary:
	return {"ok": false, "error": "not_implemented", "item": {}}


func download(_cartridge_id: String, _version: String) -> Dictionary:
	return {"ok": false, "error": "not_implemented", "path": ""}


func search(_query: String) -> Dictionary:
	return {"ok": false, "error": "not_implemented", "items": []}
