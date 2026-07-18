extends Node

signal catalog_updated(result: Dictionary)

const Cache := preload("res://app/runtime/store/catalog_cache.gd")
const DEFAULT_URL := BrandConfig.CATALOG_URL
const MAX_CATALOG_BYTES := 2 * 1024 * 1024
const MAX_ENTRIES := 2000

var catalog_url := DEFAULT_URL
var _cache := Cache.new()
var _request: HTTPRequest
var _metadata: Dictionary = {}


func _ready() -> void:
	_request = HTTPRequest.new()
	_request.timeout = 15.0
	_request.max_redirects = 5
	_request.request_completed.connect(_on_catalog_completed)
	add_child(_request)


func fetch_catalog() -> Dictionary:
	var cached := _cache.load_cache()
	_metadata = Dictionary(cached.get("metadata", {}))
	var parsed := _parse_catalog(Dictionary(cached.get("catalog", {})))
	if bool(parsed.get("ok", false)):
		parsed["cached"] = true
		parsed["saved_at"] = String(cached.get("saved_at", ""))
	return parsed


func refresh_catalog(force: bool = false) -> Dictionary:
	if _request.get_http_client_status() != HTTPClient.STATUS_DISCONNECTED:
		return {"ok": false, "error": "busy", "pending": true}
	if not catalog_url.begins_with("https://") or "@" in catalog_url:
		return {"ok": false, "error": "invalid_catalog_url"}
	var headers := PackedStringArray(["Accept: application/json", "User-Agent: " + BrandConfig.USER_AGENT])
	if not force:
		if not String(_metadata.get("etag", "")).is_empty(): headers.append("If-None-Match: " + String(_metadata["etag"]))
		if not String(_metadata.get("last_modified", "")).is_empty(): headers.append("If-Modified-Since: " + String(_metadata["last_modified"]))
	var error := _request.request(catalog_url, headers, HTTPClient.METHOD_GET)
	return {"ok": error == OK, "error": "pending" if error == OK else "network_error", "pending": error == OK}


func _on_catalog_completed(result: int, response_code: int, headers: PackedStringArray, body: PackedByteArray) -> void:
	if response_code == 304:
		catalog_updated.emit(fetch_catalog()); return
	if result != HTTPRequest.RESULT_SUCCESS or response_code < 200 or response_code >= 300:
		var fallback := fetch_catalog(); fallback["error"] = "network_error"; catalog_updated.emit(fallback); return
	if body.size() > MAX_CATALOG_BYTES:
		catalog_updated.emit({"ok": false, "error": "catalog_too_large", "items": []}); return
	var parsed_json: Variant = JSON.parse_string(body.get_string_from_utf8())
	if typeof(parsed_json) != TYPE_DICTIONARY:
		catalog_updated.emit({"ok": false, "error": "invalid_catalog", "items": []}); return
	var parsed := _parse_catalog(Dictionary(parsed_json))
	if not bool(parsed.get("ok", false)):
		catalog_updated.emit(parsed); return
	_metadata = _response_metadata(headers)
	_cache.save_cache(Dictionary(parsed_json), _metadata)
	parsed["cached"] = false
	catalog_updated.emit(parsed)


func _parse_catalog(catalog: Dictionary) -> Dictionary:
	if int(catalog.get("schema_version", 0)) != BrandConfig.CATALOG_SCHEMA_VERSION: return {"ok": false, "error": "invalid_schema", "items": []}
	var packages := Array(catalog.get("packages", []))
	if packages.size() > MAX_ENTRIES: return {"ok": false, "error": "too_many_entries", "items": []}
	var items: Array[Dictionary] = []
	var ids: Dictionary = {}
	for value in packages:
		if typeof(value) != TYPE_DICTIONARY: return {"ok": false, "error": "invalid_entry", "items": []}
		var item := Dictionary(value).duplicate(true)
		if String(item.get("moderation_status", "")) != "approved": continue
		var cartridge_id := String(item.get("id", ""))
		if cartridge_id.is_empty() or ids.has(cartridge_id): return {"ok": false, "error": "duplicate_id", "items": []}
		ids[cartridge_id] = true
		var author: Dictionary = item.get("author", {}) if typeof(item.get("author")) == TYPE_DICTIONARY else {}
		var release: Dictionary = item.get("release", {}) if typeof(item.get("release")) == TYPE_DICTIONARY else {}
		item["author"] = String(author.get("name", "Unknown"))
		item["sha256"] = String(release.get("sha256", ""))
		items.append(item)
	return {"ok": true, "error": "ok", "items": items}


func _response_metadata(headers: PackedStringArray) -> Dictionary:
	var result: Dictionary = {}
	for header in headers:
		var split := header.split(":", true, 1)
		if split.size() != 2: continue
		var key := split[0].strip_edges().to_lower()
		if key == "etag": result["etag"] = split[1].strip_edges()
		elif key == "last-modified": result["last_modified"] = split[1].strip_edges()
	return result
