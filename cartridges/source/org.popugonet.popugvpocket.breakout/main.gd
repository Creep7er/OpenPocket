extends Control

signal exit_to_library
signal request_system_menu

const PACKAGE_ID := "org.popugonet.popugvpocket.breakout"
const SCREEN_MENU := "menu"
const SCREEN_PLAYING := "playing"
const SCREEN_SETTINGS := "settings"
const SCREEN_HOWTO := "howto"
const SCREEN_STATS := "stats"
const SCREEN_QUIT := "quit"
const SCREEN_GAME_OVER := "game_over"
const SCREEN_WIN := "win"
const BALL_RADIUS := 4.0
const PADDLE_Y := 282.0
const BOARD_LEFT := 10.0
const BOARD_RIGHT := 390.0
const BOARD_TOP := 42.0
const PADDLE_SPEED := 230.0
const MENU_ITEMS: Array[String] = ["PLAY", "SETTINGS", "HOW TO PLAY", "STATISTICS", "BACK"]
const SETTING_KEYS: Array[String] = ["difficulty", "paddle", "ball_speed", "sound"]

var screen := SCREEN_MENU
var menu_index := 0
var settings_index := 0
var end_index := 0
var quit_index := 0
var paused_by_system := false
var settings: Dictionary = {}
var stats: Dictionary = {}

var paddle_x := 160.0
var ball := Vector2(200, 246)
var velocity := Vector2.ZERO
var bricks: Array[Rect2] = []
var ball_served := false
var life_pause := 0.0
var score := 0
var lives := 3


func _ready() -> void:
	_load_settings()
	_load_stats()
	_reset_round()


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
		SCREEN_HOWTO, SCREEN_STATS:
			_process_info()
		SCREEN_QUIT:
			_process_quit()
		SCREEN_GAME_OVER, SCREEN_WIN:
			_process_end()
		SCREEN_PLAYING:
			_process_game(delta)
	queue_redraw()


func _draw() -> void:
	var palette := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), palette["dark"], true)
	match screen:
		SCREEN_MENU:
			_draw_menu(palette)
		SCREEN_SETTINGS:
			_draw_settings(palette)
		SCREEN_HOWTO:
			_draw_howto(palette)
		SCREEN_STATS:
			_draw_stats(palette)
		SCREEN_QUIT:
			_draw_game(palette)
			_draw_quit(palette)
		SCREEN_GAME_OVER, SCREEN_WIN:
			_draw_end(palette)
		_:
			_draw_game(palette)


func set_paused_by_system(value: bool) -> void:
	paused_by_system = value


func open_settings() -> void:
	screen = SCREEN_SETTINGS
	settings_index = 0


