extends RefCounted
class_name ConsoleLayoutProfile

var id := ""
var display_name := ""
var orientation := DisplayServer.SCREEN_PORTRAIT
var screen_size := Vector2i(400, 320)
var body_aspect := 0.62


func _init(profile_id: String, label: String, screen_orientation: int, aspect: float) -> void:
	id = profile_id
	display_name = label
	orientation = screen_orientation
	body_aspect = aspect


func is_landscape() -> bool:
	return orientation == DisplayServer.SCREEN_LANDSCAPE

