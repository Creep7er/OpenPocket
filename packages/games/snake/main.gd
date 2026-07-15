extends Control

signal exit_to_library
signal request_system_menu

const SnakeConfig := preload("res://packages/games/snake/snake_config.gd")
const SnakeRules := preload("res://packages/games/snake/snake_rules.gd")
const SnakeStatistics := preload("res://packages/games/snake/snake_statistics.gd")

const PACKAGE_ID := "org.openpocket.snake"
const SCREEN_MENU := "menu"
const SCREEN_PLAYING := "playing"
const SCREEN_SETTINGS := "settings"
const SCREEN_STATS := "stats"
const SCREEN_HOWTO := "howto"
const SCREEN_GAME_OVER := "game_over"

var screen := SCREEN_MENU
var menu_index := 0
var settings_index := 0
var game_over_index := 0
var settings: Dictionary = {}
var stats: Dictionary = {}
var high_score := 0

var grid_size := Vector2i(16, 16)
var snake: Array[Vector2i] = []
var direction := Vector2i.RIGHT
var direction_buffer: Array[Vector2i] = []
var food := Vector2i.ZERO
var obstacles: Array[Vector2i] = []
var score := 0
var food_eaten := 0
var longest_snake := 0
var elapsed := 0.0
var match_time_left := 0.0
var food_timer := 0.0
var growth_pending := 0
var game_finished := false
var paused_by_system := false
var launch_input_delay := 0.18


func _ready() -> void:
	randomize()
	_load_settings()
	_load_stats()
	_update_high_score()


func _process(delta: float) -> void:
	if paused_by_system:
		return
	if launch_input_delay > 0.0:
		launch_input_delay = maxf(0.0, launch_input_delay - delta)
		queue_redraw()
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
		SCREEN_GAME_OVER:
			_process_game_over()
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
		SCREEN_GAME_OVER:
			_draw_game_over(p)
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
		_cycle_setting_by_key("difficulty", 1 if PocketInput.just_pressed(PocketInput.RIGHT) else -1)
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
				screen = SCREEN_STATS
			3:
				screen = SCREEN_HOWTO
			4:
				exit_to_library.emit()


func _process_settings() -> void:
	var defs: Array[Dictionary] = SnakeConfig.setting_defs()
	if PocketInput.just_pressed(PocketInput.UP):
		settings_index = wrapi(settings_index - 1, 0, defs.size() + 2)
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		settings_index = wrapi(settings_index + 1, 0, defs.size() + 2)
		CartridgeAudio.play_ui("focus")
	if settings_index < defs.size() and (PocketInput.just_pressed(PocketInput.LEFT) or PocketInput.just_pressed(PocketInput.RIGHT)):
		var direction_delta := 1 if PocketInput.just_pressed(PocketInput.RIGHT) else -1
		_cycle_setting(defs[settings_index], direction_delta)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A):
		if settings_index == defs.size():
			PocketStorage.reset_package_settings(PACKAGE_ID)
			_load_settings()
			_update_high_score()
			CartridgeAudio.play_ui("error")
		elif settings_index == defs.size() + 1:
			screen = SCREEN_MENU


func _process_back_screen() -> void:
	if PocketInput.just_pressed(PocketInput.A) or PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
		CartridgeAudio.play_ui("back")


func _process_game_over() -> void:
	var items := ["RETRY", "SETTINGS", "MAIN MENU", "LIBRARY"]
	if PocketInput.just_pressed(PocketInput.UP):
		game_over_index = wrapi(game_over_index - 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.DOWN):
		game_over_index = wrapi(game_over_index + 1, 0, items.size())
		CartridgeAudio.play_ui("focus")
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
	if PocketInput.just_pressed(PocketInput.A):
		CartridgeAudio.play_ui("select")
		match game_over_index:
			0:
				_start_game()
			1:
				screen = SCREEN_SETTINGS
			2:
				screen = SCREEN_MENU
			3:
				exit_to_library.emit()


