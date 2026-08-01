extends SceneTree

const GameStateScript := preload("res://scripts/core/GameState.gd")
const SaveManagerScript := preload("res://scripts/managers/SaveManager.gd")
const LegacySaveMigrationScript := preload("res://scripts/managers/LegacySaveMigration.gd")
const GameScript := preload("res://scripts/game/Game.gd")
const GameHudScript := preload("res://scripts/ui/GameHud.gd")


class SaveResultStub:
	extends Node
	var result := false

	func save_game(_state) -> bool:
		return result


class I18nStub:
	extends Node
	var strings := {
		"save_indicator": "Saved",
		"save_failed": "Could not save progress. You can keep playing.",
	}

	func t(key: String, _args: Array = []) -> String:
		return str(strings.get(key, key))


class SaveFeedbackHud:
	extends GameHudScript
	var flashed_text := ""
	var flash_count := 0

	func flash_save_indicator(text: String) -> void:
		flashed_text = text
		flash_count += 1


class GameSaveProbe:
	extends GameScript
	var save_stub: Node
	var i18n_stub: Node

	func _autoload(name: String) -> Node:
		if name == "SaveManager":
			return save_stub
		if name == "I18nManager":
			return i18n_stub
		return null


class NavigationProbe:
	extends Node
	var go_back_calls := 0
	var replace_calls := 0

	func go_back():
		go_back_calls += 1
		await get_tree().process_frame
		return true

	func replace(_screen_id: String) -> void:
		replace_calls += 1

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
	_test_envelope_format_unchanged()
	_test_partial_temp_never_replaces_primary()
	_test_bad_checksum_temp_never_replaces_primary()
	_test_backup_copy_failure_preserves_files()
	_test_backup_promotion_failure_preserves_files()
	_test_primary_promotion_failure_keeps_recoverable_save()
	_test_corrupt_primary_failed_promotion_preserves_valid_backup()
	_test_corrupt_primary_success_preserves_valid_backup()
	_test_no_valid_recovery_uses_verified_temp_fail_safe()
	_test_game_save_feedback_matches_result()
	await _test_failed_save_blocks_menu_navigation()
	_test_corrupt_primary_recovers_from_backup()
	_test_backup_self_heal_promotion_failure_keeps_backup()
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


func _test_envelope_format_unchanged() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(314)
	state.xp = 55
	_assert_true(_save.save_game(state), "compatible envelope: save succeeds")

	var payload = JSON.parse_string(_read_file(_primary_path()))
	_assert_true(typeof(payload) == TYPE_DICTIONARY, "compatible envelope: primary is JSON object")
	if typeof(payload) != TYPE_DICTIONARY:
		return
	_assert_eq(int(payload.get("envelope_version", -1)), 1, "compatible envelope: version remains 1")
	_assert_true(payload.has("saved_at"), "compatible envelope: saved_at remains present")
	_assert_true(payload.has("checksum"), "compatible envelope: checksum remains present")
	_assert_true(payload.has("data_json"), "compatible envelope: data_json remains present")
	_assert_false(payload.has("data"), "compatible envelope: canonical data_json shape retained")


func _test_partial_temp_never_replaces_primary() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(401)
	state.xp = 10
	_assert_true(_save.save_game(state), "partial temp: seed primary")
	var primary_before := _read_file(_primary_path())

	state.xp = 20
	_save.set_test_failure_point("temp_partial")
	_assert_false(_save.save_game(state), "partial temp: save reports false")
	_save.clear_test_failure_point()

	_assert_text_eq(_read_file(_primary_path()), primary_before, "partial temp: primary bytes unchanged")
	_assert_false(FileAccess.file_exists(_backup_path()), "partial temp: backup not created before verification")
	_assert_false(FileAccess.file_exists(_temp_path()), "partial temp: staging file cleaned")
	var loaded = _save.load_game()
	_assert_true(loaded != null, "partial temp: original primary still loads")
	_assert_eq(int(loaded.xp), 10, "partial temp: original progress preserved")


