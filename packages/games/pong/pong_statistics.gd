extends RefCounted

const DEFAULTS: Dictionary = {
	"matches": 0,
	"wins": 0,
	"losses": 0,
	"points_for": 0,
	"points_against": 0,
	"longest_rally": 0,
}


static func update_after_match(stats: Dictionary, player_score: int, cpu_score: int, longest_rally: int) -> Dictionary:
	var result := DEFAULTS.duplicate()
	for key in stats.keys():
		result[key] = stats[key]
	result["matches"] = int(result["matches"]) + 1
	result["points_for"] = int(result["points_for"]) + player_score
	result["points_against"] = int(result["points_against"]) + cpu_score
	result["longest_rally"] = maxi(int(result["longest_rally"]), longest_rally)
	if player_score > cpu_score:
		result["wins"] = int(result["wins"]) + 1
	else:
		result["losses"] = int(result["losses"]) + 1
	return result
