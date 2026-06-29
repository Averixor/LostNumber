extends RefCounted
class_name LevelManager

## Level targets and spawn tables — parity with js/game/state.js (MVP subset)

const MANUAL_LEVEL_COUNT := 40
const INITIAL_TARGET := 64

var _manual_levels: Array[Dictionary] = []


func _init() -> void:
	_manual_levels = _generate_manual_levels(MANUAL_LEVEL_COUNT)


func get_level_config(level_index: int) -> Dictionary:
	var idx := maxi(0, level_index)
	if idx < _manual_levels.size():
		var level: Dictionary = _manual_levels[idx]
		return {
			"target": level.target,
			"numbers": level.numbers.duplicate(),
			"new_numbers": level.new_numbers.duplicate(),
		}

	var target := _procedural_target(idx)
	return {
		"target": target,
		"numbers": _build_level_numbers(idx, target),
		"new_numbers": _generate_new_numbers(target),
	}


func get_minimum_spawn_tile(level_index: int) -> int:
	var idx := maxi(0, level_index)
	var target: int = get_level_config(idx).target
	var human_level := idx + 1
	var raw: int

	if human_level <= 6:
		raw = 2
	elif human_level <= 11:
		raw = 4
	elif human_level <= 15:
		raw = 8
	else:
		var bracket := int(floor((human_level - 16) / 4.0))
		var exponent := mini(4 + bracket, 52)
		raw = int(pow(2, exponent))

	return _cap_minimum_tile_to_target(_floor_power_of_two(raw), target)


func _generate_manual_levels(count: int) -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	var target := INITIAL_TARGET
	var base_numbers: Array[int] = [2, 4, 8]

	for i in count:
		levels.append({
			"target": target,
			"numbers": base_numbers.duplicate(),
			"new_numbers": _generate_new_numbers(target),
		})
		target *= 2
		if i % 3 == 2 and base_numbers.size() < 7:
			base_numbers.append(base_numbers.back() * 2)

	return levels


func _procedural_target(level_index: int) -> int:
	if level_index < MANUAL_LEVEL_COUNT:
		return _manual_levels[level_index].target
	var doubled := 64 * int(pow(2, level_index))
	return mini(doubled, int(pow(2, 52)))


func _build_level_numbers(level_index: int, target: int) -> Array[int]:
	var base_numbers: Array[int] = [2, 4, 8]
	var n := 8
	var max_len := mini(7, int(floor(level_index / 3.0)) + 1)
	while base_numbers.size() < max_len:
		n *= 2
		if n > target:
			break
		base_numbers.append(n)
	return base_numbers


func _generate_new_numbers(target: int) -> Array[int]:
	var arr: Array[int] = []
	var num := int(target / 8)
	for _i in 8:
		if num <= target:
			arr.insert(0, num)
			num *= 2
	return arr


static func _floor_power_of_two(value: int) -> int:
	if value < 2:
		return 2
	var p := 1
	while p * 2 <= value:
		p *= 2
	return p


func _cap_minimum_tile_to_target(raw_min: int, target: int) -> int:
	var min_tile := _floor_power_of_two(raw_min)
	if target <= 4096:
		return min_tile
	var cap_tile := _floor_power_of_two(int(target / 4096))
	return maxi(2, mini(min_tile, cap_tile))
