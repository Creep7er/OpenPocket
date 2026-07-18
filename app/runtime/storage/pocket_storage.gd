extends Node

const SETTINGS_PATH := "user://settings.json"

var _defaults: Dictionary = {
	"volume": 80,
	"sound_enabled": true,
	"theme": "mono",
	"scanlines": false,
	"keyboard_hints": true,
	"debug_info": false,
	"developer_mode": false,
	"console_profile": "vboy",
	"direction_control": "dpad",
	"stick_mode": "fixed",
	"stick_size": 1.0,
	"stick_deadzone": 0.28,
	"stick_side": "left",
}

var _settings: Dictionary = {}


func _ready() -> void:
	load_settings()


## Loads persistent shell settings from user storage.
func load_settings() -> Dictionary:
	_settings = _defaults.duplicate()
	if FileAccess.file_exists(SETTINGS_PATH):
		var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
		if file != null:
			var parsed = JSON.parse_string(file.get_as_text())
			if typeof(parsed) == TYPE_DICTIONARY:
				for key in parsed.keys():
					_settings[key] = parsed[key]
	_migrate_package_store()
	return _settings.duplicate()


## Saves all settings to user storage.
func save_settings(settings: Dictionary) -> void:
	for key in settings.keys():
		_settings[key] = settings[key]
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write settings to " + SETTINGS_PATH)
		return
	file.store_string(JSON.stringify(_settings, "\t"))


## Returns a single setting value.
func get_setting(key: String, fallback: Variant = null) -> Variant:
	return _settings.get(key, fallback)


## Returns whether a setting exists in the current store or defaults.
func has_setting(key: String) -> bool:
	return _settings.has(key) or _defaults.has(key)


## Sets and persists a single setting value.
func set_setting(key: String, value: Variant) -> void:
	_settings[key] = value
	save_settings(_settings)


## Restores default settings.
func reset_settings() -> void:
	var package_values: Dictionary = Dictionary(_settings.get("packages", {}))
	_settings = _defaults.duplicate()
	if not package_values.is_empty():
		_settings["packages"] = package_values
	save_settings(_settings)


func get_package_value(package_id: String, key: String, default_value: Variant = null) -> Variant:
	return get_package_data(package_id, key, default_value)


func set_package_value(package_id: String, key: String, value: Variant) -> void:
	set_package_data(package_id, key, value)


## Returns a package-scoped setting value without exposing other packages.
func get_package_setting(package_id: String, key: String, default_value: Variant = null) -> Variant:
	var package_store: Dictionary = _get_package_store(package_id)
	var settings: Dictionary = Dictionary(package_store.get("settings", {}))
	return settings.get(key, default_value)


## Sets and persists a package-scoped setting. Returns false for invalid ids/keys.
func set_package_setting(package_id: String, key: String, value: Variant) -> bool:
	if package_id.strip_edges().is_empty() or key.strip_edges().is_empty():
		return false
	var package_store: Dictionary = _get_package_store(package_id)
	var settings: Dictionary = Dictionary(package_store.get("settings", {}))
	settings[key] = value
	package_store["settings"] = settings
	_set_package_store(package_id, package_store)
	save_settings(_settings)
	return true


## Clears package settings while preserving package data such as scores and stats.
func reset_package_settings(package_id: String) -> bool:
	if package_id.strip_edges().is_empty():
		return false
	var package_store: Dictionary = _get_package_store(package_id)
	package_store["settings"] = {}
	_set_package_store(package_id, package_store)
	save_settings(_settings)
	return true


## Clears package data while preserving package settings.
func reset_package_data(package_id: String) -> bool:
	if package_id.strip_edges().is_empty():
		return false
	var package_store: Dictionary = _get_package_store(package_id)
	package_store["data"] = {}
	_set_package_store(package_id, package_store)
	save_settings(_settings)
	return true


## Clears all settings and data for one package id. Used only after explicit uninstall confirmation.
func clear_package_store(package_id: String) -> bool:
	if package_id.strip_edges().is_empty():
		return false
	var packages: Dictionary = Dictionary(_settings.get("packages", {}))
	if not packages.erase(package_id):
		return true
	_settings["packages"] = packages
	save_settings(_settings)
	return true


## Returns package-scoped persistent data.
func get_package_data(package_id: String, key: String, default_value: Variant = null) -> Variant:
	var package_store: Dictionary = _get_package_store(package_id)
	var data: Dictionary = Dictionary(package_store.get("data", {}))
	return data.get(key, default_value)


## Sets package-scoped persistent data. Data is separate from resettable settings.
func set_package_data(package_id: String, key: String, value: Variant) -> bool:
	if package_id.strip_edges().is_empty() or key.strip_edges().is_empty():
		return false
	var package_store: Dictionary = _get_package_store(package_id)
	var data: Dictionary = Dictionary(package_store.get("data", {}))
	data[key] = value
	package_store["data"] = data
	_set_package_store(package_id, package_store)
	save_settings(_settings)
	return true


func _get_package_store(package_id: String) -> Dictionary:
	var packages: Dictionary = Dictionary(_settings.get("packages", {}))
	var package_store: Dictionary = Dictionary(packages.get(package_id, {}))
	if not package_store.has("settings"):
		package_store["settings"] = {}
	if not package_store.has("data"):
		package_store["data"] = {}
	return package_store


func _set_package_store(package_id: String, package_store: Dictionary) -> void:
	var packages: Dictionary = Dictionary(_settings.get("packages", {}))
	packages[package_id] = package_store
	_settings["packages"] = packages


func _migrate_package_store() -> void:
	var packages: Dictionary = Dictionary(_settings.get("packages", {}))
	var changed := false
	for package_id in packages.keys():
		var package_store: Dictionary = Dictionary(packages[package_id])
		if package_store.has("settings") or package_store.has("data"):
			if not package_store.has("settings"):
				package_store["settings"] = {}
			if not package_store.has("data"):
				package_store["data"] = {}
			packages[package_id] = package_store
			continue
		packages[package_id] = {
			"settings": {},
			"data": package_store,
		}
		changed = true
	if changed:
		_settings["packages"] = packages
