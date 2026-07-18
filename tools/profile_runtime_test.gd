extends Node

const Vault := preload("res://app/runtime/cosmetics/reward_vault.gd")
const Provider := preload("res://app/runtime/store/github_catalog_provider.gd")


func _ready() -> void:
	var cartridge := {"id":"org.openpocket.runtime_test","achievements":[{"id":"counter","name":"Counter","description":"Test","type":"counter","event":"tick","target":2,"points":1}]}
	_assert(AchievementManager.process_event(cartridge, "tick", 1.0).is_empty(), "counter unlocked too early")
	var unlocked := AchievementManager.process_event(cartridge, "tick", 1.0)
	_assert(unlocked == ["org.openpocket.runtime_test:counter"], "counter did not unlock")
	_assert(AchievementManager.process_event(cartridge, "tick", 1.0).is_empty(), "achievement unlocked twice")
	var vault := Vault.new()
	vault.load_data()
	var reward_source := {"id":"org.openpocket.runtime_test","version":"0.4.0","_base_path":"res://tools/test_data"}
	var reward := {"id":"test_reward","type":"theme","name":"Test Reward","definition":"reward_theme.json","permanent":true}
	var first_unlock := vault.unlock(reward_source, reward)
	var second_unlock := vault.unlock(reward_source, reward)
	_assert(first_unlock != second_unlock, "reward was not idempotent")
	var reward_record := Dictionary(vault.all().get("org.openpocket.runtime_test.reward.test_reward", {}))
	_assert(FileAccess.file_exists(String(reward_record.get("path", ""))), "reward asset was not copied")
	var provider := Provider.new()
	var duplicate_catalog := {"schema_version":1,"packages":[{"id":"same","author":{}},{"id":"same","author":{}}]}
	_assert(String(provider.call("_parse_catalog", duplicate_catalog).get("error", "")) == "duplicate_id", "duplicate catalog id accepted")
	provider.free()
	print("OpenPocket 0.4 profile runtime test passed")
	get_tree().quit(0)


func _assert(condition: bool, message: String) -> void:
	if condition: return
	push_error(message)
	get_tree().quit(1)
