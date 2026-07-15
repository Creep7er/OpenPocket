extends RefCounted
class_name PackageSettingDefinition

var key := ""
var label := ""
var values: Array = []
var labels: Array[String] = []


func _init(setting_key: String = "", setting_label: String = "", setting_values: Array = [], setting_labels: Array[String] = []) -> void:
	key = setting_key
	label = setting_label
	values = setting_values
	labels = setting_labels


func value_label(value: Variant) -> String:
	var index := values.find(value)
	if index >= 0 and index < labels.size():
		return labels[index]
	return str(value).to_upper()
