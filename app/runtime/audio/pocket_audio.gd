extends Node

const SAMPLE_RATE := 22050
const UI_PLAYER_COUNT := 4
const CARTRIDGE_PLAYER_COUNT := 4
const EVENTS := {
	"focus": Vector2(660.0, 0.07),
	"select": Vector2(880.0, 0.07),
	"back": Vector2(440.0, 0.07),
	"error": Vector2(180.0, 0.07),
	"pause": Vector2(520.0, 0.07),
	"boot": Vector2(990.0, 0.13),
	"bounce": Vector2(740.0, 0.045),
	"brick": Vector2(920.0, 0.055),
	"life": Vector2(220.0, 0.12),
	"win": Vector2(1100.0, 0.16),
}

var _ui_players: Array[AudioStreamPlayer] = []
var _cartridge_players: Dictionary = {}
var _cartridge_volumes: Dictionary = {}


func _ready() -> void:
	_ui_players = _create_pool("UIAudio", UI_PLAYER_COUNT)


func is_available() -> bool:
	return is_inside_tree() and not _ui_players.is_empty()


func play_ui_safe(event_name: String) -> bool:
	if not bool(PocketStorage.get_setting("sound_enabled", true)):
		return false
	var volume := clampf(float(PocketStorage.get_setting("volume", 80)) / 100.0, 0.0, 1.0)
	return _play_on_pool(_ui_players, event_name, volume)


func play(event_name: String) -> void:
	play_ui_safe(event_name)


func focus() -> void:
	play_ui_safe("focus")


func select() -> void:
	play_ui_safe("select")


func back() -> void:
	play_ui_safe("back")


func error() -> void:
	play_ui_safe("error")


func pause() -> void:
	play_ui_safe("pause")


func boot() -> void:
	play_ui_safe("boot")


func begin_cartridge_scope(package_id: String) -> bool:
	if package_id.is_empty():
		return false
	stop_cartridge_sounds(package_id)
	_cartridge_players[package_id] = _create_pool("CartridgeAudio_" + package_id.validate_node_name(), CARTRIDGE_PLAYER_COUNT)
	_cartridge_volumes[package_id] = 1.0
	return true


func play_cartridge_safe(package_id: String, event_name: String) -> bool:
	if package_id.is_empty() or not _cartridge_players.has(package_id):
		return false
	if not bool(PocketStorage.get_setting("sound_enabled", true)):
		return false
	if not bool(PocketStorage.get_package_setting(package_id, "sound", true)):
		return false
	var global_volume := clampf(float(PocketStorage.get_setting("volume", 80)) / 100.0, 0.0, 1.0)
	var local_volume := clampf(float(_cartridge_volumes.get(package_id, 1.0)), 0.0, 1.0)
	return _play_on_pool(Array(_cartridge_players[package_id]), event_name, global_volume * local_volume)


func set_cartridge_volume(package_id: String, value: float) -> void:
	if _cartridge_players.has(package_id):
		_cartridge_volumes[package_id] = clampf(value, 0.0, 1.0)


func stop_cartridge_sounds(package_id: String) -> void:
	if not _cartridge_players.has(package_id):
		return
	for player_value in Array(_cartridge_players[package_id]):
		var player := player_value as AudioStreamPlayer
		if is_instance_valid(player):
			player.stop()
			player.queue_free()
	_cartridge_players.erase(package_id)
	_cartridge_volumes.erase(package_id)


func _create_pool(prefix: String, count: int) -> Array[AudioStreamPlayer]:
	var result: Array[AudioStreamPlayer] = []
	for index in range(count):
		var player := AudioStreamPlayer.new()
		player.name = prefix + str(index)
		player.bus = "Master"
		add_child(player)
		result.append(player)
	return result


func _play_on_pool(players: Array, event_name: String, volume: float) -> bool:
	if not EVENTS.has(event_name) or players.is_empty() or volume <= 0.0:
		return false
	var player := _free_player(players)
	if player == null or not is_instance_valid(player):
		return false
	var event: Vector2 = EVENTS[event_name]
	var stream := _make_tone(event.x, event.y)
	if stream == null:
		push_warning("PocketAudio ignored invalid event: " + event_name)
		return false
	player.stop()
	player.volume_db = linear_to_db(volume)
	player.stream = stream
	player.play()
	return true


func _free_player(players: Array) -> AudioStreamPlayer:
	for player_value in players:
		var player := player_value as AudioStreamPlayer
		if is_instance_valid(player) and not player.playing:
			return player
	return players[0] as AudioStreamPlayer if not players.is_empty() else null


func _make_tone(frequency: float, duration: float) -> AudioStreamWAV:
	if not is_finite(frequency) or not is_finite(duration) or frequency <= 0.0 or duration <= 0.0 or duration > 1.0:
		return null
	var frames := int(SAMPLE_RATE * duration)
	if frames <= 0:
		return null
	var data := PackedByteArray()
	data.resize(frames)
	for frame in range(frames):
		var wave := sin(float(frame) / float(SAMPLE_RATE) * TAU * frequency)
		var gate := 1.0 - float(frame) / float(frames)
		data[frame] = int(clampi(int(128.0 + wave * 64.0 * gate), 0, 255))
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_8_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream
