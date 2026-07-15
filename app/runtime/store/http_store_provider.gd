extends "res://app/runtime/store/store_provider.gd"

var base_url := ""
var enabled := false


func fetch_catalog() -> Dictionary:
	return {"ok": false, "error": "http_provider_disabled", "items": []}


func fetch_details(_cartridge_id: String) -> Dictionary:
	return {"ok": false, "error": "http_provider_disabled", "item": {}}


func download(_cartridge_id: String, _version: String) -> Dictionary:
	return {"ok": false, "error": "http_provider_disabled", "path": ""}
