extends Control

signal launch_package(manifest: Dictionary)
signal request_settings
signal request_about

var items: Array[Dictionary] = []
var selected_index := 0
var screen := "home"
var input_enabled := true
var booting := true
var boot_time := 0.0
var cursor_tick := 0.0
var packages: Array[Dictionary] = []
var store_items: Array[Dictionary] = []
var install_files: Array[String] = []
var screen_stack: Array[Dictionary] = []
const SEARCH_ALPHABET := " ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"

var setting_keys: Array[String] = ["sound_enabled", "volume", "theme", "scanlines", "keyboard_hints", "developer_mode", "reset"]
var pending_install_path := ""
var pending_install_trust := "untrusted"
var pending_install_manifest: Dictionary = {}
var pending_install_operation := "install"
var pending_install_inspect: Dictionary = {}
var pending_manage_manifest: Dictionary = {}
var search_query := ""
var search_char_index := 1
var last_result := ""
var pending_legacy_path := ""
var _picker_purpose := "cartridge"
var _title := "POPUGVPOCKET"
var _intro := ""
var preview_theme_id := ""


func _ready() -> void:
	if not StoreService.download_ready.is_connected(_on_store_download_ready):
		StoreService.download_ready.connect(_on_store_download_ready)
	if not StoreService.download_state_changed.is_connected(_on_store_download_state_changed):
		StoreService.download_state_changed.connect(_on_store_download_state_changed)
	set_process(true)
	PocketFilePicker.file_selected.connect(_on_picker_file_selected)
	PocketFilePicker.selection_cancelled.connect(_on_picker_cancelled)
	PocketFilePicker.import_failed.connect(_on_picker_failed)
	PocketFilePicker.state_changed.connect(_on_picker_state_changed)


func _process(delta: float) -> void:
	cursor_tick += delta
	if booting:
		boot_time += delta
		if boot_time >= 1.15 or PocketInput.just_pressed(PocketInput.A):
			booting = false
			PocketAudio.boot()
		queue_redraw()
		return
	if not visible or not input_enabled:
		return
	if PocketInput.just_pressed(PocketInput.UP):
		_move_selection(-1)
	if PocketInput.just_pressed(PocketInput.DOWN):
		_move_selection(1)
	if PocketInput.just_pressed(PocketInput.LEFT):
		_adjust_setting(-1)
	if PocketInput.just_pressed(PocketInput.RIGHT):
		_adjust_setting(1)
	if PocketInput.just_pressed(PocketInput.A):
		_activate_selected()
	if PocketInput.just_pressed(PocketInput.X):
		_activate_secondary()
	if PocketInput.just_pressed(PocketInput.Y):
		_activate_tertiary()
	if PocketInput.just_pressed(PocketInput.B):
		PocketAudio.back()
		_back()
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	if booting:
		_draw_boot(p)
		return
	PixelFont.draw_text(self, Vector2(16, 16), _title, p["hi"], 2)
	draw_rect(Rect2(Vector2(12, 42), Vector2(size.x - 24, 2)), p["mid"], true)
	_draw_screen_body(p)
	_draw_scanlines(p)
	_draw_footer(p)


func show_home() -> void:
	input_enabled = true
	screen_stack.clear()
	screen = "home"
	selected_index = 0
	items = [
		{"label": "Library", "action": "library"},
		{"label": "Store", "action": "store"},
		{"label": "Install Cartridge", "action": "install"},
		{"label": "Settings", "action": "settings"},
		{"label": "About", "action": "about"},
	]
	_render(BrandConfig.PRODUCT_NAME.to_upper(), "")


func show_library(package_list: Array[Dictionary]) -> void:
	input_enabled = true
	screen_stack.clear()
	screen = "library"
	packages = package_list
	selected_index = 0
	items = []
	for manifest in packages:
		var badge := String(manifest.get("type", "cartridge")).to_upper()
		badge += " / " + ("BUILT-IN" if bool(manifest.get("built_in", false)) else "EXTERNAL")
		if StoreService.has_update(String(manifest.get("id", ""))):
			badge += " / UPDATE"
		if not bool(CartridgeManager.verify(String(manifest.get("id", ""))).get("ok", false)):
			badge += " / BROKEN"
		items.append({"label": String(manifest.get("name", "Unknown")), "badge": badge, "action": "cartridge", "manifest": manifest})
	if packages.is_empty():
		items = [
			{"label": "Open Store", "action": "store"},
			{"label": "Install File", "action": "install"},
		]
	_render("LIBRARY", "NO CARTRIDGES INSTALLED" if packages.is_empty() else str(packages.size()) + " INSTALLED")


func show_store() -> void:
	input_enabled = true
	screen_stack.clear()
	_show_store_home(false)


func show_settings() -> void:
	input_enabled = true
	screen_stack.clear()
	screen = "settings"
	selected_index = 0
	items = []
	setting_keys = ["console_profile", "direction_control", "stick_mode", "sound_enabled", "volume", "customize", "scanlines", "keyboard_hints", "developer_mode", "reset"]
	if String(PocketStorage.get_setting("direction_control", "dpad")) == "stick":
		setting_keys.insert(3, "stick_size")
		setting_keys.insert(4, "stick_deadzone")
		setting_keys.insert(5, "stick_side")
	if bool(PocketStorage.get_setting("developer_mode", false)):
		setting_keys.insert(setting_keys.size() - 1, "debug_info")
		setting_keys.insert(setting_keys.size() - 1, "legacy_import")
	for key in setting_keys:
		items.append({"label": key, "action": "customize" if key == "customize" else "setting", "key": key})
	_render("SETTINGS", "LEFT RIGHT EDIT")


