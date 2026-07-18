extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.openpocket.notes"
const KEYBOARD := " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789.-!?"

var notes: Array[String] = []
var selected_index := 0
var mode := "list"
var edit_text := ""
var key_index := 1


func _ready() -> void:
	_load_notes()


func _process(_delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
	if mode == "edit":
		_process_edit()
	else:
		_process_list()
	queue_redraw()


func _process_list() -> void:
	if PocketInput.just_pressed(PocketInput.UP):
		selected_index = wrapi(selected_index - 1, 0, max(notes.size(), 1))
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		selected_index = wrapi(selected_index + 1, 0, max(notes.size(), 1))
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.A):
		edit_text = notes[selected_index] if not notes.is_empty() and selected_index < notes.size() else ""
		mode = "edit"
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.X) and not notes.is_empty():
		notes.remove_at(selected_index)
		selected_index = clampi(selected_index, 0, max(notes.size() - 1, 0))
		_save_notes()
		CartridgeAudio.play_ui("back")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		exit_to_library.emit()


func _process_edit() -> void:
	if PocketInput.just_pressed(PocketInput.LEFT):
		key_index = wrapi(key_index - 1, 0, KEYBOARD.length())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.RIGHT):
		key_index = wrapi(key_index + 1, 0, KEYBOARD.length())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.A) and edit_text.length() < 42:
		edit_text += KEYBOARD.substr(key_index, 1)
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.X) and not edit_text.is_empty():
		edit_text = edit_text.substr(0, edit_text.length() - 1)
		CartridgeAudio.play_ui("back")
	if PocketInput.just_pressed(PocketInput.Y):
		_commit_note()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		mode = "list"
		CartridgeAudio.play_ui("back")


func _commit_note() -> void:
	var clean := edit_text.strip_edges()
	if clean.is_empty():
		mode = "list"
		return
	if notes.is_empty() or selected_index >= notes.size():
		notes.append(clean)
		selected_index = notes.size() - 1
	else:
		notes[selected_index] = clean
	_save_notes()
	CartridgeAchievements.emit_event("note_saved")
	CartridgeAchievements.set_value("note_count", notes.size())
	mode = "list"
	CartridgeAudio.play_ui("select")


func _load_notes() -> void:
	notes.clear()
	var stored: Array = Array(PocketStorage.get_package_value(PACKAGE_ID, "notes", []))
	for item in stored:
		notes.append(String(item))


func _save_notes() -> void:
	PocketStorage.set_package_value(PACKAGE_ID, "notes", notes)


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(12, 12), "POCKET NOTES", p["hi"], 2)
	draw_rect(Rect2(Vector2(10, 38), Vector2(size.x - 20, 2)), p["mid"], true)
	if mode == "edit":
		_draw_edit(p)
	else:
		_draw_list(p)


func _draw_list(p: Dictionary) -> void:
	if notes.is_empty():
		PixelFont.draw_text(self, Vector2(18, 68), "NO NOTES\nA CREATE\nB LIBRARY", p["light"], 1)
	else:
		for index in range(min(notes.size(), 7)):
			var y := 58 + index * 26
			var selected := index == selected_index
			if selected:
				draw_rect(Rect2(Vector2(14, y - 4), Vector2(size.x - 28, 20)), p["light"], true)
			var color: Color = p["dark"] if selected else p["hi"]
			PixelFont.draw_text(self, Vector2(22, y), notes[index].left(28).to_upper(), color, 1)
	PixelFont.draw_text(self, Vector2(14, size.y - 18), "A EDIT  X DEL  B BACK", p["light"], 1)


func _draw_edit(p: Dictionary) -> void:
	draw_rect(Rect2(Vector2(14, 58), Vector2(size.x - 28, 82)), p["mid"], false, 2)
	PixelFont.draw_text(self, Vector2(22, 70), edit_text.to_upper(), p["hi"], 1)
	var key := KEYBOARD.substr(key_index, 1)
	PixelFont.draw_text(self, Vector2(22, 160), "CHAR [" + key + "]", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(14, size.y - 34), "LR CHAR  A ADD  X DEL", p["light"], 1)
	PixelFont.draw_text(self, Vector2(14, size.y - 18), "Y SAVE  B CANCEL", p["light"], 1)
