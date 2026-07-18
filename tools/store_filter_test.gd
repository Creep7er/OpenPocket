extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var manager := root.get_node("CartridgeManager")
	var store := root.get_node("StoreService")
	manager.call("bootstrap")
	store.call("refresh")
	var all_items: Array[Dictionary] = store.call("list_catalog")
	var featured_items: Array[Dictionary] = store.call("featured")
	var update_items: Array[Dictionary] = store.call("updates")
	var search_items: Array[Dictionary] = store.call("search", "clock")
	if all_items.is_empty():
		_fail("All catalog is empty")
		return
	if featured_items.is_empty() or featured_items.size() >= all_items.size():
		_fail("Featured filter is not distinct")
		return
	if not update_items.is_empty():
		_fail("Unexpected built-in updates in baseline catalog")
		return
	if search_items.size() != 1 or String(search_items[0].get("id", "")) != "org.popugonet.popugvpocket.pixelclock":
		_fail("Search filter returned incorrect items")
		return
	if not Array(store.call("search", "")).is_empty():
		_fail("Empty search must not return the full catalog")
		return
	if int(store.call("compare_versions", "1.10.0", "1.2.0")) <= 0:
		_fail("Semantic version comparison is incorrect")
		return
	var ids: Dictionary = {}
	for item in all_items:
		var cartridge_id := String(item.get("id", ""))
		if ids.has(cartridge_id):
			_fail("Duplicate cartridge id: " + cartridge_id)
			return
		ids[cartridge_id] = true
	print("Store filters passed: featured=%d all=%d updates=%d search=%d" % [featured_items.size(), all_items.size(), update_items.size(), search_items.size()])
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
