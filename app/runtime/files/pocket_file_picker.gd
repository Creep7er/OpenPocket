extends Node

signal file_selected(imported_path: String)
signal selection_cancelled
signal import_failed(code: String, message: String)
signal state_changed(state: String, detail: String)
signal copy_progress(bytes_copied: int, total_bytes: int)

const Paths := preload("res://app/runtime/cartridges/cartridge_paths.gd")
const MAX_FILE_SIZE := 64 * 1024 * 1024
const COPY_CHUNK_SIZE := 256 * 1024
const ANDROID_PLUGIN_NAME := "OpenPocketFilePicker"

var state := "idle"
var _android_plugin: Object
var _dialog: FileDialog


func _ready() -> void:
	Paths.ensure()
	if OS.get_name() == "Android" and Engine.has_singleton(ANDROID_PLUGIN_NAME):
		_android_plugin = Engine.get_singleton(ANDROID_PLUGIN_NAME)
		_android_plugin.file_selected.connect(_on_android_file_selected)
		_android_plugin.selection_cancelled.connect(_on_selection_cancelled)
		_android_plugin.import_failed.connect(_on_android_import_failed)
		_android_plugin.copy_progress.connect(_on_android_copy_progress)
	else:
		_create_desktop_dialog()
	if OS.get_name() == "Android":
		_recover_staged_import.call_deferred()


## Opens the platform file picker. Selected files are always copied to app-owned staging.
func open_cartridge_file() -> void:
	if state not in ["idle", "cancelled", "failed"]:
		return
	_set_state("selecting", "SELECTING FILE")
	if OS.get_name() == "Android":
		if _android_plugin == null:
			_fail("PICKER_UNAVAILABLE", "Android file picker plugin is not included.")
			return
		_android_plugin.openCartridgeFile(MAX_FILE_SIZE)
		return
	if _dialog == null:
		_fail("PICKER_UNAVAILABLE", "Desktop file picker is unavailable.")
		return
	_dialog.popup_centered_ratio(0.78)


func reset() -> void:
	_set_state("idle", "")


func _create_desktop_dialog() -> void:
	_dialog = FileDialog.new()
	_dialog.access = FileDialog.ACCESS_FILESYSTEM
	_dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	_dialog.use_native_dialog = true
	_dialog.add_filter("*.pctrg", "OpenPocket Cartridge")
	_dialog.file_selected.connect(_on_desktop_file_selected)
	_dialog.canceled.connect(_on_selection_cancelled)
	add_child(_dialog)


func _on_desktop_file_selected(source_path: String) -> void:
	_set_state("copying", "COPYING FILE")
	var source := FileAccess.open(source_path, FileAccess.READ)
	if source == null:
		_fail("READ_FAILED", "Cannot open selected file.")
		return
	var total_size: int = source.get_length()
	if total_size <= 0 or total_size > MAX_FILE_SIZE:
		source.close()
		_fail("ARCHIVE_TOO_LARGE", "Selected file is empty or exceeds 64 MB.")
		return
	var destination_path := Paths.new_import_path()
	var destination := FileAccess.open(destination_path, FileAccess.WRITE)
	if destination == null:
		source.close()
		_fail("WRITE_FAILED", "Cannot create staging file.")
		return
	var copied := 0
	while copied < total_size:
		var chunk: PackedByteArray = source.get_buffer(mini(COPY_CHUNK_SIZE, total_size - copied))
		if chunk.is_empty():
			break
		destination.store_buffer(chunk)
		copied += chunk.size()
		copy_progress.emit(copied, total_size)
	source.close()
	destination.close()
	if copied != total_size:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(destination_path))
		_fail("COPY_FAILED", "Selected file could not be copied completely.")
		return
	_on_import_ready(destination_path)


func _on_android_file_selected(imported_path: String) -> void:
	_on_import_ready(imported_path)


func _on_android_copy_progress(bytes_copied: int, total_bytes: int) -> void:
	if state != "copying":
		_set_state("copying", "COPYING FILE")
	copy_progress.emit(bytes_copied, total_bytes)


func _on_import_ready(imported_path: String) -> void:
	_set_state("inspecting", "READING CARTRIDGE")
	file_selected.emit(imported_path)


func _on_selection_cancelled() -> void:
	_set_state("cancelled", "CANCELLED")
	selection_cancelled.emit()


func _on_android_import_failed(code: String, message: String) -> void:
	_fail(code, message)


func _fail(code: String, message: String) -> void:
	_set_state("failed", code)
	push_error("PocketFilePicker %s: %s" % [code, message])
	import_failed.emit(code, message)


func _set_state(next_state: String, detail: String) -> void:
	state = next_state
	state_changed.emit(state, detail)


func _recover_staged_import() -> void:
	if state != "idle":
		return
	var directory := DirAccess.open(Paths.DOWNLOADS_DIR)
	if directory == null:
		return
	var newest_path := ""
	var newest_time := 0
	for file_name in directory.get_files():
		if not file_name.begins_with("import-") or not file_name.ends_with(".pctrg"):
			continue
		var path := Paths.DOWNLOADS_DIR.path_join(file_name)
		var modified := FileAccess.get_modified_time(path)
		if modified > newest_time:
			newest_time = modified
			newest_path = path
	if not newest_path.is_empty():
		_on_import_ready(newest_path)