func show_about() -> void:
	input_enabled = true
	screen_stack.clear()
	screen = "about"
	selected_index = 0
	items = [{"label": "Back", "action": "back"}]
	_render("ABOUT", BrandConfig.PRODUCT_NAME.to_upper() + "\nVERSION " + BrandConfig.VERSION + "\nA PIXEL HANDHELD PLATFORM\nBY POPUGONET\nREBORN EDITION")


func set_input_enabled(value: bool) -> void:
	input_enabled = value


func _render(title: String, intro: String) -> void:
	_title = title
	_intro = intro
	queue_redraw()


func _push_state() -> void:
	screen_stack.append({
		"screen": screen,
		"items": items.duplicate(true),
		"selected": selected_index,
		"title": _title,
		"intro": _intro,
		"packages": packages.duplicate(true),
		"store_items": store_items.duplicate(true),
		"install_files": install_files.duplicate(),
	})


func _restore_state(state: Dictionary) -> void:
	screen = String(state.get("screen", "home"))
	items.clear()
	for item in Array(state.get("items", [])):
		items.append(Dictionary(item))
	selected_index = int(state.get("selected", 0))
	_title = String(state.get("title", BrandConfig.PRODUCT_NAME.to_upper()))
	_intro = String(state.get("intro", ""))
	packages.clear()
	for package in Array(state.get("packages", [])):
		packages.append(Dictionary(package))
	store_items.clear()
	for store_item in Array(state.get("store_items", [])):
		store_items.append(Dictionary(store_item))
	install_files.clear()
	for install_file in Array(state.get("install_files", [])):
		install_files.append(String(install_file))


func _item_text(item: Dictionary) -> String:
	if screen != "settings":
		var label := String(item.get("label", "")).to_upper()
		var badge := String(item.get("badge", ""))
		if not badge.is_empty():
			return label + "  " + badge
		return label
	var key := String(item.get("key", ""))
	if key == "volume":
		var blocks: int = int(round(float(PocketStorage.get_setting("volume", 80)) / 20.0))
		return "VOLUME    [" + "#".repeat(blocks) + "-".repeat(5 - blocks) + "]"
	if key == "sound_enabled":
		return "SOUND     [" + ("ON" if bool(PocketStorage.get_setting("sound_enabled", true)) else "OFF") + "]"
	if key == "console_profile": return "PROFILE   [" + String(PocketStorage.get_setting("console_profile", "vboy")).to_upper() + "]"
	if key == "direction_control": return "CONTROL   [" + String(PocketStorage.get_setting("direction_control", "dpad")).to_upper() + "]"
	if key == "stick_mode": return "STICK     [" + String(PocketStorage.get_setting("stick_mode", "fixed")).to_upper() + "]"
	if key == "stick_size": return "SIZE      [" + str(snappedf(float(PocketStorage.get_setting("stick_size", 1.0)), 0.1)) + "]"
	if key == "stick_deadzone": return "DEADZONE  [" + str(int(float(PocketStorage.get_setting("stick_deadzone", 0.28)) * 100.0)) + "%]"
	if key == "stick_side": return "SIDE      [" + String(PocketStorage.get_setting("stick_side", "left")).to_upper() + "]"
	if key == "theme":
		return "THEME     [" + PocketTheme.theme_label() + "]"
	if key == "customize": return "CUSTOMIZE  >"
	if key == "scanlines":
		return "SCANLINES [" + ("ON" if bool(PocketStorage.get_setting("scanlines", false)) else "OFF") + "]"
	if key == "keyboard_hints":
		return "HINTS     [" + ("ON" if bool(PocketStorage.get_setting("keyboard_hints", true)) else "OFF") + "]"
	if key == "debug_info":
		return "DEBUG INFO[" + ("ON" if bool(PocketStorage.get_setting("debug_info", false)) else "OFF") + "]"
	if key == "developer_mode":
		return "DEV MODE  [" + ("ON" if bool(PocketStorage.get_setting("developer_mode", false)) else "OFF") + "]"
	if key == "legacy_import": return "IMPORT LEGACY BACKUP >"
	return "RESET UI SETTINGS"


func _move_selection(delta: int) -> void:
	if items.is_empty():
		return
	selected_index = wrapi(selected_index + delta, 0, items.size())
	if screen == "themes" and selected_index < items.size():
		preview_theme_id = String(items[selected_index].get("theme_id", "mono"))
		PocketTheme.preview(preview_theme_id)
	PocketAudio.focus()
	_render(_title, _intro_for_screen())


