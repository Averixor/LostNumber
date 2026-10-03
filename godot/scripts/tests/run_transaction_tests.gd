extends SceneTree

const SettingsScript := preload("res://scripts/managers/SettingsManager.gd")
const AuthScript := preload("res://scripts/managers/AuthManager.gd")
const RouterScript := preload("res://scripts/ui/ScreenRouter.gd")
const MigrationScript := preload("res://scripts/managers/LegacySaveMigration.gd")

class AndroidAuthProbe:
	extends AuthScript
	func is_android() -> bool:
		return true
	func _bind_plugin() -> void:
		pass

class NativeAuthStub:
	extends RefCounted
	var auth: Node
	var fail := true
	func signOut() -> void:
		auth._on_plugin_auth_result(JSON.stringify({"status": "error" if fail else "logged_out", "error": "firebase_not_configured" if fail else ""}))

class TransitionStub:
	extends Node
	func cover(_duration: float, _slide: bool) -> void:
		await get_tree().process_frame
	func uncover(_duration: float, _slide: bool) -> void:
		await get_tree().process_frame

var failed := 0
var settings_events := 0

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SettingsManager").sound_enabled = false
	root.get_node("SettingsManager").music_enabled = false
	root.get_node("SaveManager").enable_test_root(ProjectSettings.globalize_path("user://"))
	_test_xp()
	_test_wheel()
	_test_merge_snapshot()
	_test_migration()
	_test_settings_writes()
	_test_sign_out()
	await _test_settings_opt_in()
	await _test_navigation()
	await _test_live_merge_save()
	await _test_wheel_exit()
	var audio := root.get_node("AudioManager")
	audio.stop_music()
	for player in audio._sfx_players:
		player.stop()
		player.stream = null
	audio._streams = {}
	await process_frame
	await process_frame
	print("Transaction regression tests: %d failures" % failed)
	quit(1 if failed else 0)

func check(ok: bool, label: String) -> void:
	if not ok:
		failed += 1
		push_error("FAIL: " + label)
	else:
		print("OK: " + label)

func fresh() -> GameState:
	var state := GameState.new()
	state.start_new_game(42)
	return state

func _test_xp() -> void:
	var state := fresh()
	var daily := DailyQuestManager.new(state)
	state.grant_xp(90)
	check(daily.get_progress("xp100").current == 90, "all earned XP advances daily quest")
	daily.on_level_complete()
	check(state.xp == 140 and state.progress.stats.total_xp == 140, "quest XP and threshold reward recorded once")
	check(state.progress.stats.session_xp_today == 140, "daily XP includes quest rewards")
	daily.on_session_xp_changed()
	check(state.xp == 140, "completed XP quest cannot reward itself twice")
	state.grant_xp(4860)
	check(state.progress.achievements.xp_5000.unlocked, "all XP sources unlock achievements")
	check(state.progress.leaderboard.best_xp == 5000, "leaderboard counts all earned XP")
	state.daily_quests.date = "2000-01-01"
	state.progress._daily_date = "2000-01-01"
	state.last_wheel_day = "2000-01-01"
	state.wheel_spins_today = 20
	state.grant_xp(7)
	WheelManager.new(state).check_daily_reset()
	check(state.daily_quests.date == state.last_wheel_day, "wheel and quests share local day")
	check(state.progress.stats.session_xp_today == 7, "midnight resets before recording new XP")
	check(state.wheel_spins_today == 0, "new day restores spin quota")

