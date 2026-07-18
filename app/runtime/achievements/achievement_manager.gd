extends Node

signal achievement_unlocked(scoped_id: String, definition: Dictionary)

const Storage := preload("res://app/runtime/achievements/achievement_storage.gd")
const Definition := preload("res://app/runtime/achievements/achievement_definition.gd")

var _storage := Storage.new()
var _data: Dictionary = {}


func _ready() -> void:
	_data = _storage.load_data()


func process_event(cartridge: Dictionary, event_name: String, amount: float, set_value: bool = false) -> Array[String]:
	var cartridge_id := String(cartridge.get("id", ""))
	if cartridge_id.is_empty() or event_name.is_empty():
		return []
	var unlocked: Array[String] = []
	var records := Dictionary(_data.get("achievements", {}))
	for value in Array(cartridge.get("achievements", [])):
		var definition := Dictionary(value)
		if not Definition.validate(definition) or String(definition.get("event", "")) != event_name:
			continue
		var scoped_id := cartridge_id + ":" + String(definition.get("id", ""))
		var record := Dictionary(records.get(scoped_id, {}))
		if bool(record.get("unlocked", false)):
			continue
		var kind := String(definition.get("type", "event"))
		var progress := amount if set_value or kind == "value" else float(record.get("progress", 0.0)) + amount
		var target := float(definition.get("target", 1.0))
		var comparison := String(definition.get("comparison", "gte"))
		var complete := progress >= target
		if comparison == "lte": complete = progress <= target
		elif comparison == "eq": complete = is_equal_approx(progress, target)
		record = {"unlocked": complete, "progress": progress, "target": target}
		if complete:
			record["unlocked_at"] = Time.get_datetime_string_from_system(true)
			unlocked.append(scoped_id)
		records[scoped_id] = record
		if complete: achievement_unlocked.emit(scoped_id, definition.duplicate(true))
	_data = {"format_version": 1, "achievements": records}
	_storage.save_data(_data)
	return unlocked


func all_progress() -> Dictionary:
	return Dictionary(_data.get("achievements", {})).duplicate(true)