func _test_bad_checksum_temp_never_replaces_primary() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(402)
	state.xp = 30
	_assert_true(_save.save_game(state), "bad checksum temp: seed primary")
	var primary_before := _read_file(_primary_path())

	state.xp = 40
	_save.set_test_failure_point("temp_checksum")
	_assert_false(_save.save_game(state), "bad checksum temp: save reports false")
	_save.clear_test_failure_point()

	_assert_text_eq(_read_file(_primary_path()), primary_before, "bad checksum temp: primary bytes unchanged")
	_assert_false(FileAccess.file_exists(_backup_path()), "bad checksum temp: backup not created before verification")
	_assert_false(FileAccess.file_exists(_temp_path()), "bad checksum temp: staging file cleaned")


func _test_backup_copy_failure_preserves_files() -> void:
	_seed_primary_and_backup(501)
	var primary_before := _read_file(_primary_path())
	var backup_before := _read_file(_backup_path())
	var state := GameStateScript.new()
	state.start_new_game(503)
	state.xp = 503

	_save.set_test_failure_point("backup_copy")
	_assert_false(_save.save_game(state), "backup copy failure: save reports false")
	_save.clear_test_failure_point()

	_assert_text_eq(_read_file(_primary_path()), primary_before, "backup copy failure: primary unchanged")
	_assert_text_eq(_read_file(_backup_path()), backup_before, "backup copy failure: backup unchanged")
	_assert_false(FileAccess.file_exists(_temp_path()), "backup copy failure: temp cleaned")
	_assert_false(FileAccess.file_exists(_backup_temp_path()), "backup copy failure: backup stage cleaned")


func _test_backup_promotion_failure_preserves_files() -> void:
	_seed_primary_and_backup(601)
	var primary_before := _read_file(_primary_path())
	var backup_before := _read_file(_backup_path())
	var state := GameStateScript.new()
	state.start_new_game(603)
	state.xp = 603

	_save.set_test_failure_point("backup_promotion")
	_assert_false(_save.save_game(state), "backup promotion failure: save reports false")
	_save.clear_test_failure_point()

	_assert_text_eq(_read_file(_primary_path()), primary_before, "backup promotion failure: primary unchanged")
	_assert_text_eq(_read_file(_backup_path()), backup_before, "backup promotion failure: old backup unchanged")
	_assert_false(FileAccess.file_exists(_temp_path()), "backup promotion failure: temp cleaned")
	_assert_false(FileAccess.file_exists(_backup_temp_path()), "backup promotion failure: backup stage cleaned")


func _test_primary_promotion_failure_keeps_recoverable_save() -> void:
	_seed_primary_and_backup(701)
	var primary_before := _read_file(_primary_path())
	var state := GameStateScript.new()
	state.start_new_game(703)
	state.xp = 703

	_save.set_test_failure_point("primary_promotion")
	_assert_false(_save.save_game(state), "primary promotion failure: save reports false")
	_save.clear_test_failure_point()

	_assert_text_eq(_read_file(_primary_path()), primary_before, "primary promotion failure: primary unchanged")
	_assert_text_eq(_read_file(_backup_path()), primary_before, "primary promotion failure: backup holds old primary")
	_assert_false(FileAccess.file_exists(_temp_path()), "primary promotion failure: temp cleaned")
	var loaded = _save.load_game()
	_assert_true(loaded != null, "primary promotion failure: save remains loadable")
	_assert_eq(int(loaded.xp), 702, "primary promotion failure: last committed progress preserved")


