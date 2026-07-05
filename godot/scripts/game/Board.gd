extends Control
class_name BoardView

signal chain_finished(path: Array[Vector2i])
signal chain_cancelled()
signal cell_picked(cell: Vector2i)

const TILE_SCENE := preload("res://scenes/components/Tile.tscn")
const CHAIN_SCENE := preload("res://scenes/components/ChainLineLayer.tscn")

const GRID_W := 5
const GRID_H := 8

@export var cell_size: Vector2 = Vector2(72, 72)
@export var cell_gap: float = 6.0
@export var gap_tolerance: float = 14.0

var state: GameState
var _tiles: Array = []
var _chain_layer: ChainLineLayer
var _dragging: bool = false
var _last_pointer_local: Vector2 = Vector2.INF
var _highlighted_cells: Dictionary = {}
var _drag_flush_queued: bool = false
var _pending_drag_local: Vector2 = Vector2.ZERO
var bonus_pick_mode: bool = false


func _ready() -> void:
	_build_grid()
	mouse_filter = Control.MOUSE_FILTER_STOP


func bind_state(game_state: GameState) -> void:
	state = game_state
	refresh_all()


func _build_grid() -> void:
	_tiles.clear()

	for child in get_children():
		child.queue_free()

	custom_minimum_size = Vector2(
		GRID_W * cell_size.x + (GRID_W - 1) * cell_gap,
		GRID_H * cell_size.y + (GRID_H - 1) * cell_gap
	)

	for x in GRID_W:
		var col: Array = []

		for y in GRID_H:
			var tile: TileView = TILE_SCENE.instantiate()
			tile.cell_size = cell_size
			tile.position = Vector2(
				x * (cell_size.x + cell_gap),
				y * (cell_size.y + cell_gap)
			)

			add_child(tile)
			tile.setup(Vector2i(x, y), 0)
			col.append(tile)

		_tiles.append(col)

	_chain_layer = CHAIN_SCENE.instantiate()
	_chain_layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chain_layer.size = custom_minimum_size
	add_child(_chain_layer)


func refresh_all() -> void:
	if state == null:
		return

	var target := state.get_target()
	_clear_chain_highlights()

	for x in GRID_W:
		for y in GRID_H:
			var value: int = state.board.grid[x][y]
			var tile: TileView = _tiles[x][y]

			tile.set_value(value)
			tile.set_target_highlight(value == target)
			tile.set_chain_selected(false)
			tile.set_bonus_mode(bonus_pick_mode)
			tile.set_carry(state.carry_number > 0 and value == state.carry_number)

	_update_chain_visual()


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _play_connect_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "chain_connect")


func _gui_input(event: InputEvent) -> void:
	if not is_inside_tree():
		return
	if state == null or state.phase != GameState.Phase.PLAYING:
		return

	var local_pos: Vector2 = _pointer_local_from_gui_event(event)

	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag_at_local(local_pos)
		else:
			_finish_drag()
		accept_event()
		return

	if event is InputEventMouseMotion:
		if _dragging:
			_queue_drag(local_pos)
			accept_event()
		return

	if event is InputEventScreenTouch:
		if event.pressed:
			_start_drag_at_local(local_pos)
		else:
			_finish_drag()
		accept_event()
		return

	if event is InputEventScreenDrag:
		if _dragging:
			_queue_drag(local_pos)
			accept_event()
		return


func _queue_drag(local_pos: Vector2) -> void:
	_pending_drag_local = local_pos
	if _drag_flush_queued:
		return
	_drag_flush_queued = true
	call_deferred("_flush_pending_drag")


func _flush_pending_drag() -> void:
	_drag_flush_queued = false
	if not _dragging:
		return
	_extend_drag_at_local(_pending_drag_local)


func _start_drag_at_local(local_pos: Vector2) -> void:
	var cell := _cell_at_local(local_pos)

	if cell.x < 0:
		return

	if bonus_pick_mode:
		cell_picked.emit(cell)
		return

	_dragging = true
	_last_pointer_local = local_pos
	state.begin_chain(cell)
	_play_tile_select_sfx()
	_update_chain_visual()


func _play_tile_select_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "tile_select")


