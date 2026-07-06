extends Control
class_name BoardView

signal chain_finished(path: Array[Vector2i])
signal chain_cancelled()
signal cell_picked(cell: Vector2i)
signal chain_updated(can_finish: bool)

const TILE_SCENE := preload("res://scenes/components/Tile.tscn")
const CHAIN_SCENE := preload("res://scenes/components/ChainLineLayer.tscn")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const GRID_W := 5
const GRID_H := 8

@export var cell_size: Vector2 = Vector2(72, 72)
@export var cell_gap: float = 6.0
@export var gap_tolerance: float = 20.0

var state: GameState
var _tiles: Array[Array] = []
var _chain_layer: ChainLineLayer
var _preview_bubble: PanelContainer
var _preview_vbox: VBoxContainer
var _preview_sum_label: Label
var _preview_status_label: Label
var _dragging: bool = false
var _last_pointer_local: Vector2 = Vector2.INF
var _highlighted_cells: Dictionary = {}
var _drag_flush_queued: bool = false
var _pending_drag_local: Vector2 = Vector2.ZERO
var bonus_pick_mode: bool = false


func _ready() -> void:
	_build_grid()
	_build_preview_bubble()
	mouse_filter = Control.MOUSE_FILTER_STOP
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_signal("tile_font_scale_changed"):
		settings.tile_font_scale_changed.connect(_on_tile_font_scale_changed)


func bind_state(game_state: GameState) -> void:
	state = game_state
	refresh_all()


func _build_grid() -> void:
	_tiles.clear()

	for child in get_children():
		if child != _preview_bubble:
			child.queue_free()

	custom_minimum_size = Vector2(
		GRID_W * cell_size.x + (GRID_W - 1) * cell_gap,
		GRID_H * cell_size.y + (GRID_H - 1) * cell_gap
	)

	for x in GRID_W:
		var col: Array[TileView] = []

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
	if _preview_bubble != null:
		move_child(_preview_bubble, get_child_count() - 1)


func is_chain_dragging() -> bool:
	return _dragging


func get_chain_pointer_local() -> Vector2:
	if _dragging and _pending_drag_local.is_finite():
		return _pending_drag_local
	return Vector2.INF


func get_cell_center_local(cell: Vector2i) -> Vector2:
	return _cell_center(cell)


func _build_preview_bubble() -> void:
	_preview_bubble = PanelContainer.new()
	_preview_bubble.name = "PreviewBubble"
	_preview_bubble.visible = false
	_preview_bubble.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_sync_preview_bubble_metrics()

	_preview_vbox = VBoxContainer.new()
	_preview_vbox.add_theme_constant_override("separation", 0)
	_preview_vbox.alignment = BoxContainer.ALIGNMENT_CENTER

	_preview_sum_label = Label.new()
	_preview_sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_sum_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_preview_status_label = Label.new()
	_preview_status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_preview_status_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	_preview_vbox.add_child(_preview_sum_label)
	_preview_vbox.add_child(_preview_status_label)
	_preview_bubble.add_child(_preview_vbox)
	add_child(_preview_bubble)
	_sync_preview_bubble_metrics()


func _sync_preview_bubble_metrics() -> void:
	if _preview_bubble == null:
		return
	var bubble_w := maxf(cell_size.x * 0.92, 58.0)
	var bubble_h := maxf(cell_size.y * 0.72, 42.0)
	_preview_bubble.custom_minimum_size = Vector2(bubble_w, bubble_h)
	if _preview_sum_label != null:
		var preview_text := _preview_sum_label.text if _preview_sum_label.text != "" else "0"
		_preview_sum_label.add_theme_font_size_override(
			"font_size",
			_tile_font_size_for_text(preview_text) + 2
		)
	if _preview_status_label != null:
		_preview_status_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)


func _tile_font_scale() -> float:
	var settings := _autoload("SettingsManager")
	if settings != null:
		return float(settings.get("tile_font_scale"))
	return 1.0


func _tile_font_size_for_text(text: String) -> int:
	var digits := maxi(1, text.length())
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("get_tile_font_size"):
		return int(settings.call("get_tile_font_size", cell_size, digits))
	return ThemeTokensLib.tile_font_size_for_cell(cell_size, digits, _tile_font_scale())


