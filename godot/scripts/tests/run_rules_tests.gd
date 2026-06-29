extends SceneTree

func _init() -> void:
	var args := OS.get_cmdline_args()
	if "--test-rules" in args:
		var exit_code := _run_rules_tests()
		quit(exit_code)


func _run_rules_tests() -> int:
	var failures := 0

	if not Rules.is_power_of_two(64):
		push_error("FAIL: 64 is power of two")
		failures += 1
	if Rules.is_power_of_two(65):
		push_error("FAIL: 65 is not power of two")
		failures += 1

	if not Rules.is_valid_next_number(4, 4, 4):
		push_error("FAIL: same number rule")
		failures += 1
	if not Rules.is_valid_next_number(8, 4, 4):
		push_error("FAIL: double rule")
		failures += 1
	if not Rules.is_valid_next_number(8, 4, 8):
		push_error("FAIL: sum power-of-two rule")
		failures += 1
	if Rules.is_valid_next_number(8, 4, 6):
		push_error("FAIL: sum must be power of two")
		failures += 1

	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(1, 1)]
	var grid := [
		[2, 2, 0, 0, 0, 0, 0, 0],
		[2, 4, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
		[0, 0, 0, 0, 0, 0, 0, 0],
	]
	var result := Rules.validate_chain(path, grid, 5, 8)
	if not result.valid:
		push_error("FAIL: valid chain 2+2+4=8")
		failures += 1

	if failures == 0:
		print("Rules tests: OK")
	return 1 if failures > 0 else 0