func _test_wheel() -> void:
	for seed_value in range(30):
		var state := fresh()
		state.xp = 500
		var board_rng := state.board.rng.state
		var wheel := WheelManager.new(state)
		wheel.rng.seed = seed_value
		var prep := wheel.prepare_spin()
		check(prep.ok, "prepare spin %d" % seed_value)
		check(state.board.rng.state == board_rng, "wheel leaves board RNG unchanged")
		check(state.wheel_spins_today == 1 and state.progress.stats.wheel_spins == 1, "spin committed before animation")
		check(bool(state.daily_quests.completed.spinWheel), "spin quest committed before animation")
		var sector: Dictionary = prep.sector
		if sector.effect == "xp":
			var reward := int(sector.value) + 15
			if reward >= 100:
				reward += 30
			check(state.xp == 500 - 25 + reward, "payment and all XP rewards are atomic")
			check(state.progress.stats.total_xp == reward, "wheel XP counts as earnings; cost does not subtract earnings")
		elif sector.effect == "bonus":
			check(state.get_bonus_count(str(sector.value)) == 1, "bonus awarded before animation")
		else:
			check(state.xp_multiplier == 2 and state.xp_multiplier_turns == 3, "multiplier awarded before animation")
		var snapshot := state.to_save_dict()
		var restored := GameState.new()
		restored.load_from_save_dict(snapshot)
		check(restored.to_save_dict() == snapshot, "mid-spin snapshot contains complete result")
		check(not wheel.prepare_spin().ok, "overlapping spin rejected")
		wheel.finish_spin(sector)
		wheel.finish_spin(sector)
		check(state.to_save_dict() == snapshot, "animation callback cannot award twice")

func _test_merge_snapshot() -> void:
	for winning in [false, true]:
		var state := fresh()
		var value := state.get_target() / 2 if winning else 2
		state.board.grid[0][0] = value
		state.board.grid[1][0] = value
		state.selected_path = [Vector2i(0, 0), Vector2i(1, 0)]
		var result := state.merge_current_chain()
		check(result.ok, "merge accepted")
		var snapshot := state.to_save_dict()
		check(not state.board.has_value_on_board(0), "snapshot before animation has no holes")
		var restored := GameState.new()
		restored.load_from_save_dict(snapshot)
		check(restored.board.grid == state.board.grid, "reload preserves settled board")
		check(restored.should_show_level_complete() == winning, "mid-animation save preserves victory")
		check(state.progress.stats.total_merges == 1, "merge statistics counted once")
	var old := fresh().to_save_dict()
	old.grid[0][0] = 0
	var repaired := GameState.new()
	repaired.load_from_save_dict(old)
	check(not repaired.board.has_value_on_board(0), "old interrupted save repaired on load")

func _test_migration() -> void:
	var migration := MigrationScript.new()
	var legacy := {
		"version": 2, "currentLevel": 0, "xp": 42,
		"grid": fresh().board.grid_to_arrays(),
		"dailyQuests": {"date": Time.get_date_string_from_system(), "completed": {"spinWheel": true}, "progress": {"xp100": 62}, "list": [{"id": "spinWheel", "textKey": "daily_spin_wheel"}]},
	}
	var state := GameState.new()
	state.load_from_save_dict(migration._map_legacy_to_godot(legacy))
	var daily := DailyQuestManager.new(state)
	daily.ensure_loaded()
	check(daily.is_done("spinWheel"), "migration keeps claimed quests")
	check(daily.get_progress("xp100").current == 62, "migration keeps partial XP quest")
	check(state.progress.get_session_xp_today() == 62, "migrated XP quest continues from imported progress")
	daily.on_wheel_spun()
	check(state.xp == 42, "imported completed quest cannot pay again")
	check(daily.get_quests()[0].has("text_key"), "migration replaces legacy labels with Godot localization")
	migration.free()

func _test_settings_writes() -> void:
	var settings := SettingsScript.new()
	root.add_child(settings)
	settings.settings_saved.connect(func(): settings_events += 1)
	settings.language = "uk"
	check(settings.save_settings(), "settings saved successfully")
	var original := FileAccess.get_file_as_string(settings.SETTINGS_PATH)
	var temp_path := settings.SETTINGS_PATH + ".tmp"
	DirAccess.make_dir_absolute(temp_path)
	settings.language = "en"
	check(not settings.save_settings(), "settings staging open failure reported")
	check(settings_events == 1, "failed write emits no settings_saved")
	check(FileAccess.get_file_as_string(settings.SETTINGS_PATH) == original, "failed write preserves prior settings")
	DirAccess.remove_absolute(temp_path)
	check(settings.save_settings(), "settings retry succeeds")
	settings.language = "ru"
	settings.load_settings()
	check(settings.language == "en", "settings survive reload")
	settings.free()