func _activate_selected() -> void:
	if items.is_empty():
		return
	var item: Dictionary = items[selected_index]
	PocketAudio.select()
	match String(item.get("action", "")):
		"library":
			PocketRouter.open_library()
		"cartridge":
			_show_cartridge_details(Dictionary(item.get("manifest", {})))
		"play":
			launch_package.emit(Dictionary(item.get("manifest", {})))
		"play_settings":
			var settings_manifest := Dictionary(item.get("manifest", {})).duplicate(true)
			settings_manifest["open_settings"] = true
			launch_package.emit(settings_manifest)
		"store":
			_show_store_home(true)
		"store_section":
			_show_store_section(String(item.get("section", "all")))
		"store_item":
			_show_store_details(Dictionary(item.get("store_item", {})))
		"search_append":
			search_query += SEARCH_ALPHABET.substr(search_char_index, 1)
			_render_store_search()
		"store_manage":
			_show_manage_cartridge(Dictionary(item.get("manifest", {})))
		"install_store":
			_install_from_store(Dictionary(item.get("store_item", {})))
		"cancel_download":
			StoreService.cancel_download()
		"repair":
			_repair_cartridge(String(item.get("id", "")))
		"install":
			_start_file_picker()
		"legacy_import":
			_start_legacy_picker()
		"legacy_all":
			_import_legacy(false)
		"legacy_settings":
			_import_legacy(true)
		"install_file":
			_prepare_external_install(String(item.get("path", "")))
		"confirm_install":
			_confirm_external_install()
		"open_settings":
			request_settings.emit()
		"cancel":
			_back()
		"enable_developer_mode":
			PocketStorage.set_setting("developer_mode", true)
			_show_result("DEVELOPER MODE", "ENABLED\nEXTERNAL CODE IS UNSAFE", false)
		"settings":
			request_settings.emit()
		"about":
			request_about.emit()
		"verify":
			_verify_cartridge(String(item.get("id", "")))
		"uninstall":
			_show_uninstall_confirmation(Dictionary(item.get("manifest", {})))
		"uninstall_app_only":
			_uninstall_cartridge(pending_manage_manifest, false)
		"uninstall_app_data":
			_uninstall_cartridge(pending_manage_manifest, true)
		"manage":
			_show_manage_cartridge(Dictionary(item.get("manifest", {})))
		"view_manifest":
			_show_manifest(Dictionary(item.get("manifest", {})))
		"reset_settings":
			PocketStorage.reset_package_settings(String(Dictionary(item.get("manifest", {})).get("id", "")))
			_show_result("SETTINGS RESET", "PACKAGE SETTINGS CLEARED", true)
		"reset_data":
			PocketStorage.reset_package_data(String(Dictionary(item.get("manifest", {})).get("id", "")))
			_show_result("DATA RESET", "SAVE DATA CLEARED", true)
		"back":
			_back()
		"setting":
			_activate_setting(String(item.get("key", "")))
		"customize":
			_show_customize()
		"themes":
			_show_themes()
		"collection":
			_show_collection()
		"apply_theme":
			PocketStorage.set_setting("theme", String(item.get("theme_id", "mono")))
			PocketTheme.clear_preview()
			_show_result("THEME", "APPLIED", true)


func _activate_secondary() -> void:
	if screen == "library" and selected_index < packages.size():
		_show_cartridge_details(packages[selected_index])
	elif screen == "install_confirmation":
		_show_install_details()
	elif screen == "store_search":
		if not search_query.is_empty():
			search_query = search_query.left(search_query.length() - 1)
			_render_store_search()
	elif screen.begins_with("store_") and screen != "store_detail":
		_show_store_section("search")


func _activate_tertiary() -> void:
	if screen == "library" and selected_index < packages.size():
		_show_manage_cartridge(packages[selected_index])


func _activate_setting(key: String) -> void:
	if key == "reset":
		PocketStorage.reset_settings()
		_render(_title, _intro_for_screen())
	elif key == "developer_mode" and not bool(PocketStorage.get_setting("developer_mode", false)):
		_show_developer_warning()
	elif key == "legacy_import":
		_start_legacy_picker()
	else:
		_adjust_setting(1)


func _adjust_setting(delta: int) -> void:
	if screen == "store_search":
		search_char_index = wrapi(search_char_index + delta, 0, SEARCH_ALPHABET.length())
		_render_store_search()
		PocketAudio.focus()
		return
	if screen != "settings" or items.is_empty():
		return
	var key := String(items[selected_index].get("key", ""))
	match key:
		"console_profile":
			ConsoleLayoutManager.cycle_profile()
		"direction_control":
			PocketStorage.set_setting("direction_control", "stick" if String(PocketStorage.get_setting("direction_control", "dpad")) == "dpad" else "dpad")
		"stick_mode":
			PocketStorage.set_setting("stick_mode", "floating" if String(PocketStorage.get_setting("stick_mode", "fixed")) == "fixed" else "fixed")
		"stick_size":
			PocketStorage.set_setting("stick_size", clampf(float(PocketStorage.get_setting("stick_size", 1.0)) + delta * 0.1, 0.8, 1.3))
		"stick_deadzone":
			PocketStorage.set_setting("stick_deadzone", clampf(float(PocketStorage.get_setting("stick_deadzone", 0.28)) + delta * 0.05, 0.15, 0.55))
		"stick_side":
			PocketStorage.set_setting("stick_side", "right" if String(PocketStorage.get_setting("stick_side", "left")) == "left" else "left")
		"volume":
			var volume: int = clampi(int(PocketStorage.get_setting("volume", 80)) + delta * 20, 0, 100)
			PocketStorage.set_setting("volume", volume)
		"sound_enabled":
			PocketStorage.set_setting("sound_enabled", not bool(PocketStorage.get_setting("sound_enabled", true)))
		"theme":
			var current: String = String(PocketStorage.get_setting("theme", "mono"))
			PocketStorage.set_setting("theme", PocketTheme.next_theme(current))
		"scanlines":
			PocketStorage.set_setting("scanlines", not bool(PocketStorage.get_setting("scanlines", false)))
		"keyboard_hints":
			PocketStorage.set_setting("keyboard_hints", not bool(PocketStorage.get_setting("keyboard_hints", true)))
		"debug_info":
			PocketStorage.set_setting("debug_info", not bool(PocketStorage.get_setting("debug_info", false)))
		"developer_mode":
			if bool(PocketStorage.get_setting("developer_mode", false)):
				PocketStorage.set_setting("developer_mode", false)
	PocketAudio.focus()
	_render(_title, _intro_for_screen())


