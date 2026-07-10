extends Node

## Capacitor/Web → Godot save migration (file-based + optional Android plugin).
## Startup order: Godot save → legacy migration file → Android plugin export → new game.

const GameStateScript := preload("res://scripts/core/GameState.gd")

const LEGACY_CAPACITOR_PATH := "user://legacy_capacitor_save.json"
const IMPORTED_SAVE_PATH := "user://imported_save.json"
const ARCHIVE_SUFFIX := ".imported"

const ANDROID_PLUGIN_NAME := "LostNumberMigration"
const ANDROID_EXPORT_FILENAME := "lostnumber_legacy_export.json"

## JS achievement keys (camelCase) → Godot progress keys (snake_case).
const ACHIEVEMENT_KEY_MAP := {
	"firstGame": "first_game",
	"level10": "level_10",
	"level25": "level_25",
	"xp1000": "xp_1000",
	"xp5000": "xp_5000",
	"chain5": "chain_5",
	"chain10": "chain_10",
}


var _save_override: Node = null


func set_save_manager_for_test(node: Node) -> void:
	_save_override = node


func _get_save_manager() -> Node:
	if _save_override != null:
		return _save_override
	return _autoload("SaveManager")


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func try_migrate_on_startup() -> bool:
	var save := _get_save_manager()
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		return false

	for path in [LEGACY_CAPACITOR_PATH, IMPORTED_SAVE_PATH]:
		if FileAccess.file_exists(path):
			if import_from_file(path):
				return true

	if import_from_android_plugin():
		return true

	return false


func import_from_file(path: String) -> bool:
	if not FileAccess.file_exists(path):
		return false

	var text := _read_text(path)
	if text.is_empty():
		push_warning("LegacySaveMigration: empty file %s" % path)
		return false

	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("LegacySaveMigration: invalid JSON in %s" % path)
		return false

	return _import_payload(parsed, path)


## Manual import (Settings button): Android plugin first, then user:// legacy files.
func try_manual_import() -> bool:
	if OS.has_feature("android"):
		if import_from_android_plugin():
			return true
	for path in [IMPORTED_SAVE_PATH, LEGACY_CAPACITOR_PATH]:
		if import_from_file(path):
			return true
	return false


