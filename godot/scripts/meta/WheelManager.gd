extends RefCounted
class_name WheelManager

## Simplified wheel from js/game/mechanics/wheel.js (logic only, no canvas animation).

const SECTORS := [
	{"id": 0, "effect": "xp", "value": 15, "label": "XP+15"},
	{"id": 1, "effect": "xp", "value": -10, "label": "XP-10"},
	{"id": 2, "effect": "bonus", "value": "shuffle", "label": "Shuffle"},
	{"id": 3, "effect": "bonus", "value": "destroy", "label": "Destroy"},
	{"id": 4, "effect": "bonus", "value": "explosion", "label": "Blast"},
	{"id": 5, "effect": "multiplier", "value": 2, "turns": 3, "label": "×2 XP"},
	{"id": 6, "effect": "gift", "value": null, "label": "Gift"},
	{"id": 7, "effect": "xp", "value": 5, "label": "XP+5"},
]

var state: GameState


func _init(game_state: GameState) -> void:
	state = game_state


func spin() -> Dictionary:
	var idx := state.board.rng.randi_range(0, SECTORS.size() - 1)
	var sector: Dictionary = SECTORS[idx]
	_apply_sector(sector)
	state.progress.record_wheel_spin()
	return {"ok": true, "sector": sector, "index": idx}


func _apply_sector(sector: Dictionary) -> void:
	match sector.get("effect", ""):
		"xp":
			var delta := int(sector.get("value", 0))
			state.xp = maxi(0, state.xp + delta)
		"bonus":
			state.grant_bonus(str(sector.get("value", "")), 1)
		"multiplier":
			state.xp_multiplier = int(sector.get("value", 2))
			state.xp_multiplier_turns = int(sector.get("turns", 3))
		"gift":
			state.grant_bonus("shuffle", 1)
			state.grant_bonus("destroy", 1)