func _test_corrupt_primary_failed_promotion_preserves_valid_backup() -> void:
	_seed_corrupt_primary_with_valid_backup(901)
	var corrupt_primary_before := _read_file(_primary_path())
	var valid_backup_before := _read_file(_backup_path())
	var state := GameStateScript.new()
	state.start_new_game(903)
	state.xp = 903

	_save.set_test_failure_point("primary_promotion")
	_assert_false(
		_save.save_game(state),
		"corrupt primary failed promotion: save reports false"
	)
	_save.clear_test_failure_point()

	_assert_text_eq(
		_read_file(_primary_path()),
		corrupt_primary_before,
		"corrupt primary failed promotion: corrupt primary is not copied elsewhere"
	)
	_assert_text_eq(
		_read_file(_backup_path()),
		valid_backup_before,
		"corrupt primary failed promotion: valid backup bytes remain untouched"
	)
	_assert_true(
		_save._is_valid_save_path(_backup_path()),
		"corrupt primary failed promotion: backup remains valid"
	)
	var loaded = _save.load_game()
	_assert_true(loaded != null, "corrupt primary failed promotion: backup remains loadable")
	_assert_eq(int(loaded.xp), 901, "corrupt primary failed promotion: backup progress preserved")


func _test_corrupt_primary_success_preserves_valid_backup() -> void:
	_seed_corrupt_primary_with_valid_backup(911)
	var valid_backup_before := _read_file(_backup_path())
	var state := GameStateScript.new()
	state.start_new_game(913)
	state.xp = 913

	_assert_true(_save.save_game(state), "corrupt primary success: verified temp is promoted")
	_assert_text_eq(
		_read_file(_backup_path()),
		valid_backup_before,
		"corrupt primary success: valid backup is preserved"
	)
	_assert_true(_save._is_valid_save_path(_backup_path()), "corrupt primary success: backup stays valid")
	var loaded = _save.load_game()
	_assert_true(loaded != null, "corrupt primary success: new primary loads")
	_assert_eq(int(loaded.xp), 913, "corrupt primary success: new progress committed")


func _test_no_valid_recovery_uses_verified_temp_fail_safe() -> void:
	_save.delete_save()
	_write_file(_primary_path(), "{corrupt primary")
	_write_file(_backup_path(), "{corrupt backup")
	var primary_before := _read_file(_primary_path())
	var backup_before := _read_file(_backup_path())
	var state := GameStateScript.new()
	state.start_new_game(921)
	state.xp = 921

	_save.set_test_failure_point("primary_promotion")
	_assert_false(_save.save_game(state), "no valid recovery: failed promotion reports false")
	_save.clear_test_failure_point()
	_assert_text_eq(_read_file(_primary_path()), primary_before, "no valid recovery: primary unchanged on failure")
	_assert_text_eq(_read_file(_backup_path()), backup_before, "no valid recovery: backup unchanged on failure")

	_assert_true(_save.save_game(state), "no valid recovery: retry promotes verified temp")
	_assert_true(_save._is_valid_save_path(_primary_path()), "no valid recovery: new primary is valid")
	_assert_text_eq(_read_file(_backup_path()), backup_before, "no valid recovery: corrupt backup is not rotated")
	var loaded = _save.load_game()
	_assert_true(loaded != null, "no valid recovery: committed state loads")
	_assert_eq(int(loaded.xp), 921, "no valid recovery: in-memory progress becomes recovery state")


func _test_game_save_feedback_matches_result() -> void:
	var save_stub := SaveResultStub.new()
	var i18n_stub := I18nStub.new()
	var hud := SaveFeedbackHud.new()
	var game := GameSaveProbe.new()
	game.save_stub = save_stub
	game.i18n_stub = i18n_stub
	game.game_hud = hud
	game.state.start_new_game(801)
	game.state.xp = 81

	save_stub.result = false
	_assert_false(game._save_game(), "game feedback: failed save returns false")
	_assert_text_eq(
		hud.flashed_text,
		"Could not save progress. You can keep playing.",
		"game feedback: failed save shows localized error"
	)
	_assert_eq(int(game.state.xp), 81, "game feedback: failed save leaves gameplay state intact")

	save_stub.result = true
	_assert_true(game._save_game(), "game feedback: successful save returns true")
	_assert_text_eq(hud.flashed_text, "Saved", "game feedback: success shown only for true")
	_assert_eq(hud.flash_count, 2, "game feedback: each attempt produces one message")

	game.free()
	hud.free()
	i18n_stub.free()
	save_stub.free()


