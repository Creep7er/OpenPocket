extends Control

signal resume_requested
signal restart_requested
signal home_requested
signal settings_requested
signal game_settings_requested
signal library_requested
signal exit_requested

var has_active_game := false
var has_game_settings := false
var confirm_exit := false
var selected_index := 0
var items: Array[Dictionary] = []
var cursor_tick := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if confirm_exit:
		items = [
			{"label": "Cancel", "action": "resume"},
			{"label": "Exit App", "action": "exit"},
		]
	else:
		if has_active_game:
			items = [
				{"label": "Resume", "action": "resume"},
				{"label": "Restart", "action": "restart"},
			]
			if has_game_settings:
				items.append({"label": "Game Settings", "action": "game_settings"})
			items.append({"label": "Library", "action": "library"})
			items.append({"label": "Home", "action": "home"})
		else:
			items = [
				{"label": "Resume", "action": "resume"},
				{"label": "Home", "action": "home"},
				{"label": "Settings", "action": "settings"},
				{"label": "Exit OpenPocket", "action": "exit"},
			]


func _process(delta: float) -> void:
	cursor_tick += delta
	if PocketInput.just_pressed(PocketInput.UP):
		selected_index = wrapi(selected_index - 1, 0, items.size())
		PocketAudio.focus()
	if PocketInput.just_pressed(PocketInput.DOWN):
		selected_index = wrapi(selected_index + 1, 0, items.size())
		PocketAudio.focus()
	if PocketInput.just_pressed(PocketInput.B):
		resume_requested.emit()
	if PocketInput.just_pressed(PocketInput.A):
		_activate()
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	_draw_dither(p)
	var panel := Rect2(Vector2(36, 42), Vector2(size.x - 72, size.y - 84))
	draw_rect(panel, p["dark"], true)
	draw_rect(panel, p["hi"], false, 2)
	draw_rect(Rect2(panel.position + Vector2(6, 6), panel.size - Vector2(12, 12)), p["mid"], false, 2)
	var title := "EXIT OPENPOCKET?" if confirm_exit else "PAUSED" if has_active_game else "SYSTEM"
	PixelFont.draw_text(self, panel.position + Vector2(18, 18), title, p["hi"], 2)
	var y := int(panel.position.y + 60)
	for index in range(items.size()):
		var selected := index == selected_index
		var row := Rect2(Vector2(panel.position.x + 14, y - 4), Vector2(panel.size.x - 28, 20))
		if selected:
			draw_rect(row, p["light"], true)
			draw_rect(row, p["hi"], false, 2)
		var cursor := ">" if selected and int(cursor_tick * 5.0) % 2 == 0 else " "
		var color: Color = p["dark"] if selected else p["hi"]
		PixelFont.draw_text(self, Vector2(panel.position.x + 24, y), cursor + " " + String(items[index]["label"]).to_upper(), color, 1)
		y += 24


func _activate() -> void:
	PocketAudio.select()
	match String(items[selected_index]["action"]):
		"resume":
			resume_requested.emit()
		"restart":
			restart_requested.emit()
		"home":
			home_requested.emit()
		"settings":
			settings_requested.emit()
		"game_settings":
			game_settings_requested.emit()
		"library":
			library_requested.emit()
		"exit":
			exit_requested.emit()


func _draw_dither(p: Dictionary) -> void:
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	for y in range(0, int(size.y), 4):
		for x in range((y / 4) % 2 * 4, int(size.x), 8):
			draw_rect(Rect2(Vector2(x, y), Vector2(4, 4)), p["mid"], true)
