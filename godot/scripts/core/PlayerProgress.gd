extends RefCounted
class_name PlayerProgress

const AutoloadAccessLib := preload("res://scripts/managers/AutoloadAccess.gd")

var stats := {
	"games_played": 0,
	"levels_completed": 0,
	"highest_level": 0,
	"total_xp": 0,
	"total_merges": 0,
	"longest_chain": 0,
	"bonuses_used": 0,
	"wheel_spins": 0,
	"session_xp_today": 0,
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

var leaderboard := {
	"best_level": 0,
	"best_xp": 0,
	"longest_chain": 0,
	"opt_in": false,
	"pending_submits": [],
}

var _daily_date: String = ""


func record_new_game() -> void:
	stats["games_played"] = int(stats["games_played"]) + 1
	_unlock_progress("first_game", 1)


func record_merge(chain_len: int, xp: int, current_level: int) -> void:
	stats["total_merges"] = int(stats["total_merges"]) + 1
	stats["total_xp"] = int(stats["total_xp"]) + xp
	stats["session_xp_today"] = int(stats.get("session_xp_today", 0)) + xp
	stats["longest_chain"] = maxi(int(stats["longest_chain"]), chain_len)
	stats["highest_level"] = maxi(int(stats["highest_level"]), current_level + 1)
	_unlock_progress("xp_1000", int(stats["total_xp"]))
	_unlock_progress("xp_5000", int(stats["total_xp"]))
	if chain_len >= 5:
		_unlock_progress("chain_5", 1)
	if chain_len >= 10:
		_unlock_progress("chain_10", 1)
	_update_leaderboard_peaks(current_level + 1, int(stats["total_xp"]), chain_len)


func record_level_complete(current_level: int) -> void:
	stats["levels_completed"] = int(stats["levels_completed"]) + 1
	stats["highest_level"] = maxi(int(stats["highest_level"]), current_level + 1)
	_unlock_progress("level_10", int(stats["highest_level"]))
	_unlock_progress("level_25", int(stats["highest_level"]))
	_update_leaderboard_peaks(int(stats["highest_level"]), int(stats["total_xp"]), int(stats["longest_chain"]))


func record_bonus_used() -> void:
	stats["bonuses_used"] = int(stats["bonuses_used"]) + 1


func record_wheel_spin() -> void:
	stats["wheel_spins"] = int(stats["wheel_spins"]) + 1


func reset_daily_session_if_needed(today_key: String) -> void:
	if _daily_date != today_key:
		_daily_date = today_key
		stats["session_xp_today"] = 0


func get_session_xp_today() -> int:
	return int(stats.get("session_xp_today", 0))


func build_leaderboard_payload() -> Dictionary:
	return {
		"best_level": {
			"score": int(leaderboard.get("best_level", 0)),
			"player": "local",
		},
		"total_xp": {
			"score": int(leaderboard.get("best_xp", 0)),
			"player": "local",
		},
		"longest_chain": {
			"score": int(leaderboard.get("longest_chain", 0)),
			"player": "local",
		},
	}


func queue_leaderboard_submit(board_id: String, payload: Dictionary) -> void:
	var pending: Array = leaderboard.get("pending_submits", [])
	var entry := payload.duplicate(true)
	entry["board"] = board_id
	entry["queued_at"] = Time.get_unix_time_from_system()
	pending.append(entry)
	leaderboard["pending_submits"] = pending


func flush_leaderboard_queue() -> void:
	var pending: Array = leaderboard.get("pending_submits", [])
	if pending.is_empty():
		return
	var svc := AutoloadAccessLib.get_autoload("LeaderboardService")
	if svc != null and svc.has_method("flush_pending"):
		leaderboard["pending_submits"] = svc.call("flush_pending", pending)


func _update_leaderboard_peaks(level: int, total_xp: int, chain_len: int) -> void:
	leaderboard["best_level"] = maxi(int(leaderboard.get("best_level", 0)), level)
	leaderboard["best_xp"] = maxi(int(leaderboard.get("best_xp", 0)), total_xp)
	leaderboard["longest_chain"] = maxi(int(leaderboard.get("longest_chain", 0)), chain_len)


func _unlock_progress(key: String, value: int) -> void:
	if not achievements.has(key):
		return
	var item: Dictionary = achievements[key]
	item["progress"] = mini(value, int(item["max"]))
	item["unlocked"] = int(item["progress"]) >= int(item["max"])
	achievements[key] = item


func to_dict() -> Dictionary:
	return {
		"stats": stats.duplicate(true),
		"achievements": achievements.duplicate(true),
		"leaderboard": leaderboard.duplicate(true),
		"daily_date": _daily_date,
	}


func load_from_dict(data: Dictionary) -> void:
	if data.has("stats") and typeof(data.stats) == TYPE_DICTIONARY:
		for k in data.stats.keys():
			if stats.has(k):
				stats[k] = int(data.stats[k])
	if data.has("achievements") and typeof(data.achievements) == TYPE_DICTIONARY:
		for k in data.achievements.keys():
			if achievements.has(k) and typeof(data.achievements[k]) == TYPE_DICTIONARY:
				achievements[k].merge(data.achievements[k], true)
	if data.has("leaderboard") and typeof(data.leaderboard) == TYPE_DICTIONARY:
		for k in data.leaderboard.keys():
			leaderboard[k] = data.leaderboard[k]
	_daily_date = str(data.get("daily_date", ""))
	ensure_defaults()


func ensure_defaults() -> void:
	var stat_defaults := {
		"games_played": 0,
		"levels_completed": 0,
		"highest_level": 0,
		"total_xp": 0,
		"total_merges": 0,
		"longest_chain": 0,
		"bonuses_used": 0,
		"wheel_spins": 0,
		"session_xp_today": 0,
	}
	for k in stat_defaults.keys():
		if not stats.has(k):
			stats[k] = stat_defaults[k]

	var achievement_templates := {
		"first_game": {"unlocked": false, "progress": 0, "max": 1},
		"level_10": {"unlocked": false, "progress": 0, "max": 10},
		"level_25": {"unlocked": false, "progress": 0, "max": 25},
		"xp_1000": {"unlocked": false, "progress": 0, "max": 1000},
		"xp_5000": {"unlocked": false, "progress": 0, "max": 5000},
		"chain_5": {"unlocked": false, "progress": 0, "max": 1},
		"chain_10": {"unlocked": false, "progress": 0, "max": 1},
	}
	for k in achievement_templates.keys():
		if not achievements.has(k):
			achievements[k] = achievement_templates[k].duplicate(true)
		else:
			var item: Dictionary = achievements[k]
			item["max"] = int(achievement_templates[k]["max"])
			if not item.has("progress"):
				item["progress"] = 0
			if not item.has("unlocked"):
				item["unlocked"] = false
			achievements[k] = item

	var board_defaults := {
		"best_level": 0,
		"best_xp": 0,
		"longest_chain": 0,
		"opt_in": false,
		"pending_submits": [],
	}
	for k in board_defaults.keys():
		if not leaderboard.has(k):
			leaderboard[k] = board_defaults[k]
	if typeof(leaderboard.get("pending_submits")) != TYPE_ARRAY:
		leaderboard["pending_submits"] = []