func _process_menu() -> void:
	if PocketInput.just_pressed(PocketInput.UP):
		menu_index = wrapi(menu_index - 1, 0, MENU_ITEMS.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		menu_index = wrapi(menu_index + 1, 0, MENU_ITEMS.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		exit_to_library.emit()
	if PocketInput.just_pressed(PocketInput.A):
		CartridgeAudio.play_ui("select")
		match menu_index:
			0:
				_start_game()
			1:
				screen = SCREEN_SETTINGS
			2:
				screen = SCREEN_HOWTO
			3:
				screen = SCREEN_STATS
			4:
				exit_to_library.emit()


func _process_settings() -> void:
	var item_count := SETTING_KEYS.size() + 1
	if PocketInput.just_pressed(PocketInput.UP):
		settings_index = wrapi(settings_index - 1, 0, item_count)
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		settings_index = wrapi(settings_index + 1, 0, item_count)
		CartridgeAudio.play_ui("focus")
	if settings_index < SETTING_KEYS.size() and (PocketInput.just_pressed(PocketInput.LEFT) or PocketInput.just_pressed(PocketInput.RIGHT)):
		_cycle_setting(SETTING_KEYS[settings_index], 1 if PocketInput.just_pressed(PocketInput.RIGHT) else -1)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A) and settings_index == SETTING_KEYS.size():
		screen = SCREEN_MENU


func _process_info() -> void:
	if PocketInput.just_pressed(PocketInput.A) or PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
		CartridgeAudio.play_ui("back")


func _process_game(delta: float) -> void:
	_move_paddle(delta)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_QUIT
		quit_index = 0
		return
	if life_pause > 0.0:
		life_pause = maxf(0.0, life_pause - delta)
		_attach_ball_to_paddle()
		return
	if not ball_served:
		_attach_ball_to_paddle()
		if PocketInput.just_pressed(PocketInput.A):
			_serve_ball()
		return
	_step_ball(delta)


func _process_quit() -> void:
	if PocketInput.just_pressed(PocketInput.UP) or PocketInput.just_pressed(PocketInput.DOWN):
		quit_index = 1 - quit_index
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_PLAYING
	if PocketInput.just_pressed(PocketInput.A):
		if quit_index == 0:
			screen = SCREEN_PLAYING
		else:
			CartridgeAudio.stop_own_sounds()
			screen = SCREEN_MENU


func _process_end() -> void:
	if PocketInput.just_pressed(PocketInput.UP) or PocketInput.just_pressed(PocketInput.DOWN):
		end_index = 1 - end_index
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A):
		if end_index == 0:
			_start_game()
		else:
			screen = SCREEN_MENU


func _start_game() -> void:
	score = 0
	lives = 3
	end_index = 0
	_reset_round()
	screen = SCREEN_PLAYING


func _reset_round() -> void:
	_build_bricks()
	paddle_x = (400.0 - _paddle_width()) * 0.5
	ball_served = false
	life_pause = 0.0
	_attach_ball_to_paddle()


func _move_paddle(delta: float) -> void:
	var direction := 0.0
	if PocketInput.is_pressed(PocketInput.LEFT):
		direction -= 1.0
	if PocketInput.is_pressed(PocketInput.RIGHT):
		direction += 1.0
	paddle_x = clampf(paddle_x + direction * PADDLE_SPEED * delta, BOARD_LEFT, BOARD_RIGHT - _paddle_width())


func _attach_ball_to_paddle() -> void:
	ball = Vector2(paddle_x + _paddle_width() * 0.5, PADDLE_Y - BALL_RADIUS - 2.0)


func _serve_ball() -> void:
	var speed := _ball_speed()
	var horizontal := 0.62 if randi() % 2 == 0 else -0.62
	velocity = Vector2(horizontal, -0.78).normalized() * speed
	ball_served = true
	CartridgeAudio.play_sfx("select")


func _step_ball(delta: float) -> void:
	var travel := velocity.length() * delta
	var steps := clampi(int(ceil(travel / 4.0)), 1, 12)
	var step_delta := delta / float(steps)
	for _step in range(steps):
		var previous := ball
		ball += velocity * step_delta
		_resolve_walls()
		_resolve_paddle(previous)
		if _resolve_brick(previous):
			if bricks.is_empty():
				_finish_game(true)
				return
		if ball.y - BALL_RADIUS > 320.0:
			_lose_life()
			return


func _resolve_walls() -> void:
	if ball.x - BALL_RADIUS < BOARD_LEFT:
		ball.x = BOARD_LEFT + BALL_RADIUS
		velocity.x = absf(velocity.x)
	if ball.x + BALL_RADIUS > BOARD_RIGHT:
		ball.x = BOARD_RIGHT - BALL_RADIUS
		velocity.x = -absf(velocity.x)
	if ball.y - BALL_RADIUS < BOARD_TOP:
		ball.y = BOARD_TOP + BALL_RADIUS
		velocity.y = absf(velocity.y)