func _test_failed_save_blocks_menu_navigation() -> void:
	await process_frame
	var runtime_save := root.get_node_or_null("SaveManager")
	_assert_true(runtime_save != null, "menu failure lifecycle: runtime SaveManager exists")
	if runtime_save == null:
		return

	var original_router := root.get_node_or_null("ScreenRouter")
	if original_router != null:
		root.remove_child(original_router)
	var navigation := NavigationProbe.new()
	navigation.name = "ScreenRouter"
	root.add_child(navigation)

	var packed := load("res://scenes/Game.tscn") as PackedScene
	_assert_true(packed != null, "menu failure lifecycle: Game scene loads")
	if packed == null:
		root.remove_child(navigation)
		navigation.free()
		if original_router != null:
			root.add_child(original_router)
		return

	var game := packed.instantiate()
	game.set_meta("visual_capture_no_persistence", true)
	root.add_child(game)
	await process_frame
	await process_frame

	var game_state = game.get("state")
	game_state.xp = 91
	game.set_meta("visual_capture_no_persistence", false)
	runtime_save.call("enable_test_root", _test_dir)
	runtime_save.call("set_test_failure_point", "temp_write")
	game.call("_show_pause")
	game.call("_on_back_to_menu")
	await process_frame
	await process_frame

	var hud = game.get("game_hud")
	var i18n := root.get_node_or_null("I18nManager")
	var expected_error := str(i18n.call("t", "save_failed")) if i18n != null else "save_failed"
	_assert_true(game.is_inside_tree(), "menu failure lifecycle: Game remains in tree")
	_assert_false(game.is_queued_for_deletion(), "menu failure lifecycle: Game is not queued for deletion")
	_assert_true(game.get_parent() == root, "menu failure lifecycle: Game screen remains mounted")
	_assert_eq(navigation.go_back_calls, 0, "menu failure lifecycle: router.go_back is not called")
	_assert_eq(navigation.replace_calls, 0, "menu failure lifecycle: router.replace is not called")
	_assert_text_eq(
		str(hud.save_indicator.text),
		expected_error,
		"menu failure lifecycle: localized error remains visible on live HUD"
	)
	_assert_eq(int(game_state.xp), 91, "menu failure lifecycle: in-memory progress remains available")

	var save_tween = hud.get("_save_flash_tween")
	if save_tween is Tween and save_tween.is_valid():
		save_tween.kill()
	var audio := root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_music"):
		audio.call("stop_music")
		for sfx_player in audio.get("_sfx_players"):
			sfx_player.stop()
			sfx_player.stream = null
		audio.set("_streams", {})
	runtime_save.call("clear_test_failure_point")
	runtime_save.call("disable_test_root")
	game.set_meta("visual_capture_no_persistence", true)
	var game_ref: WeakRef = weakref(game)
	var navigation_ref: WeakRef = weakref(navigation)
	game.queue_free()
	navigation.queue_free()
	await process_frame
	await process_frame
	await process_frame
	_assert_true(game_ref.get_ref() == null, "menu failure lifecycle: Game is freed during cleanup")
	_assert_true(
		navigation_ref.get_ref() == null,
		"menu failure lifecycle: navigation probe is freed during cleanup"
	)
	if original_router != null:
		root.add_child(original_router)
	await process_frame


func _seed_primary_and_backup(seed: int) -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(seed)
	state.xp = seed
	_assert_true(_save.save_game(state), "failure setup: first committed save")
	state.xp = seed + 1
	_assert_true(_save.save_game(state), "failure setup: second committed save")


func _seed_corrupt_primary_with_valid_backup(seed: int) -> void:
	_seed_primary_and_backup(seed)
	_write_file(_primary_path(), "{corrupt primary")
	_assert_false(_save._is_valid_save_path(_primary_path()), "corrupt-primary setup: primary invalid")
	_assert_true(_save._is_valid_save_path(_backup_path()), "corrupt-primary setup: backup valid")


