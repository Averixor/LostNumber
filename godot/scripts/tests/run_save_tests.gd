extends SceneTree

const GameStateScript := preload("res://scripts/core/GameState.gd")
const SaveManagerScript := preload("res://scripts/managers/SaveManager.gd")
const LegacySaveMigrationScript := preload("res://scripts/managers/LegacySaveMigration.gd")

var failed := 0
var _test_dir := ""
var _save: SaveManagerScript
var _migration: LegacySaveMigrationScript


func _init() -> void:
	print("Lost Number Save tests...")
	_save = SaveManagerScript.new()
	_migration = LegacySaveMigrationScript.new()
	_migration.set_save_manager_for_test(_save)
	_test_dir = ProjectSettings.globalize_path("user://save_tests_%d" % Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(_test_dir)
	_save.enable_test_root(_test_dir)

	_test_roundtrip()
	_test_corrupt_primary_recovers_from_backup()
	_test_backup_only_valid_has_save()
	_test_backup_only_corrupt_no_has_save()
	_test_corrupt_primary_valid_backup_has_save()
	_test_legacy_flat_save()
	_test_stale_pending_transition_resets_to_playing()
	_test_both_corrupt_returns_null()
	_test_meta_roundtrip()
	_test_legacy_capacitor_import()

	_save.disable_test_root()
	_cleanup_test_dir()

	if failed > 0:
		push_error("Save tests failed: %s" % failed)
		_cleanup()
		quit(1)

	print("Save tests passed")
	_cleanup()
	quit(0)


func _test_roundtrip() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(42)
	state.xp = 128

	_assert_true(_save.save_game(state), "save roundtrip")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "load roundtrip")
	_assert_eq(int(loaded.xp), 128, "xp preserved")


func _test_corrupt_primary_recovers_from_backup() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(7)
	state.current_level = 1
	_assert_true(_save.save_game(state), "first save")

	state.current_level = 3
	_assert_true(_save.save_game(state), "second save creates backup")

	var primary := "%s/lost_number_save.json" % _test_dir
	_write_file(primary, "{not json")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "recover from backup after corrupt primary")
	_assert_eq(int(loaded.current_level), 1, "backup level preserved (first save)")


func _test_backup_only_valid_has_save() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(11)
	state.xp = 77
	_assert_true(_save.save_game(state), "backup-only: write primary")

	var primary := "%s/lost_number_save.json" % _test_dir
	var backup := "%s/lost_number_save.bak.json" % _test_dir
	var text := FileAccess.get_file_as_string(primary)
	_write_file(backup, text)
	DirAccess.remove_absolute(primary)

	_assert_false(FileAccess.file_exists(primary), "backup-only: primary removed")
	_assert_true(FileAccess.file_exists(backup), "backup-only: backup present")
	_assert_true(_save.has_save(), "backup-only valid: has_save true")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "backup-only valid: load_game restores")
	_assert_eq(int(loaded.xp), 77, "backup-only valid: xp preserved")


func _test_backup_only_corrupt_no_has_save() -> void:
	_save.delete_save()
	var primary := "%s/lost_number_save.json" % _test_dir
	var backup := "%s/lost_number_save.bak.json" % _test_dir
	_write_file(backup, "{not json")

	_assert_false(FileAccess.file_exists(primary), "corrupt backup-only: no primary")
	_assert_false(_save.has_save(), "corrupt backup-only: has_save false")
	_assert_true(_save.load_game() == null, "corrupt backup-only: load_game null")


func _test_corrupt_primary_valid_backup_has_save() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(19)
	state.current_level = 2
	_assert_true(_save.save_game(state), "corrupt+backup: first save")

	state.current_level = 5
	_assert_true(_save.save_game(state), "corrupt+backup: second save creates backup")

	var primary := "%s/lost_number_save.json" % _test_dir
	_write_file(primary, "{not json")

	_assert_true(_save.has_save(), "corrupt primary + valid backup: has_save true")
	var loaded = _save.load_game()
	_assert_true(loaded != null, "corrupt primary + valid backup: load recovers")
	_assert_eq(int(loaded.current_level), 2, "corrupt primary + valid backup: level from backup")


func _test_legacy_flat_save() -> void:
	_save.delete_save()
	var legacy := {
		"version": 2,
		"current_level": 1,
		"xp": 50,
		"carry_number": 0,
		"max_reached_number": 16,
		"grid": [],
		"pending_transition": {},
		"xp_multiplier": 1,
		"xp_multiplier_turns": 0,
		"bonus_inventory": {"destroy": 0, "shuffle": 0, "explosion": 0},
		"progress": {},
	}
	var primary := "%s/lost_number_save.json" % _test_dir
	_write_file(primary, JSON.stringify(legacy))

	var loaded = _save.load_game()
	_assert_true(loaded != null, "legacy flat save loads")
	_assert_eq(int(loaded.xp), 50, "legacy xp preserved")


