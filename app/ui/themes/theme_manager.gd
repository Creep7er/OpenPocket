extends Node

const MONO := "mono"
const AMBER := "amber"

const VIRTUAL_SCREEN_SIZE := Vector2i(400, 320)
var _preview_theme := ""

const _PALETTES: Dictionary = {
	MONO: {
		"dark": Color("#0f380f"),
		"mid": Color("#306230"),
		"light": Color("#8bac0f"),
		"hi": Color("#9bbc0f"),
		"case_dark": Color("#1b2518"),
		"case_mid": Color("#55613a"),
		"case_light": Color("#9aa35b"),
	},
	AMBER: {
		"dark": Color("#1b1208"),
		"mid": Color("#5a3715"),
		"light": Color("#c47a22"),
		"hi": Color("#f2c14e"),
		"case_dark": Color("#20140a"),
		"case_mid": Color("#6a4219"),
		"case_light": Color("#b8782e"),
	},
}


func active_theme_id() -> String:
	if not _preview_theme.is_empty(): return _preview_theme
	var stored: String = String(PocketStorage.get_setting("theme", MONO)).to_lower()
	if stored == "green":
		return MONO
	if not _PALETTES.has(stored) and CosmeticsManager.theme_data(stored).is_empty(): return MONO
	return stored


func palette(theme_id: String = "") -> Dictionary:
	var id := active_theme_id() if theme_id.is_empty() else theme_id
	if not _PALETTES.has(id):
		var data := CosmeticsManager.theme_data(id)
		var colors := Dictionary(data.get("palette", {}))
		if not colors.is_empty():
			return {"dark": Color(String(colors.get("background", "#0f380f"))), "mid": Color(String(colors.get("surface", "#306230"))), "light": Color(String(colors.get("primary", "#8bac0f"))), "hi": Color(String(colors.get("text", "#9bbc0f"))), "case_dark": Color(String(colors.get("background", "#1b2518"))), "case_mid": Color(String(colors.get("surface", "#55613a"))), "case_light": Color(String(colors.get("secondary", "#9aa35b")))}
	return Dictionary(_PALETTES.get(id, _PALETTES[MONO]))


func color(name: String, theme_id: String = "") -> Color:
	var colors := palette(theme_id)
	return Color(colors.get(name, Color.MAGENTA))


func next_theme(current: String) -> String:
	var themes := CosmeticsManager.list_themes()
	var ids: Array[String] = []
	for theme in themes: ids.append(String(theme.get("id", MONO)))
	var index := ids.find(current.to_lower())
	return ids[wrapi(index + 1, 0, ids.size())] if not ids.is_empty() else MONO


func theme_label() -> String:
	var active := active_theme_id()
	for theme in CosmeticsManager.list_themes():
		if String(theme.get("id", "")) == active: return String(theme.get("name", active)).to_upper()
	return active.to_upper()


func preview(theme_id: String) -> void:
	_preview_theme = theme_id


func clear_preview() -> void:
	_preview_theme = ""


func pixel_style(bg: Color, border: Color, border_width: int = 2, margin: int = 4) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(0)
	style.content_margin_left = margin
	style.content_margin_right = margin
	style.content_margin_top = margin
	style.content_margin_bottom = margin
	return style