func _test_sign_out() -> void:
	var auth := AndroidAuthProbe.new()
	var plugin := NativeAuthStub.new()
	plugin.auth = auth
	auth._plugin = plugin
	auth._apply_payload({"status": "logged_in", "uid": "test-user", "displayName": "Test"}, true)
	auth.sign_out()
	check(auth.is_signed_in(), "failed native logout retains honest signed-in state for retry")
	check(auth.last_error == "firebase_not_configured", "logout failure remains visible")
	var reloaded := AuthScript.new()
	reloaded._load_session_cache()
	check(reloaded.is_signed_in() == auth.is_signed_in(), "failed logout UI agrees with restored cache")
	reloaded.free()
	plugin.fail = false
	auth.sign_out()
	check(not auth.is_signed_in() and not FileAccess.file_exists(auth.SESSION_PATH), "successful retry removes session cache")
	auth.free()

func _test_settings_opt_in() -> void:
	var save := root.get_node("SaveManager")
	var state := fresh()
	save.save_game(state)
	var screen = load("res://scenes/Settings.tscn").instantiate()
	root.add_child(screen)
	check(not screen.leaderboard_check.button_pressed, "opt-in starts disabled")
	screen._on_leaderboard_toggled(true)
	check(save.load_game().progress.leaderboard.opt_in, "opt-in persisted to progress")
	screen._load_settings()
	check(screen.leaderboard_check.button_pressed, "opt-in checkbox restored")
	screen._on_leaderboard_toggled(false)
	check(not save.load_game().progress.leaderboard.opt_in, "opt-out persisted")
	save.set_test_failure_point("temp_write")
	screen._on_leaderboard_toggled(true)
	check(not screen.leaderboard_check.button_pressed, "failed opt-in write restores checkbox")
	check(not save.load_game().progress.leaderboard.opt_in, "failed opt-in write preserves persisted consent")
	save.clear_test_failure_point()
	screen.queue_free()
	await process_frame

func _test_navigation() -> void:
	var router := RouterScript.new()
	var mount := Control.new()
	var transition := TransitionStub.new()
	root.add_child(router)
	root.add_child(mount)
	root.add_child(transition)
	router.register(mount, transition)
	await router.replace("about")
	router.push("stats")
	check(await router.go_back(), "back during cover is eventually handled")
	check(router.current_screen_id == "about", "queued back returns to previous screen")
	router.push("stats")
	await router.replace("achievements")
	check(router.current_screen_id == "achievements", "replace during transition is retained")
	router.replace("stats")
	await router.push("about")
	check(router.current_screen_id == "about", "push during transition is retained")
	await router.go_back()
	check(router.current_screen_id == "stats", "queued push keeps correct back stack")
	router.unregister()
	router.queue_free()
	mount.queue_free()
	transition.queue_free()
	await process_frame

func _test_wheel_exit() -> void:
	var save := root.get_node("SaveManager")
	var state := fresh()
	state.xp = 500
	save.save_game(state)
	var wheel = load("res://scenes/Wheel.tscn").instantiate()
	root.add_child(wheel)
	wheel._wheel.rng.seed = 4
	wheel._on_spin()
	var persisted: GameState = save.load_game()
	check(persisted.wheel_spins_today == 1, "live Wheel persists spin before yielding")
	check(JSON.parse_string(JSON.stringify(persisted.to_save_dict())) == JSON.parse_string(JSON.stringify(wheel._state.to_save_dict())), "live Wheel persists entire reward before animation")
	wheel.queue_free()
	await process_frame
	check(save.load_game().to_save_dict() == persisted.to_save_dict(), "leaving wheel during animation loses no reward")

func _test_live_merge_save() -> void:
	var save := root.get_node("SaveManager")
	var state := fresh()
	save.save_game(state)
	var game = load("res://scenes/Game.tscn").instantiate()
	root.add_child(game)
	await process_frame
	game.state.board.grid[0][0] = 2
	game.state.board.grid[1][0] = 2
	game.board_view.refresh_all()
	var path: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0)]
	game.state.selected_path = path
	game._on_chain_finished(path.duplicate())
	check(game.state.phase == GameState.Phase.ANIMATING, "live merge is still animating")
	game._show_pause()
	game._on_save_pressed()
	var persisted: GameState = save.load_game()
	check(not persisted.board.has_value_on_board(0), "manual save during merge persists full board")
	check(persisted.board.grid == game.state.board.grid, "saved merge matches in-memory model")
	game.queue_free()
	await process_frame
	check(save.load_game().board.grid == persisted.board.grid, "scene exit during merge preserves full board")