func _resolve_paddle(previous: Vector2) -> void:
	if velocity.y <= 0.0:
		return
	var paddle := Rect2(Vector2(paddle_x, PADDLE_Y), Vector2(_paddle_width(), 9.0)).grow(BALL_RADIUS)
	if not paddle.has_point(ball) or previous.y > PADDLE_Y:
		return
	ball.y = PADDLE_Y - BALL_RADIUS
	var offset := clampf((ball.x - (paddle_x + _paddle_width() * 0.5)) / (_paddle_width() * 0.5), -1.0, 1.0)
	var speed := maxf(_ball_speed(), velocity.length())
	velocity = Vector2(offset * 0.78, -maxf(0.45, 1.0 - absf(offset) * 0.35)).normalized() * speed
	CartridgeAudio.play_sfx("bounce")


func _resolve_brick(previous: Vector2) -> bool:
	for index in range(bricks.size()):
		var brick := bricks[index]
		if not brick.grow(BALL_RADIUS).has_point(ball):
			continue
		var hit_side := previous.x <= brick.position.x - BALL_RADIUS or previous.x >= brick.end.x + BALL_RADIUS
		if hit_side:
			velocity.x *= -1.0
		else:
			velocity.y *= -1.0
		bricks.remove_at(index)
		score += 10
		CartridgeAudio.play_sfx("brick")
		return true
	return false


func _lose_life() -> void:
	lives -= 1
	ball_served = false
	velocity = Vector2.ZERO
	CartridgeAudio.play_sfx("life")
	if lives <= 0:
		_finish_game(false)
	else:
		life_pause = 0.65
		_attach_ball_to_paddle()


func _finish_game(won: bool) -> void:
	ball_served = false
	velocity = Vector2.ZERO
	stats["games"] = int(stats.get("games", 0)) + 1
	stats["wins"] = int(stats.get("wins", 0)) + (1 if won else 0)
	stats["high_score"] = maxi(int(stats.get("high_score", 0)), score)
	PocketStorage.set_package_data(PACKAGE_ID, "statistics", stats)
	screen = SCREEN_WIN if won else SCREEN_GAME_OVER
	end_index = 0
	CartridgeAudio.play_sfx("win" if won else "error")


func _build_bricks() -> void:
	bricks.clear()
	var rows := {"easy": 3, "normal": 4, "hard": 5}.get(String(settings.get("difficulty", "normal")), 4) as int
	for row in range(rows):
		for column in range(8):
			bricks.append(Rect2(14.0 + column * 47.0, 62.0 + row * 18.0, 41.0, 10.0))


func _load_settings() -> void:
	settings = {
		"difficulty": PocketStorage.get_package_setting(PACKAGE_ID, "difficulty", "normal"),
		"paddle": PocketStorage.get_package_setting(PACKAGE_ID, "paddle", "normal"),
		"ball_speed": PocketStorage.get_package_setting(PACKAGE_ID, "ball_speed", "normal"),
		"sound": PocketStorage.get_package_setting(PACKAGE_ID, "sound", true),
	}


func _load_stats() -> void:
	stats = Dictionary(PocketStorage.get_package_data(PACKAGE_ID, "statistics", {"games": 0, "wins": 0, "high_score": 0}))


func _cycle_setting(key: String, delta: int) -> void:
	if key == "sound":
		settings[key] = not bool(settings.get(key, true))
	else:
		var values: Array[String] = ["easy", "normal", "hard"] if key == "difficulty" else ["small", "normal", "large"] if key == "paddle" else ["slow", "normal", "fast"]
		var current := String(settings.get(key, values[1]))
		settings[key] = values[wrapi(values.find(current) + delta, 0, values.size())]
	PocketStorage.set_package_setting(PACKAGE_ID, key, settings[key])
	CartridgeAudio.play_ui("focus")


func _paddle_width() -> float:
	match String(settings.get("paddle", "normal")):
		"small":
			return 56.0
		"large":
			return 88.0
	return 72.0


func _ball_speed() -> float:
	match String(settings.get("ball_speed", "normal")):
		"slow":
			return 155.0
		"fast":
			return 225.0
	return 190.0