func _process_game(delta: float) -> void:
	_read_direction_input()
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		screen = SCREEN_MENU
		return
	if String(settings.get("mode", "classic")) == "time_attack":
		match_time_left -= delta
		if match_time_left <= 0.0:
			_finish_game()
			return
	if String(settings.get("food_mode", "classic")) == "timed":
		food_timer -= delta
		if food_timer <= 0.0:
			_spawn_food()
	elapsed += delta
	var difficulty := String(settings.get("difficulty", "normal"))
	var step_seconds := float(Dictionary(SnakeConfig.DIFFICULTY_CONFIG.get(difficulty, SnakeConfig.DIFFICULTY_CONFIG["normal"])).get("step_seconds", 0.17))
	if elapsed >= step_seconds:
		elapsed = 0.0
		_step()


func _start_game() -> void:
	var grid_value: Variant = SnakeConfig.GRID_CONFIG.get(String(settings.get("grid", "normal")), Vector2i(16, 16))
	grid_size = grid_value if grid_value is Vector2i else Vector2i(16, 16)
	var start_y := int(grid_size.y / 2)
	snake = [Vector2i(3, start_y), Vector2i(2, start_y), Vector2i(1, start_y)]
	direction = Vector2i.RIGHT
	direction_buffer.clear()
	score = 0
	food_eaten = 0
	longest_snake = snake.size()
	elapsed = 0.0
	match_time_left = SnakeConfig.TIME_ATTACK_SECONDS
	growth_pending = 0
	game_finished = false
	_generate_obstacles()
	_spawn_food()
	screen = SCREEN_PLAYING


func _read_direction_input() -> void:
	var candidates: Array[Vector2i] = []
	if PocketInput.just_pressed(PocketInput.UP):
		candidates.append(Vector2i.UP)
	if PocketInput.just_pressed(PocketInput.DOWN):
		candidates.append(Vector2i.DOWN)
	if PocketInput.just_pressed(PocketInput.LEFT):
		candidates.append(Vector2i.LEFT)
	if PocketInput.just_pressed(PocketInput.RIGHT):
		candidates.append(Vector2i.RIGHT)
	for candidate in candidates:
		var base := direction_buffer[-1] if not direction_buffer.is_empty() else direction
		if not SnakeRules.is_reverse(base, candidate) and direction_buffer.size() < 2:
			direction_buffer.append(candidate)


func _step() -> void:
	if not direction_buffer.is_empty():
		direction = direction_buffer.pop_front()
	var move: Dictionary = SnakeRules.move_head(snake[0], direction, grid_size, String(settings.get("walls", "solid")))
	var head: Vector2i = move["head"]
	if bool(move["wall_collision"]) or snake.has(head) or obstacles.has(head):
		_finish_game()
		return
	snake.insert(0, head)
	if head == food:
		food_eaten += 1
		score += SnakeConfig.score_for_food(settings)
		growth_pending += int(settings.get("growth", 1))
		longest_snake = maxi(longest_snake, snake.size())
		_spawn_food()
	if growth_pending > 0:
		growth_pending -= 1
	else:
		snake.pop_back()
	longest_snake = maxi(longest_snake, snake.size())


func _finish_game() -> void:
	if game_finished:
		return
	game_finished = true
	_update_high_score_after_game()
	stats = SnakeStatistics.update_after_game(stats, settings, score, food_eaten, longest_snake)
	PocketStorage.set_package_data(PACKAGE_ID, "statistics", stats)
	screen = SCREEN_GAME_OVER
	CartridgeAudio.play_ui("error")


func _spawn_food() -> void:
	var blocked: Array[Vector2i] = []
	blocked.append_array(snake)
	blocked.append_array(obstacles)
	for attempt in range(256):
		var candidate := Vector2i(randi_range(0, grid_size.x - 1), randi_range(0, grid_size.y - 1))
		if not blocked.has(candidate):
			food = candidate
			food_timer = SnakeConfig.TIMED_FOOD_SECONDS
			return
	food = SnakeRules.first_free_cell(grid_size, blocked)
	food_timer = SnakeConfig.TIMED_FOOD_SECONDS


