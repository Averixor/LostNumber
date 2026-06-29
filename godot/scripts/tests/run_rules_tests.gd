extends SceneTree

const Rules := preload("res://scripts/core/Rules.gd")

var failed := 0


func _init() -> void:
	print("Lost Number Rules tests...")

	_assert_true(Rules.is_power_of_two(1), "1 is power of two")
	_assert_true(Rules.is_power_of_two(2), "2 is power of two")
	_assert_true(Rules.is_power_of_two(64), "64 is power of two")
	_assert_false(Rules.is_power_of_two(0), "0 is not power of two")
	_assert_false(Rules.is_power_of_two(3), "3 is not power of two")
	_assert_false(Rules.is_power_of_two(12), "12 is not power of two")

	_assert_true(Rules.is_valid_next_number(2, 2, 2), "same value can be added")
	_assert_true(Rules.is_valid_next_number(4, 2, 2), "double value can be added")
	_assert_true(Rules.is_valid_next_number(4, 4, 4), "current power-of-two sum can be added")

	_assert_false(Rules.is_valid_next_number(6, 4, 6), "non-power sum cannot be used as rule 3")
	_assert_false(Rules.is_valid_next_number(8, 2, 2), "unrelated value cannot be added")

	_assert_true(Rules.can_finish_chain(PackedInt32Array([2, 2])), "2+2=4 can finish")
	_assert_true(Rules.can_finish_chain(PackedInt32Array([4, 4])), "4+4=8 can finish (sum > first)")
	_assert_false(Rules.can_finish_chain(PackedInt32Array([8])), "single tile cannot finish")
	_assert_false(Rules.can_finish_chain(PackedInt32Array([2, 4])), "2+4=6 cannot finish (not power of two)")

	_assert_true(Rules.is_adjacent(Vector2i(0, 0), Vector2i(1, 1)), "diagonal is adjacent")
	_assert_false(Rules.is_adjacent(Vector2i(0, 0), Vector2i(0, 0)), "same cell is not adjacent")
	_assert_false(Rules.is_adjacent(Vector2i(0, 0), Vector2i(2, 0)), "two steps away is not adjacent")

	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	var grid := [
		[2, 2, 0, 0, 0, 0, 0, 0],
		[2, 4, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
	]
	var chain_result := Rules.validate_chain(path, grid, 5, 8)
	_assert_true(chain_result.valid, "valid chain 2+2+4=8 on grid")

	if failed > 0:
		push_error("Rules tests failed: %s" % failed)
		quit(1)
	else:
		print("Rules tests passed")
		quit(0)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)
