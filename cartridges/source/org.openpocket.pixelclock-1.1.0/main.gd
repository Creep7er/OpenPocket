extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.openpocket.pixelclock"
const MODES := ["CLOCK", "STOPWATCH", "TIMER", "SETTINGS"]

var mode := 0
var running := false
var elapsed := 0.0
var timer_seconds := 300.0


func _ready() -> void:
	set_process(true)
	timer_seconds = float(PocketStorage.get_package_setting(PACKAGE_ID, "timer_seconds", 300))


func _process(delta: float) -> void:
	if running:
		if mode == 1:
			elapsed += delta
		elif mode == 2:
			timer_seconds = maxf(0.0, timer_seconds - delta)
			if timer_seconds <= 0.0:
				running = false
				CartridgeAudio.play_ui("error")
	if PocketInput.just_pressed(PocketInput.LEFT):
		mode = wrapi(mode - 1, 0, MODES.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.RIGHT):
		mode = wrapi(mode + 1, 0, MODES.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.A):
		_activate()
	if PocketInput.just_pressed(PocketInput.X) and mode == 3:
		var current := bool(PocketStorage.get_package_setting(PACKAGE_ID, "hour_24", true))
		PocketStorage.set_package_setting(PACKAGE_ID, "hour_24", not current)
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.Y) and mode == 3:
		var display_style := String(PocketStorage.get_package_setting(PACKAGE_ID, "display_style", "MONO"))
		PocketStorage.set_package_setting(PACKAGE_ID, "display_style", "AMBER" if display_style == "MONO" else "MONO")
		CartridgeAudio.play_ui("select")
	if PocketInput.just_pressed(PocketInput.B):
		exit_to_library.emit()
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
	queue_redraw()


func _activate() -> void:
	if mode in [1, 2]:
		running = not running
	elif mode == 3:
		var seconds := int(timer_seconds) + 60
		timer_seconds = float(wrapi(seconds, 60, 3660))
		PocketStorage.set_package_setting(PACKAGE_ID, "timer_seconds", int(timer_seconds))
	CartridgeAudio.play_ui("select")


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	draw_rect(Rect2(8, 8, size.x - 16, size.y - 16), p["mid"], false, 2)
	PixelFont.draw_text(self, Vector2(16, 16), "PIXEL CLOCK 1.1", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(16, 48), "< " + MODES[mode] + " >", p["light"], 1)
	var value := _display_value()
	var width := PixelFont.measure(value, 4).x
	PixelFont.draw_text(self, Vector2((size.x - width) / 2.0, 112), value, p["hi"], 4)
	var status := "RUNNING" if running else "READY"
	if mode == 3:
		status = "24H " + ("ON" if bool(PocketStorage.get_package_setting(PACKAGE_ID, "hour_24", true)) else "OFF")
		status += "  STYLE " + String(PocketStorage.get_package_setting(PACKAGE_ID, "display_style", "MONO"))
	PixelFont.draw_text(self, Vector2(16, 220), status, p["light"], 1)
	PixelFont.draw_text(self, Vector2(16, 286), "A SET  X 12/24  Y STYLE  B BACK", p["light"], 1)


func _display_value() -> String:
	if mode == 0:
		var now := Time.get_time_dict_from_system()
		var hour := int(now.get("hour", 0))
		if not bool(PocketStorage.get_package_setting(PACKAGE_ID, "hour_24", true)):
			hour = ((hour + 11) % 12) + 1
		return "%02d:%02d:%02d" % [hour, int(now.get("minute", 0)), int(now.get("second", 0))]
	if mode == 1:
		return "%02d:%02d.%d" % [int(elapsed) / 60, int(elapsed) % 60, int(elapsed * 10.0) % 10]
	return "%02d:%02d" % [int(timer_seconds) / 60, int(timer_seconds) % 60]


func set_paused_by_system(paused: bool) -> void:
	set_process(not paused)
