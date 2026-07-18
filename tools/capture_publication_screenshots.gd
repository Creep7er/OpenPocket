extends Control

const MainScene := preload("res://app/main.tscn")
const BreakoutScene := preload("res://cartridges/source/org.popugonet.popugvpocket.breakout/main.tscn")
const CAPTURE_SIZE := Vector2i(393, 852)
const LANDSCAPE_SIZE := Vector2i(852, 393)
const OUTPUT_DIR := "res://docs/screenshots"

var app: Control
var _saved_settings: Dictionary = {}
var _capture_size := CAPTURE_SIZE


func _ready() -> void:
	DisplayServer.window_set_size(CAPTURE_SIZE)
	_save_capture_settings()
	_apply_capture_settings()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))

	app = MainScene.instantiate()
	add_child(app)
	await _wait_frames(5)
	await _capture("boot.png")
	app.shell_view.booting = false

	await _capture_shell_screens()
	await _capture_builtin_screens()
	await _capture_breakout()
	await _capture_landscape_profile()
	_build_hero()
	_restore_capture_settings()
	CartridgeAudio.end_scope()
	app.free()
	app = null
	await _wait_frames(2)
	print("Publication screenshots captured at 393x852.")
	var tree := get_tree()
	var exit_timer := tree.create_timer(0.1)
	exit_timer.timeout.connect(func() -> void: tree.quit(0))
	queue_free()


func _capture_shell_screens() -> void:
	app.shell_view.show_home()
	await _capture("home.png")
	await _capture("vboy-home.png")
	app.call("_open_system_menu")
	await _capture("system-menu.png")
	app.call("_close_system_menu")

	var packages: Array[Dictionary] = PocketPackages.get_packages()
	app.shell_view.show_library(packages)
	await _capture("library.png")
	await _capture("vboy-library.png")

	if not packages.is_empty():
		app.shell_view.call("_show_cartridge_details", packages[0])
		await _capture("cartridge-details.png")

	PocketStorage.set_setting("developer_mode", false)
	var fixture := ProjectSettings.globalize_path("res://store/test_fixtures/org.popugonet.popugvpocket.pixelclock-1.0.0.pctrg")
	app.shell_view.call("_prepare_external_install", fixture)
	await _capture("install-cartridge.png")
	await _capture("vboy-install.png")
	PocketStorage.set_setting("developer_mode", true)

	app.shell_view.show_store()
	await _capture("store.png")
	await _capture("vboy-store.png")
	app.shell_view.screen = "store_download"
	app.shell_view.items.clear()
	app.shell_view.items.append({"label": "Cancel", "action": "cancel_download"})
	app.shell_view.call("_on_store_download_state_changed", {"state": "downloading", "progress": 0.74, "item": {"name": "Pixel Clock"}})
	await _capture("store-download.png")
	app.shell_view.show_settings()
	app.shell_view.call("_show_customize")
	await _capture("customize-themes.png")
	app.shell_view.show_home()
	app.call("_on_achievement_unlocked", "org.popugonet.popugvpocket.snake:first_meal", {"name": "First Meal", "description": "Eat the first fruit."})
	await _capture("achievement-unlocked.png")
	if app.achievement_popup != null:
		app.achievement_popup.free()
		app.achievement_popup = null
	PocketStorage.set_setting("direction_control", "dpad")
	await _capture("controls-dpad.png")


func _capture_builtin_screens() -> void:
	await _launch_builtin("org.popugonet.popugvpocket.snake")
	await _capture("snake-menu.png")
	app.active_game.call("_start_game")
	await _capture("snake.png")

	await _launch_builtin("org.popugonet.popugvpocket.pong")
	await _capture("pong-menu.png")
	app.active_game.call("_start_match")
	await _capture("pong.png")

	await _launch_builtin("org.popugonet.popugvpocket.notes")
	var demo_notes: Array[String] = ["PUBLIC SNAPSHOT", "CARTRIDGES READY", "PIXEL NOTES"]
	app.active_game.notes = demo_notes
	app.active_game.selected_index = 1
	app.active_game.queue_redraw()
	await _capture("notes.png")


func _capture_breakout() -> void:
	_clear_active_game()
	var breakout := BreakoutScene.instantiate()
	app.active_game = breakout
	app.active_package = {"id": "org.popugonet.popugvpocket.breakout", "name": "Breakout Mini"}
	CartridgeAudio.begin_scope("org.popugonet.popugvpocket.breakout")
	app.console_frame.set_screen(breakout)
	await _wait_frames(3)
	await _capture("breakout-menu.png")
	breakout.call("_start_game")
	breakout.call("_serve_ball")
	breakout.screen = "quit"
	await _capture("breakout-dialog.png")
	breakout.screen = "playing"
	await _capture("breakout.png")


