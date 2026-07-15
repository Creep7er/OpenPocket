extends RefCounted

const DEFAULT_SETTINGS: Dictionary = {
	"difficulty": "normal",
	"walls": "solid",
	"growth": 1,
	"food_mode": "classic",
	"grid": "normal",
	"obstacles": "off",
	"mode": "classic",
}

const DIFFICULTY_CONFIG: Dictionary = {
	"easy": {"label": "EASY", "step_seconds": 0.24, "score_multiplier": 1.0},
	"normal": {"label": "NORMAL", "step_seconds": 0.17, "score_multiplier": 1.25},
	"hard": {"label": "HARD", "step_seconds": 0.11, "score_multiplier": 1.5},
	"extreme": {"label": "EXTREME", "step_seconds": 0.075, "score_multiplier": 2.0},
}

const GRID_CONFIG: Dictionary = {
	"small": Vector2i(12, 12),
	"normal": Vector2i(16, 16),
	"large": Vector2i(20, 20),
}

const TIME_ATTACK_SECONDS := 60.0
const TIMED_FOOD_SECONDS := 7.0


static func setting_defs() -> Array[Dictionary]:
	return [
		{"key": "mode", "label": "MODE", "values": ["classic", "time_attack"], "labels": ["CLASSIC", "TIME ATTACK"]},
		{"key": "difficulty", "label": "DIFFICULTY", "values": ["easy", "normal", "hard", "extreme"], "labels": ["EASY", "NORMAL", "HARD", "EXTREME"]},
		{"key": "walls", "label": "WALLS", "values": ["solid", "wrap"], "labels": ["SOLID", "WRAP"]},
		{"key": "growth", "label": "GROWTH", "values": [1, 2, 3], "labels": ["1", "2", "3"]},
		{"key": "food_mode", "label": "FOOD", "values": ["classic", "timed"], "labels": ["CLASSIC", "TIMED"]},
		{"key": "grid", "label": "GRID", "values": ["small", "normal", "large"], "labels": ["SMALL", "NORMAL", "LARGE"]},
		{"key": "obstacles", "label": "OBSTACLES", "values": ["off", "low", "high"], "labels": ["OFF", "LOW", "HIGH"]},
	]


static func score_for_food(settings: Dictionary) -> int:
	var difficulty := String(settings.get("difficulty", DEFAULT_SETTINGS["difficulty"]))
	var multiplier := float(Dictionary(DIFFICULTY_CONFIG.get(difficulty, DIFFICULTY_CONFIG["normal"])).get("score_multiplier", 1.0))
	if String(settings.get("mode", "classic")) == "time_attack":
		multiplier += 0.25
	if String(settings.get("obstacles", "off")) == "low":
		multiplier += 0.15
	elif String(settings.get("obstacles", "off")) == "high":
		multiplier += 0.35
	if String(settings.get("food_mode", "classic")) == "timed":
		multiplier += 0.15
	return int(round(10.0 * multiplier))


static func high_score_key(settings: Dictionary) -> String:
	return "high_score." + String(settings.get("mode", "classic")) + "." + String(settings.get("difficulty", "normal"))
