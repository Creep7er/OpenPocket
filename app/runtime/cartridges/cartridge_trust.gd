extends RefCounted

const BUILT_IN := "built_in"
const TRUSTED := "trusted"
const UNTRUSTED := "untrusted"
const BLOCKED := "blocked"


static func is_launch_allowed(trust: String, developer_mode: bool) -> bool:
	if trust == BUILT_IN or trust == TRUSTED:
		return true
	if trust == UNTRUSTED:
		return developer_mode
	return false
