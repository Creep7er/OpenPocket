extends Control

signal exit_to_library
signal request_system_menu

const PongConfig := preload("res://packages/games/pong/pong_config.gd")
const PongRules := preload("res://packages/games/pong/pong_rules.gd")
const PongCPU := preload("res://packages/games/pong/pong_cpu_controller.gd")
const PongStatistics := preload("res://packages/games/pong/pong_statistics.gd")

const PACKAGE_ID := "org.openpocket.pong"
const SCREEN_MENU := "menu"
const SCREEN_PLAYING := "playing"
const SCREEN_SETTINGS := "settings"
const SCREEN_STATS := "stats"
const SCREEN_HOWTO := "howto"
const SCREEN_MATCH_OVER := "match_over"

var screen := SCREEN_MENU
var menu_index := 0
var settings_index := 0
var over_index := 0
var settings: Dictionary = {}
var stats: Dictionary = {}
var paused_by_system := false

var paddle_y := 120.0
var cpu_y := 120.0
var ball := Vector2(200, 160)
var velocity := Vector2(165, 76)
var player_score := 0
var cpu_score := 0
var rally := 0
var longest_rally := 0
var serve_to_player := false
var match_recorded := false


func _ready() -> void:
	randomize()
	_load_settings()
	_load_stats()


func _process(delta: float) -> void:
	if paused_by_system:
		return
	if PocketInput.just_pressed(PocketInput.MENU):
		request_system_menu.emit()
		return
	match screen:
		SCREEN_MENU:
			_process_menu()
		SCREEN_SETTINGS:
			_process_settings()
		SCREEN_STATS, SCREEN_HOWTO:
			_process_back_screen()
		SCREEN_MATCH_OVER:
			_process_match_over()
		SCREEN_PLAYING:
			_process_game(delta)
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	match screen:
		SCREEN_MENU:
			_draw_menu(p)
		SCREEN_SETTINGS:
			_draw_settings(p)
		SCREEN_STATS:
			_draw_stats(p)
		SCREEN_HOWTO:
			_draw_howto(p)
		SCREEN_MATCH_OVER:
			_draw_match_over(p)
		_:
			_draw_game(p)
	_draw_scanlines(p)


func set_paused_by_system(value: bool) -> void:
	paused_by_system = value


func open_settings() -> void:
	screen = SCREEN_SETTINGS
	settings_index = 0


func _process_menu() -> void:
	var items := ["PLAY", "SETTINGS", "STATISTICS", "HOW TO PLAY", "BACK"]
	if PocketInput.just_pressed(PocketInput.UP):
		menu_index = wrapi(menu_index - 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		menu_index = wrapi(menu_index + 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.LEFT) or PocketInput.just_pressed(PocketInput.RIGHT):
		_cycle_setting_by_key("cpu", 1 if PocketInput.just_pressed(PocketInput.RIGHT) else -1)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		exit_to_library.emit()
	if PocketInput.just_pressed(PocketInput.A):
		CartridgeAudio.play_ui("select")
		match menu_index:
			0:
				_start_match()
			1:
				screen = SCREEN_SETTINGS
			2:
				screen = SCREEN_STATS
			3:
				screen = SCREEN_HOWTO
			4:
				exit_to_library.emit()


func _process_settings() -> void:
	var defs: Array[Dictionary] = PongConfig.setting_defs()
	if PocketInput.just_pressed(PocketInput.UP):
		settings_index = wrapi(settings_index - 1, 0, defs.size() + 2)
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		settings_index = wrapi(settings_index + 1, 0, defs.size() + 2)
		CartridgeAudio.play_ui("focus")
	if settings_index < defs.size() and (PocketInput.just_pressed(PocketInput.LEFT) or PocketInput.just_pressed(PocketInput.RIGHT)):
		_cycle_setting(defs[settings_index], 1 if PocketInput.just_pressed(PocketInput.RIGHT) else -1)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A):
		if settings_index == defs.size():
			PocketStorage.reset_package_settings(PACKAGE_ID)
			_load_settings()
			CartridgeAudio.play_ui("error")
		elif settings_index == defs.size() + 1:
			screen = SCREEN_MENU


func _process_back_screen() -> void:
	if PocketInput.just_pressed(PocketInput.A) or PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
		CartridgeAudio.play_ui("back")


