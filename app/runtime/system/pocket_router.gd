extends Node

signal route_changed(route: String, payload: Dictionary)
signal system_menu_requested

var _history: Array[Dictionary] = []
var _current_route := "home"
var _current_payload: Dictionary = {}


## Opens the Home screen.
func go_home() -> void:
	_set_route("home", {}, true)


## Opens the package library.
func open_library() -> void:
	_set_route("library")


## Opens Settings.
func open_settings() -> void:
	_set_route("settings")


## Opens About.
func open_about() -> void:
	_set_route("about")


func open_store() -> void:
	_set_route("store")


## Opens a game package from its manifest.
func open_game(manifest: Dictionary) -> void:
	_set_route("game", manifest)


## Requests the global system overlay.
func open_system_menu() -> void:
	system_menu_requested.emit()


## Moves to the previous shell route, or Home when history is empty.
func back() -> void:
	if _history.is_empty():
		go_home()
		return
	var previous: Dictionary = _history.pop_back()
	_current_route = String(previous.get("route", "home"))
	_current_payload = Dictionary(previous.get("payload", {}))
	route_changed.emit(_current_route, _current_payload)


func _set_route(route: String, payload: Dictionary = {}, clear_history: bool = false) -> void:
	if clear_history:
		_history.clear()
	elif route != _current_route:
		_history.append({"route": _current_route, "payload": _current_payload})
	_current_route = route
	_current_payload = payload
	route_changed.emit(route, payload)