func _on_tile_font_scale_changed(_scale: float) -> void:
	_sync_preview_bubble_metrics()
	for x in GRID_W:
		for y in GRID_H:
			var tile: TileView = _tiles[x][y] as TileView
			if tile != null:
				tile.refresh_font_size()


func refresh_all() -> void:
	if state == null:
		return

	var board_max := _board_max_value()
	_clear_chain_highlights()

	for x in GRID_W:
		for y in GRID_H:
			var value: int = state.board.grid[x][y]
			var tile: TileView = _tiles[x][y] as TileView

			tile.set_value(value)
			tile.set_target_highlight(value > 0 and value == board_max)
			tile.set_chain_selected(false)
			tile.set_bonus_mode(bonus_pick_mode)
			tile.set_carry(state.carry_number > 0 and value == state.carry_number)

	_update_chain_visual()
	_hide_preview_bubble()


func reset_all_highlights() -> void:
	_clear_chain_highlights()
	bonus_pick_mode = false
	if state == null:
		return
	for x in GRID_W:
		for y in GRID_H:
			var tile: TileView = _tiles[x][y] as TileView
			tile.set_chain_selected(false)
			tile.set_bonus_mode(false)
			tile.set_pressed_visual(false)
	_hide_preview_bubble()
	if _chain_layer != null:
		_chain_layer.clear_chain()
	chain_updated.emit(false)


func update_preview_bubble(can_finish: bool, follow_local: Vector2 = Vector2.INF) -> void:
	if state == null or state.selected_path.is_empty():
		_hide_preview_bubble()
		return

	var numbers := PackedInt32Array()
	for p in state.selected_path:
		numbers.append(state.board.grid[p.x][p.y])
	var total: int = Rules.chain_sum(numbers)
	_preview_sum_label.text = state.format_value(total)
	_preview_sum_label.add_theme_font_size_override(
		"font_size",
		_tile_font_size_for_text(_preview_sum_label.text) + 2
	)

	var path_len := state.selected_path.size()
	var status_key := ""
	var status_color: Color
	var bg_color: Color
	var border_color: Color

	if path_len < 2:
		status_key = "chain_status_continue"
		status_color = Color(0.94, 0.94, 0.98, 1.0)
		bg_color = Color(0.06, 0.04, 0.1, 0.82)
		border_color = Color(_theme_chain_continue_color(), 0.85)
	elif can_finish:
		status_key = "chain_status_valid"
		status_color = Color.WHITE
		bg_color = Color(_theme_chain_valid_color(), 0.92)
		border_color = _theme_chain_valid_color()
	else:
		status_key = "chain_status_invalid"
		status_color = Color.WHITE
		bg_color = Color(_theme_chain_invalid_color(), 0.88)
		border_color = _theme_chain_invalid_color()

	_preview_status_label.text = _i18n(status_key)
	_preview_status_label.add_theme_color_override("font_color", status_color)
	_preview_sum_label.add_theme_color_override("font_color", status_color if path_len >= 2 else Color.WHITE)

	var style: StyleBoxFlat = StyleBoxFlat.new()
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_PILL)
	style.set_border_width_all(2)
	style.set_content_margin_all(6)
	style.bg_color = bg_color
	style.border_color = border_color
	style.shadow_color = Color(border_color, 0.35)
	style.shadow_size = 8
	_preview_bubble.add_theme_stylebox_override("panel", style)

	_position_preview_bubble(follow_local)
	_preview_bubble.visible = true


func _position_preview_bubble(follow_local: Vector2) -> void:
	if _preview_bubble == null or state == null or state.selected_path.is_empty():
		return

	var bubble_size := _preview_bubble.size
	if bubble_size.x < 1.0:
		bubble_size = _preview_bubble.custom_minimum_size

	var anchor: Vector2
	if follow_local.is_finite():
		anchor = follow_local
	else:
		anchor = _cell_center(state.selected_path.back())

	var pos := anchor - Vector2(bubble_size.x * 0.5, bubble_size.y + cell_size.y * 0.55)
	pos.x = clampf(pos.x, 0.0, maxf(0.0, size.x - bubble_size.x))
	pos.y = clampf(pos.y, 0.0, maxf(0.0, size.y - bubble_size.y))
	_preview_bubble.position = pos


