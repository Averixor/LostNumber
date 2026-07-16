extends SceneTree

const BoardView := preload("res://scripts/game/Board.gd")
const GameState := preload("res://scripts/core/GameState.gd")
const Rules := preload("res://scripts/core/Rules.gd")

var failed := 0


func _init() -> void:
	print("Lost Number Board chain tests...")
	var board: BoardView = BoardView.new()
	board.cell_size = Vector2(72, 72)
	board.cell_gap = 6.0
	root.add_child(board)
	board.call("_build_grid")
	board.set_size(board.custom_minimum_size)

	var state := GameState.new()
	state.start_new_game(42)
	board.bind_state(state)

	_test_grid_line_diagonal(board)
	_test_collect_diagonal_span(board, state)
	_test_collect_mixed_diagonal(board, state)

	if failed > 0:
		push_error("Board chain tests failed: %s" % failed)
		quit(1)
	else:
		print("Board chain tests passed")
		quit(0)


func _test_grid_line_diagonal(board: BoardView) -> void:
	var line: Array[Vector2i] = board.call("_cells_on_grid_line", Vector2i(0, 0), Vector2i(2, 2))
	_assert_eq(line.size(), 3, "diagonal grid line length")
	_assert_true(Rules.is_adjacent(line[0], line[1]), "diagonal grid line step 1")
	_assert_true(Rules.is_adjacent(line[1], line[2]), "diagonal grid line step 2")


func _test_collect_diagonal_span(board: BoardView, state: GameState) -> void:
	state.begin_chain(Vector2i(0, 0))
	board.set("_last_pointer_local", board.call("_cell_center", Vector2i(0, 0)))
	var end_center: Vector2 = board.call("_cell_center", Vector2i(2, 2))
	var cells: Array[Vector2i] = board.call("_collect_cells_along_pointer_path", end_center)
	_assert_eq(cells.size(), 2, "diagonal span collects two new cells")
	_assert_eq(cells[0], Vector2i(1, 1), "diagonal span first step")
	_assert_eq(cells[1], Vector2i(2, 2), "diagonal span second step")


func _test_collect_mixed_diagonal(board: BoardView, state: GameState) -> void:
	state.clear_chain()
	state.begin_chain(Vector2i(1, 1))
	board.set("_last_pointer_local", board.call("_cell_center", Vector2i(1, 1)))
	var end_center: Vector2 = board.call("_cell_center", Vector2i(0, 3))
	var cells: Array[Vector2i] = board.call("_collect_cells_along_pointer_path", end_center)
	_assert_true(cells.size() >= 2, "mixed diagonal span collects multiple cells")
	_assert_eq(cells.back(), Vector2i(0, 3), "mixed diagonal last step")
	var cursor := Vector2i(1, 1)
	for cell in cells:
		_assert_true(Rules.is_adjacent(cursor, cell), "mixed diagonal keeps 8-neighbor path")
		cursor = cell


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(actual: Variant, expected: Variant, message: String) -> void:
	if actual != expected:
		failed += 1
		push_error("FAIL: %s (got %s expected %s)" % [message, actual, expected])
	else:
		print("OK: " + message)
