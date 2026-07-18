extends RefCounted
class_name ConsoleLayoutRegistry

const VBoy := preload("res://app/runtime/layout/profiles/vboy_layout.gd")
const VGirl := preload("res://app/runtime/layout/profiles/vgirl_layout.gd")


static func all() -> Array[ConsoleLayoutProfile]:
	return [VBoy.new(), VGirl.new()]


static func get_profile(profile_id: String) -> ConsoleLayoutProfile:
	for profile in all():
		if profile.id == profile_id:
			return profile
	return VBoy.new()

