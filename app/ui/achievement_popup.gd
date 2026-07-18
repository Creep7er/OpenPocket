extends Control
class_name AchievementPopup

var achievement_name := "ACHIEVEMENT"
var description := "UNLOCKED"
var _elapsed := 0.0


func setup(definition: Dictionary) -> void:
	achievement_name = String(definition.get("name", "ACHIEVEMENT")).to_upper()
	description = String(definition.get("description", "UNLOCKED")).to_upper()
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	queue_redraw()


func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= 3.0:
		queue_free()


func _draw() -> void:
	var p := PocketTheme.palette()
	var panel := Rect2(Vector2(8, 8), Vector2(384, 62))
	draw_rect(Rect2(panel.position + Vector2(3, 3), panel.size), p["dark"], true)
	draw_rect(panel, p["case_dark"], true)
	draw_rect(panel, p["hi"], false, 2)
	draw_rect(Rect2(panel.position + Vector2(8, 9), Vector2(42, 42)), p["case_mid"], true)
	PixelFont.draw_text(self, panel.position + Vector2(17, 20), "V", p["hi"], 2)
	PixelFont.draw_text(self, panel.position + Vector2(60, 10), "ACHIEVEMENT UNLOCKED", p["case_light"], 1)
	PixelFont.draw_text(self, panel.position + Vector2(60, 26), achievement_name.left(30), p["hi"], 2)
	PixelFont.draw_text(self, panel.position + Vector2(60, 48), description.left(48), p["case_light"], 1)
