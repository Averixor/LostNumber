extends SceneTree

## BoardLogic spawn contract: LevelManager.numbers ∩ [min_spawn, max_reached].

const BoardLogicLib := preload("res://scripts/core/BoardLogic.gd")
const LevelManagerLib := preload("res://scripts/core/LevelManager.gd")

var failed := 0
var _board: BoardLogic
var _levels: LevelManager


func _init() -> void:
	print("Lost Number board spawn tests...")
	_board = BoardLogicLib.new()
	_levels = _board.level_manager
	_board.rng.seed = 42

	_test_level_spawn_window(0, 8)
	_test_level_spawn_window(5, 16)
	_test_level_spawn_window(15, 64)
	_test_level_spawn_window(39, 128)
	_test_level_spawn_window(40, 128)
	_test_empty_pool_falls_back_to_min_spawn()
	_test_fill_random_respects_high_max_reached()
	_test_fill_random_ignores_legacy_dynamic_window()

	if failed > 0:
		push_error("Board spawn tests failed: %s" % failed)
		quit(1)
	else:
		print("Board spawn tests passed")
		quit(0)


func _test_level_spawn_window(level_index: int, max_reached: int) -> void:
	var config := _levels.get_level_config(level_index)
	var numbers: Array = config["numbers"]
	var target: int = config["target"]
	var min_spawn: int = _levels.get_minimum_spawn_tile(level_index)
	var carry := 0

	for _i in 64:
		var value: int = _board.call(
			"_pick_spawn_value", level_index, carry, target, numbers, max_reached
		)
		var in_pool := false
		for n in numbers:
			if int(n) == value:
				in_pool = true
				break
		var empty_path := value == min_spawn and not _has_eligible(numbers, min_spawn, max_reached, carry, target)
		if empty_path:
			_assert_eq(value, min_spawn, "level %d empty filter → min_spawn" % level_index)
			continue
		_assert_true(in_pool, "level %d spawn %d is in numbers" % [level_index, value])
		_assert_true(value >= min_spawn, "level %d spawn %d >= min_spawn %d" % [level_index, value, min_spawn])
		_assert_true(value <= max_reached, "level %d spawn %d <= max_reached %d" % [level_index, value, max_reached])
		_assert_true(value != target, "level %d spawn ≠ target" % level_index)
	print("OK: level %d spawn window max_reached=%d" % [level_index, max_reached])


func _test_empty_pool_falls_back_to_min_spawn() -> void:
	## Late bracket with max_reached below min_spawn → filter empty → always min_spawn.
	var level_index := 20
	var min_spawn: int = _levels.get_minimum_spawn_tile(level_index)
	_assert_true(min_spawn > 8, "level 20 min_spawn > 8 (got %d)" % min_spawn)
	var config := _levels.get_level_config(level_index)
	for _i in 32:
		var value: int = _board.call(
			"_pick_spawn_value",
			level_index,
			0,
			config["target"],
			config["numbers"],
			8
		)
		_assert_eq(value, min_spawn, "empty pool fallback is min_spawn")
	print("OK: empty pool falls back to min_spawn")


func _test_fill_random_respects_high_max_reached() -> void:
	var level_index := 15
	var config := _levels.get_level_config(level_index)
	var max_reached := 64
	_board.rng.seed = 7
	_board.fill_random(level_index, 0, max_reached)
	var saw_above_eight := false
	var min_spawn: int = _levels.get_minimum_spawn_tile(level_index)
	for x in _board.grid_w:
		for y in _board.grid_h:
			var value: int = _board.grid[x][y]
			_assert_true(value >= min_spawn, "fill value >= min_spawn")
			_assert_true(value <= max_reached, "fill value <= max_reached")
			_assert_true(value != int(config["target"]), "fill value ≠ target")
			var in_pool := false
			for n in config["numbers"]:
				if int(n) == value:
					in_pool = true
					break
			_assert_true(in_pool, "fill value in level numbers")
			if value > 8:
				saw_above_eight = true
	_assert_true(saw_above_eight, "fill_random with max_reached=64 can spawn tiles > 8")
	print("OK: fill_random respects high max_reached")


func _test_fill_random_ignores_legacy_dynamic_window() -> void:
	## With numbers=[2,4,8] and max_reached=8, never invent 16+ from old WINDOW helper.
	var level_index := 0
	_board.rng.seed = 11
	_board.fill_random(level_index, 0, 8)
	for x in _board.grid_w:
		for y in _board.grid_h:
			var value: int = _board.grid[x][y]
			_assert_true(value <= 8, "level 0 fill never exceeds numbers/max_reached (got %d)" % value)
	print("OK: fill_random does not use legacy dynamic WINDOW")


func _has_eligible(numbers: Array, min_spawn: int, max_reached: int, carry: int, target: int) -> bool:
	for n in numbers:
		var value := int(n)
		if value >= min_spawn and value <= max_reached and value != carry and value != target:
			return true
	return false


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		# Keep stdout quieter than LevelManager suite for per-roll asserts.
		pass


func _assert_eq(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failed += 1
		push_error("FAIL: %s (got %s expected %s)" % [message, actual, expected])
