extends RefCounted
class_name DailyQuestManager

## Daily quests ported from js/game/meta/daily.js

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
		return
	state.daily_quests = {
		"date": today,
		"completed": {},
		"list": QUEST_DEFS.duplicate(true),
	}


func complete(id: String) -> bool:
	ensure_loaded()
	var completed: Dictionary = state.daily_quests.get("completed", {})
	if bool(completed.get(id, false)):
		return false
	completed[id] = true
	state.daily_quests["completed"] = completed
	_give_reward(id)
	return true


func is_done(id: String) -> bool:
	ensure_loaded()
	return bool(state.daily_quests.get("completed", {}).get(id, false))


func get_quests() -> Array:
	ensure_loaded()
	return state.daily_quests.get("list", [])


func on_level_complete() -> void:
	complete("completeLevel")


func on_chain_merged(chain_len: int) -> void:
	if chain_len >= 5:
		complete("chain5")


func on_bonus_used() -> void:
	complete("useBonus")


func on_wheel_spun() -> void:
	complete("spinWheel")


func on_session_xp_changed() -> void:
	if state.progress.get_session_xp_today() >= 100:
		complete("xp100")


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
