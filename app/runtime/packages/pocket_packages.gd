extends Node

var _packages: Array[Dictionary] = []


## Loads built-in package manifests.
func load_builtin_packages() -> void:
	CartridgeManager.bootstrap()
	_packages = CartridgeManager.list_installed()


## Returns loaded package manifests.
func get_packages() -> Array[Dictionary]:
	return CartridgeManager.list_installed()


## Resolves a package entry scene to a Godot resource path.
func resolve_entry_scene(manifest: Dictionary) -> String:
	return CartridgeManager.resolve_entry_scene(manifest)
