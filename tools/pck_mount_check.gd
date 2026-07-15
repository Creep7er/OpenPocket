extends SceneTree


func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2:
		printerr("usage: pck_mount_check.gd <content.pck> <entry-scene>")
		quit(2)
		return
	var content_path := String(args[0])
	var entry_scene := String(args[1])
	if not ProjectSettings.load_resource_pack(content_path, false):
		printerr("PCK mount failed: " + content_path)
		quit(3)
		return
	if not ResourceLoader.exists(entry_scene, "PackedScene"):
		printerr("Entry scene missing after mount: " + entry_scene)
		quit(4)
		return
	var packed := load(entry_scene) as PackedScene
	if packed == null:
		printerr("Entry scene failed to load: " + entry_scene)
		quit(5)
		return
	var instance := packed.instantiate()
	if instance == null:
		printerr("Entry scene failed to instantiate: " + entry_scene)
		quit(6)
		return
	instance.free()
	print("PCK mount check passed: " + entry_scene)
	quit(0)