func _test_corrupt_primary_recovers_from_backup() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(7)
	state.current_level = 1
	_assert_true(_save.save_game(state), "first save")

	state.current_level = 3
	_assert_true(_save.save_game(state), "second save creates backup")

	var backup_before := _read_file(_backup_path())
	_write_file(_primary_path(), "{not json")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "recover from backup after corrupt primary")
	_assert_eq(int(loaded.current_level), 1, "backup level preserved (first save)")
	_assert_true(_save._is_valid_save_path(_primary_path()), "successful self-heal: primary restored and valid")
	_assert_text_eq(
		_read_file(_primary_path()),
		backup_before,
		"successful self-heal: primary restored from exact backup bytes"
	)
	_assert_text_eq(
		_read_file(_backup_path()),
		backup_before,
		"successful self-heal: backup bytes remain unchanged"
	)
	_assert_false(FileAccess.file_exists(_temp_path()), "successful self-heal: staging temp cleaned")


func _test_backup_self_heal_promotion_failure_keeps_backup() -> void:
	_save.delete_save()
	var state := GameStateScript.new()
	state.start_new_game(1007)
	state.xp = 70
	_assert_true(_save.save_game(state), "failed self-heal setup: first committed save")
	state.xp = 80
	_assert_true(_save.save_game(state), "failed self-heal setup: second committed save")

	_write_file(_primary_path(), "{corrupt primary before self-heal")
	var corrupt_primary_before := _read_file(_primary_path())
	var valid_backup_before := _read_file(_backup_path())
	_save.set_test_failure_point("recovery_promotion")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "failed self-heal: load still returns backup state")
	_assert_eq(int(loaded.xp), 70, "failed self-heal: backup progress returned")
	_assert_text_eq(
		_read_file(_primary_path()),
		corrupt_primary_before,
		"failed self-heal: corrupt primary bytes remain unchanged"
	)
	_assert_text_eq(
		_read_file(_backup_path()),
		valid_backup_before,
		"failed self-heal: valid backup bytes remain unchanged"
	)
	_assert_true(_save._is_valid_save_path(_backup_path()), "failed self-heal: backup remains valid")
	var backup_loaded = _save._try_load_path(_backup_path(), null)
	_assert_true(backup_loaded != null, "failed self-heal: backup remains directly loadable")
	_assert_eq(int(backup_loaded.xp), 70, "failed self-heal: direct backup load preserves progress")
	_assert_false(FileAccess.file_exists(_temp_path()), "failed self-heal: staging temp cleaned")

	_save.clear_test_failure_point()
	loaded = _save.load_game()
	_assert_true(loaded != null, "self-heal retry: load returns backup state")
	_assert_eq(int(loaded.xp), 70, "self-heal retry: backup progress returned")
	_assert_true(_save._is_valid_save_path(_primary_path()), "self-heal retry: primary restored and valid")
	_assert_text_eq(
		_read_file(_primary_path()),
		valid_backup_before,
		"self-heal retry: primary restored from exact backup bytes"
	)
	_assert_text_eq(
		_read_file(_backup_path()),
		valid_backup_before,
		"self-heal retry: backup bytes remain unchanged"
	)
	_assert_false(FileAccess.file_exists(_temp_path()), "self-heal retry: staging temp cleaned")


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


func _read_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _primary_path() -> String:
	return "%s/lost_number_save.json" % _test_dir


func _backup_path() -> String:
	return "%s/lost_number_save.bak.json" % _test_dir


func _temp_path() -> String:
	return "%s/lost_number_save.tmp.json" % _test_dir


func _backup_temp_path() -> String:
	return "%s/lost_number_save.bak.tmp.json" % _test_dir


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


func _assert_text_eq(a: String, b: String, message: String) -> void:
	if a != b:
		failed += 1
		push_error("FAIL: %s (text mismatch)" % message)
	else:
		print("OK: " + message)


func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)
