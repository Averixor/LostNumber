extends RefCounted
class_name Rules

## Pure chain rules — parity with js/core/rules.js


static func is_power_of_two(value: int) -> bool:
	return value > 0 and (value & (value - 1)) == 0


static func is_adjacent(a: Vector2i, b: Vector2i) -> bool:
	if a == b:
		return false
	return absi(a.x - b.x) <= 1 and absi(a.y - b.y) <= 1


static func is_valid_next_number(next_value: int, prev_value: int, chain_sum: int) -> bool:
	if next_value == prev_value:
		return true
	if next_value == prev_value * 2:
		return true
	if is_power_of_two(chain_sum) and next_value == chain_sum and chain_sum >= prev_value:
		return true
	return false


static func can_finish_chain(numbers: PackedInt32Array) -> bool:
	if numbers.size() < 2:
		return false
	var total := 0
	for n in numbers:
		total += n
	return is_power_of_two(total) and total > numbers[0]


static func chain_sum(numbers: PackedInt32Array) -> int:
	var total := 0
	for n in numbers:
		total += n
	return total


static func base_xp_by_len(length: int) -> int:
	if length <= 1:
		return 0
	if length == 2:
		return 4
	if length == 3:
		return 8
	if length == 4:
		return 12
	if length == 5:
		return 18
	return 25


static func validate_chain(path: Array[Vector2i], grid: Array, grid_w: int, grid_h: int) -> Dictionary:
	if path.size() < 2:
		return {"valid": false, "reason": "chain_too_short"}

	var numbers := PackedInt32Array()
	for cell in path:
		if cell.x < 0 or cell.x >= grid_w or cell.y < 0 or cell.y >= grid_h:
			return {"valid": false, "reason": "out_of_bounds"}
		var value: int = grid[cell.x][cell.y]
		if value <= 0:
			return {"valid": false, "reason": "empty_cell"}
		numbers.append(value)

	for i in range(1, path.size()):
		if not is_adjacent(path[i - 1], path[i]):
			return {"valid": false, "reason": "not_adjacent"}
		var partial_sum := 0
		for j in range(i):
			partial_sum += numbers[j]
		if not is_valid_next_number(numbers[i], numbers[i - 1], partial_sum):
			return {"valid": false, "reason": "invalid_number"}

	if not can_finish_chain(numbers):
		return {"valid": false, "reason": "invalid_sum"}

	return {"valid": true, "numbers": numbers, "sum": chain_sum(numbers)}
