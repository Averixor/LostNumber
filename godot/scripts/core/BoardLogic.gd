extends RefCounted
class_name BoardLogic

## Grid operations — no UI. MVP: no freeze, no pressure transfer.

const EMPTY := 0

var grid_w: int = 5
var grid_h: int = 8
var grid: Array = []
var level_manager: LevelManager
var rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _init(width: int = 5, height: int = 8) -> void:
	grid_w = width
	grid_h = height
	level_manager = LevelManager.new()
	grid = _create_empty_grid()


func _create_empty_grid() -> Array:
	var g: Array = []
	for x in grid_w:
		var col: Array = []
		col.resize(grid_h)
		col.fill(EMPTY)
		g.append(col)
	return g


func fill_random(level_index: int, carry_number: int = 0) -> void:
	var level: Dictionary = level_manager.get_level_config(level_index)
	var spawn_pool: Array = level["numbers"]

	for x in grid_w:
		for y in grid_h:
			var n: int = _pick_spawn_value(level_index, carry_number, level["target"], spawn_pool, 8)
			grid[x][y] = n


func _pick_spawn_value(level_index: int, carry_number: int, level_target: int, _pool: Array, max_reached: int = 8) -> int:
	var allowed := _get_allowed_numbers(level_index, max_reached)
	var min_spawn: int = level_manager.get_minimum_spawn_tile(level_index)
	var filtered: Array[Dictionary] = []

	for i in allowed.size():
		var value: int = allowed[i]
		if value >= min_spawn and value != carry_number and value != level_target:
			filtered.append({"value": value, "weight": 1.0 / pow(2.0, i)})

	if filtered.is_empty():
		return min_spawn

	var total_weight := 0.0
	for item in filtered:
		total_weight += item.weight

	var roll := rng.randf() * total_weight
	for item in filtered:
		roll -= item.weight
		if roll <= 0.0:
			return item.value
	return filtered.back().value


func _get_allowed_numbers(level_index: int, max_reached: int = 8) -> Array[int]:
	const WINDOW := 9
	var min_spawn: int = level_manager.get_minimum_spawn_tile(level_index)
	var max_val := maxi(max_reached, min_spawn)
	var arr: Array[int] = []
	var current := _floor_power_of_two(min_spawn)
	while arr.size() < WINDOW and current <= max_val:
		arr.append(current)
		current *= 2
	return arr


static func _floor_power_of_two(value: int) -> int:
	if value < 2:
		return 2
	var p := 1
	while p * 2 <= value:
		p *= 2
	return p


func apply_merge(anchor: Vector2i, removed: Array[Vector2i], result_number: int) -> void:
	for cell in removed:
		grid[cell.x][cell.y] = EMPTY
	grid[anchor.x][anchor.y] = result_number


func apply_gravity() -> void:
	for x in grid_w:
		var nums: Array[int] = []
		for y in grid_h:
			var v: int = grid[x][y]
			if v != EMPTY:
				nums.append(v)

		for y in grid_h:
			grid[x][y] = EMPTY

		var write_y := grid_h - 1
		for i in range(nums.size() - 1, -1, -1):
			grid[x][write_y] = nums[i]
			write_y -= 1

		while write_y >= 0:
			grid[x][write_y] = EMPTY
			write_y -= 1


func spawn_new_cells(level_index: int = 0, carry_number: int = 0, max_reached: int = 8) -> void:
	var level: Dictionary = level_manager.get_level_config(level_index)
	for x in grid_w:
		for y in grid_h:
			if grid[x][y] == EMPTY:
				grid[x][y] = _pick_spawn_value(level_index, carry_number, level["target"], level["numbers"], max_reached)


func has_value_on_board(value: int) -> bool:
	for x in grid_w:
		for y in grid_h:
			if grid[x][y] == value:
				return true
	return false


func place_carry_unique(carry_number: int, level_index: int, max_reached: int = 8) -> void:
	if carry_number <= 0:
		return

	var found := false
	for x in grid_w:
		for y in grid_h:
			if grid[x][y] == carry_number:
				found = true
				break

	if found:
		for x in grid_w:
			for y in grid_h:
				if grid[x][y] == carry_number:
					var level: Dictionary = level_manager.get_level_config(level_index)
					grid[x][y] = _pick_spawn_value(level_index, carry_number, level["target"], level["numbers"], max_reached)
		return

	var rx := rng.randi_range(0, grid_w - 1)
	var ry := rng.randi_range(0, grid_h - 1)
	grid[rx][ry] = carry_number


func grid_to_arrays() -> Array:
	var copy: Array = []
	for x in grid_w:
		var col: Array = []
		for y in grid_h:
			col.append(grid[x][y])
		copy.append(col)
	return copy


func load_from_arrays(data: Array) -> void:
	grid = _create_empty_grid()
	for x in mini(data.size(), grid_w):
		for y in mini(data[x].size(), grid_h):
			grid[x][y] = int(data[x][y])


func shuffle_grid() -> void:
	var values: Array[int] = []
	for x in grid_w:
		for y in grid_h:
			var v: int = grid[x][y]
			values.append(v if v != EMPTY else 2)

	for i in range(values.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var tmp := values[i]
		values[i] = values[j]
		values[j] = tmp

	var k := 0
	for x in grid_w:
		for y in grid_h:
			grid[x][y] = values[k]
			k += 1


func remove_cells(cells: Array[Vector2i]) -> void:
	for cell in cells:
		if cell.x >= 0 and cell.x < grid_w and cell.y >= 0 and cell.y < grid_h:
			grid[cell.x][cell.y] = EMPTY
	apply_gravity()
