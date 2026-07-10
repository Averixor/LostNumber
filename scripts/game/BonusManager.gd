extends RefCounted
class_name BonusManager

## Bonus activation ported from js/game/mechanics/bonuses.js (MVP subset).

var state: GameState


func _init(game_state: GameState) -> void:
	state = game_state


func activate(type: String) -> Dictionary:
	if state.phase != GameState.Phase.PLAYING:
		return {"ok": false, "reason": "busy"}

	match type:
		"shuffle":
			return _activate_shuffle()
		"destroy", "explosion":
			return _toggle_pick_bonus(type)
		_:
			return {"ok": false, "reason": "unknown"}


func apply_at_cell(cell: Vector2i) -> Dictionary:
	if state.active_bonus.is_empty():
		return {"ok": false, "reason": "no_active"}

	match state.active_bonus:
		"destroy":
			return _apply_destroy(cell)
		"explosion":
			return _apply_explosion(cell)
		_:
			return {"ok": false, "reason": "unknown"}


func _activate_shuffle() -> Dictionary:
	if state.get_bonus_count("shuffle") <= 0:
		return {"ok": false, "reason": "empty"}
	if not state.consume_bonus("shuffle", 1):
		return {"ok": false, "reason": "empty"}

	state.clear_chain()
	state.board.shuffle_grid()
	state.progress.record_bonus_used()
	return {"ok": true, "message_key": "shuffle_done"}


func _toggle_pick_bonus(type: String) -> Dictionary:
	if state.get_bonus_count(type) <= 0:
		return {"ok": false, "reason": "empty"}
	if state.active_bonus == type:
		state.active_bonus = ""
		return {"ok": true, "message_key": ""}
	state.active_bonus = type
	return {"ok": true, "message_key": "choose_cell_bonus"}


func _apply_destroy(cell: Vector2i) -> Dictionary:
	if not state.consume_bonus("destroy", 1):
		state.active_bonus = ""
		return {"ok": false, "reason": "empty"}

	state.clear_chain()
	state.board.remove_cells([cell])
	state.board.spawn_new_cells(state.current_level, state.carry_number, state.max_reached_number)
	state.progress.record_bonus_used()
	state.active_bonus = ""
	return {"ok": true, "message_key": "destroy_done"}


func _apply_explosion(cell: Vector2i) -> Dictionary:
	if not state.consume_bonus("explosion", 1):
		state.active_bonus = ""
		return {"ok": false, "reason": "empty"}

	var removed: Array[Vector2i] = []
	for dx in range(-1, 2):
		for dy in range(-1, 2):
			var nx := cell.x + dx
			var ny := cell.y + dy
			if nx >= 0 and nx < state.board.grid_w and ny >= 0 and ny < state.board.grid_h:
				removed.append(Vector2i(nx, ny))

	state.clear_chain()
	state.board.remove_cells(removed)
	state.board.spawn_new_cells(state.current_level, state.carry_number, state.max_reached_number)
	state.progress.record_bonus_used()
	state.active_bonus = ""
	return {"ok": true, "message_key": "explosion_done"}
