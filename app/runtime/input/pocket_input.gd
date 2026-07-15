extends Node

const UP := "UP"
const DOWN := "DOWN"
const LEFT := "LEFT"
const RIGHT := "RIGHT"
const A := "A"
const B := "B"
const X := "X"
const Y := "Y"
const MENU := "MENU"
const EXIT := "EXIT"

const BUTTONS: Array[String] = [UP, DOWN, LEFT, RIGHT, A, B, X, Y, MENU, EXIT]

var _actions: Dictionary = {
	UP: "pocket_up",
	DOWN: "pocket_down",
	LEFT: "pocket_left",
	RIGHT: "pocket_right",
	A: "pocket_a",
	B: "pocket_b",
	X: "pocket_x",
	Y: "pocket_y",
	MENU: "pocket_menu",
	EXIT: "pocket_exit",
}

var _pressed: Dictionary = {}
var _previous: Dictionary = {}
var _virtual_pressed: Dictionary = {}


func _ready() -> void:
	for button in BUTTONS:
		_pressed[button] = false
		_previous[button] = false
		_virtual_pressed[button] = false


func _process(_delta: float) -> void:
	for button in BUTTONS:
		_previous[button] = _pressed[button]
		var action_name: String = _actions[button]
		_pressed[button] = bool(_virtual_pressed[button]) or Input.is_action_pressed(action_name)


## Returns true while a Pocket button is held.
func is_pressed(button: String) -> bool:
	return bool(_pressed.get(button, false))


## Returns true on the frame a Pocket button becomes pressed.
func just_pressed(button: String) -> bool:
	return bool(_pressed.get(button, false)) and not bool(_previous.get(button, false))


## Returns true on the frame a Pocket button is released.
func just_released(button: String) -> bool:
	return not bool(_pressed.get(button, false)) and bool(_previous.get(button, false))


## Updates the virtual touchscreen button state.
func set_virtual_button(button: String, pressed: bool) -> void:
	if not _virtual_pressed.has(button):
		push_warning("Unknown PocketInput button: " + button)
		return
	_virtual_pressed[button] = pressed