func _show_cartridge_details(manifest: Dictionary) -> void:
	_push_state()
	screen = "cartridge_detail"
	selected_index = 0
	items = [
		{"label": "Open", "action": "play", "manifest": manifest},
		{"label": "Settings", "action": "play_settings", "manifest": manifest},
		{"label": "Manage", "action": "manage", "manifest": manifest},
	]
	var author := _author_name(manifest)
	var intro := String(manifest.get("category", "cartridge")).to_upper() + " " + String(manifest.get("type", "game")).to_upper()
	intro += "\nVERSION " + String(manifest.get("version", "0.3.0-dev"))
	intro += "\nBY " + author.to_upper()
	_render(String(manifest.get("name", "CARTRIDGE")).to_upper(), intro)


func _show_customize() -> void:
	_push_state()
	screen = "customize"
	selected_index = 0
	items = [{"label":"Theme","action":"themes"},{"label":"Collection","action":"collection"}]
	_render("CUSTOMIZE", "LOCAL THEMES AND REWARDS")


func _show_themes() -> void:
	_push_state()
	screen = "themes"
	items = []
	var current := String(PocketStorage.get_setting("theme", "mono"))
	selected_index = 0
	for theme in CosmeticsManager.list_themes():
		var theme_id := String(theme.get("id", "mono"))
		items.append({"label":String(theme.get("name", theme_id)),"badge":String(theme.get("source", "built-in")).to_upper(),"action":"apply_theme","theme_id":theme_id})
		if theme_id == current: selected_index = items.size() - 1
	preview_theme_id = current
	PocketTheme.preview(current)
	_render("THEMES", "A APPLY  B CANCEL")


func _show_collection() -> void:
	_push_state()
	screen = "collection"
	selected_index = 0
	var progress := AchievementManager.all_progress()
	var unlocked := 0
	for value in progress.values():
		if bool(Dictionary(value).get("unlocked", false)): unlocked += 1
	items = [{"label":"Achievements " + str(unlocked) + "/" + str(progress.size()),"action":"back"},{"label":"Themes " + str(CosmeticsManager.list_themes().size()),"action":"back"},{"label":"Back","action":"back"}]
	_render("COLLECTION", "LOCAL PROFILE")


func _show_manage_cartridge(manifest: Dictionary) -> void:
	_push_state()
	pending_manage_manifest = manifest.duplicate(true)
	screen = "cartridge_manage"
	selected_index = 0
	var built_in := bool(manifest.get("built_in", false))
	var cartridge_id := String(manifest.get("id", ""))
	var verification: Dictionary = CartridgeManager.verify(cartridge_id)
	items = [
		{"label": "Verify", "action": "verify", "id": cartridge_id},
		{"label": "Reset Settings", "action": "reset_settings", "manifest": manifest},
		{"label": "Reset Data", "action": "reset_data", "manifest": manifest},
	]
	if not built_in:
		if not bool(verification.get("ok", false)) and not StoreService.catalog_item(cartridge_id).is_empty():
			items.push_front({"label": "Repair", "action": "repair", "id": cartridge_id})
		items.append({"label": "Uninstall", "action": "uninstall", "manifest": manifest})
	if bool(PocketStorage.get_setting("developer_mode", false)):
		items.append({"label": "Technical Details", "action": "view_manifest", "manifest": manifest})
	_render("MANAGE", String(manifest.get("name", "CARTRIDGE")).to_upper())


func _show_manifest(manifest: Dictionary) -> void:
	_push_state()
	screen = "manifest"
	selected_index = 0
	items = [{"label": "Back", "action": "back"}]
	var intro := "ID " + String(manifest.get("id", ""))
	intro += "\nVERSION " + String(manifest.get("version", ""))
	intro += "\nENTRY " + String(manifest.get("entry_scene", ""))
	intro += "\nROOT " + String(manifest.get("resource_root", ""))
	intro += "\nCAPS " + ",".join(PackedStringArray(Array(manifest.get("capabilities", []))))
	_render("TECHNICAL DETAILS", intro)


