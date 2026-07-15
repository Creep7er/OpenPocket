extends RefCounted

const ROOT := "user://cartridges"
const REGISTRY_PATH := "user://cartridges/installed.json"
const STAGING_DIR := "user://cartridges/staging"
const DOWNLOADS_DIR := "user://cartridges/downloads"
const PACKAGES_DIR := "user://cartridges/packages"
const IMPORTS_DIR := "user://imports"


static func ensure() -> void:
	for path in [ROOT, STAGING_DIR, DOWNLOADS_DIR, PACKAGES_DIR, IMPORTS_DIR]:
		DirAccess.make_dir_recursive_absolute(path)


static func package_dir(cartridge_id: String) -> String:
	return PACKAGES_DIR.path_join(cartridge_id)


static func staging_dir(cartridge_id: String) -> String:
	return STAGING_DIR.path_join(cartridge_id)


static func download_path(file_name: String) -> String:
	return DOWNLOADS_DIR.path_join(file_name.get_file())


static func new_import_path() -> String:
	return DOWNLOADS_DIR.path_join("import-" + _random_token() + ".pctrg")


static func _random_token() -> String:
	var random := RandomNumberGenerator.new()
	random.randomize()
	return "%08x%08x" % [random.randi(), random.randi()]
