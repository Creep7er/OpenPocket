extends Node

signal notification(message: String)


## Broadcasts a small system notification.
func notify(message: String) -> void:
	print("[OpenPocket] " + message)
	notification.emit(message)


## Exits the application through Godot's portable API.
func exit_application() -> void:
	get_tree().quit()


## Returns the read-only context of the currently launched cartridge.
func get_cartridge_context() -> Dictionary:
	return CartridgeManager.active_context()