func _show_store_home(push: bool) -> void:
	if push:
		_push_state()
	screen = "store"
	selected_index = 0
	StoreService.refresh()
	items = [
		{"label": "Featured", "action": "store_section", "section": "featured"},
		{"label": "All", "action": "store_section", "section": "all"},
		{"label": "Updates", "action": "store_section", "section": "updates"},
		{"label": "Search", "action": "store_section", "section": "search"},
	]
	_render("STORE", StoreService.status_label() + "\nGITHUB CATALOG")


func _show_store_section(section: String) -> void:
	_push_state()
	screen = "store_" + section
	selected_index = 0
	store_items.clear()
	if section == "search":
		search_query = ""
		search_char_index = 1
		_render_store_search()
		return
	match section:
		"featured":
			store_items = StoreService.featured()
		"updates":
			store_items = StoreService.updates()
		_:
			store_items = StoreService.list_catalog()
	_build_store_items(store_items)
	if items.is_empty():
		var empty_label := "NO FEATURED CARTRIDGES" if section == "featured" else "NO UPDATES AVAILABLE" if section == "updates" else "NO CARTRIDGES AVAILABLE"
		items.append({"label": empty_label, "action": "back"})
	_render("STORE " + section.to_upper(), "" if not store_items.is_empty() else String(items[0]["label"]))


func _render_store_search() -> void:
	screen = "store_search"
	store_items = StoreService.search(search_query)
	items = [{"label": "TYPE [" + SEARCH_ALPHABET.substr(search_char_index, 1) + "] " + search_query, "action": "search_append"}]
	_build_store_items(store_items, false)
	selected_index = clampi(selected_index, 0, items.size() - 1)
	var intro := "TYPE TO SEARCH" if search_query.is_empty() else "NO RESULTS" if store_items.is_empty() else str(store_items.size()) + " RESULTS"
	_render("SEARCH", intro)


func _build_store_items(entries: Array[Dictionary], clear: bool = true) -> void:
	if clear:
		items = []
	for entry in entries:
		var cartridge_id := String(entry.get("id", ""))
		var installed := not CartridgeManager.get_cartridge(cartridge_id).is_empty()
		var status := "UPDATE" if installed and StoreService.has_update(cartridge_id) else "INSTALLED" if installed else "INSTALL"
		items.append({
			"label": String(entry.get("name", "Unknown")),
			"badge": String(entry.get("category", "cartridge")).to_upper() + " / " + status,
			"action": "store_item",
			"store_item": entry,
		})


func _show_store_details(item: Dictionary) -> void:
	_push_state()
	screen = "store_detail"
	selected_index = 0
	var installed := not CartridgeManager.get_cartridge(String(item.get("id", ""))).is_empty()
	var installed_manifest := CartridgeManager.get_cartridge(String(item.get("id", "")))
	items = []
	if installed:
		if StoreService.has_update(String(item.get("id", ""))):
			items.append({"label": "Update", "action": "install_store", "store_item": item})
		else:
			items.append({"label": "Reinstall", "action": "install_store", "store_item": item})
		items.append({"label": "Open", "action": "play", "manifest": installed_manifest})
		items.append({"label": "Manage", "action": "store_manage", "manifest": installed_manifest})
	else:
		items.append({"label": "Install", "action": "install_store", "store_item": item})
	var intro := String(item.get("description", "Local cartridge.")).to_upper()
	intro += "\nVERSION " + String(item.get("version", ""))
	intro += "\nBY " + String(item.get("author", "Unknown")).to_upper()
	_render(String(item.get("name", "CARTRIDGE")).to_upper(), intro)


func _install_from_store(item: Dictionary) -> void:
	var download: Dictionary = StoreService.download_to_imports(String(item.get("id", "")), String(item.get("version", "")))
	if bool(download.get("pending", false)):
		screen = "store_download"
		selected_index = 0
		items = [{"label": "Cancel", "action": "cancel_download"}]
		_render("DOWNLOADING", String(item.get("name", "CARTRIDGE")).to_upper() + "\n[----------] 0%")
		return
	if not bool(download.get("ok", false)):
		_show_result("INSTALL FAILED", String(download.get("error", "download failed")).to_upper(), true)
		return
	var install_result: Dictionary = CartridgeManager.install_from_file(String(download.get("path", "")), String(download.get("trust", "trusted")), true)
	if bool(install_result.get("ok", false)):
		_show_installed(Dictionary(install_result.get("record", {})), bool(install_result.get("restart_required", false)))
	else:
		_show_result("INSTALL FAILED", String(install_result.get("error", "install failed")).to_upper(), true)


func _on_store_download_ready(download: Dictionary) -> void:
	if not bool(download.get("ok", false)):
		var error := String(download.get("error", "download_failed"))
		if error == "cancelled":
			_back()
		else:
			_show_result("DOWNLOAD FAILED", StoreDownloadErrors.user_message(error), true)
		return
	screen = "store_installing"
	items = []
	_render("INSTALLING", "VERIFYING CARTRIDGE")
	StoreService.mark_installing()
	var install_result: Dictionary = CartridgeManager.install_from_file(String(download.get("path", "")), String(download.get("trust", "trusted")), true)
	if bool(install_result.get("ok", false)):
		StoreService.mark_completed()
		_show_installed(Dictionary(install_result.get("record", {})), bool(install_result.get("restart_required", false)))
	else:
		_show_result("INSTALL FAILED", String(install_result.get("error", "install failed")).to_upper(), true)