func _theme_chain_valid_color() -> Color:
	var theme: Node = _autoload("ThemeManager")
	if theme != null and theme.has_method("get_chain_valid_color"):
		return theme.call("get_chain_valid_color")
	return ThemeTokensLib.COLOR_CHAIN_VALID


func _theme_chain_invalid_color() -> Color:
	var theme: Node = _autoload("ThemeManager")
	if theme != null and theme.has_method("get_chain_invalid_color"):
		return theme.call("get_chain_invalid_color")
	return ThemeTokensLib.COLOR_CHAIN_INVALID


func _theme_chain_continue_color() -> Color:
	var theme: Node = _autoload("ThemeManager")
	if theme != null and theme.has_method("get_chain_continue_color"):
		return theme.call("get_chain_continue_color")
	return ThemeTokensLib.COLOR_CHAIN_CONTINUE


func _i18n(key: String) -> String:
	var i18n: Node = _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _hide_preview_bubble() -> void:
	if _preview_bubble != null:
		_preview_bubble.visible = false


func _board_max_value() -> int:
	if state == null:
		return 0
	var max_val := 0
	for x in GRID_W:
		for y in GRID_H:
			max_val = maxi(max_val, int(state.board.grid[x][y]))
	return max_val


func animate_merge_settle(removed: Array, anchor: Vector2i) -> void:
	if state == null:
		return

	_clear_chain_highlights()
	_hide_preview_bubble()

	var removed_map: Dictionary = {}
	for cell in removed:
		if cell is Vector2i:
			if not removed_map.has(cell.x):
				removed_map[cell.x] = []
			(removed_map[cell.x] as Array).append(cell.y)

	var pop_tween := create_tween().set_parallel(true)
	for cell in removed:
		if cell is Vector2i:
			var tile: TileView = _tiles[cell.x][cell.y] as TileView
			tile.set_value(0)
			tile.modulate.a = 0.0
			pop_tween.tween_property(tile, "scale", Vector2(0.2, 0.2), 0.12)
	if anchor.x >= 0:
		var anchor_tile: TileView = _tiles[anchor.x][anchor.y] as TileView
		anchor_tile.set_value(state.board.grid[anchor.x][anchor.y])
		pop_tween.tween_property(anchor_tile, "scale", Vector2(1.12, 1.12), 0.1)
		pop_tween.tween_property(anchor_tile, "scale", Vector2.ONE, 0.12).set_delay(0.1)

	await pop_tween.finished

	var fall_tween := create_tween().set_parallel(true)
	var step_y := cell_size.y + cell_gap
	for x in GRID_W:
		if not removed_map.has(x):
			continue
		var removed_ys: Array = removed_map[x]
		removed_ys.sort()
		for y in GRID_H:
			if removed_ys.has(y):
				continue
			var holes_below := 0
			for ry in removed_ys:
				if int(ry) > y:
					holes_below += 1
			if holes_below <= 0:
				continue
			var tile: TileView = _tiles[x][y] as TileView
			var target_pos := tile.position + Vector2(0.0, float(holes_below) * step_y)
			fall_tween.tween_property(tile, "position", target_pos, 0.22) \
				.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await fall_tween.finished

	state.board.apply_gravity()
	state.board.spawn_new_cells(state.current_level, state.carry_number, state.max_reached_number)

	for x in GRID_W:
		for y in GRID_H:
			var tile: TileView = _tiles[x][y] as TileView
			var step := cell_size + Vector2(cell_gap, cell_gap)
			tile.position = Vector2(x * step.x, y * step.y)
			tile.scale = Vector2.ONE
			tile.modulate = Color.WHITE

	refresh_all()


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _play_connect_sfx() -> void:
	var audio: Node = _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "chain_connect")
	var settings: Node = _autoload("SettingsManager")
	if settings != null and bool(settings.get("sound_enabled")):
		Input.vibrate_handheld(20)


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
			_update_preview_position(local_pos)
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
			_update_preview_position(local_pos)
			accept_event()
		return


