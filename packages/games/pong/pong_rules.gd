extends RefCounted


static func capped_velocity(velocity: Vector2, cap: float) -> Vector2:
	if velocity.length() <= cap:
		return velocity
	return velocity.normalized() * cap


static func bounce_from_paddle(ball_y: float, paddle_y: float, paddle_h: float, x_speed: float, direction: float) -> Vector2:
	var relative := clampf((ball_y - (paddle_y + paddle_h * 0.5)) / (paddle_h * 0.5), -1.0, 1.0)
	var velocity := Vector2(absf(x_speed) * direction, relative * absf(x_speed) * 0.72)
	if absf(velocity.y) < 24.0:
		velocity.y = 24.0 * signf(relative if relative != 0.0 else 1.0)
	return velocity


static func match_finished(player_score: int, cpu_score: int, target_score: int) -> bool:
	return player_score >= target_score or cpu_score >= target_score
