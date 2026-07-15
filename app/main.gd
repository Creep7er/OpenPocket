extends Control

const ConsoleFrameScene := preload("res://app/ui/console_frame.gd")
const ShellViewScene := preload("res://app/shell/shell_view.gd")
const SystemMenuScene := preload("res://app/shell/system_menu.gd")

var console_frame: Control
var shell_view: Control
var system_menu: Control
var active_game: Node
var active_package: Dictionary = {}
var current_route := "home"


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	DisplayServer.window_set_min_size(Vector2i(360, 640))
	CartridgeManager.bootstrap()
	PocketPackages.load_builtin_packages()
	PocketRouter.route_changed.connect(_on_route_changed)
	PocketRouter.system_menu_requested.connect(_open_system_menu)
	_build_console()
	PocketRouter.go_home()


func _process(_delta: float) -> void:
	if system_menu != null:
		return
	if PocketInput.just_pressed(PocketInput.MENU):
		_open_system_menu()
	if PocketInput.just_pressed(PocketInput.EXIT):
		_handle_exit_button()


func _build_console() -> void:
	console_frame = ConsoleFrameScene.new()
	add_child(console_frame)
	console_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	console_frame.virtual_button_changed.connect(PocketInput.set_virtual_button)

	shell_view = ShellViewScene.new()
	console_frame.set_screen(shell_view)
	shell_view.launch_package.connect(_launch_package)
	shell_view.request_settings.connect(PocketRouter.open_settings)
	shell_view.request_about.connect(PocketRouter.open_about)


func _on_route_changed(route: String, payload: Dictionary) -> void:
	current_route = route
	if active_game != null and route != "game":
		CartridgeAudio.end_scope()
		active_game.queue_free()
		active_game = null
		active_package = {}
		console_frame.set_screen(shell_view)

	match route:
		"home":
			shell_view.show_home()
		"library":
			shell_view.show_library(PocketPackages.get_packages())
		"settings":
			shell_view.show_settings()
		"about":
			shell_view.show_about()
		"store":
			shell_view.show_store()
		"game":
			_launch_package(payload)
		_:
			shell_view.show_home()


func _launch_package(manifest: Dictionary) -> void:
	var cartridge_id := String(manifest.get("id", ""))
	var launch_result: Dictionary = CartridgeManager.launch(cartridge_id)
	if not bool(launch_result.get("ok", false)):
		PocketSystem.notify("Cannot launch cartridge: " + String(launch_result.get("error", "unknown")))
		PocketRouter.open_library()
		return
	var entry_scene_path: String = String(launch_result.get("entry_scene", ""))
	var packed_scene: PackedScene = load(entry_scene_path) as PackedScene
	if packed_scene == null:
		PocketSystem.notify("Package entry scene missing: " + entry_scene_path)
		PocketRouter.open_library()
		return

	if active_game != null:
		CartridgeAudio.end_scope()
		active_game.queue_free()
	active_package = manifest
	active_game = packed_scene.instantiate()
	CartridgeAudio.begin_scope(cartridge_id)
	console_frame.set_screen(active_game)
	if bool(manifest.get("open_settings", false)) and active_game.has_method("open_settings"):
		active_game.call_deferred("open_settings")
	if active_game.has_signal("exit_to_library"):
		active_game.exit_to_library.connect(PocketRouter.open_library)
	if active_game.has_signal("request_system_menu"):
		active_game.request_system_menu.connect(_open_system_menu)


func _open_system_menu() -> void:
	if system_menu != null:
		return
	_set_content_input_enabled(false)
	system_menu = SystemMenuScene.new()
	system_menu.has_active_game = active_game != null
	system_menu.has_game_settings = active_game != null and active_game.has_method("open_settings")
	system_menu.confirm_exit = false
	system_menu.resume_requested.connect(_close_system_menu)
	system_menu.restart_requested.connect(_restart_game)
	system_menu.home_requested.connect(_go_home_from_menu)
	system_menu.settings_requested.connect(_settings_from_menu)
	system_menu.game_settings_requested.connect(_game_settings_from_menu)
	system_menu.library_requested.connect(_library_from_menu)
	system_menu.exit_requested.connect(_open_exit_confirmation)
	console_frame.show_screen_overlay(system_menu)
	PocketAudio.pause()


func _open_exit_confirmation() -> void:
	if system_menu != null:
		console_frame.clear_screen_overlay()
	system_menu = SystemMenuScene.new()
	system_menu.confirm_exit = true
	system_menu.has_active_game = active_game != null
	system_menu.resume_requested.connect(_close_system_menu)
	system_menu.exit_requested.connect(PocketSystem.exit_application)
	console_frame.show_screen_overlay(system_menu)
	PocketAudio.error()


func _close_system_menu() -> void:
	if system_menu == null:
		return
	console_frame.clear_screen_overlay()
	system_menu = null
	_set_content_input_enabled(true)
	PocketAudio.back()


func _restart_game() -> void:
	var package_to_restart: Dictionary = active_package.duplicate()
	_close_system_menu()
	if not package_to_restart.is_empty():
		_launch_package(package_to_restart)


func _go_home_from_menu() -> void:
	_close_system_menu()
	PocketRouter.go_home()


func _settings_from_menu() -> void:
	_close_system_menu()
	PocketRouter.open_settings()


func _game_settings_from_menu() -> void:
	var game := active_game
	_close_system_menu()
	if game != null and game.has_method("open_settings"):
		game.call("open_settings")


func _library_from_menu() -> void:
	_close_system_menu()
	PocketRouter.open_library()


func _handle_exit_button() -> void:
	if system_menu != null:
		_close_system_menu()
		return
	if active_game != null:
		_open_system_menu()
	elif current_route == "home":
		_open_exit_confirmation()
	else:
		PocketRouter.back()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_exit_button()


func _set_content_input_enabled(enabled: bool) -> void:
	if active_game != null and active_game.has_method("set_paused_by_system"):
		active_game.set_paused_by_system(not enabled)
	if active_game == null and shell_view.has_method("set_input_enabled"):
		shell_view.set_input_enabled(enabled)
