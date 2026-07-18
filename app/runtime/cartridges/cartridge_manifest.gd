extends RefCounted

const FORMAT_VERSION := 1
const SUPPORTED_TYPES := ["game", "app", "theme"]
const RUNTIME_TYPES := ["game", "app"]
const SUPPORTED_CAPABILITIES := ["storage", "audio", "theme", "system_menu"]
const REQUIRED_FIELDS := [
	"format_version",
	"id",
	"name",
	"version",
	"type",
	"entry_scene",
	"sdk_version",
	"author",
	"description",
	"content",
]


static func normalize_author(author_value: Variant) -> Dictionary:
	if typeof(author_value) == TYPE_DICTIONARY:
		var author: Dictionary = Dictionary(author_value)
		return {
			"name": String(author.get("name", "Unknown")),
			"url": String(author.get("url", "")),
		}
	return {
		"name": String(author_value),
		"url": "",
	}


static func required_capabilities(manifest: Dictionary) -> Array[String]:
	var value: Variant = manifest.get("capabilities", [])
	var result: Array[String] = []
	if typeof(value) == TYPE_DICTIONARY:
		for entry in Array(Dictionary(value).get("required", [])):
			result.append(String(entry))
		return result
	for entry in Array(value):
		result.append(String(entry))
	return result


static func validate(manifest: Dictionary) -> Dictionary:
	for field in REQUIRED_FIELDS:
		if not manifest.has(field):
			return {"ok": false, "error": "missing " + field}
	var format_version: int = int(manifest.get("format_version", 0))
	if format_version != FORMAT_VERSION:
		return {"ok": false, "error": "unsupported format_version"}
	var cartridge_id := String(manifest.get("id", ""))
	if not _is_valid_id(cartridge_id):
		return {"ok": false, "error": "invalid id"}
	var cartridge_type := String(manifest.get("type", ""))
	if not SUPPORTED_TYPES.has(cartridge_type):
		return {"ok": false, "error": "unsupported type"}
	if not RUNTIME_TYPES.has(cartridge_type):
		return {"ok": false, "error": "runtime support for type is future"}
	var author: Dictionary = normalize_author(manifest.get("author", {}))
	if String(author.get("name", "")).strip_edges().is_empty():
		return {"ok": false, "error": "missing author.name"}
	var content: Dictionary = Dictionary(manifest.get("content", {}))
	if String(content.get("file", "")).strip_edges().is_empty():
		return {"ok": false, "error": "missing content.file"}
	if String(content.get("sha256", "")).strip_edges().length() != 64:
		return {"ok": false, "error": "missing content.sha256"}
	for capability in required_capabilities(manifest):
		if not SUPPORTED_CAPABILITIES.has(capability):
			return {"ok": false, "error": "unsupported capability " + capability}
	var achievement_ids: Dictionary = {}
	for value in Array(manifest.get("achievements", [])):
		var achievement := Dictionary(value)
		var achievement_id := String(achievement.get("id", ""))
		if achievement_id.is_empty() or achievement_id.contains(":") or achievement_ids.has(achievement_id):
			return {"ok": false, "error": "invalid achievement id"}
		if not ["event", "counter", "value"].has(String(achievement.get("type", "event"))):
			return {"ok": false, "error": "invalid achievement type"}
		achievement_ids[achievement_id] = true
	for group in ["provided", "rewards"]:
		for value in Array(Dictionary(manifest.get("cosmetics", {})).get(group, [])):
			var cosmetic := Dictionary(value)
			if not ["theme", "background"].has(String(cosmetic.get("type", ""))):
				return {"ok": false, "error": "invalid cosmetic type"}
			var asset_path := String(cosmetic.get("definition", cosmetic.get("asset", "")))
			if asset_path.is_empty() or asset_path.is_absolute_path() or asset_path.contains(".."):
				return {"ok": false, "error": "invalid cosmetic path"}
	return {"ok": true, "error": ""}


static func _is_valid_id(cartridge_id: String) -> bool:
	if cartridge_id.length() < 3 or not cartridge_id.contains("."):
		return false
	for character_index in range(cartridge_id.length()):
		var code := cartridge_id.unicode_at(character_index)
		var is_letter := code >= 97 and code <= 122
		var is_digit := code >= 48 and code <= 57
		var is_symbol := code == 45 or code == 46 or code == 95
		if not (is_letter or is_digit or is_symbol):
			return false
	return true


static func from_package_manifest(package_manifest: Dictionary, base_path: String) -> Dictionary:
	var package_id := String(package_manifest.get("id", ""))
	var entry_scene := String(package_manifest.get("entry_scene", "main.tscn"))
	var author_name := String(package_manifest.get("author", "OpenPocket Contributors"))
	return {
		"format_version": FORMAT_VERSION,
		"id": package_id,
		"name": String(package_manifest.get("name", package_id)),
		"version": String(package_manifest.get("version", "0.3.0-dev")),
		"type": String(package_manifest.get("type", "game")),
		"entry_scene": base_path.path_join(entry_scene),
		"sdk_version": String(package_manifest.get("sdk_version", "0.3.0")),
		"runtime": {"min_version": "0.3.0", "max_version": null},
		"author": {"name": author_name, "url": ""},
		"description": String(package_manifest.get("description", "OpenPocket cartridge.")),
		"category": String(package_manifest.get("category", "misc")),
		"icon": String(package_manifest.get("icon", "icon.png")),
		"license": String(package_manifest.get("license", "MIT")),
		"capabilities": Array(package_manifest.get("capabilities", ["storage", "audio", "theme"])),
		"permissions": [],
		"content": {"file": "content.pck", "sha256": "0".repeat(64)},
		"signature": null,
		"store": {"featured": false, "tags": []},
		"_base_path": base_path,
	}
