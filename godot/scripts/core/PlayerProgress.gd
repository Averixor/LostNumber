extends RefCounted
class_name PlayerProgress

## Stats and achievements ported from the JS prototype. Logic-only; UI can bind later.

var stats := {
	"games_played": 0,
	"levels_completed": 0,
	"highest_level": 0,
	"total_xp": 0,
	"total_merges": 0,
	"longest_chain": 0,
	"bonuses_used": 0,
	"wheel_spins": 0,
}

var achievements := {
	"first_game": {"unlocked": false, "progress": 0, "max": 1},
	"level_10": {"unlocked": false, "progress": 0, "max": 10},
	"level_25": {"unlocked": false, "progress": 0, "max": 25},
	"xp_1000": {"unlocked": false, "progress": 0, "max": 1000},
	"xp_5000": {"unlocked": false, "progress": 0, "max": 5000},
	"chain_5": {"unlocked": false, "progress": 0, "max": 1},
	"chain_10": {"unlocked": false, "progress": 0, "max": 1},
}


func record_new_game() -> void:
	stats["games_played"] = int(stats["games_played"]) + 1
	_unlock_progress("first_game", 1)


func record_merge(chain_len: int, xp: int, current_level: int) -> void:
	stats["total_merges"] = int(stats["total_merges"]) + 1
	stats["total_xp"] = int(stats["total_xp"]) + xp
	stats["longest_chain"] = maxi(int(stats["longest_chain"]), chain_len)
	stats["highest_level"] = maxi(int(stats["highest_level"]), current_level + 1)
	_unlock_progress("xp_1000", int(stats["total_xp"]))
	_unlock_progress("xp_5000", int(stats["total_xp"]))
	if chain_len >= 5:
		_unlock_progress("chain_5", 1)
	if chain_len >= 10:
		_unlock_progress("chain_10", 1)


func record_level_complete(current_level: int) -> void:
	stats["levels_completed"] = int(stats["levels_completed"]) + 1
	stats["highest_level"] = maxi(int(stats["highest_level"]), current_level + 1)
	_unlock_progress("level_10", int(stats["highest_level"]))
	_unlock_progress("level_25", int(stats["highest_level"]))


func _unlock_progress(key: String, value: int) -> void:
	if not achievements.has(key):
		return
	var item: Dictionary = achievements[key]
	item["progress"] = mini(value, int(item["max"]))
	item["unlocked"] = int(item["progress"]) >= int(item["max"])
	achievements[key] = item


func to_dict() -> Dictionary:
	return {"stats": stats.duplicate(true), "achievements": achievements.duplicate(true)}


func load_from_dict(data: Dictionary) -> void:
	if data.has("stats") and typeof(data.stats) == TYPE_DICTIONARY:
		for k in data.stats.keys():
			if stats.has(k):
				stats[k] = int(data.stats[k])
	if data.has("achievements") and typeof(data.achievements) == TYPE_DICTIONARY:
		for k in data.achievements.keys():
			if achievements.has(k) and typeof(data.achievements[k]) == TYPE_DICTIONARY:
				achievements[k].merge(data.achievements[k], true)