func _test_both_corrupt_returns_null() -> void:
	_save.delete_save()
	_write_file("%s/lost_number_save.json" % _test_dir, "broken")
	_write_file("%s/lost_number_save.bak.json" % _test_dir, "broken")

	var loaded = _save.load_game()
	_assert_true(loaded == null, "both corrupt saves return null")


func _test_stale_pending_transition_resets_to_playing() -> void:
	_save.delete_save()
	var stale := {
		"version": 2,
		"current_level": 0,
		"xp": 0,
		"carry_number": 0,
		"max_reached_number": 8,
		"grid": [],
		"pending_transition": {"next_level": 1},
		"xp_multiplier": 1,
		"xp_multiplier_turns": 0,
		"bonus_inventory": {"destroy": 0, "shuffle": 0, "explosion": 0},
		"progress": {},
	}
	var primary := "%s/lost_number_save.json" % _test_dir
	_write_file(primary, JSON.stringify(stale))

	var loaded = _save.load_game()
	_assert_true(loaded != null, "stale pending save loads")
	_assert_eq(int(loaded.phase), GameStateScript.Phase.PLAYING, "stale pending resets phase")
	_assert_true(loaded.pending_transition.is_empty(), "stale pending cleared")
	_assert_true(not loaded.should_show_level_complete(), "stale pending hides overlay")


func _test_meta_roundtrip() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(99)
	state.grant_bonus("shuffle", 2)
	state.daily_quests = {"date": "2026-07-02", "completed": {"useBonus": true}, "list": []}
	state.progress.leaderboard["opt_in"] = true
	state.progress.leaderboard["pending_submits"] = [{"board": "best_level", "score": 3}]
	_assert_true(_save.save_game(state), "meta save")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "meta load")
	_assert_eq(int(loaded.get_bonus_count("shuffle")), 2, "bonus inventory preserved")
	_assert_true(bool(loaded.daily_quests.get("completed", {}).get("useBonus", false)), "daily quests preserved")
	_assert_true(bool(loaded.progress.leaderboard.get("opt_in", false)), "leaderboard opt-in preserved")
	_assert_true(loaded.active_bonus.is_empty(), "active_bonus cleared on load")


func _write_file(path: String, text: String) -> void:
	var file := FileAccess.open(path, FileAccess.WRITE)
	file.store_string(text)
	file.close()


func _cleanup_test_dir() -> void:
	var dir := DirAccess.open(_test_dir)
	if dir:
		dir.list_dir_begin()
		var name := dir.get_next()
		while name != "":
			if not dir.current_is_dir():
				dir.remove(name)
			name = dir.get_next()
		DirAccess.remove_absolute(_test_dir)


func _test_legacy_capacitor_import() -> void:
	_save.delete_save()
	var legacy := {
		"version": 2,
		"gridSchemaVersion": 2,
		"currentLevel": 3,
		"xp": 120,
		"xpMultiplier": 2,
		"xpMultiplierTurns": 1,
		"maxReachedNumber": 32,
		"carryNumber": 4,
		"wheelSpinsToday": 2,
		"lastWheelDay": "2026-07-01",
		"bonusInventory": {"destroy": 1, "shuffle": 0, "explosion": 2},
		"pendingTransition": {},
		"stats": {"games_played": 5, "total_xp": 500, "wheel_spins": 2},
		"achievements": {
			"firstGame": {"unlocked": true, "progress": 1, "max": 1},
			"level10": {"unlocked": false, "progress": 3, "max": 10},
		},
		"grid": [
			[
				{"value": 2, "merged": false, "frozen": false},
				{"value": 4, "merged": false, "frozen": false},
			],
			[
				{"value": 8, "merged": false, "frozen": false},
				null,
			],
		],
	}
	var legacy_path := "%s/legacy_capacitor_save.json" % _test_dir
	_write_file(legacy_path, JSON.stringify(legacy))

	_assert_true(_migration.import_from_file(legacy_path), "capacitor legacy import")
	_assert_true(_save.has_save(), "godot save created after import")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "imported save loads")
	_assert_eq(int(loaded.current_level), 3, "imported current_level")
	_assert_eq(int(loaded.xp), 120, "imported xp")
	_assert_eq(int(loaded.get_bonus_count("destroy")), 1, "imported bonus destroy")
	_assert_true(bool(loaded.progress.achievements["first_game"]["unlocked"]), "achievement mapped")
	_assert_false(FileAccess.file_exists(legacy_path), "legacy file archived")


func _cleanup() -> void:
	if _migration != null:
		_migration.free()
		_migration = null
	if _save != null:
		_save.free()
		_save = null


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(a: int, b: int, message: String) -> void:
	_assert_true(a == b, "%s (got %s expected %s)" % [message, a, b])


func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)
