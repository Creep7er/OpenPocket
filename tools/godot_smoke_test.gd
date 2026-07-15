extends SceneTree

# Godot 4.7 on this Windows setup can crash when this file is launched with
# `--script` before it can write `user://logs/...`. Set APPDATA/LOCALAPPDATA
# to a project-local directory or run `res://tools/smoke_runner.tscn`.

const SCENES: Array[String] = [
	"res://app/main.tscn",
	"res://packages/games/snake/main.tscn",
	"res://sdk/templates/game/main.tscn",
]


func _init() -> void:
	for scene_path in SCENES:
		var resource: Resource = load(scene_path)
		if resource == null or not resource is PackedScene:
			push_error("Cannot load scene: " + scene_path)
			quit(1)
			return
		var scene: PackedScene = resource as PackedScene
		var instance: Node = scene.instantiate()
		if instance == null:
			push_error("Cannot instantiate scene: " + scene_path)
			quit(1)
			return
		instance.free()
	print("OpenPocket Godot smoke test passed.")
	quit()
