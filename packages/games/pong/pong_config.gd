extends RefCounted

const DEFAULT_SETTINGS: Dictionary = {
	"mode": "player_cpu",
	"cpu": "normal",
	"target_score": 7,
	"ball_speed": "normal",
	"paddle_size": "normal",
	"serve": "alternate",
}

const CPU_CONFIG: Dictionary = {
	"easy": {"label": "EASY", "tracking": 0.035, "error": 18.0},
	"normal": {"label": "NORMAL", "tracking": 0.06, "error": 8.0},
	"hard": {"label": "HARD", "tracking": 0.09, "error": 2.0},
}

const BALL_SPEEDS: Dictionary = {
	"slow": 135.0,
	"normal": 165.0,
	"fast": 205.0,
}

const PADDLE_SIZES: Dictionary = {
	"small": 40.0,
	"normal": 52.0,
	"large": 68.0,
}


static func setting_defs() -> Array[Dictionary]:
	return [
		{"key": "mode", "label": "MODE", "values": ["player_cpu"], "labels": ["PLAYER VS CPU"]},
		{"key": "cpu", "label": "CPU", "values": ["easy", "normal", "hard"], "labels": ["EASY", "NORMAL", "HARD"]},
		{"key": "target_score", "label": "TARGET", "values": [5, 7, 11], "labels": ["5", "7", "11"]},
		{"key": "ball_speed", "label": "BALL", "values": ["slow", "normal", "fast"], "labels": ["SLOW", "NORMAL", "FAST"]},
		{"key": "paddle_size", "label": "PADDLE", "values": ["small", "normal", "large"], "labels": ["SMALL", "NORMAL", "LARGE"]},
		{"key": "serve", "label": "SERVE", "values": ["alternate", "random"], "labels": ["ALTERNATE", "RANDOM"]},
	]


static func base_ball_speed(settings: Dictionary) -> float:
	return float(BALL_SPEEDS.get(String(settings.get("ball_speed", "normal")), BALL_SPEEDS["normal"]))


static func paddle_height(settings: Dictionary) -> float:
	return float(PADDLE_SIZES.get(String(settings.get("paddle_size", "normal")), PADDLE_SIZES["normal"]))