func _on_store_download_state_changed(snapshot: Dictionary) -> void:
	if screen != "store_download":
		return
	var state := String(snapshot.get("state", "connecting"))
	var item := Dictionary(snapshot.get("item", {}))
	var progress := clampf(float(snapshot.get("progress", 0.0)), 0.0, 1.0)
	var blocks: int = clampi(int(floor(progress * 10.0)), 0, 10)
	var body := String(item.get("name", "CARTRIDGE")).to_upper()
	body += "\n[" + "#".repeat(blocks) + "-".repeat(10 - blocks) + "] " + str(int(progress * 100.0)) + "%"
	_render(state.to_upper(), body)


func _repair_cartridge(cartridge_id: String) -> void:
	var item := StoreService.catalog_item(cartridge_id)
	if item.is_empty():
		_show_result("REPAIR FAILED", "CATALOG ENTRY NOT AVAILABLE", true)
		return
	_install_from_store(item)


func _start_file_picker() -> void:
	_picker_purpose = "cartridge"
	_push_state()
	screen = "install_selecting"
	selected_index = 0
	items = []
	_render("INSTALL CARTRIDGE", "SELECTING FILE...")
	PocketFilePicker.reset()
	PocketFilePicker.open_cartridge_file()


func _start_legacy_picker() -> void:
	_picker_purpose = "legacy"
	_push_state()
	screen = "legacy_selecting"
	items = []
	_render("LEGACY OPENPOCKET BACKUP", "SELECTING FILE...")
	PocketFilePicker.reset()
	PocketFilePicker.open_legacy_backup()


func _on_picker_state_changed(next_state: String, detail: String) -> void:
	if next_state in ["selecting", "copying", "inspecting"]:
		screen = ("legacy_" if _picker_purpose == "legacy" else "install_") + next_state
		items = []
		_render("INSTALL CARTRIDGE", detail + "...")


func _on_picker_file_selected(path: String) -> void:
	if _picker_purpose == "legacy":
		_prepare_legacy_import(path)
	else:
		_prepare_external_install(path)


func _on_picker_cancelled() -> void:
	if screen.begins_with("install_") or screen.begins_with("legacy_"):
		_back()


func _prepare_legacy_import(path: String) -> void:
	var checked: Dictionary = LegacyBackupImporter.inspect(path)
	if not bool(checked.get("ok", false)):
		_show_result("INVALID LEGACY BACKUP", String(checked.get("error", "invalid")).to_upper(), false)
		return
	pending_legacy_path = path
	screen = "legacy_confirm"
	selected_index = 0
	items = [
		{"label": "Import Everything", "action": "legacy_all"},
		{"label": "Import Settings Only", "action": "legacy_settings"},
		{"label": "Cancel", "action": "cancel"},
	]
	_render("LEGACY OPENPOCKET BACKUP", "SAFE DATA ONLY\nEXECUTABLE CONTENT IS SKIPPED")


func _import_legacy(settings_only: bool) -> void:
	var result: Dictionary = LegacyBackupImporter.import_backup(pending_legacy_path, settings_only)
	if bool(result.get("ok", false)):
		_show_result("LEGACY IMPORT", "COMPLETE\nRESTART RECOMMENDED", true)
	else:
		_show_result("LEGACY IMPORT FAILED", String(result.get("error", "failed")).to_upper(), false)


func _on_picker_failed(code: String, _message: String) -> void:
	_show_result("IMPORT FAILED", _friendly_error(code), false)


func _prepare_external_install(path: String) -> void:
	var inspect: Dictionary = CartridgeManager.inspect_file(path)
	if not bool(inspect.get("ok", false)):
		_show_result("INVALID CARTRIDGE", String(inspect.get("error", "invalid")).to_upper(), true)
		return
	var manifest: Dictionary = Dictionary(inspect.get("manifest", {}))
	pending_install_path = path
	pending_install_inspect = inspect.duplicate(true)
	pending_install_trust = "untrusted"
	pending_install_manifest = manifest.duplicate(true)
	pending_install_operation = String(inspect.get("operation", "install"))
	if pending_install_operation == "blocked":
		_show_result("INSTALL FAILED", "BUILT-IN ID CONFLICT", false)
		return
	if not bool(PocketStorage.get_setting("developer_mode", false)):
		screen = "developer_required"
		selected_index = 0
		items = [
			{"label": "Cancel", "action": "cancel"},
			{"label": "Open Settings", "action": "open_settings"},
		]
		_render("DEVELOPER MODE REQUIRED", "EXTERNAL CARTRIDGES CAN RUN CODE.\nENABLE DEVELOPER MODE TO INSTALL.")
		return
	screen = "install_confirmation"
	selected_index = 0
	items = [
		{"label": "Cancel", "action": "cancel"},
		{"label": pending_install_operation.capitalize(), "action": "confirm_install"},
	]
	var intro := String(manifest.get("name", "")).to_upper()
	intro += "\n" + String(manifest.get("type", "cartridge")).to_upper() + " / VERSION " + String(manifest.get("version", ""))
	intro += "\nBY " + _author_name(manifest).to_upper()
	intro += "\n\nUNTRUSTED EXTERNAL CODE"
	_render("INSTALL CARTRIDGE", intro)


