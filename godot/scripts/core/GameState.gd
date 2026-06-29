extends RefCounted
class_name GameState

## Session state — logic only, no nodes.

enum Phase { MENU, PLAYING, ANIMATING, WIN, TRANSITIONING }

var board: BoardLogic
var current_level: int = 0
var xp: int = 0
var carry_number: int = 0
var max_reached_number: int = 8
var phase: Phase = Phase.MENU

var pending_transition: Dictionary = {}
var selected_path: Array[Vector2i] = []

var xp_multiplier: int = 1
var xp_multiplier_turns: int = 0


func _init() -> void:
	board = BoardLogic.new()


func start_new_game(seed_value: int = -1) -> void:
	if seed_value >= 0:
		board.rng.seed = seed_value
	else:
		board.rng.randomize()

	current_level = 0
	xp = 0
	carry_number = 0
	max_reached_number = 8
	pending_transition = {}
	selected_path.clear()
	phase = Phase.PLAYING

	board.grid = board._create_empty_grid()
	board.fill_random(current_level, carry_number)


func begin_chain(cell: Vector2i) -> void:
	selected_path = [cell]


func extend_chain(cell: Vector2i) -> bool:
	if selected_path.is_empty():
		begin_chain(cell)
		return true

	if selected_path.size() >= 2:
		var prev2 := selected_path[selected_path.size() - 2]
		if prev2 == cell:
			selected_path.pop_back()
			return true

	for existing in selected_path:
		if existing == cell:
			return false

	var last := selected_path.back()
	if not Rules.is_adjacent(last, cell):
		return false

	var numbers := PackedInt32Array()
	for p in selected_path:
		numbers.append(board.grid[p.x][p.y])
	var next_val: int = board.grid[cell.x][cell.y]
	var partial := Rules.chain_sum(numbers)
	if not Rules.is_valid_next_number(next_val, numbers[numbers.size() - 1], partial):
		return false

	selected_path.append(cell)
	return true


func clear_chain() -> void:
	selected_path.clear()


func can_finish_current_chain() -> bool:
	if selected_path.size() < 2:
		return false
	var numbers := PackedInt32Array()
	for p in selected_path:
		numbers.append(board.grid[p.x][p.y])
	return Rules.can_finish_chain(numbers)


func merge_current_chain() -> Dictionary:
	var validation := Rules.validate_chain(selected_path, board.grid, board.grid_w, board.grid_h)
	if not validation.valid:
		return {"ok": false, "reason": validation.get("reason", "invalid")}

	var numbers: PackedInt32Array = validation.numbers
	var sum: int = validation.sum
	var level := board.level_manager.get_level_config(current_level)
	var target: int = level.target
	var is_level_complete := sum >= target
	var result_number := target if is_level_complete else sum
	var surplus := maxi(0, sum - target) if is_level_complete else 0

	max_reached_number = maxi(max_reached_number, result_number)

	var anchor := selected_path.back()
	var removed: Array[Vector2i] = []
	for i in selected_path.size() - 1:
		removed.append(selected_path[i])

	board.apply_merge(anchor, removed, result_number)
	board.apply_gravity()
	board.spawn_new_cells(current_level, carry_number, max_reached_number)

	var chain_len := selected_path.size()
	var xp_earned := _calculate_xp(chain_len)
	xp += xp_earned + surplus

	selected_path.clear()

	var won := board.has_value_on_board(target)
	if won:
		_start_level_complete(target)

	return {
		"ok": true,
		"xp": xp_earned,
		"surplus": surplus,
		"level_complete": won,
		"result": result_number,
	}


func _calculate_xp(chain_len: int) -> int:
	var base := Rules.base_xp_by_len(chain_len)
	return base * xp_multiplier


func _start_level_complete(completed_target: int) -> void:
	phase = Phase.WIN
	carry_number = completed_target
	pending_transition = {
		"active": true,
		"next_level": current_level + 1,
		"carry_number": completed_target,
		"completed_level_index": current_level,
	}


func complete_level_transition() -> void:
	if pending_transition.is_empty() or not pending_transition.get("active", false):
		return

	current_level = int(pending_transition.next_level)
	carry_number = int(pending_transition.carry_number)
	pending_transition = {}
	phase = Phase.PLAYING

	board.grid = board._create_empty_grid()
	board.fill_random(current_level, carry_number)
	board.place_carry_unique(carry_number, current_level, max_reached_number)


func get_target() -> int:
	return board.level_manager.get_level_config(current_level).target


func to_save_dict() -> Dictionary:
	return {
		"version": 1,
		"current_level": current_level,
		"xp": xp,
		"carry_number": carry_number,
		"max_reached_number": max_reached_number,
		"grid": board.grid_to_arrays(),
		"pending_transition": pending_transition.duplicate(true),
	}


func load_from_save_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	current_level = int(data.get("current_level", 0))
	xp = int(data.get("xp", 0))
	carry_number = int(data.get("carry_number", 0))
	max_reached_number = int(data.get("max_reached_number", 8))
	pending_transition = data.get("pending_transition", {})
	board.load_from_arrays(data.get("grid", []))
	selected_path.clear()
	phase = Phase.PLAYING if pending_transition.is_empty() else Phase.WIN
	return true
