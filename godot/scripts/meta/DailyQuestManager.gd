extends RefCounted
class_name DailyQuestManager

## Daily quests ported from js/game/meta/daily.js

const AutoloadAccessLib := preload("res://scripts/managers/AutoloadAccess.gd")

const QUEST_DEFS := [
	{"id": "completeLevel", "text_key": "daily_complete_level", "reward": {"type": "xp", "amount": 20}},
	{"id": "chain5", "text_key": "daily_chain_5", "reward": {"type": "bonus", "bonus": "explosion", "amount": 1}},
	{"id": "xp100", "text_key": "daily_xp_100", "reward": {"type": "xp", "amount": 30}},
	{"id": "useBonus", "text_key": "daily_use_bonus", "reward": {"type": "bonus", "bonus": "shuffle", "amount": 1}},
	{"id": "spinWheel", "text_key": "daily_spin_wheel", "reward": {"type": "xp", "amount": 15}},
]

var state: GameState


func _init(game_state: GameState) -> void:
	state = game_state


func ensure_loaded() -> void:
	var today := _today_key()
	state.progress.reset_daily_session_if_needed(today)
	if state.daily_quests.get("date", "") == today:
		_ensure_progress_dict()
		return
	state.daily_quests = {
		"date": today,
		"completed": {},
		"progress": {},
		"list": QUEST_DEFS.duplicate(true),
	}
	_ensure_progress_dict()


func complete(id: String) -> bool:
	ensure_loaded()
	var completed: Dictionary = state.daily_quests.get("completed", {})
	if bool(completed.get(id, false)):
		return false
	completed[id] = true
	state.daily_quests["completed"] = completed
	_set_progress(id, _progress_max(id))
	_give_reward(id)
	AutoloadAccessLib.call_method("AudioManager", "play_sfx", ["quest_complete"])
	return true


func is_done(id: String) -> bool:
	ensure_loaded()
	return bool(state.daily_quests.get("completed", {}).get(id, false))


func get_quests() -> Array:
	ensure_loaded()
	return state.daily_quests.get("list", [])


func on_level_complete() -> void:
	_add_progress("completeLevel", 1)
	if _get_progress("completeLevel") >= _progress_max("completeLevel"):
		complete("completeLevel")


func on_chain_merged(chain_len: int) -> void:
	if chain_len >= 5:
		_add_progress("chain5", 1)
		if _get_progress("chain5") >= _progress_max("chain5"):
			complete("chain5")


func on_bonus_used() -> void:
	_add_progress("useBonus", 1)
	if _get_progress("useBonus") >= _progress_max("useBonus"):
		complete("useBonus")


func on_wheel_spun() -> void:
	_add_progress("spinWheel", 1)
	if _get_progress("spinWheel") >= _progress_max("spinWheel"):
		complete("spinWheel")


func on_session_xp_changed() -> void:
	var cur := state.progress.get_session_xp_today()
	_set_progress("xp100", mini(cur, 100))
	if cur >= 100:
		complete("xp100")


func get_progress(id: String) -> Dictionary:
	ensure_loaded()
	var max_val := _progress_max(id)
	if is_done(id):
		return {"current": max_val, "max": max_val}
	return {"current": mini(_get_progress(id), max_val), "max": max_val}


func get_reward_label(id: String) -> String:
	for quest in QUEST_DEFS:
		if str(quest.get("id", "")) != id:
			continue
		var reward: Dictionary = quest.get("reward", {})
		match reward.get("type", ""):
			"xp":
				return "+%d XP" % int(reward.get("amount", 0))
			"bonus":
				return "+%d" % int(reward.get("amount", 1))
		break
	return ""


func _ensure_progress_dict() -> void:
	if typeof(state.daily_quests.get("progress")) != TYPE_DICTIONARY:
		state.daily_quests["progress"] = {}


func _progress_max(id: String) -> int:
	match id:
		"xp100":
			return 100
		_:
			return 1


func _get_progress(id: String) -> int:
	_ensure_progress_dict()
	var progress: Dictionary = state.daily_quests.get("progress", {})
	return maxi(0, int(progress.get(id, 0)))


func _set_progress(id: String, value: int) -> void:
	_ensure_progress_dict()
	var progress: Dictionary = state.daily_quests.get("progress", {})
	progress[id] = maxi(0, value)
	state.daily_quests["progress"] = progress


func _add_progress(id: String, delta: int) -> void:
	if delta <= 0:
		return
	_set_progress(id, _get_progress(id) + delta)


func _give_reward(id: String) -> void:
	for quest in QUEST_DEFS:
		if quest.id != id:
			continue
		var reward: Dictionary = quest.reward
		match reward.get("type", ""):
			"xp":
				state.xp += int(reward.get("amount", 0))
			"bonus":
				state.grant_bonus(str(reward.get("bonus", "")), int(reward.get("amount", 1)))
		return


func _today_key() -> String:
	return Time.get_date_string_from_system(true)