func import_from_android_plugin() -> bool:
	if not OS.has_feature("android"):
		return false
	if not Engine.has_singleton(ANDROID_PLUGIN_NAME):
		push_warning("LegacySaveMigration: Android plugin not installed (file import still works)")
		return false

	var plugin = Engine.get_singleton(ANDROID_PLUGIN_NAME)
	if plugin == null or not plugin.has_method("exportLegacySave"):
		return false

	var json_text := str(plugin.call("exportLegacySave"))
	if json_text.is_empty():
		return false

	var parsed = JSON.parse_string(json_text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_warning("LegacySaveMigration: Android plugin returned invalid JSON")
		return false

	# Cache plugin payload for manual re-import / debugging.
	_write_text(IMPORTED_SAVE_PATH, json_text)
	return _import_payload(parsed, IMPORTED_SAVE_PATH)


func _import_payload(raw: Dictionary, source_path: String) -> bool:
	var godot_dict := _map_legacy_to_godot(raw)
	if godot_dict.is_empty():
		push_warning("LegacySaveMigration: could not map legacy save from %s" % source_path)
		return false

	var state := GameStateScript.new()
	if not state.load_from_save_dict(godot_dict):
		push_warning("LegacySaveMigration: load_from_save_dict failed for %s" % source_path)
		return false

	var save := _get_save_manager()
	if save == null or not save.has_method("save_game"):
		push_warning("LegacySaveMigration: SaveManager unavailable")
		return false

	if not bool(save.call("save_game", state)):
		push_warning("LegacySaveMigration: save_game failed after import")
		return false

	_archive_source(source_path)
	print("LegacySaveMigration: imported save from %s" % source_path)
	return true


func _map_legacy_to_godot(raw: Dictionary) -> Dictionary:
	# Already Godot flat save (snake_case + grid).
	if raw.has("current_level") and raw.has("grid"):
		return raw.duplicate(true)

	# Capacitor/Web flat save (camelCase) — version 2 from js/app/persistence/save-load.js.
	if not raw.has("version") and not raw.has("currentLevel") and not raw.has("grid"):
		return {}

	var grid_raw: Variant = raw.get("grid", raw.get("Grid", []))
	var bonus_raw: Variant = raw.get("bonus_inventory", raw.get("bonusInventory", {}))
	var pending_raw: Variant = raw.get("pending_transition", raw.get("pendingTransition", {}))

	var progress := {
		"stats": _coerce_dict(raw.get("stats", {})),
		"achievements": _map_achievements(_coerce_dict(raw.get("achievements", {}))),
	}

	var carry_val: Variant = raw.get("carry_number", raw.get("carryNumber", 0))
	var carry := 0
	if carry_val != null and str(carry_val) != "null":
		carry = maxi(0, int(carry_val))

	return {
		"version": int(raw.get("version", 2)),
		"current_level": _int_field(raw, "current_level", "currentLevel", 0),
		"xp": maxi(0, _int_field(raw, "xp", "xp", 0)),
		"carry_number": carry,
		"max_reached_number": maxi(2, _int_field(raw, "max_reached_number", "maxReachedNumber", 8)),
		"grid": _convert_grid(grid_raw),
		"pending_transition": _map_pending_transition(pending_raw),
		"xp_multiplier": maxi(1, _int_field(raw, "xp_multiplier", "xpMultiplier", 1)),
		"xp_multiplier_turns": maxi(0, _int_field(raw, "xp_multiplier_turns", "xpMultiplierTurns", 0)),
		"bonus_inventory": _map_bonus_inventory(bonus_raw),
		"active_bonus": "",
		"daily_quests": {},
		"wheel_spins_today": maxi(0, _int_field(raw, "wheel_spins_today", "wheelSpinsToday", 0)),
		"last_wheel_day": str(raw.get("last_wheel_day", raw.get("lastWheelDay", ""))),
		"progress": progress,
	}


func _convert_grid(raw_grid: Variant) -> Array:
	var board := BoardLogic.new()
	var empty := board.grid_to_arrays()

	if typeof(raw_grid) != TYPE_ARRAY:
		return empty

	for x in range(mini(raw_grid.size(), board.grid_w)):
		if typeof(raw_grid[x]) != TYPE_ARRAY:
			continue
		for y in range(mini(raw_grid[x].size(), board.grid_h)):
			empty[x][y] = _cell_value(raw_grid[x][y])

	return empty


func _cell_value(cell: Variant) -> int:
	if cell == null:
		return 0
	if typeof(cell) == TYPE_DICTIONARY:
		var v: Variant = cell.get("value", cell.get("number", 0))
		if v == null:
			return 0
		return maxi(0, int(v))
	if typeof(cell) == TYPE_FLOAT or typeof(cell) == TYPE_INT:
		return maxi(0, int(cell))
	return 0


func _map_bonus_inventory(raw: Variant) -> Dictionary:
	var src := _coerce_dict(raw)
	return {
		"destroy": maxi(0, int(src.get("destroy", 0))),
		"shuffle": maxi(0, int(src.get("shuffle", 0))),
		"explosion": maxi(0, int(src.get("explosion", 0))),
	}


func _map_pending_transition(raw: Variant) -> Dictionary:
	var src := _coerce_dict(raw)
	if src.is_empty():
		return {}
	var mapped := src.duplicate(true)
	if mapped.has("nextLevel") and not mapped.has("next_level"):
		mapped["next_level"] = mapped["nextLevel"]
	if mapped.has("carryNumber") and not mapped.has("carry_number"):
		mapped["carry_number"] = mapped["carryNumber"]
	if mapped.has("completedLevelIndex") and not mapped.has("completed_level_index"):
		mapped["completed_level_index"] = mapped["completedLevelIndex"]
	return mapped


func _map_achievements(raw: Dictionary) -> Dictionary:
	var defaults := PlayerProgress.new().achievements
	for js_key in raw.keys():
		var gd_key: String = str(ACHIEVEMENT_KEY_MAP.get(js_key, js_key))
		if not defaults.has(gd_key):
			continue
		if typeof(raw[js_key]) != TYPE_DICTIONARY:
			continue
		defaults[gd_key].merge(raw[js_key], true)
	return defaults


func _int_field(raw: Dictionary, snake: String, camel: String, fallback: int) -> int:
	if raw.has(snake):
		return int(raw[snake])
	if raw.has(camel):
		return int(raw[camel])
	return fallback


func _coerce_dict(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}


func _read_text(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _write_text(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(text)
	file.close()


func _archive_source(path: String) -> void:
	if path.is_empty() or not FileAccess.file_exists(path):
		return
	var archive := path + ARCHIVE_SUFFIX
	if FileAccess.file_exists(archive):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(archive))
	var err := DirAccess.rename_absolute(
		ProjectSettings.globalize_path(path),
		ProjectSettings.globalize_path(archive)
	)
	if err != OK:
		push_warning("LegacySaveMigration: could not archive %s (err %s)" % [path, err])