func _draw_menu(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 28), "BREAKOUT", palette["hi"], 2)
	_draw_rows(MENU_ITEMS, menu_index, 82, palette)
	PixelFont.draw_text(self, Vector2(24, 276), "HIGH SCORE " + str(stats.get("high_score", 0)), palette["light"], 1)


func _draw_settings(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(20, 24), "BREAKOUT SETTINGS", palette["hi"], 2)
	var labels: Array[String] = [
		"DIFFICULTY  " + String(settings["difficulty"]).to_upper(),
		"PADDLE      " + String(settings["paddle"]).to_upper(),
		"BALL SPEED  " + String(settings["ball_speed"]).to_upper(),
		"SOUND       " + ("ON" if bool(settings["sound"]) else "OFF"),
		"BACK",
	]
	_draw_rows(labels, settings_index, 78, palette)


func _draw_howto(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "HOW TO PLAY", palette["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 76), "MOVE PADDLE  LEFT RIGHT\nSERVE        A\nPAUSE        MENU\nLEAVE ROUND  B", palette["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 176), "CLEAR EVERY BRICK.\nYOU HAVE THREE LIVES.", palette["hi"], 1)
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", palette["light"], 1)


func _draw_stats(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "STATISTICS", palette["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 82), "GAMES       " + str(stats.get("games", 0)), palette["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 112), "WINS        " + str(stats.get("wins", 0)), palette["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 142), "HIGH SCORE  " + str(stats.get("high_score", 0)), palette["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", palette["light"], 1)


func _draw_game(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(10, 12), "BREAKOUT  SCORE " + str(score) + "  LIVES " + str(lives), palette["hi"], 1)
	draw_rect(Rect2(Vector2(BOARD_LEFT, BOARD_TOP), Vector2(BOARD_RIGHT - BOARD_LEFT, 260)), palette["mid"], false, 1)
	for brick in bricks:
		draw_rect(brick, palette["light"], true)
		draw_rect(brick, palette["hi"], false, 1)
	draw_rect(Rect2(Vector2(paddle_x, PADDLE_Y), Vector2(_paddle_width(), 9)), palette["hi"], true)
	draw_rect(Rect2(ball - Vector2(BALL_RADIUS, BALL_RADIUS), Vector2(BALL_RADIUS * 2.0, BALL_RADIUS * 2.0)), palette["light"], true)
	if not ball_served and life_pause <= 0.0:
		PixelFont.draw_text(self, Vector2(152, 248), "A SERVE", palette["light"], 1)


func _draw_quit(palette: Dictionary) -> void:
	var panel := Rect2(Vector2(82, 104), Vector2(236, 112))
	draw_rect(panel, palette["dark"], true)
	draw_rect(panel, palette["hi"], false, 2)
	PixelFont.draw_text(self, panel.position + Vector2(18, 16), "LEAVE ROUND?", palette["hi"], 1)
	_draw_rows(["CANCEL", "MAIN MENU"], quit_index, 148, palette, int(panel.position.x + 12), int(panel.size.x - 24))


func _draw_end(palette: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 28), "YOU WIN" if screen == SCREEN_WIN else "GAME OVER", palette["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 82), "SCORE      " + str(score), palette["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 106), "HIGH SCORE " + str(stats.get("high_score", 0)), palette["light"], 1)
	_draw_rows(["RETRY", "MAIN MENU"], end_index, 166, palette)


func _draw_rows(labels: Array[String], current: int, start_y: int, palette: Dictionary, row_x: int = 20, row_width: int = 360) -> void:
	for index in range(labels.size()):
		var selected := index == current
		var y := start_y + index * 26
		if selected:
			draw_rect(Rect2(Vector2(row_x, y - 5), Vector2(row_width, 20)), palette["light"], true)
		var color: Color = palette["dark"] if selected else palette["hi"]
		PixelFont.draw_text(self, Vector2(row_x + 8, y), ("> " if selected else "  ") + labels[index], color, 1)
