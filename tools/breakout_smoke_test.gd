extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var cartridge_audio := root.get_node("CartridgeAudio")
	var storage := root.get_node("PocketStorage")
	storage.call("set_package_setting", "org.popugonet.popugvpocket.breakout", "sound", true)
	var scene := load("res://cartridges/source/org.popugonet.popugvpocket.breakout/main.tscn") as PackedScene
	if scene == null:
		_fail("Breakout entry scene did not load")
		return
	var game := scene.instantiate()
	root.add_child(game)
	cartridge_audio.call("begin_scope", "org.popugonet.popugvpocket.breakout")
	game.call("_start_game")
	if String(game.get("screen")) != "playing" or int(game.get("lives")) != 3:
		_fail("Breakout round did not start")
		return
	game.call("_serve_ball")
	var velocity: Vector2 = game.get("velocity")
	if velocity.length() < 100.0 or absf(velocity.x) < 40.0:
		_fail("Breakout serve velocity is invalid")
		return
	var paddle_before := float(game.get("paddle_x"))
	game.set("paddle_x", paddle_before + 10.0)
	if float(game.get("paddle_x")) <= paddle_before:
		_fail("Breakout paddle did not move")
		return
	var bricks: Array = game.get("bricks")
	var brick_count := bricks.size()
	var brick: Rect2 = bricks[0]
	game.set("ball", brick.get_center())
	game.set("velocity", Vector2(120.0, 160.0))
	if not bool(game.call("_resolve_brick", brick.get_center() - Vector2(0, 8))) or Array(game.get("bricks")).size() != brick_count - 1:
		_fail("Breakout brick collision did not remove exactly one brick")
		return
	game.call("_lose_life")
	game.call("_lose_life")
	game.call("_lose_life")
	if String(game.get("screen")) != "game_over" or int(game.get("lives")) != 0:
		_fail("Breakout game over state failed")
		return
	cartridge_audio.call("end_scope")
	game.queue_free()
	call_deferred("_complete")


func _complete() -> void:
	await process_frame
	await process_frame
	print("Breakout smoke passed: launch, serve, move, brick, lives, game over, exit")
	quit(0)


func _fail(message: String) -> void:
	var cartridge_audio := root.get_node_or_null("CartridgeAudio")
	if cartridge_audio != null:
		cartridge_audio.call("end_scope")
	push_error(message)
	quit(1)
