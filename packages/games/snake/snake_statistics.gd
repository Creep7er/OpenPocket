extends RefCounted

const DEFAULTS: Dictionary = {
	"games_played": 0,
	"total_score": 0,
	"food_eaten": 0,
	"best_classic": 0,
	"best_time_attack": 0,
	"longest_snake": 0,
}


static func update_after_game(stats: Dictionary, settings: Dictionary, score: int, food_eaten: int, longest_snake: int) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in stats.keys():
		result[key] = stats[key]
	result["games_played"] = int(result["games_played"]) + 1
	result["total_score"] = int(result["total_score"]) + score
	result["food_eaten"] = int(result["food_eaten"]) + food_eaten
	result["longest_snake"] = maxi(int(result["longest_snake"]), longest_snake)
	if String(settings.get("mode", "classic")) == "time_attack":
		result["best_time_attack"] = maxi(int(result["best_time_attack"]), score)
	else:
		result["best_classic"] = maxi(int(result["best_classic"]), score)
	return result
