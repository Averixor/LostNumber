extends RefCounted
class_name WheelManager

## Wheel logic from js/game/mechanics/wheel.js (cost, daily limit, sectors).

const BASE_COST := 25
const STEP_COST := 10
const FREE_SPINS := 5
const MAX_DAILY_SPINS := 20
const SPIN_DURATION_SEC := 3.1

const SECTORS := [
	{"id": 0, "type": "xp_plus", "label": "XP+", "effect": "xp", "value": 15, "message_key": "wheel_xp_plus"},
	{"id": 1, "type": "xp_minus", "label": "XP−", "effect": "xp", "value": -10, "message_key": "wheel_xp_minus"},
	{"id": 2, "type": "shuffle", "label": "SHUF", "effect": "bonus", "value": "shuffle", "message_key": "wheel_bonus_shuffle_added"},
	{"id": 3, "type": "destroy", "label": "BRK", "effect": "bonus", "value": "destroy", "message_key": "wheel_bonus_destroy_added"},
	{"id": 4, "type": "explosion", "label": "BLST", "effect": "bonus", "value": "explosion", "message_key": "wheel_bonus_explosion_added"},
	{"id": 5, "type": "xp_multiplier", "label": "×2 XP", "effect": "multiplier", "value": 5, "message_key": "wheel_xp_multiplier", "multiplier": 2, "turns": 3},
	{"id": 6, "type": "gift", "label": "GIFT", "effect": "gift", "value": null, "message_key": "wheel_gift"},
	{"id": 7, "type": "freeze", "label": "ICE", "effect": "freeze", "value": 5, "message_key": "wheel_freeze_message", "fallback_xp": 50},
]

var state: GameState
var is_spinning: bool = false


func _init(game_state: GameState) -> void:
	state = game_state


func check_daily_reset() -> void:
	var today := _today_key()
	if state.last_wheel_day != today:
		state.last_wheel_day = today
		state.wheel_spins_today = 0


func get_cost() -> int:
	check_daily_reset()
	if state.wheel_spins_today < FREE_SPINS:
		return BASE_COST
	return BASE_COST + (state.wheel_spins_today - FREE_SPINS) * STEP_COST


func can_spin() -> Dictionary:
	check_daily_reset()
	if is_spinning:
		return {"ok": false, "reason": "spinning"}
	if state.wheel_spins_today >= MAX_DAILY_SPINS:
		return {"ok": false, "reason": "limit"}
	var cost := get_cost()
	if state.xp < cost:
		return {"ok": false, "reason": "not_enough_xp", "cost": cost}
	return {"ok": true, "cost": cost}


func prepare_spin() -> Dictionary:
	var check := can_spin()
	if not check.ok:
		return check

	var cost := int(check.cost)
	state.xp = maxi(0, state.xp - cost)
	state.wheel_spins_today += 1

	var idx := state.board.rng.randi_range(0, SECTORS.size() - 1)
	var sector: Dictionary = SECTORS[idx]
	is_spinning = true

	return {"ok": true, "sector": sector, "index": idx, "cost": cost}


func finish_spin(sector: Dictionary) -> void:
	_apply_sector(sector)
	state.progress.record_wheel_spin()
	is_spinning = false


func spin() -> Dictionary:
	var prep := prepare_spin()
	if not prep.ok:
		return prep
	var sector: Dictionary = prep.sector
	finish_spin(sector)
	return {"ok": true, "sector": sector, "index": prep.index}


func _apply_sector(sector: Dictionary) -> void:
	match str(sector.get("effect", "")):
		"xp":
			var delta := int(sector.get("value", 0))
			state.xp = maxi(0, state.xp + delta)
		"bonus":
			state.grant_bonus(str(sector.get("value", "")), 1)
		"multiplier":
			state.xp_multiplier = int(sector.get("multiplier", 2))
			state.xp_multiplier_turns = int(sector.get("turns", 3))
		"gift":
			state.grant_bonus("shuffle", 1)
			state.grant_bonus("destroy", 1)
		"freeze":
			# Freeze not implemented on board yet — grant fallback XP.
			state.xp += int(sector.get("fallback_xp", 50))


func _today_key() -> String:
	var dt := Time.get_datetime_dict_from_system()
	return "%04d-%02d-%02d" % [dt.year, dt.month, dt.day]
