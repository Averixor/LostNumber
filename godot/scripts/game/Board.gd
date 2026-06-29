extends Control
class_name BoardView

signal chain_finished(path: Array[Vector2i])
signal chain_cancelled()

const GRID_W := 5
const GRID_H := 8

@export var cell_size: Vector2 = Vector2(72, 72)
@export var cell_gap: float = 6.0

var state: GameState
var _tiles: Array = []
var _dragging: bool = false


func _ready() -> void:
	_build_grid()


func bind_state(game_state: GameState) -> void:
	state = game_state
	refresh_all()


func _build_grid() -> void:
	_tiles.clear()
	for child in get_children():
		child.queue_free()

	var total_w := GRID_W * cell_size.x + (GRID_W - 1) * cell_gap
	var total_h := GRID_H * cell_size.y + (GRID_H - 1) * cell_gap
	custom_minimum_size = Vector2(total_w, total_h)

	for x in GRID_W:
		var col: Array = []
		for y in GRID_H:
			var tile := TileView.new()
			tile.cell_size = cell_size
			tile.setup(Vector2i(x, y), 0)
			tile.position = Vector2(
				x * (cell_size.x + cell_gap),
				y * (cell_size.y + cell_gap)
			)
			tile.pressed.connect(_on_tile_pressed)
			add_child(tile)
			col.append(tile)
		_tiles.append(col)


func refresh_all() -> void:
	if state == null:
		return
	var target := state.get_target()
	for x in GRID_W:
		for y in GRID_H:
			var v: int = state.board.grid[x][y]
			_tiles[x][y].set_value(v)
			_tiles[x][y].set_target_highlight(v == target)
			_tiles[x][y].set_chain_selected(false)


func _on_tile_pressed(cell: Vector2i) -> void:
	if state == null or state.phase != GameState.Phase.PLAYING:
		return
	_dragging = true
	state.begin_chain(cell)
	_update_chain_visual()


func _input(event: InputEvent) -> void:
	if not _dragging or state == null:
		return

	if event is InputEventMouseMotion:
		var cell := _cell_at_screen(event.position)
		if cell.x >= 0:
			state.extend_chain(cell)
			_update_chain_visual()

	if event is InputEventMouseButton and not event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_finish_drag()

	if event is InputEventScreenDrag:
		var cell := _cell_at_screen(event.position)
		if cell.x >= 0:
			state.extend_chain(cell)
			_update_chain_visual()

	if event is InputEventScreenTouch and not event.pressed:
		_finish_drag()


func _finish_drag() -> void:
	_dragging = false
	if state == null:
		return

	if state.can_finish_current_chain():
		chain_finished.emit(state.selected_path.duplicate())
	else:
		state.clear_chain()
		chain_cancelled.emit()
	_update_chain_visual()


func _cell_at_screen(screen_pos: Vector2) -> Vector2i:
	var local := get_global_transform().affine_inverse() * screen_pos
	var step := cell_size + Vector2(cell_gap, cell_gap)
	var x := int(floor(local.x / step.x))
	var y := int(floor(local.y / step.y))
	if x < 0 or x >= GRID_W or y < 0 or y >= GRID_H:
		return Vector2i(-1, -1)
	var in_cell := local - Vector2(x, y) * step
	if in_cell.x > cell_size.x or in_cell.y > cell_size.y:
		return Vector2i(-1, -1)
	return Vector2i(x, y)


func _update_chain_visual() -> void:
	var can_finish := state.can_finish_current_chain()
	for x in GRID_W:
		for y in GRID_H:
			var selected := false
			for p in state.selected_path:
				if p == Vector2i(x, y):
					selected = true
					break
			_tiles[x][y].set_chain_selected(selected, can_finish)