func _generate_obstacles() -> void:
	obstacles.clear()
	var mode := String(settings.get("obstacles", "off"))
	var count := 0
	if mode == "low":
		count = 5
	elif mode == "high":
		count = 12
	var protected := [snake[0], snake[0] + Vector2i.RIGHT, snake[0] + Vector2i.RIGHT * 2]
	while obstacles.size() < count:
		var candidate := Vector2i(randi_range(1, grid_size.x - 2), randi_range(1, grid_size.y - 2))
		if snake.has(candidate) or obstacles.has(candidate) or protected.has(candidate):
			continue
		obstacles.append(candidate)


func _load_settings() -> void:
	settings = SnakeConfig.DEFAULT_SETTINGS.duplicate()
	var keys := settings.keys()
	for key in keys:
		settings[key] = PocketStorage.get_package_setting(PACKAGE_ID, String(key), settings[key])


func _load_stats() -> void:
	stats = SnakeStatistics.DEFAULTS.duplicate()
	var stored: Dictionary = Dictionary(PocketStorage.get_package_data(PACKAGE_ID, "statistics", {}))
	for key in stored.keys():
		stats[key] = stored[key]


func _update_high_score() -> void:
	high_score = int(PocketStorage.get_package_data(PACKAGE_ID, SnakeConfig.high_score_key(settings), 0))


func _update_high_score_after_game() -> void:
	var key := SnakeConfig.high_score_key(settings)
	var stored := int(PocketStorage.get_package_data(PACKAGE_ID, key, 0))
	if score > stored:
		PocketStorage.set_package_data(PACKAGE_ID, key, score)
		high_score = score


func _cycle_setting_by_key(key: String, delta: int) -> void:
	for def in SnakeConfig.setting_defs():
		if String(def["key"]) == key:
			_cycle_setting(def, delta)
			return


func _cycle_setting(definition: Dictionary, delta: int) -> void:
	var values: Array = Array(definition["values"])
	var key := String(definition["key"])
	var current: Variant = settings.get(key, SnakeConfig.DEFAULT_SETTINGS.get(key))
	var index := values.find(current)
	if index < 0:
		index = 0
	index = wrapi(index + delta, 0, values.size())
	settings[key] = values[index]
	PocketStorage.set_package_setting(PACKAGE_ID, key, settings[key])
	_update_high_score()
	CartridgeAudio.play_ui("focus")


func _value_label(definition: Dictionary) -> String:
	var values: Array = Array(definition["values"])
	var labels: Array = Array(definition["labels"])
	var index := values.find(settings.get(String(definition["key"])))
	if index < 0:
		index = 0
	return String(labels[index])


func _draw_menu(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(28, 32), "SNAKE", p["hi"], 2)
	_draw_menu_items(["PLAY", "SETTINGS", "STATISTICS", "HOW TO PLAY", "BACK"], menu_index, 88, p)
	PixelFont.draw_text(self, Vector2(28, 242), "HIGH SCORE " + _pad_score(high_score), p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 262), "DIFFICULTY " + String(settings.get("difficulty", "normal")).to_upper(), p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 282), "LEFT RIGHT CHANGES DIFFICULTY", p["mid"], 1)


func _draw_settings(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "SNAKE SETTINGS", p["hi"], 2)
	var defs: Array[Dictionary] = SnakeConfig.setting_defs()
	var y := 70
	for index in range(defs.size()):
		var selected := index == settings_index
		_draw_row(22, y, String(defs[index]["label"]), _value_label(defs[index]), selected, p)
		y += 24
	_draw_row(22, y + 6, "RESET SETTINGS", "", settings_index == defs.size(), p)
	_draw_row(22, y + 30, "BACK", "", settings_index == defs.size() + 1, p)
	PixelFont.draw_text(self, Vector2(22, 292), "APPLIES NEXT GAME", p["mid"], 1)


