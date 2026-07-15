extends RefCounted

const Trust := preload("res://app/runtime/cartridges/cartridge_trust.gd")

var _mounted: Dictionary = {}


func prepare_launch(record: Dictionary, developer_mode: bool) -> Dictionary:
	var trust := String(record.get("trust", Trust.UNTRUSTED))
	if not Trust.is_launch_allowed(trust, developer_mode):
		return {"ok": false, "error": "blocked", "entry_scene": ""}
	var content_path := String(record.get("content_path", ""))
	var cartridge_id := String(record.get("id", ""))
	if not content_path.is_empty() and FileAccess.file_exists(content_path) and not _mounted.has(cartridge_id):
		var loaded := ProjectSettings.load_resource_pack(content_path, false)
		if not loaded:
			return {"ok": false, "error": "pck_load_failed", "entry_scene": ""}
		_mounted[cartridge_id] = content_path
	var entry_scene := String(record.get("entry_scene", ""))
	if entry_scene.is_empty() or not ResourceLoader.exists(entry_scene, "PackedScene"):
		return {"ok": false, "error": "entry_scene_missing", "entry_scene": entry_scene}
	return {"ok": true, "error": "", "entry_scene": entry_scene}


func is_mounted(cartridge_id: String) -> bool:
	return _mounted.has(cartridge_id)