func _update_preview_position(local_pos: Vector2) -> void:
	if _preview_bubble == null or not _preview_bubble.visible or state == null:
		return
	var can_finish: bool = state.can_finish_current_chain()
	update_preview_bubble(can_finish, local_pos)


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
	var cell: Vector2i = _cell_at_local(local_pos)

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
	var audio: Node = _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "tile_select")


func _extend_drag_at_local(local_pos: Vector2) -> void:
	var cells: Array[Vector2i] = _collect_cells_along_pointer_path(local_pos)
	if cells.is_empty():
		return

	var path_changed: bool = false
	for cell in cells:
		var path_len_before: int = state.selected_path.size()
		if not state.extend_chain(cell):
			continue
		path_changed = true
		if state.selected_path.size() > path_len_before:
			_play_connect_sfx()

	if path_changed:
		_update_chain_visual()
		_last_pointer_local = local_pos


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_WINDOW_FOCUS_OUT and _dragging:
		_finish_drag(false)


func _collect_cells_along_pointer_path(local_pos: Vector2) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	var target: Vector2i = _pick_cell_for_chain(local_pos)

	if target.x < 0:
		return cells

	if not _last_pointer_local.is_finite():
		return [target]

	var dx: float = local_pos.x - _last_pointer_local.x
	var dy: float = local_pos.y - _last_pointer_local.y
	var distance: float = sqrt(dx * dx + dy * dy)
	var min_side: float = minf(cell_size.x, cell_size.y)
	var is_diagonal_move: bool = absf(dx) > 1.0 and absf(dy) > 1.0
	var step: float = maxf(min_side * (0.2 if is_diagonal_move else 0.35), 8.0)

	if distance >= step * 0.45:
		var count: int = maxi(1, int(ceil(distance / step)))
		for i in range(1, count + 1):
			var t: float = float(i) / float(count)
			var sample: Vector2 = _last_pointer_local.lerp(local_pos, t)
			var sample_cell: Vector2i = _pick_cell_for_chain(sample)
			if sample_cell.x < 0:
				continue
			if cells.is_empty() or cells.back() != sample_cell:
				cells.append(sample_cell)

	if state != null and not state.selected_path.is_empty():
		var anchor: Vector2i = state.selected_path.back()
		for line_cell in _cells_on_grid_line(anchor, target):
			if line_cell == anchor:
				continue
			if cells.is_empty() or cells.back() != line_cell:
				cells.append(line_cell)
	elif cells.is_empty() or cells.back() != target:
		cells.append(target)

	return cells


func _finish_drag(play_cancel_signal: bool = true) -> void:
	if not _dragging:
		return

	var release_outside: bool = (
		_pending_drag_local.is_finite()
		and _cell_at_local(_pending_drag_local).x < 0
	)

	_dragging = false
	_drag_flush_queued = false
	_last_pointer_local = Vector2.INF
	_hide_preview_bubble()

	if state == null:
		return

	if not release_outside and state.can_finish_current_chain():
		var finished_path: Array[Vector2i] = state.selected_path.duplicate()
		chain_finished.emit(finished_path)
	else:
		state.clear_chain()

		if play_cancel_signal:
			chain_cancelled.emit()

	_update_chain_visual()


func _pointer_local_from_gui_event(event: InputEvent) -> Vector2:
	return event.position


func _cell_at_local(local_pos: Vector2) -> Vector2i:
	var step: Vector2 = cell_size + Vector2(cell_gap, cell_gap)
	var min_side: float = minf(cell_size.x, cell_size.y)
	var tolerance: float = maxf(gap_tolerance, min_side * 0.28)

	if (
		local_pos.x < -tolerance
		or local_pos.y < -tolerance
		or local_pos.x > custom_minimum_size.x + tolerance
		or local_pos.y > custom_minimum_size.y + tolerance
	):
		return Vector2i(-1, -1)

	var gx: float = (local_pos.x - cell_size.x * 0.5) / step.x
	var gy: float = (local_pos.y - cell_size.y * 0.5) / step.y
	var base_x: int = int(floor(gx))
	var base_y: int = int(floor(gy))

	var best := Vector2i(-1, -1)
	var best_dist_sq := INF
	for ox in range(-1, 2):
		for oy in range(-1, 2):
			var cx := base_x + ox
			var cy := base_y + oy
			if cx < 0 or cx >= GRID_W or cy < 0 or cy >= GRID_H:
				continue
			var center := _cell_center(Vector2i(cx, cy))
			var dist_sq := local_pos.distance_squared_to(center)
			if dist_sq < best_dist_sq:
				best_dist_sq = dist_sq
				best = Vector2i(cx, cy)

	return best