func _draw_stats(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "SNAKE STATS", p["hi"], 2)
	var rows := [
		["GAMES PLAYED", stats["games_played"]],
		["TOTAL SCORE", stats["total_score"]],
		["FOOD EATEN", stats["food_eaten"]],
		["BEST CLASSIC", stats["best_classic"]],
		["BEST TIME ATTACK", stats["best_time_attack"]],
		["LONGEST SNAKE", stats["longest_snake"]],
	]
	var y := 72
	for row in rows:
		_draw_row(28, y, String(row[0]), str(row[1]), false, p)
		y += 26
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", p["light"], 1)


func _draw_howto(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 24), "HOW TO PLAY", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 76), "MOVE       D-PAD\nPAUSE      MENU\nBACK       B", p["light"], 1)
	var wall_text := "DO NOT HIT WALLS." if String(settings.get("walls", "solid")) == "solid" else "WRAP THROUGH EDGES."
	PixelFont.draw_text(self, Vector2(28, 160), "EAT FOOD TO GROW.\nDO NOT HIT YOUR BODY.\n" + wall_text, p["hi"], 1)
	PixelFont.draw_text(self, Vector2(28, 286), "A/B BACK", p["light"], 1)


func _draw_game_over(p: Dictionary) -> void:
	PixelFont.draw_text(self, Vector2(24, 28), "GAME OVER", p["hi"], 2)
	PixelFont.draw_text(self, Vector2(28, 72), "SCORE      " + _pad_score(score), p["light"], 1)
	PixelFont.draw_text(self, Vector2(28, 94), "HIGH SCORE " + _pad_score(high_score), p["light"], 1)
	_draw_menu_items(["RETRY", "SETTINGS", "MAIN MENU", "LIBRARY"], game_over_index, 148, p)


func _draw_game(p: Dictionary) -> void:
	var mode_label := "TA " + str(maxi(0, int(ceil(match_time_left)))) if String(settings.get("mode")) == "time_attack" else "CLASSIC"
	PixelFont.draw_text(self, Vector2(12, 12), "SCORE " + str(score) + "  HI " + str(high_score) + "  " + mode_label, p["hi"], 1)
	var cell_size: float = floor(min((size.x - 28.0) / grid_size.x, (size.y - 58.0) / grid_size.y))
	var board_size := Vector2(cell_size * grid_size.x, cell_size * grid_size.y)
	var origin := Vector2(floor((size.x - board_size.x) * 0.5), 42.0)
	draw_rect(Rect2(origin, board_size), p["dark"], true)
	draw_rect(Rect2(origin, board_size), p["hi"], false, 2)
	for obstacle in obstacles:
		draw_rect(Rect2(origin + Vector2(obstacle) * cell_size + Vector2(3, 3), Vector2(cell_size - 6, cell_size - 6)), p["mid"], true)
	for part in snake:
		draw_rect(Rect2(origin + Vector2(part) * cell_size + Vector2(2, 2), Vector2(cell_size - 4, cell_size - 4)), p["hi"], true)
		draw_rect(Rect2(origin + Vector2(part) * cell_size + Vector2(4, 4), Vector2(cell_size - 8, cell_size - 8)), p["light"], true)
	var food_rect := Rect2(origin + Vector2(food) * cell_size + Vector2(3, 3), Vector2(cell_size - 6, cell_size - 6))
	draw_rect(food_rect, p["light"], true)
	draw_rect(food_rect.grow(-3), p["hi"], true)
	PixelFont.draw_text(self, Vector2(12, size.y - 18), "MENU PAUSE  B MENU", p["light"], 1)


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


func _pad_score(value: int) -> String:
	return str(value).pad_zeros(4)


func _draw_scanlines(p: Dictionary) -> void:
	if not bool(PocketStorage.get_setting("scanlines", false)):
		return
	for y in range(1, int(size.y), 4):
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, 1)), p["mid"], true)
