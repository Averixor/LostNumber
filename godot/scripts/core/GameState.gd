extends RefCounted
class_name GameState

## Session state — logic only, no nodes.
## Pulled forward from the JS prototype: core rules, level flow, compact numbers,
## stats/achievements, deterministic seed hooks, and Android-safe chain behavior.

enum Phase { MENU, PLAYING, ANIMATING, WIN, TRANSITIONING }

var board: BoardLogic
var progress: PlayerProgress = PlayerProgress.new()
var current_level: int = 0
var xp: int = 0
var carry_number: int = 0
var max_reached_number: int = 8
var phase: Phase = Phase.MENU

var pending_transition: Dictionary = {}
var selected_path: Array[Vector2i] = []

var xp_multiplier: int = 1
var xp_multiplier_turns: int = 0
var bonus_inventory := {"destroy": 0, "shuffle": 0, "explosion": 0}
var active_bonus: String = ""
var daily_quests: Dictionary = {}
var wheel_spins_today: int = 0
var last_wheel_day: String = ""


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
	bonus_inventory = {"destroy": 0, "shuffle": 0, "explosion": 0}
	active_bonus = ""
	daily_quests = {}
	progress.record_new_game()

	board.grid = board._create_empty_grid()
	board.fill_random(current_level, carry_number)


func begin_chain(cell: Vector2i) -> void:
	if not _is_valid_cell(cell):
		return
	selected_path = [cell]


func extend_chain(cell: Vector2i) -> bool:
	if not _is_valid_cell(cell):
		return false

	if selected_path.is_empty():
		begin_chain(cell)
		return true

	if selected_path.back() == cell:
		return false

	if selected_path.size() >= 2:
		var prev2 := selected_path[selected_path.size() - 2]
		if prev2 == cell:
			selected_path.pop_back()
			return true

	for existing in selected_path:
		if existing == cell:
			return false

	var last: Vector2i = selected_path.back()
	if not Rules.is_adjacent(last, cell):
		# Important Android fix: low FPS can skip pointer positions.
		# Do not reset the chain here; ignore the skipped cell and wait for a valid neighbour.
		return false

	var numbers := PackedInt32Array()
	for p in selected_path:
		numbers.append(board.grid[p.x][p.y])
	var next_val: int = board.grid[cell.x][cell.y]
	var partial: int = Rules.chain_sum(numbers)
	if not Rules.is_valid_next_number(next_val, numbers[numbers.size() - 1], partial):
		# Same policy: invalid next number is rejected, but the drag is not killed.
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
	var validation: Dictionary = Rules.validate_chain(selected_path, board.grid, board.grid_w, board.grid_h)
	if not validation.valid:
		return {"ok": false, "reason": validation.get("reason", "invalid")}

	var numbers: PackedInt32Array = validation.numbers
	var sum: int = validation.sum
	var level: Dictionary = board.level_manager.get_level_config(current_level)
	var target: int = level["target"]
	var is_level_complete := sum >= target
	var result_number := target if is_level_complete else sum
	var surplus := maxi(0, sum - target) if is_level_complete else 0

	max_reached_number = maxi(max_reached_number, result_number)

	var anchor: Vector2i = selected_path.back()
	var removed: Array[Vector2i] = []
	for i in selected_path.size() - 1:
		removed.append(selected_path[i])

	board.apply_merge(anchor, removed, result_number)
	board.apply_gravity()
	board.spawn_new_cells(current_level, carry_number, max_reached_number)

	var chain_len: int = selected_path.size()
	var xp_earned := _calculate_xp(chain_len)
	if xp_multiplier > 1 and xp_multiplier_turns > 0:
		xp_multiplier_turns -= 1
		if xp_multiplier_turns <= 0:
			xp_multiplier = 1
	xp += xp_earned + surplus
	progress.record_merge(chain_len, xp_earned + surplus, current_level)

	selected_path.clear()

	var won: bool = board.has_value_on_board(target)
	if won:
		progress.record_level_complete(current_level)
		_start_level_complete(target)

	return {
		"ok": true,
		"xp": xp_earned,
		"surplus": surplus,
		"level_complete": won,
		"result": result_number,
	}


