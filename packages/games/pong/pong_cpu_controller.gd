extends RefCounted

const PongConfig := preload("res://packages/games/pong/pong_config.gd")


static func next_paddle_y(current_y: float, ball_y: float, paddle_h: float, settings: Dictionary, delta: float) -> float:
	var cpu_config := Dictionary(PongConfig.CPU_CONFIG.get(String(settings.get("cpu", "normal")), PongConfig.CPU_CONFIG["normal"]))
	var tracking := float(cpu_config.get("tracking", 0.06))
	var error := float(cpu_config.get("error", 8.0))
	var target := ball_y - paddle_h * 0.5 + sin(ball_y * 0.07) * error
	return lerpf(current_y, target, clampf(tracking * delta * 60.0, 0.0, 1.0))
