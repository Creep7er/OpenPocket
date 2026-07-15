extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.example.game"


func _process(_delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		exit_to_library.emit()
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(24, 48), "EXAMPLE GAME", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(24, 92), "USE POCKET API ONLY", p["light"], 1)
	PixelFont.draw_text(self, Vector2(24, size.y - 24), "B BACK  MENU SYSTEM", p["light"], 1)
