extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var storage := root.get_node("PocketStorage")
	var audio := root.get_node("PocketAudio")
	var cartridge_audio := root.get_node("CartridgeAudio")
	storage.call("set_setting", "sound_enabled", true)
	storage.call("set_setting", "volume", 80)
	if not bool(audio.call("is_available")) or not bool(audio.call("play_ui_safe", "focus")):
		_fail("Shell audio unavailable before cartridge launch")
		return
	if bool(audio.call("play_ui_safe", "missing_event")) or not bool(audio.call("play_ui_safe", "focus")):
		_fail("Invalid audio event affected PocketAudio health")
		return
	cartridge_audio.call("begin_scope", "org.popugonet.popugvpocket.breakout")
	storage.call("set_package_setting", "org.popugonet.popugvpocket.breakout", "sound", true)
	if not bool(cartridge_audio.call("play_sfx", "brick")):
		_fail("Breakout scoped audio unavailable")
		return
	storage.call("set_package_setting", "org.popugonet.popugvpocket.breakout", "sound", false)
	if bool(cartridge_audio.call("play_sfx", "brick")):
		_fail("Breakout local mute was ignored")
		return
	if not bool(audio.call("play_ui_safe", "select")):
		_fail("Breakout local mute affected Shell audio")
		return
	cartridge_audio.call("end_scope")
	if not bool(audio.call("play_ui_safe", "back")):
		_fail("Shell audio unavailable after Breakout exit")
		return
	cartridge_audio.call("begin_scope", "org.popugonet.popugvpocket.snake")
	if not bool(cartridge_audio.call("play_sfx", "select")):
		_fail("Snake audio unavailable after Breakout exit")
		return
	cartridge_audio.call("end_scope")
	cartridge_audio.call("begin_scope", "org.popugonet.popugvpocket.pong")
	if not bool(cartridge_audio.call("play_sfx", "select")):
		_fail("Pong audio unavailable after Breakout exit")
		return
	cartridge_audio.call("end_scope")
	call_deferred("_complete")


func _complete() -> void:
	await create_timer(0.25).timeout
	print("Audio isolation passed: Shell -> Breakout -> Shell -> Snake -> Pong")
	quit(0)


func _fail(message: String) -> void:
	var cartridge_audio := root.get_node_or_null("CartridgeAudio")
	if cartridge_audio != null:
		cartridge_audio.call("end_scope")
	push_error(message)
	quit(1)