func _capture_landscape_profile() -> void:
	_clear_active_game()
	PocketStorage.set_setting("console_profile", "vgirl")
	_capture_size = LANDSCAPE_SIZE
	DisplayServer.window_set_min_size(Vector2i(640, 360))
	DisplayServer.window_set_size(_capture_size)
	await _wait_frames(8)
	app.shell_view.show_home()
	await _capture("vgirl-home.png")
	app.shell_view.show_library(PocketPackages.get_packages())
	await _capture("vgirl-library.png")
	app.shell_view.show_store()
	await _capture("vgirl-store.png")
	app.shell_view.show_settings()
	await _capture("vgirl-settings.png")
	app.shell_view.show_home()
	await _capture("vgirl-controls.png")
	PocketStorage.set_setting("direction_control", "stick")
	PocketStorage.set_setting("stick_mode", "fixed")
	await _capture("controls-fixed-stick.png")
	PocketStorage.set_setting("stick_mode", "floating")
	await _capture("controls-floating-stick.png")
	await _launch_builtin("org.popugonet.popugvpocket.snake")
	app.active_game.call("_start_game")
	await _capture("vgirl-game.png")
	PocketStorage.set_setting("console_profile", "vboy")
	PocketStorage.set_setting("direction_control", "dpad")
	_capture_size = CAPTURE_SIZE
	DisplayServer.window_set_min_size(Vector2i(360, 640))
	DisplayServer.window_set_size(_capture_size)
	await _wait_frames(8)


func _launch_builtin(cartridge_id: String) -> void:
	var manifest: Dictionary = CartridgeManager.get_cartridge(cartridge_id)
	if manifest.is_empty():
		push_error("Missing built-in cartridge: " + cartridge_id)
		get_tree().quit(1)
		return
	app.call("_launch_package", manifest)
	await _wait_frames(3)


func _clear_active_game() -> void:
	if app.active_game != null:
		CartridgeAudio.end_scope()
		app.active_game.queue_free()
		app.active_game = null
		app.active_package = {}
	app.console_frame.set_screen(app.shell_view)


func _capture(filename: String) -> void:
	app.queue_redraw()
	app.console_frame.queue_redraw()
	if is_instance_valid(app.console_frame.current_screen) and app.console_frame.current_screen is CanvasItem:
		app.console_frame.current_screen.queue_redraw()
	await _wait_frames(6)
	await RenderingServer.frame_post_draw
	var image := get_viewport().get_texture().get_image()
	if image.get_size() != _capture_size:
		push_error("Unexpected screenshot size: " + str(image.get_size()))
		get_tree().quit(1)
		return
	var result := image.save_png(OUTPUT_DIR.path_join(filename))
	if result != OK:
		push_error("Could not save screenshot: " + filename)
		get_tree().quit(1)


func _build_hero() -> void:
	var border := 16
	var gap := 12
	var hero_size := Vector2i(CAPTURE_SIZE.x + gap + LANDSCAPE_SIZE.x + border * 2, CAPTURE_SIZE.y + border * 2)
	var hero := Image.create(hero_size.x, hero_size.y, false, Image.FORMAT_RGBA8)
	hero.fill(Color("162317"))
	var vboy := Image.load_from_file(OUTPUT_DIR.path_join("vboy-home.png"))
	var vgirl := Image.load_from_file(OUTPUT_DIR.path_join("vgirl-home.png"))
	var mascot := Image.load_from_file("res://app/assets/branding/v-parrot-idle.png")
	vboy.convert(Image.FORMAT_RGBA8)
	vgirl.convert(Image.FORMAT_RGBA8)
	mascot.convert(Image.FORMAT_RGBA8)
	hero.blit_rect(vboy, Rect2i(Vector2i.ZERO, CAPTURE_SIZE), Vector2i(border, border))
	hero.blit_rect(vgirl, Rect2i(Vector2i.ZERO, LANDSCAPE_SIZE), Vector2i(border + CAPTURE_SIZE.x + gap, border))
	var mascot_position := Vector2i(border + CAPTURE_SIZE.x + gap + (LANDSCAPE_SIZE.x - mascot.get_width()) / 2, border + LANDSCAPE_SIZE.y + 42)
	hero.blend_rect(mascot, Rect2i(Vector2i.ZERO, mascot.get_size()), mascot_position)
	var result := hero.save_png(OUTPUT_DIR.path_join("popugvpocket-0.5.1-hero.png"))
	if result != OK:
		push_error("Could not save hero image")
		get_tree().quit(1)


func _save_capture_settings() -> void:
	for key in ["theme", "scanlines", "debug_info", "developer_mode", "sound_enabled", "console_profile", "direction_control", "stick_mode"]:
		_saved_settings[key] = PocketStorage.get_setting(key, null)


func _apply_capture_settings() -> void:
	PocketStorage.set_setting("theme", "mono")
	PocketStorage.set_setting("scanlines", false)
	PocketStorage.set_setting("debug_info", false)
	PocketStorage.set_setting("developer_mode", false)
	PocketStorage.set_setting("sound_enabled", false)
	PocketStorage.set_setting("console_profile", "vboy")
	PocketStorage.set_setting("direction_control", "dpad")
	PocketStorage.set_setting("stick_mode", "fixed")
	DisplayServer.window_set_min_size(Vector2i(360, 640))
	DisplayServer.window_set_size(CAPTURE_SIZE)


func _restore_capture_settings() -> void:
	for key in _saved_settings:
		PocketStorage.set_setting(String(key), _saved_settings[key])


func _wait_frames(count: int) -> void:
	for _index in count:
		await get_tree().process_frame
