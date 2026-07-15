extends Control

signal exit_to_library
signal request_system_menu

var cursor := 0
var rows := ["NEW NOTE", "SETTINGS", "ABOUT"]


func _process(_delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		exit_to_library.emit()
	if PocketInput.just_pressed(PocketInput.UP):
		cursor = max(0, cursor - 1)
		CartridgeAudio.play_ui("focus")
		queue_redraw()
	if PocketInput.just_pressed(PocketInput.DOWN):
		cursor = min(rows.size() - 1, cursor + 1)
		CartridgeAudio.play_ui("focus")
		queue_redraw()
	if PocketInput.just_pressed(PocketInput.A):
		CartridgeAudio.play_ui("select")


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(24, 36), "EXAMPLE APP", p["hi"], 2)
	for i in rows.size():
		var y := 92 + i * 28
		if i == cursor:
			draw_rect(Rect2(20, y - 12, 180, 20), p["hi"], true)
		PixelFont.draw_text(self, Vector2(28, y), rows[i], p["dark"] if i == cursor else p["light"], 1)
	PixelFont.draw_text(self, Vector2(24, size.y - 26), "A SELECT  B LIBRARY  MENU PAUSE", p["light"], 1)
