extends Node
class_name StoreDownloadManager

const Job := preload("res://app/runtime/store/store_download_job.gd")

signal state_changed(snapshot: Dictionary)
signal finished(result: Dictionary)

var _active: StoreDownloadJob


func start(item: Dictionary) -> Dictionary:
	if _active != null and _active.state not in ["completed", "failed", "cancelled"]:
		return {"ok": false, "error": "busy", "pending": true}
	if _active != null:
		_active.queue_free()
	_active = Job.new()
	_active.state_changed.connect(state_changed.emit)
	_active.finished.connect(_on_finished)
	add_child(_active)
	return _active.start(item)


func cancel() -> void:
	if _active != null:
		_active.cancel()


func snapshot() -> Dictionary:
	return _active.snapshot() if _active != null else {"state": "idle", "progress": 0.0}


func mark_installing() -> void:
	if _active != null:
		_active.state = "installing"
		state_changed.emit(_active.snapshot())


func mark_completed() -> void:
	if _active != null:
		_active.state = "completed"
		state_changed.emit(_active.snapshot())


func _on_finished(result: Dictionary) -> void:
	finished.emit(result)
