extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.popugonet.popugvpocket.dice"
const DICE := [4, 6, 8, 10, 12, 20]
var die_index := 1
var result := 1
var history: Array[int] = []
var animation := 0.0
var random := RandomNumberGenerator.new()


func _ready() -> void:
	random.randomize()
	die_index = int(PocketStorage.get_package_setting(PACKAGE_ID, "die_index", 1))


func _process(delta: float) -> void:
	if animation > 0.0:
		animation -= delta
		result = random.randi_range(1, DICE[die_index])
	if PocketInput.just_pressed(PocketInput.LEFT):
		die_index = wrapi(die_index - 1, 0, DICE.size())
		_save_die()
	if PocketInput.just_pressed(PocketInput.RIGHT):
		die_index = wrapi(die_index + 1, 0, DICE.size())
		_save_die()
	if PocketInput.just_pressed(PocketInput.A):
		result = random.randi_range(1, DICE[die_index])
		history.push_front(result)
		if history.size() > 6: history.pop_back()
		animation = 0.28
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.B): exit_to_library.emit()
	if PocketInput.just_pressed(PocketInput.MENU): request_system_menu.emit()
	queue_redraw()


func _save_die() -> void:
	PocketStorage.set_package_setting(PACKAGE_ID, "die_index", die_index)
	CartridgeAudio.play_ui("focus")


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(16, 16), "POCKET DICE", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(126, 58), "< D" + str(DICE[die_index]) + " >", p["light"], 2)
	draw_rect(Rect2(120, 100, 160, 120), p["mid"], true)
	draw_rect(Rect2(120, 100, 160, 120), p["hi"], false, 4)
	var text := str(result)
	PixelFont.draw_text(self, Vector2(200 - PixelFont.measure(text, 6).x / 2, 136), text, p["hi"], 6)
	PixelFont.draw_text(self, Vector2(16, 238), "HISTORY " + " ".join(PackedStringArray(history.map(func(v: int) -> String: return str(v)))), p["light"], 1)
	PixelFont.draw_text(self, Vector2(16, 286), "LEFT RIGHT DIE  A ROLL  B BACK", p["light"], 1)


func set_paused_by_system(paused: bool) -> void: set_process(not paused)
