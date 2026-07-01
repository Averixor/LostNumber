extends SceneTree

const GameStateScript := preload("res://scripts/core/GameState.gd")
const SaveManagerScript := preload("res://scripts/managers/SaveManager.gd")

var failed := 0
var _test_dir := ""
var _save: SaveManagerScript


func _init() -> void:
	print("Lost Number Save tests...")
	_save = SaveManagerScript.new()
	_test_dir = ProjectSettings.globalize_path("user://save_tests_%d" % Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(_test_dir)
	_save.enable_test_root(_test_dir)

	_test_roundtrip()
	_test_corrupt_primary_recovers_from_backup()
	_test_legacy_flat_save()
	_test_stale_pending_transition_resets_to_playing()
	_test_both_corrupt_returns_null()

	_save.disable_test_root()
	_cleanup_test_dir()

	if failed > 0:
		push_error("Save tests failed: %s" % failed)
		quit(1)
	else:
		print("Save tests passed")
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


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(a: int, b: int, message: String) -> void:
	_assert_true(a == b, "%s (got %s expected %s)" % [message, a, b])
