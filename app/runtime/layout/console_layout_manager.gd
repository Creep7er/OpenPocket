extends Node

signal profile_changed(profile_id: String)

const Registry := preload("res://app/runtime/layout/console_layout_registry.gd")


func current_profile() -> ConsoleLayoutProfile:
	return Registry.get_profile(String(PocketStorage.get_setting("console_profile", "vboy")))


func set_profile(profile_id: String) -> bool:
	var profile := Registry.get_profile(profile_id)
	if profile.id != profile_id:
		return false
	PocketStorage.set_setting("console_profile", profile.id)
	if OS.has_feature("android"):
		DisplayServer.screen_set_orientation(profile.orientation)
	profile_changed.emit(profile.id)
	return true


func cycle_profile() -> void:
	set_profile("vgirl" if current_profile().id == "vboy" else "vboy")