func level_xp_mult() -> float:
	return 1.0 + (current_level + 1) * 0.06


func _calculate_xp(chain_len: int) -> int:
	var base: int = Rules.base_xp_by_len(chain_len)
	var xp_earned := maxi(0, int(round(float(base) * level_xp_mult())))
	if xp_multiplier > 1 and xp_multiplier_turns > 0:
		xp_earned = int(round(float(xp_earned) * float(xp_multiplier)))
	return xp_earned


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
	return board.level_manager.get_level_config(current_level)["target"]


func format_value(value: int) -> String:
	return NumberFormatter.format_number(value)


func get_bonus_count(type: String) -> int:
	return int(bonus_inventory.get(type, 0))


func grant_bonus(type: String, amount: int = 1) -> void:
	if not bonus_inventory.has(type):
		bonus_inventory[type] = 0
	bonus_inventory[type] = int(bonus_inventory.get(type, 0)) + amount


func consume_bonus(type: String, amount: int = 1) -> bool:
	var current := get_bonus_count(type)
	if current < amount:
		return false
	bonus_inventory[type] = current - amount
	return true


func to_save_dict() -> Dictionary:
	return {
		"version": 2,
		"current_level": current_level,
		"xp": xp,
		"carry_number": carry_number,
		"max_reached_number": max_reached_number,
		"grid": board.grid_to_arrays(),
		"pending_transition": pending_transition.duplicate(true),
		"xp_multiplier": xp_multiplier,
		"xp_multiplier_turns": xp_multiplier_turns,
		"bonus_inventory": bonus_inventory.duplicate(true),
		"active_bonus": active_bonus,
		"daily_quests": daily_quests.duplicate(true),
		"wheel_spins_today": wheel_spins_today,
		"last_wheel_day": last_wheel_day,
		"progress": progress.to_dict(),
	}


func load_from_save_dict(data: Dictionary) -> bool:
	if data.is_empty():
		return false

	current_level = int(data.get("current_level", 0))
	xp = int(data.get("xp", 0))
	carry_number = int(data.get("carry_number", 0))
	max_reached_number = int(data.get("max_reached_number", 8))
	pending_transition = data.get("pending_transition", {})
	xp_multiplier = int(data.get("xp_multiplier", 1))
	xp_multiplier_turns = int(data.get("xp_multiplier_turns", 0))
	bonus_inventory = data.get("bonus_inventory", {"destroy": 0, "shuffle": 0, "explosion": 0})
	active_bonus = str(data.get("active_bonus", ""))
	daily_quests = data.get("daily_quests", {})
	if typeof(daily_quests) != TYPE_DICTIONARY:
		daily_quests = {}
	wheel_spins_today = maxi(0, int(data.get("wheel_spins_today", 0)))
	last_wheel_day = str(data.get("last_wheel_day", ""))
	if data.has("progress") and typeof(data.progress) == TYPE_DICTIONARY:
		progress.load_from_dict(data.progress)
	else:
		progress.ensure_defaults()
	board.load_from_arrays(data.get("grid", []))
	selected_path.clear()
	_sanitize_loaded_state()
	_sanitize_win_phase()
	return true


func _sanitize_loaded_state() -> void:
	var defaults := {"destroy": 0, "shuffle": 0, "explosion": 0}
	for key in defaults.keys():
		bonus_inventory[key] = maxi(0, int(bonus_inventory.get(key, defaults[key])))

	# Transient UI state — never restore pick mode from save.
	if active_bonus != "":
		active_bonus = ""

	if xp_multiplier < 1:
		xp_multiplier = 1
	if xp_multiplier_turns < 0:
		xp_multiplier_turns = 0


func sanitize_win_phase() -> void:
	_sanitize_win_phase()


func _sanitize_win_phase() -> void:
	if pending_transition.get("active", false):
		phase = Phase.WIN
	else:
		pending_transition = {}
		phase = Phase.PLAYING


func should_show_level_complete() -> bool:
	return phase == Phase.WIN and pending_transition.get("active", false)


func _is_valid_cell(cell: Vector2i) -> bool:
	return cell.x >= 0 and cell.x < board.grid_w and cell.y >= 0 and cell.y < board.grid_h
