extends SceneTree

const LevelManager := preload("res://scripts/core/LevelManager.gd")
const Rules := preload("res://scripts/core/Rules.gd")

const MAX_TARGET := 1 << 52

var failed := 0
var _manager: LevelManager


func _init() -> void:
	print("Lost Number LevelManager tests...")
	_manager = LevelManager.new()

	_test_last_manual_level()
	_test_first_procedural_level()
	_test_procedural_continues()
	_test_high_procedural_levels([49, 99, 199, 499])
	_test_high_procedural_levels([1000, 5000])

	if failed > 0:
		push_error("LevelManager tests failed: %s" % failed)
		quit(1)
	else:
		print("LevelManager tests passed")
		quit(0)


func _test_last_manual_level() -> void:
	var idx := 39
	var config := _manager.get_level_config(idx)
	_assert_valid_config(config, idx)
	var expected_target := LevelManager.INITIAL_TARGET << idx
	_assert_eq(config["target"], expected_target, "level 39 target is last manual (64 * 2^39)")
	_assert_true(
		config["numbers"].size() > 0 and config["new_numbers"].size() > 0,
		"level 39 config has numbers and new_numbers"
	)


func _test_first_procedural_level() -> void:
	var idx := 40
	var config := _manager.get_level_config(idx)
	_assert_valid_config(config, idx)
	var expected_target := 1 << mini(idx + 6, LevelManager.MAX_PROCEDURAL_TARGET_EXPONENT)
	_assert_eq(config["target"], expected_target, "level 40 uses procedural target 64 * 2^40")
	_assert_ne(config["target"], _manager.get_level_config(39)["target"], "level 40 is not last manual entry")


func _test_procedural_continues() -> void:
	var idx := 41
	var config := _manager.get_level_config(idx)
	_assert_valid_config(config, idx)
	var expected_target := 1 << mini(idx + 6, LevelManager.MAX_PROCEDURAL_TARGET_EXPONENT)
	_assert_eq(config["target"], expected_target, "level 41 procedural target doubles from 40")
	var prev := _manager.get_level_config(idx - 1)
	_assert_true(config["target"] > prev["target"], "level 41 target exceeds level 40")


func _test_high_procedural_levels(indices: Array) -> void:
	for idx in indices:
		var config := _manager.get_level_config(idx)
		_assert_valid_config(config, idx)
		_assert_true(config["target"] <= MAX_TARGET, "level %d target <= 2^52" % (idx + 1))
		_assert_true(config["target"] > 0, "level %d target is positive" % (idx + 1))


func _assert_valid_config(config: Dictionary, level_index: int) -> void:
	var target: int = config.get("target", -1)
	_assert_true(Rules.is_power_of_two(target), "level %d target is power of two (%d)" % [level_index + 1, target])
	var numbers: Array = config.get("numbers", [])
	var new_numbers: Array = config.get("new_numbers", [])
	_assert_true(numbers.size() > 0, "level %d has numbers" % (level_index + 1))
	_assert_true(new_numbers.size() > 0, "level %d has new_numbers" % (level_index + 1))


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(actual: int, expected: int, message: String) -> void:
	if actual != expected:
		failed += 1
		push_error("FAIL: %s (got %s expected %s)" % [message, actual, expected])
	else:
		print("OK: " + message)


func _assert_ne(actual: int, expected: int, message: String) -> void:
	if actual == expected:
		failed += 1
		push_error("FAIL: %s (got %s)" % [message, actual])
	else:
		print("OK: " + message)
