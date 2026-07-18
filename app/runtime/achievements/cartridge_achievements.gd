extends Node


func emit_event(event_name: String, amount: float = 1.0, _metadata: Dictionary = {}) -> void:
	_submit(event_name, amount, false)


func increment(event_name: String, amount: float = 1.0) -> void:
	_submit(event_name, amount, false)


func set_value(event_name: String, value: float, _metadata: Dictionary = {}) -> void:
	_submit(event_name, value, true)


func _submit(event_name: String, value: float, set_value: bool) -> void:
	var cartridge_id := String(CartridgeManager.active_context().get("id", ""))
	if not cartridge_id.is_empty():
		AchievementManager.process_event(CartridgeManager.get_cartridge(cartridge_id), event_name, value, set_value)