func _process_match_over() -> void:
	var items := ["REMATCH", "SETTINGS", "MAIN MENU", "LIBRARY"]
	if PocketInput.just_pressed(PocketInput.UP):
		over_index = wrapi(over_index - 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		over_index = wrapi(over_index + 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A):
		match over_index:
			0:
				_start_match()
			1:
				screen = SCREEN_SETTINGS
			2:
				screen = SCREEN_MENU
			3:
				exit_to_library.emit()


func _process_game(delta: float) -> void:
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
		return
	var paddle_h := PongConfig.paddle_height(settings)
	var player_speed := 190.0
	if PocketInput.is_pressed(PocketInput.UP):
		paddle_y -= player_speed * delta
	if PocketInput.is_pressed(PocketInput.DOWN):
		paddle_y += player_speed * delta
	paddle_y = clampf(paddle_y, 42.0, size.y - 18.0 - paddle_h)
	cpu_y = PongCPU.next_paddle_y(cpu_y, ball.y, paddle_h, settings, delta)
	cpu_y = clampf(cpu_y, 42.0, size.y - 18.0 - paddle_h)
	_step_ball(delta)


func _start_match() -> void:
	player_score = 0
	cpu_score = 0
	rally = 0
	longest_rally = 0
	match_recorded = false
	paddle_y = size.y * 0.5 - PongConfig.paddle_height(settings) * 0.5
	cpu_y = paddle_y
	_serve(1.0)
	screen = SCREEN_PLAYING


func _serve(direction: float) -> void:
	ball = Vector2(size.x * 0.5, size.y * 0.5)
	var base := PongConfig.base_ball_speed(settings)
	if String(settings.get("serve", "alternate")) == "random":
		direction = -1.0 if randi() % 2 == 0 else 1.0
	velocity = Vector2(base * direction, randf_range(-base * 0.35, base * 0.35))
	rally = 0


func _step_ball(delta: float) -> void:
	var paddle_h := PongConfig.paddle_height(settings)
	ball += velocity * delta
	if ball.y < 40.0:
		ball.y = 40.0
		velocity.y = absf(velocity.y)
	if ball.y > size.y - 18.0:
		ball.y = size.y - 18.0
		velocity.y = -absf(velocity.y)
	var player_paddle := Rect2(Vector2(20, paddle_y), Vector2(10, paddle_h))
	var cpu_paddle := Rect2(Vector2(size.x - 30, cpu_y), Vector2(10, paddle_h))
	var cap := PongConfig.base_ball_speed(settings) * 1.85
	if player_paddle.grow(3).has_point(ball) and velocity.x < 0.0:
		velocity = PongRules.bounce_from_paddle(ball.y, paddle_y, paddle_h, PongConfig.base_ball_speed(settings) * 1.06, 1.0)
		velocity = PongRules.capped_velocity(velocity, cap)
		rally += 1
		longest_rally = maxi(longest_rally, rally)
		CartridgeAudio.play_ui("select")
	if cpu_paddle.grow(3).has_point(ball) and velocity.x > 0.0:
		velocity = PongRules.bounce_from_paddle(ball.y, cpu_y, paddle_h, PongConfig.base_ball_speed(settings) * 1.04, -1.0)
		velocity = PongRules.capped_velocity(velocity, cap)
		rally += 1
		longest_rally = maxi(longest_rally, rally)
	if ball.x < -8.0:
		cpu_score += 1
		_after_point(1.0)
	if ball.x > size.x + 8.0:
		player_score += 1
		_after_point(-1.0)


func _after_point(next_direction: float) -> void:
	if PongRules.match_finished(player_score, cpu_score, int(settings.get("target_score", 7))):
		_finish_match()
	else:
		_serve(next_direction)


func _finish_match() -> void:
	if not match_recorded:
		stats = PongStatistics.update_after_match(stats, player_score, cpu_score, longest_rally)
		PocketStorage.set_package_data(PACKAGE_ID, "statistics", stats)
		match_recorded = true
	screen = SCREEN_MATCH_OVER
	CartridgeAudio.play_ui("error")


func _load_settings() -> void:
	settings = PongConfig.DEFAULT_SETTINGS.duplicate()
	for key in settings.keys():
		settings[key] = PocketStorage.get_package_setting(PACKAGE_ID, key, settings[key])


func _load_stats() -> void:
	stats = PongStatistics.DEFAULTS.duplicate()
	var stored := Dictionary(PocketStorage.get_package_data(PACKAGE_ID, "statistics", {}))
	for key in stored.keys():
		stats[key] = stored[key]


func _cycle_setting_by_key(key: String, delta: int) -> void:
	for def in PongConfig.setting_defs():
		if String(def["key"]) == key:
			_cycle_setting(def, delta)
			return


func _cycle_setting(definition: Dictionary, delta: int) -> void:
	var values: Array = Array(definition["values"])
	if values.size() <= 1:
		return
	var key := String(definition["key"])
	var current: Variant = settings.get(key, PongConfig.DEFAULT_SETTINGS.get(key))
	var index := values.find(current)
	if index < 0:
		index = 0
	index = wrapi(index + delta, 0, values.size())
	settings[key] = values[index]
	PocketStorage.set_package_setting(PACKAGE_ID, key, settings[key])
	CartridgeAudio.play_ui("focus")


func _value_label(definition: Dictionary) -> String:
	var values: Array = Array(definition["values"])
	var labels: Array = Array(definition["labels"])
	var index := values.find(settings.get(String(definition["key"])))
	if index < 0:
		index = 0
	return String(labels[index])


func _draw_menu(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 32), "POCKET PONG", p["hi"], 2)
	_draw_menu_items(["PLAY", "SETTINGS", "STATISTICS", "HOW TO PLAY", "BACK"], menu_index, 88, p)
	PixelFont.draw_text(self, Vector2(28, 242), "MODE PLAYER VS CPU", p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 262), "CPU " + String(settings["cpu"]).to_upper(), p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 282), "LEFT RIGHT CHANGES CPU", p["mid"], 1)


