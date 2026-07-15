extends Node

var _package_id := ""


func begin_scope(package_id: String) -> bool:
	end_scope()
	_package_id = package_id
	if not PocketAudio.begin_cartridge_scope(package_id):
		_package_id = ""
		return false
	return true


func end_scope() -> void:
	if _package_id.is_empty():
		return
	PocketAudio.stop_cartridge_sounds(_package_id)
	_package_id = ""


func play_ui(event_name: String) -> bool:
	return PocketAudio.play_cartridge_safe(_package_id, event_name)


func play_sfx(stream_id: String) -> bool:
	return PocketAudio.play_cartridge_safe(_package_id, stream_id)


func stop_own_sounds() -> void:
	if not _package_id.is_empty():
		PocketAudio.stop_cartridge_sounds(_package_id)


func set_local_volume(value: float) -> void:
	if not _package_id.is_empty():
		PocketAudio.set_cartridge_volume(_package_id, value)


func active_package_id() -> String:
	return _package_id
