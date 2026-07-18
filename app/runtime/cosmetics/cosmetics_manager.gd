extends Node

signal cosmetic_unlocked(cosmetic_id: String)

const Vault := preload("res://app/runtime/cosmetics/reward_vault.gd")
var _vault := Vault.new()


func _ready() -> void:
	_vault.load_data()
	AchievementManager.achievement_unlocked.connect(_on_achievement_unlocked)


func list_themes() -> Array[Dictionary]:
	var result: Array[Dictionary] = [{"id": "mono", "name": "Pocket Mono", "source": "built-in"}, {"id": "amber", "name": "Pocket Amber", "source": "built-in"}]
	for cartridge in CartridgeManager.list_installed():
		for value in Array(Dictionary(cartridge.get("cosmetics", {})).get("provided", [])):
			var cosmetic := Dictionary(value)
			if String(cosmetic.get("type", "")) == "theme":
				result.append({"id": String(cartridge.get("id", "")) + ":" + String(cosmetic.get("id", "")), "name": String(cosmetic.get("name", "THEME")), "source": "cartridge", "definition": cosmetic, "cartridge": cartridge})
	var rewards := _vault.all()
	for key in rewards.keys():
		var reward := Dictionary(rewards[key])
		if String(reward.get("type", "")) == "theme": result.append({"id": String(key), "name": String(reward.get("name", "REWARD")), "source": "reward", "path": String(reward.get("path", ""))})
	return result


func ensure_active_available() -> void:
	var selected := String(PocketStorage.get_setting("theme", "mono"))
	for theme in list_themes():
		if String(theme.get("id", "")) == selected: return
	PocketStorage.set_setting("theme", "mono")


func theme_data(theme_id: String) -> Dictionary:
	for theme in list_themes():
		if String(theme.get("id", "")) != theme_id: continue
		var path := String(theme.get("path", ""))
		if path.is_empty() and String(theme.get("source", "")) == "cartridge":
			var cartridge := Dictionary(theme.get("cartridge", {}))
			path = String(cartridge.get("_base_path", cartridge.get("resource_root", ""))).path_join(String(Dictionary(theme.get("definition", {})).get("definition", "")))
		return _read_json(path)
	return {}


func _on_achievement_unlocked(scoped_id: String, definition: Dictionary) -> void:
	var cartridge_id := scoped_id.get_slice(":", 0)
	var cartridge := CartridgeManager.get_cartridge(cartridge_id)
	for reward_value in Array(definition.get("rewards", [])):
		for value in Array(Dictionary(cartridge.get("cosmetics", {})).get("rewards", [])):
			var reward := Dictionary(value)
			if String(reward.get("id", "")) == String(reward_value) and bool(reward.get("permanent", false)) and _vault.unlock(cartridge, reward): cosmetic_unlocked.emit(cartridge_id + ".reward." + String(reward_value))


func _read_json(path: String) -> Dictionary:
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	return Dictionary(parsed) if typeof(parsed) == TYPE_DICTIONARY else {}