func _show_install_details() -> void:
	_push_state()
	screen = "install_details"
	selected_index = 0
	items = [{"label": "Back", "action": "back"}]
	var manifest := pending_install_manifest
	var intro := "CAPABILITIES " + ",".join(PackedStringArray(Array(manifest.get("capabilities", [])))).to_upper()
	intro += "\nCHECKSUM VALID"
	intro += "\nSIZE " + _format_bytes(int(pending_install_inspect.get("archive_size", 0)))
	intro += "\nRUNTIME " + String(Dictionary(manifest.get("runtime", {})).get("min_version", "ANY"))
	intro += "\nFILE " + pending_install_path.get_file()
	_render("INSTALL DETAILS", intro)


func _confirm_external_install() -> void:
	screen = "install_installing"
	items = []
	_render("INSTALL CARTRIDGE", "INSTALLING...")
	var allow_replace := pending_install_operation in ["update", "reinstall", "downgrade"]
	var install_result: Dictionary = CartridgeManager.install_from_file(pending_install_path, pending_install_trust, allow_replace)
	if bool(install_result.get("ok", false)):
		_show_installed(Dictionary(install_result.get("record", {})), bool(install_result.get("restart_required", false)))
	else:
		_show_result("INSTALL FAILED", _friendly_error(String(install_result.get("error", "install_failed"))), false)


func _show_installed(record: Dictionary, restart_required: bool) -> void:
	screen = "install_complete"
	selected_index = 0
	items = []
	if not restart_required:
		items.append({"label": "Open", "action": "play", "manifest": record})
	items.append({"label": "Library", "action": "library"})
	var body := String(record.get("name", "CARTRIDGE")).to_upper()
	if restart_required:
		body += "\nRESTART %s TO APPLY UPDATE" % BrandConfig.PRODUCT_NAME.to_upper()
	_render("INSTALLED", body)


func _show_developer_warning() -> void:
	_push_state()
	screen = "developer_warning"
	selected_index = 0
	items = [
		{"label": "Cancel", "action": "cancel"},
		{"label": "Enable", "action": "enable_developer_mode"},
	]
	_render("WARNING", "EXTERNAL CARTRIDGES CAN RUN CODE.\nONLY INSTALL FILES YOU TRUST.")


func _verify_cartridge(cartridge_id: String) -> void:
	var result: Dictionary = CartridgeManager.verify(cartridge_id)
	_show_result("VERIFY", ("OK" if bool(result.get("ok", false)) else String(result.get("error", "failed")).to_upper()), true)


func _show_uninstall_confirmation(manifest: Dictionary) -> void:
	_push_state()
	pending_manage_manifest = manifest.duplicate(true)
	screen = "uninstall_confirmation"
	selected_index = 0
	items = [
		{"label": "Cancel", "action": "cancel"},
		{"label": "Remove App Only", "action": "uninstall_app_only"},
		{"label": "Remove App And Data", "action": "uninstall_app_data"},
	]
	_render("REMOVE " + String(manifest.get("name", "CARTRIDGE")).to_upper() + "?", "ACHIEVEMENTS AND EARNED REWARDS\nWILL BE KEPT.")


func _uninstall_cartridge(manifest: Dictionary, remove_data: bool) -> void:
	var ok := CartridgeManager.uninstall(String(manifest.get("id", "")), remove_data)
	var body := "REMOVED APP AND DATA" if remove_data else "REMOVED APP ONLY"
	_show_result("UNINSTALL", body if ok else "FAILED", false)


func _show_result(title: String, body: String, push: bool) -> void:
	if push:
		_push_state()
	screen = "result"
	selected_index = 0
	last_result = body
	items = [
		{"label": "Library", "action": "library"},
		{"label": "Back", "action": "back"},
	]
	_render(title, body)


func _find_import_files() -> Array[String]:
	var result: Array[String] = []
	var roots: Array[String] = ["user://imports", "user://cartridges/downloads"]
	for root in roots:
		DirAccess.make_dir_recursive_absolute(root)
		var dir := DirAccess.open(root)
		if dir == null:
			continue
		for file_name in dir.get_files():
			if file_name.to_lower().ends_with(".pctrg"):
				result.append(root.path_join(file_name))
	return result


func _friendly_error(code: String) -> String:
	var names := {
		"invalid_archive": "INVALID FILE",
		"invalid_manifest": "INVALID MANIFEST",
		"unsupported_format": "UNSUPPORTED FORMAT",
		"checksum_mismatch": "CHECKSUM FAILED",
		"incompatible_runtime": "INCOMPATIBLE RUNTIME",
		"unsupported_capability": "UNSUPPORTED CAPABILITY",
		"limit_exceeded": "ARCHIVE TOO LARGE",
		"unsafe_path": "UNSAFE ARCHIVE PATH",
		"install_failed": "INSTALL FAILED",
		"download_unavailable": "DOWNLOAD NOT AVAILABLE",
		"download_too_large": "DOWNLOAD TOO LARGE",
		"download_io_error": "DOWNLOAD SAVE FAILED",
		"archive_checksum_mismatch": "CARTRIDGE CHECKSUM FAILED",
	}
	return String(names.get(code.to_lower(), code.to_upper().replace("_", " ")))


func _format_bytes(value: int) -> String:
	if value >= 1024 * 1024:
		return "%.1f MB" % (float(value) / 1048576.0)
	return "%.1f KB" % (float(value) / 1024.0)


func _author_name(manifest: Dictionary) -> String:
	var author_value: Variant = manifest.get("author", "Unknown")
	if typeof(author_value) == TYPE_DICTIONARY:
		return String(Dictionary(author_value).get("name", "Unknown"))
	return String(author_value)


func _back() -> void:
	if screen == "themes": PocketTheme.clear_preview()
	if screen == "home":
		PocketRouter.back()
		return
	if not screen_stack.is_empty():
		var state: Dictionary = screen_stack.pop_back()
		_restore_state(state)
		queue_redraw()
		return
	PocketRouter.back()


func _intro_for_screen() -> String:
	match screen:
		"home":
			return ""
		"library":
			return str(packages.size()) + " INSTALLED"
		"settings":
			return "LEFT RIGHT EDIT"
		"about":
			return BrandConfig.PRODUCT_NAME.to_upper() + " " + BrandConfig.VERSION + "\nSDK 0.5.1 EXPERIMENTAL\nCARTRIDGE FORMAT 2\nNO CODE SANDBOX"
	return _intro


func _draw_boot(p: Dictionary) -> void:
	var progress: int = clampi(int(boot_time / 1.15 * 10.0), 0, 10)
	var bar := "[" + "#".repeat(progress) + "-".repeat(10 - progress) + "]"
	draw_texture_rect(BrandAssets.MASCOT_BOOT, Rect2(Vector2(158, 34), Vector2(84, 84)), false)
	PixelFont.draw_text(self, Vector2(52, 122), BrandConfig.PRODUCT_NAME.to_upper(), p["hi"], 2)
	PixelFont.draw_text(self, Vector2(126, 158), "REBORN", p["light"], 2)
	PixelFont.draw_text(self, Vector2(58, 190), bar, p["hi"], 2)
	if progress >= 9:
		PixelFont.draw_text(self, Vector2(70, 222), "SYSTEM READY", p["hi"], 2)


func _draw_screen_body(p: Dictionary) -> void:
	var y := 56
	for line in _intro.split("\n"):
		PixelFont.draw_text(self, Vector2(18, y), line, p["light"], 1)
		y += 12
	y += 8
	for index in range(items.size()):
		var selected := index == selected_index
		var row_rect := Rect2(Vector2(14, y - 4), Vector2(size.x - 28, 20))
		if selected:
			draw_rect(row_rect, p["light"], true)
			draw_rect(row_rect, p["hi"], false, 2)
		var cursor := ">" if selected and int(cursor_tick * 5.0) % 2 == 0 else " "
		var color: Color = p["dark"] if selected else p["hi"]
		PixelFont.draw_text(self, Vector2(22, y), cursor + " " + _item_text(items[index]), color, 1)
		y += 24
	if screen == "library" and not packages.is_empty() and selected_index < packages.size():
		var manifest: Dictionary = packages[selected_index]
		var preview := String(manifest.get("type", "cartridge")).to_upper()
		preview += " / " + ("BUILT-IN" if bool(manifest.get("built_in", false)) else "EXTERNAL")
		preview += "\nVERSION " + String(manifest.get("version", "0.3.0-dev"))
		if StoreService.has_update(String(manifest.get("id", ""))):
			preview += "\nUPDATE AVAILABLE"
		draw_rect(Rect2(Vector2(16, size.y - 78), Vector2(size.x - 32, 48)), p["mid"], false, 2)
		PixelFont.draw_text(self, Vector2(24, size.y - 68), preview, p["light"], 1)


func _draw_footer(p: Dictionary) -> void:
	if not bool(PocketStorage.get_setting("keyboard_hints", true)):
		return
	var footer := "A SELECT  B BACK  MENU SYSTEM"
	match screen:
		"home":
			footer = "A OPEN  MENU SYSTEM"
		"library":
			footer = "A OPEN  X DETAILS  Y MANAGE  B BACK"
		"cartridge_detail":
			footer = "A SELECT  B BACK"
		"store":
			footer = "A OPEN  B BACK"
		"store_featured", "store_all", "store_updates":
			footer = "A DETAILS  B BACK  X SEARCH"
		"store_search":
			footer = "A TYPE/OPEN  X DELETE  B BACK"
		"install_confirmation", "developer_required", "uninstall_confirmation":
			footer = "A SELECT  B CANCEL  X DETAILS" if screen == "install_confirmation" else "A SELECT  B CANCEL"
	PixelFont.draw_text(self, Vector2(16, size.y - 18), footer, p["light"], 1)


func _draw_scanlines(p: Dictionary) -> void:
	if not bool(PocketStorage.get_setting("scanlines", false)):
		return
	for y in range(1, int(size.y), 4):
		draw_rect(Rect2(Vector2(0, y), Vector2(size.x, 1)), p["mid"], true)
