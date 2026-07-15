extends Control
class_name PackageSettingsView

signal back_requested
signal setting_changed(key: String, value: Variant)

var package_id := ""
var definitions: Array[PackageSettingDefinition] = []
var selected_index := 0


func configure(id: String, setting_definitions: Array[PackageSettingDefinition]) -> void:
	package_id = id
	definitions = setting_definitions
	selected_index = 0
	queue_redraw()


func _process(_delta: float) -> void:
	if definitions.is_empty():
		return
	if PocketInput.just_pressed(PocketInput.UP):
		selected_index = wrapi(selected_index - 1, 0, definitions.size())
		PocketAudio.focus()
	if PocketInput.just_pressed(PocketInput.DOWN):
		selected_index = wrapi(selected_index + 1, 0, definitions.size())
		PocketAudio.focus()
	if PocketInput.just_pressed(PocketInput.LEFT):
		_cycle(-1)
	if PocketInput.just_pressed(PocketInput.RIGHT) or PocketInput.just_pressed(PocketInput.A):
		_cycle(1)
	if PocketInput.just_pressed(PocketInput.B) or PocketInput.just_pressed(PocketInput.EXIT):
		back_requested.emit()
	queue_redraw()


func _draw() -> void:
	var p := PocketTheme.palette()
	draw_rect(Rect2(Vector2.ZERO, size), p["dark"], true)
	PixelFont.draw_text(self, Vector2(20, 20), "PACKAGE SETTINGS", p["hi"], 2)
	for index in range(definitions.size()):
		var definition := definitions[index]
		var value: Variant = PocketStorage.get_package_setting(package_id, definition.key, definition.values[0] if not definition.values.is_empty() else null)
		var row := Rect2(Vector2(20, 66 + index * 24), Vector2(size.x - 40, 20))
		PackageSettingsRenderer.draw_row(self, row, definition.label, definition.value_label(value), index == selected_index, p)


func _cycle(delta: int) -> void:
	var definition := definitions[selected_index]
	if definition.values.is_empty():
		return
	var current: Variant = PocketStorage.get_package_setting(package_id, definition.key, definition.values[0])
	var index := definition.values.find(current)
	if index < 0:
		index = 0
	index = wrapi(index + delta, 0, definition.values.size())
	var value: Variant = definition.values[index]
	if PocketStorage.set_package_setting(package_id, definition.key, value):
		setting_changed.emit(definition.key, value)
		PocketAudio.focus()