func _draw_settings(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(20, 24), "PONG SETTINGS", p["hi"], 2)
	var defs: Array[Dictionary] = PongConfig.setting_defs()
	var y := 70
	for index in range(defs.size()):
		_draw_row(22, y, String(defs[index]["label"]), _value_label(defs[index]), index == settings_index, p)
		y += 24
	_draw_row(22, y + 6, "RESET SETTINGS", "", settings_index == defs.size(), p)
	_draw_row(22, y + 30, "BACK", "", settings_index == defs.size() + 1, p)
	PixelFont.draw_text(self, Vector2(22, 292), "APPLIES NEXT MATCH", p["mid"], 1)


func _draw_stats(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "PONG STATS", p["hi"], 2)
	var rows := [
		["MATCHES", stats["matches"]],
		["WINS", stats["wins"]],
		["LOSSES", stats["losses"]],
		["POINTS FOR", stats["points_for"]],
		["POINTS AGAINST", stats["points_against"]],
		["LONGEST RALLY", stats["longest_rally"]],
	]
	var y := 72
	for row in rows:
		_draw_row(28, y, String(row[0]), str(row[1]), false, p)
		y += 26
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", p["light"], 1)


func _draw_howto(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "HOW TO PLAY", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 76), "MOVE       UP DOWN\nPAUSE      MENU\nBACK       B", p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 154), "RETURN THE BALL.\nFIRST TO TARGET WINS.\nCPU CONTROLS RIGHT SIDE.", p["hi"], 1)
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", p["light"], 1)


func _draw_match_over(p: Dictionary) -> void:
	var title := "YOU WIN" if player_score > cpu_score else "CPU WINS"
	PixelFont.draw_text(self, Vector2(24, 28), title, p["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 72), "SCORE " + str(player_score) + " - " + str(cpu_score), p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 94), "RALLY " + str(longest_rally), p["light"], 1)
	_draw_menu_items(["REMATCH", "SETTINGS", "MAIN MENU", "LIBRARY"], over_index, 148, p)


func _draw_game(p: Dictionary) -> void:
	var paddle_h := PongConfig.paddle_height(settings)
	PixelFont.draw_text(self, Vector2(12, 14), "PONG " + str(player_score) + " - " + str(cpu_score) + "  TO " + str(settings["target_score"]), p["hi"], 1)
	draw_rect(Rect2(Vector2(8, 34), Vector2(size.x - 16, size.y - 46)), p["mid"], false, 2)
	for y in range(42, int(size.y - 20), 18):
		draw_rect(Rect2(Vector2(size.x * 0.5 - 1, y), Vector2(2, 10)), p["mid"], true)
	draw_rect(Rect2(Vector2(20, paddle_y), Vector2(10, paddle_h)), p["hi"], true)
	draw_rect(Rect2(Vector2(size.x - 30, cpu_y), Vector2(10, paddle_h)), p["light"], true)
	draw_rect(Rect2(ball - Vector2(4, 4), Vector2(8, 8)), p["hi"], true)
	PixelFont.draw_text(self, Vector2(14, size.y - 18), "UP DOWN  MENU PAUSE  B MENU", p["light"], 1)


func _draw_menu_items(items: Array[String], selected_index: int, start_y: int, p: Dictionary) -> void:
	for index in range(items.size()):
		_draw_row(34, start_y + index * 26, items[index], "", index == selected_index, p)


func _draw_row(x: int, y: int, label: String, value: String, selected: bool, p: Dictionary) -> void:
	if selected:
		draw_rect(Rect2(Vector2(x - 8, y - 5), Vector2(size.x - x * 2 + 16, 20)), p["light"], true)
	var color: Color = p["dark"] if selected else p["hi"]
	var prefix := ">" if selected else " "
	PixelFont.draw_text(self, Vector2(x, y), prefix + " " + label, color, 1)
	if not value.is_empty():
		var text_size := PixelFont.measure(value, 1)
		PixelFont.draw_text(self, Vector2(size.x - x - text_size.x, y), value, color, 1)


func _draw_scanlines(p: Dictionary) -> void:
	if not bool(PocketStorage.get_setting("scanlines", false)):
		return
	for y in range(1, int(size.y), 4):
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, 1)), p["mid"], true)
