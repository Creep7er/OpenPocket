extends Control

const Manifest := preload("res://app/runtime/cartridges/cartridge_manifest.gd")
const Registry := preload("res://app/runtime/layout/console_layout_registry.gd")
const Stick := preload("res://app/ui/components/pixel_stick.gd")


func _ready() -> void:
	_assert(PocketScreen.logical_size() == Vector2i(400, 320), "PocketScreen logical size changed")
	_assert(Registry.get_profile("vboy").orientation == DisplayServer.SCREEN_PORTRAIT, "VBoy orientation invalid")
	_assert(Registry.get_profile("vgirl").orientation == DisplayServer.SCREEN_LANDSCAPE, "VGirl orientation invalid")
	var legacy := {"format_version": 1}
	for field in Manifest.REQUIRED_FIELDS:
		if not legacy.has(field): legacy[field] = ""
	_assert(not bool(Manifest.validate(legacy).get("ok", false)), "format v1 was accepted")
	_test_stick()
	_test_legacy_archive()
	print("PopugVPocket Reborn runtime checks passed.")
	get_tree().quit(0)


func _test_stick() -> void:
	var stick := Stick.new()
	stick.size = Vector2(200, 200)
	add_child(stick)
	stick.configure(false, 0.25)
	var events: Array[String] = []
	stick.state_changed.connect(func(button: String, pressed: bool) -> void: events.append(button + ("+" if pressed else "-")))
	stick.call("_update_stick", Vector2(190, 100))
	_assert(events.has(PocketInput.RIGHT + "+"), "stick did not press RIGHT")
	stick.call("_update_stick", Vector2(100, 100))
	_assert(events.has(PocketInput.RIGHT + "-"), "stick did not release RIGHT in deadzone")
	stick.queue_free()


func _test_legacy_archive() -> void:
	var path := "user://reborn-legacy-test.zip"
	var packer := ZIPPacker.new()
	_assert(packer.open(path) == OK, "could not create legacy ZIP fixture")
	packer.start_file("settings.json")
	packer.write_file(JSON.stringify({"volume": 40, "packages": {"org.openpocket.snake": {"data": {"score": 12}}}}).to_utf8_buffer())
	packer.close_file()
	packer.start_file("cartridges/unsafe/content.pck")
	packer.write_file(PackedByteArray([71, 68, 80, 67]))
	packer.close_file()
	packer.close()
	var checked: Dictionary = LegacyBackupImporter.inspect(path)
	_assert(bool(checked.get("ok", false)), "safe legacy backup was rejected")
	_assert(Array(checked.get("skipped", [])).has("cartridges/unsafe/content.pck"), "legacy executable was not skipped")
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))


func _assert(condition: bool, message: String) -> void:
	if condition: return
	push_error(message)
	get_tree().quit(1)