func _pick_cell_for_chain(local_pos: Vector2) -> Vector2i:
	var nearest: Vector2i = _cell_at_local(local_pos)
	if nearest.x < 0:
		return nearest
	if state == null or state.selected_path.is_empty():
		return nearest

	var last: Vector2i = state.selected_path.back()
	if nearest == last or Rules.is_adjacent(last, nearest):
		return nearest

	var min_side: float = minf(cell_size.x, cell_size.y)
	var reach_sq: float = pow(min_side * 0.78 + cell_gap * 0.5, 2.0)
	var best_adj := Vector2i(-1, -1)
	var best_dist_sq := INF

	for dx in [-1, 0, 1]:
		for dy in [-1, 0, 1]:
			if dx == 0 and dy == 0:
				continue
			var candidate := Vector2i(last.x + dx, last.y + dy)
			if candidate.x < 0 or candidate.x >= GRID_W or candidate.y < 0 or candidate.y >= GRID_H:
				continue
			var center := _cell_center(candidate)
			var dist_sq := local_pos.distance_squared_to(center)
			if dist_sq > reach_sq or dist_sq >= best_dist_sq:
				continue
			best_dist_sq = dist_sq
			best_adj = candidate

	if best_adj.x >= 0:
		return best_adj
	return nearest


func _cells_on_grid_line(from_cell: Vector2i, to_cell: Vector2i) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if from_cell == to_cell:
		return [from_cell]

	var x0 := from_cell.x
	var y0 := from_cell.y
	var x1 := to_cell.x
	var y1 := to_cell.y
	var dx := absi(x1 - x0)
	var dy := absi(y1 - y0)
	var sx := 1 if x0 < x1 else -1
	var sy := 1 if y0 < y1 else -1
	var err := dx - dy

	while true:
		cells.append(Vector2i(x0, y0))
		if x0 == x1 and y0 == y1:
			break
		var e2 := err * 2
		if e2 > -dy:
			err -= dy
			x0 += sx
		if e2 < dx:
			err += dx
			y0 += sy

	return cells


func _clear_chain_highlights() -> void:
	for cell in _highlighted_cells:
		var tile: TileView = _tiles[cell.x][cell.y] as TileView
		tile.set_chain_selected(false)
		tile.set_pressed_visual(false)
	_highlighted_cells.clear()
	if _chain_layer != null:
		_chain_layer.clear_chain()


func _cell_center(cell: Vector2i) -> Vector2:
	var step: Vector2 = cell_size + Vector2(cell_gap, cell_gap)
	return Vector2(cell) * step + cell_size * 0.5


func _update_chain_visual() -> void:
	if state == null:
		return

	var can_finish: bool = state.can_finish_current_chain()
	var next: Dictionary = {}

	for p in state.selected_path:
		next[p] = true

	for cell in _highlighted_cells:
		if not next.has(cell):
			var tile: TileView = _tiles[cell.x][cell.y] as TileView
			tile.set_chain_selected(false)
			tile.set_pressed_visual(false)

	var path_len := state.selected_path.size()
	for p in state.selected_path:
		var tile: TileView = _tiles[p.x][p.y] as TileView
		var preview := ""
		if path_len >= 2:
			preview = "valid" if can_finish else "invalid"
		elif path_len == 1:
			preview = "continue"
		tile.set_chain_selected(true, preview)
		tile.set_pressed_visual(true)

	_highlighted_cells = next
	chain_updated.emit(can_finish)

	if state.selected_path.size() >= 1 and _dragging:
		update_preview_bubble(can_finish, _pending_drag_local if _pending_drag_local.is_finite() else Vector2.INF)

	if _chain_layer == null:
		return

	if state.selected_path.size() < 2:
		_chain_layer.clear_chain()
		return

	var pts := PackedVector2Array()
	for p in state.selected_path:
		pts.append(_cell_center(p))
	_chain_layer.set_chain_points(pts, can_finish)
