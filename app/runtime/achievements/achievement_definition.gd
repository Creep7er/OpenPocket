extends RefCounted

const TYPES := ["event", "counter", "value"]
const COMPARISONS := ["gte", "lte", "eq"]


static func validate(definition: Dictionary) -> bool:
	var achievement_id := String(definition.get("id", ""))
	return not achievement_id.is_empty() and not achievement_id.contains(":") and not String(definition.get("event", "")).is_empty() and TYPES.has(String(definition.get("type", "event"))) and COMPARISONS.has(String(definition.get("comparison", "gte"))) and float(definition.get("target", 1.0)) > 0.0
