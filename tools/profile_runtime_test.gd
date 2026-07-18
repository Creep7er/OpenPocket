extends Node

const Vault := preload("res://app/runtime/cosmetics/reward_vault.gd")
const Provider := preload("res://app/runtime/store/github_catalog_provider.gd")

var _failed := false


func _ready() -> void:
	var test_id := "org.popugonet.popugvpocket.runtime_test_" + str(Time.get_ticks_usec())
	var cartridge := {"id":test_id,"achievements":[{"id":"counter","name":"Counter","description":"Test","type":"counter","event":"tick","target":2,"points":1}]}
	_assert(AchievementManager.process_event(cartridge, "tick", 1.0).is_empty(), "counter unlocked too early")
	var unlocked := AchievementManager.process_event(cartridge, "tick", 1.0)
	_assert(unlocked == [test_id + ":counter"], "counter did not unlock")
	_assert(AchievementManager.process_event(cartridge, "tick", 1.0).is_empty(), "achievement unlocked twice")
	var vault := Vault.new()
	vault.load_data()
	var reward_source := {"id":test_id,"version":"0.5.1","_base_path":"res://tools/test_data"}
	var reward := {"id":"test_reward","type":"theme","name":"Test Reward","definition":"reward_theme.json","permanent":true}
	var first_unlock := vault.unlock(reward_source, reward)
	var second_unlock := vault.unlock(reward_source, reward)
	_assert(first_unlock != second_unlock, "reward was not idempotent")
	var reward_record := Dictionary(vault.all().get(test_id + ".reward.test_reward", {}))
	_assert(FileAccess.file_exists(String(reward_record.get("path", ""))), "reward asset was not copied")
	var provider := Provider.new()
	var duplicate_catalog := {"schema_version":2,"packages":[{"id":"same","moderation_status":"approved","author":{}},{"id":"same","moderation_status":"approved","author":{}}]}
	_assert(String(provider.call("_parse_catalog", duplicate_catalog).get("error", "")) == "duplicate_id", "duplicate catalog id accepted")
	provider.free()
	if not _failed:
		print("PopugVPocket 0.5.1 profile runtime test passed")
	get_tree().quit(1 if _failed else 0)


func _assert(condition: bool, message: String) -> void:
	if condition: return
	_failed = true
	push_error(message)
