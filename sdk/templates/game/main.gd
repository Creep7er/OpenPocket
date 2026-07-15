extends Control

signal exit_to_library
signal request_system_menu


func _process(_delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
	if PocketInput.just_pressed(PocketInput.B):
		exit_to_library.emit()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(24, 42), "EXAMPLE GAME", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(24, 78), "A START\nB LIBRARY\nMENU PAUSE", p["light"], 1)
