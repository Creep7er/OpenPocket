extends Control

const SCENES: Array[String] = [
	"res://app/main.tscn",
	"res://packages/games/snake/main.tscn",
	"res://packages/games/breakout/main.tscn",
	"res://sdk/templates/game/main.tscn",
]

var _frames := 0


func _ready() -> void:
	if not _check_autoloads():
		get_tree().quit(1)
		return
	for scene_path in SCENES:
		if not _check_scene(scene_path):
			get_tree().quit(1)
			return


func _process(_delta: float) -> void:
	_frames += 1
	if _frames >= 3:
		print("PopugVPocket scene smoke test passed.")
		get_tree().quit(0)


func _check_autoloads() -> bool:
	var required: Array[String] = ["BrandConfig", "PocketScreen", "ConsoleLayoutManager", "PocketInput", "PocketRouter", "PocketStorage", "PocketFilePicker", "LegacyBackupImporter", "CartridgeManager", "PocketPackages", "PocketSystem", "PocketAudio", "CartridgeAudio", "PocketTheme", "StoreService"]
	for autoload_name in required:
		if not Engine.has_singleton(autoload_name) and get_node_or_null("/root/" + autoload_name) == null:
			push_error("Missing autoload: " + autoload_name)
			return false
	return true


func _check_scene(scene_path: String) -> bool:
	var resource: Resource = load(scene_path)
	if resource == null or not resource is PackedScene:
		push_error("Cannot load scene: " + scene_path)
		return false
	var scene: PackedScene = resource as PackedScene
	var instance: Node = scene.instantiate()
	if instance == null:
		push_error("Cannot instantiate scene: " + scene_path)
		return false
	instance.free()
	return true
