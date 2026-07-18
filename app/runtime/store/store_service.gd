extends Node

const LocalStoreProvider := preload("res://app/runtime/store/local_store_provider.gd")
const GitHubCatalogProvider := preload("res://app/runtime/store/github_catalog_provider.gd")
const Trust := preload("res://app/runtime/cartridges/cartridge_trust.gd")

signal catalog_changed
signal download_ready(result: Dictionary)

var _provider: Node
var _fallback := LocalStoreProvider.new()
var _catalog: Array[Dictionary] = []
var _loaded := false
var _status := "updating"


func _ready() -> void:
	_provider = GitHubCatalogProvider.new()
	add_child(_provider)
	_provider.catalog_updated.connect(_on_catalog_updated)
	_provider.download_finished.connect(_on_download_finished)
	refresh()


func refresh(force: bool = false) -> Dictionary:
	var result: Dictionary = _provider.fetch_catalog()
	if not bool(result.get("ok", false)):
		result = _fallback.fetch_catalog()
		_status = "offline cache"
	else:
		_status = "offline cache" if bool(result.get("cached", false)) else "online"
	_apply_catalog(result)
	_provider.refresh_catalog(force)
	return result


func status_label() -> String:
	return _status.to_upper()


func _apply_catalog(result: Dictionary) -> void:
	_catalog.clear()
	_loaded = true
	if bool(result.get("ok", false)):
		var by_id: Dictionary = {}
		for item in Array(result.get("items", [])):
			var entry := Dictionary(item)
			var cartridge_id := String(entry.get("id", ""))
			if cartridge_id.is_empty():
				continue
			if not by_id.has(cartridge_id) or compare_versions(
				String(entry.get("version", "0")),
				String(Dictionary(by_id[cartridge_id]).get("version", "0"))
			) > 0:
				by_id[cartridge_id] = entry
		for cartridge_id in by_id.keys():
			_catalog.append(Dictionary(by_id[cartridge_id]))
		_catalog.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
			return String(a.get("name", "")) < String(b.get("name", ""))
		)
	catalog_changed.emit()


func _on_catalog_updated(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		_status = "offline cache" if bool(result.get("cached", false)) else "online"
		_apply_catalog(result)
	elif not _catalog.is_empty():
		_status = "offline cache"
	else:
		_status = "unavailable"


func list_catalog() -> Array[Dictionary]:
	if not _loaded:
		refresh()
	return _catalog.duplicate(true)


func featured() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in list_catalog():
		if bool(item.get("featured", false)):
			result.append(item)
	return result


func updates() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for item in list_catalog():
		var installed: Dictionary = CartridgeManager.get_cartridge(String(item.get("id", "")))
		if installed.is_empty():
			continue
		if compare_versions(String(item.get("version", "0")), String(installed.get("version", "0"))) > 0:
			result.append(item)
	return result


func search(query: String) -> Array[Dictionary]:
	var normalized := query.strip_edges().to_lower()
	if normalized.is_empty():
		return []
	var result: Array[Dictionary] = []
	for item in list_catalog():
		var haystack := (
			String(item.get("name", "")) + " " +
			String(item.get("author", "")) + " " +
			String(item.get("category", "")) + " " +
			" ".join(PackedStringArray(Array(item.get("tags", []))))
		).to_lower()
		if haystack.contains(normalized):
			result.append(item)
	return result


func has_update(cartridge_id: String) -> bool:
	var installed := CartridgeManager.get_cartridge(cartridge_id)
	if installed.is_empty():
		return false
	for item in list_catalog():
		if String(item.get("id", "")) == cartridge_id:
			return compare_versions(String(item.get("version", "0")), String(installed.get("version", "0"))) > 0
	return false


static func compare_versions(left: String, right: String) -> int:
	var left_core := left.split("-", false, 1)[0]
	var right_core := right.split("-", false, 1)[0]
	var left_parts := left_core.split(".")
	var right_parts := right_core.split(".")
	var count := maxi(left_parts.size(), right_parts.size())
	for index in range(count):
		var left_value := int(left_parts[index]) if index < left_parts.size() and left_parts[index].is_valid_int() else 0
		var right_value := int(right_parts[index]) if index < right_parts.size() and right_parts[index].is_valid_int() else 0
		if left_value != right_value:
			return 1 if left_value > right_value else -1
	var left_prerelease := left.contains("-")
	var right_prerelease := right.contains("-")
	if left_prerelease != right_prerelease:
		return -1 if left_prerelease else 1
	return 0


func download_to_imports(cartridge_id: String, version: String = "") -> Dictionary:
	var item: Dictionary = {}
	for candidate in _catalog:
		if String(candidate.get("id", "")) == cartridge_id and (version.is_empty() or String(candidate.get("version", "")) == version):
			item = candidate
			break
	if not item.is_empty() and not Dictionary(item.get("release", {})).is_empty():
		return _provider.download_cartridge(item)
	var download_result: Dictionary = _fallback.download(cartridge_id, version)
	if not bool(download_result.get("ok", false)):
		return download_result
	var path := String(download_result.get("path", ""))
	var local_item: Dictionary = Dictionary(download_result.get("item", {}))
	var expected_sha := String(local_item.get("sha256", "")).to_lower()
	if not expected_sha.is_empty():
		var actual_sha := FileAccess.get_sha256(path).to_lower()
		if actual_sha != expected_sha:
			return {"ok": false, "error": "archive_checksum_mismatch", "path": path}
	return {
		"ok": true,
		"error": "ok",
		"path": path,
		"trust": Trust.TRUSTED if bool(local_item.get("curated", false)) else Trust.UNTRUSTED,
		"item": local_item,
	}


func _on_download_finished(result: Dictionary) -> void:
	if bool(result.get("ok", false)):
		result["trust"] = Trust.TRUSTED
	download_ready.emit(result)
