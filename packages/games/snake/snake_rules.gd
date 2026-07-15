extends RefCounted


static func is_reverse(current: Vector2i, next: Vector2i) -> bool:
	return current + next == Vector2i.ZERO


static func move_head(head: Vector2i, direction: Vector2i, grid_size: Vector2i, walls: String) -> Dictionary:
	var next := head + direction
	if walls == "wrap":
		next.x = wrapi(next.x, 0, grid_size.x)
		next.y = wrapi(next.y, 0, grid_size.y)
		return {"head": next, "wall_collision": false}
	return {"head": next, "wall_collision": next.x < 0 or next.y < 0 or next.x >= grid_size.x or next.y >= grid_size.y}


static func first_free_cell(grid_size: Vector2i, blocked: Array[Vector2i]) -> Vector2i:
	for y in range(grid_size.y):
		for x in range(grid_size.x):
			var candidate := Vector2i(x, y)
			if not blocked.has(candidate):
				return candidate
	return Vector2i.ZERO