func _extend_drag_at_local(local_pos: Vector2) -> void:
	var cells := _collect_cells_along_pointer_path(local_pos)
	if cells.is_empty():
		return

	var path_changed := false
	for cell in cells:
		var path_len_before := state.selected_path.size()
		if not state.extend_chain(cell):
			continue
		path_changed = true
		if state.selected_path.size() > path_len_before:
			_play_connect_sfx()

	if path_changed:
		_update_chain_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and _dragging:
		_finish_drag(false)


func _collect_cells_along_pointer_path(local_pos: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var cell := _cell_at_local(local_pos)

	if cell.x < 0:
		_last_pointer_local = local_pos
		return cells

	if not _last_pointer_local.is_finite():
		_last_pointer_local = local_pos
		return [cell]

	var dx := local_pos.x - _last_pointer_local.x
	var dy := local_pos.y - _last_pointer_local.y
	var distance := sqrt(dx * dx + dy * dy)
	var min_side := minf(cell_size.x, cell_size.y)
	var step := maxf(min_side * 0.35, 10.0)

	if distance < step * 0.45:
		_last_pointer_local = local_pos
		return [cell]

	var count := maxi(1, int(ceil(distance / step)))
	for i in range(1, count + 1):
		var t := float(i) / float(count)
		var sample := Vector2(
			_last_pointer_local.x + dx * t,
			_last_pointer_local.y + dy * t
		)
		var sample_cell := _cell_at_local(sample)
		if sample_cell.x < 0:
			continue
		if cells.is_empty() or cells.back() != sample_cell:
			cells.append(sample_cell)

	_last_pointer_local = local_pos
	return cells


func _finish_drag(play_cancel_signal: bool = true) -> void:
	if not _dragging:
		return

	_dragging = false
	_drag_flush_queued = false
	_last_pointer_local = Vector2.INF

	if state == null:
		return

	if state.can_finish_current_chain():
		var finished_path := state.selected_path.duplicate()
		chain_finished.emit(finished_path)
	else:
		state.clear_chain()

		if play_cancel_signal:
			chain_cancelled.emit()

	_update_chain_visual()


func _pointer_local_from_gui_event(event: InputEvent) -> Vector2:
	return event.position


func _cell_at_local(local_pos: Vector2) -> Vector2i:
	var step := cell_size + Vector2(cell_gap, cell_gap)

	var x := int(floor(local_pos.x / step.x))
	var y := int(floor(local_pos.y / step.y))

	if x < 0 or x >= GRID_W:
		return Vector2i(-1, -1)

	if y < 0 or y >= GRID_H:
		return Vector2i(-1, -1)

	var cell_origin := Vector2(x, y) * step
	var in_cell := local_pos - cell_origin

	var inside := (
		in_cell.x >= -gap_tolerance
		and in_cell.y >= -gap_tolerance
		and in_cell.x <= cell_size.x + gap_tolerance
		and in_cell.y <= cell_size.y + gap_tolerance
	)

	if not inside:
		return Vector2i(-1, -1)

	return Vector2i(x, y)


func _clear_chain_highlights() -> void:
	for cell in _highlighted_cells:
		_tiles[cell.x][cell.y].set_chain_selected(false)
	_highlighted_cells.clear()
	if _chain_layer != null:
		_chain_layer.clear_chain()


func _cell_center(cell: Vector2i) -> Vector2:
	var step := cell_size + Vector2(cell_gap, cell_gap)
	return Vector2(cell) * step + cell_size * 0.5


func _update_chain_visual() -> void:
	if state == null:
		return

	var can_finish := state.can_finish_current_chain()
	var next: Dictionary = {}

	for p in state.selected_path:
		next[p] = true

	for cell in _highlighted_cells:
		if not next.has(cell):
			_tiles[cell.x][cell.y].set_chain_selected(false)

	for p in state.selected_path:
		_tiles[p.x][p.y].set_chain_selected(true, can_finish)

	_highlighted_cells = next

	if _chain_layer == null:
		return

	if state.selected_path.size() < 2:
		_chain_layer.clear_chain()
		return

	var pts := PackedVector2Array()
	for p in state.selected_path:
		pts.append(_cell_center(p))
	_chain_layer.set_chain_points(pts)
