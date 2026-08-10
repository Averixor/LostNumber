extends SceneTree

## Project + gameplay stabilization smoke tests (headless, no GPU scenes).

const GameStateScript := preload("res://scripts/core/GameState.gd")
const SaveManagerScript := preload("res://scripts/managers/SaveManager.gd")
const BonusManagerScript := preload("res://scripts/game/BonusManager.gd")
const DailyQuestManagerScript := preload("res://scripts/meta/DailyQuestManager.gd")
const WheelManagerScript := preload("res://scripts/meta/WheelManager.gd")

const AUTOLOAD_PATHS := {
	"SaveManager": "res://scripts/managers/SaveManager.gd",
	"SettingsManager": "res://scripts/managers/SettingsManager.gd",
	"AudioManager": "res://scripts/managers/AudioManager.gd",
	"I18nManager": "res://scripts/managers/I18nManager.gd",
	"ThemeManager": "res://scripts/managers/ThemeManager.gd",
	"LeaderboardService": "res://scripts/managers/LeaderboardService.gd",
	"ScreenRouter": "res://scripts/ui/ScreenRouter.gd",
	"LegacySaveMigration": "res://scripts/managers/LegacySaveMigration.gd",
}

const SCENES := [
	"res://scenes/Boot.tscn",
	"res://scenes/App.tscn",
	"res://scenes/MainMenu.tscn",
	"res://scenes/Game.tscn",
	"res://scenes/Settings.tscn",
	"res://scenes/Achievements.tscn",
	"res://scenes/DailyQuests.tscn",
	"res://scenes/Wheel.tscn",
	"res://scenes/Stats.tscn",
	"res://scenes/About.tscn",
	"res://scenes/SkinPreview.tscn",
	"res://scenes/BackgroundPreview.tscn",
	"res://scenes/components/BackgroundLayer.tscn",
	"res://scenes/components/NeonButton.tscn",
	"res://scenes/components/MenuDockButton.tscn",
	"res://scenes/components/MenuQuickChip.tscn",
	"res://scenes/components/FeatureStubOverlay.tscn",
	"res://scenes/components/ScreenTransition.tscn",
	"res://scenes/components/Tile.tscn",
	"res://scenes/components/ChainLineLayer.tscn",
	"res://scenes/components/GameHud.tscn",
	"res://scenes/components/AchievementCard.tscn",
	"res://scenes/components/DailyQuestCard.tscn",
]

const SCENE_SCRIPTS := [
	"res://scripts/managers/AutoloadAccess.gd",
	"res://scripts/App.gd",
	"res://scripts/ui/Boot.gd",
	"res://scripts/ui/ScreenRouter.gd",
	"res://scripts/ui/ScreenTransition.gd",
	"res://scripts/ui/BackgroundLayer.gd",
	"res://scripts/ui/NeonButton.gd",
	"res://scripts/ui/ThemeTokens.gd",
	"res://scripts/ui/MainMenu.gd",
	"res://scripts/game/Game.gd",
	"res://scripts/game/Board.gd",
	"res://scripts/ui/Settings.gd",
	"res://scripts/ui/Achievements.gd",
	"res://scripts/ui/DailyQuests.gd",
	"res://scripts/ui/Wheel.gd",
	"res://scripts/ui/WheelCanvas.gd",
	"res://scripts/ui/GameHud.gd",
	"res://scripts/ui/Stats.gd",
	"res://scripts/ui/About.gd",
	"res://scripts/ui/SkinPreview.gd",
	"res://scripts/ui/MenuDockButton.gd",
	"res://scripts/ui/MenuQuickChip.gd",
	"res://scripts/ui/FeatureStubOverlay.gd",
	"res://scripts/ui/AchievementCard.gd",
	"res://scripts/ui/DailyQuestCard.gd",
	"res://scripts/game/Tile.gd",
	"res://scripts/game/ChainLineLayer.gd",
	"res://scripts/managers/I18nManager.gd",
	"res://scripts/managers/AudioManager.gd",
	"res://scripts/managers/ThemeManager.gd",
	"res://scripts/managers/LeaderboardService.gd",
	"res://scripts/managers/LegacySaveMigration.gd",
]

const KEY_RESOURCES := [
	"res://assets/icons/icon-1024.png",
	"res://assets/icons/icon-1024.png",
	"res://scripts/game/Board.gd",
	"res://scripts/managers/SaveManager.gd",
	"res://scripts/core/GameState.gd",
]


class NavigationProbe:
	extends Node
	var current_screen_id := "main_menu"
	var current_screen: Node = null
	var pushed_screen := ""

	func push(screen_id: String) -> void:
		pushed_screen = screen_id

	func get_current_screen() -> Node:
		return current_screen

var failed := 0
var _save: SaveManagerScript
var _test_dir := ""
var _save_added_to_root := false


func _init() -> void:
	print("Lost Number smoke tests...")
	_save = _test_save_manager()
	_test_dir = ProjectSettings.globalize_path("user://smoke_tests_%d" % Time.get_ticks_msec())
	DirAccess.make_dir_recursive_absolute(_test_dir)
	_save.enable_test_root(_test_dir)

	_test_autoloads()
	_test_scene_scripts_compile()
	_test_scenes_load()
	_test_key_resources()
	_test_gameplay_core()
	_test_bonuses()
	_test_carry_unique_singular()
	_test_meta_managers()
	await _test_safe_new_game_confirmation()
	await _test_wheel_without_save_does_not_create_session()
	_test_old_save_defaults()
	_test_minimal_legacy_save()

	_save.disable_test_root()
	_cleanup_test_dir()

	if failed > 0:
		push_error("Smoke tests failed: %s" % failed)
		_cleanup()
		quit(1)
		return

	print("Smoke tests passed")
	_cleanup()
	quit(0)


func _test_autoloads() -> void:
	for name in AUTOLOAD_PATHS.keys():
		var path: String = AUTOLOAD_PATHS[name]
		_assert_script_compiles(path, "autoload script: %s" % name)


func _test_scene_scripts_compile() -> void:
	for path in SCENE_SCRIPTS:
		_assert_script_compiles(path, "scene script compiles")


func _test_scenes_load() -> void:
	for path in SCENES:
		_assert_true(ResourceLoader.exists(path), "scene exists: %s" % path)
		var packed: Resource = load(path)
		if packed == null:
			failed += 1
			push_error("FAIL: scene load returned null: %s" % path)
			continue
		_assert_true(packed is PackedScene, "scene is PackedScene: %s" % path)


func _test_key_resources() -> void:
	for path in KEY_RESOURCES:
		_assert_true(ResourceLoader.exists(path), "resource exists: %s" % path)
		if path.ends_with(".gd"):
			_assert_script_compiles(path, "key script compiles")
			continue
		var res = load(path)
		if res == null:
			failed += 1
			push_error("FAIL: resource load returned null: %s" % path)
			continue
		print("OK: resource loads: %s" % path)


func _assert_script_compiles(path: String, label: String) -> void:
	if not ResourceLoader.exists(path):
		failed += 1
		push_error("FAIL: %s missing (%s)" % [label, path])
		return

	if ResourceLoader.has_cached(path):
		ResourceLoader.load(path, "Script", ResourceLoader.CACHE_MODE_REPLACE)

	var script: Resource = load(path)
	if script == null:
		failed += 1
		push_error("FAIL: %s compile/load returned null (%s)" % [label, path])
		return
	if not (script is GDScript):
		failed += 1
		push_error("FAIL: %s is not GDScript (%s)" % [label, path])
		return
	var reload_err := (script as GDScript).reload(true)
	if reload_err != OK:
		failed += 1
		push_error("FAIL: %s parse/reload failed (%s, err=%s)" % [label, path, reload_err])
		return
	print("OK: %s (%s)" % [label, path])


func _test_gameplay_core() -> void:
	var state = GameStateScript.new()
	state.start_new_game(12345)
	_assert_eq(state.current_level, 0, "new game level 0")
	_assert_eq(state.xp, 0, "new game xp 0")
	_assert_true(state.phase == GameStateScript.Phase.PLAYING, "new game playing phase")

	for x in state.board.grid_w:
		for y in state.board.grid_h:
			state.board.grid[x][y] = 0
	state.board.grid[0][0] = 2
	state.board.grid[1][0] = 2

	state.begin_chain(Vector2i(0, 0))
	_assert_true(state.extend_chain(Vector2i(1, 0)), "extend chain")
	_assert_true(state.can_finish_current_chain(), "chain can finish")

	var before_xp = state.xp
	var merge = state.merge_current_chain()
	_assert_true(merge.ok, "merge succeeds")
	_assert_true(state.xp > before_xp, "xp increases after merge")
	_assert_eq(int(merge.get("result", 0)), 4, "merge result value")


func _test_bonuses() -> void:
	var state = GameStateScript.new()
	state.start_new_game(77)
	var bonus = BonusManagerScript.new(state)

	state.grant_bonus("shuffle", 1)
	var shuffle = bonus.activate("shuffle")
	_assert_true(shuffle.ok, "shuffle bonus activates")

	state.grant_bonus("destroy", 1)
	var pick = bonus.activate("destroy")
	_assert_true(pick.ok, "destroy pick mode")
	var destroy = bonus.apply_at_cell(Vector2i(0, 0))
	_assert_true(destroy.ok, "destroy applies at top-left")

	state.grant_bonus("explosion", 1)
	bonus.activate("explosion")
	var blast = bonus.apply_at_cell(Vector2i(0, 0))
	_assert_true(blast.ok, "explosion applies at top-left")


func _test_carry_unique_singular() -> void:
	var state = GameStateScript.new()
	state.start_new_game(11)
	state.carry_number = 8
	state.board.fill_random(state.current_level, state.carry_number)
	# Force several matching values, then unique placement must leave exactly one.
	state.board.grid[0][0] = 8
	state.board.grid[1][1] = 8
	state.board.grid[2][2] = 8
	state.board.place_carry_unique(8, state.current_level, state.max_reached_number)
	var count := 0
	for x in state.board.grid_w:
		for y in state.board.grid_h:
			if int(state.board.grid[x][y]) == 8:
				count += 1
	_assert_eq(count, 1, "exactly one carry tile after place_carry_unique")


func _test_meta_managers() -> void:
	var state = GameStateScript.new()
	state.start_new_game(5)
	var daily = DailyQuestManagerScript.new(state)
	daily.ensure_loaded()
	_assert_true(daily.get_quests().size() > 0, "daily quests generated")

	var wheel = WheelManagerScript.new(state)
	state.xp = 100
	var spin = wheel.spin()
	_assert_true(spin.ok, "wheel spin ok")


func _test_safe_new_game_confirmation() -> void:
	# SceneTree._init runs before autoload _ready callbacks. Yield before constructing
	# the real menu so its music request cannot race AudioManager initialization.
	await process_frame
	var audio := root.get_node_or_null("AudioManager")
	var audio_ready: bool = audio == null or audio.get("_music_player") != null
	_assert_true(
		audio_ready,
		"new-game menu test waits for AudioManager readiness"
	)
	if not audio_ready:
		return

	_save.delete_save()
	var state = GameStateScript.new()
	state.start_new_game(20260731)
	state.xp = 17
	_assert_true(_save.save_game(state), "new-game confirmation setup writes primary save")
	state.xp = 29
	_assert_true(_save.save_game(state), "new-game confirmation setup writes backup save")

	var primary := "%s/lost_number_save.json" % _test_dir
	var backup := "%s/lost_number_save.bak.json" % _test_dir
	var primary_before := _read_file(primary)
	var backup_before := _read_file(backup)
	_assert_true(not primary_before.is_empty(), "new-game confirmation setup has primary bytes")
	_assert_true(not backup_before.is_empty(), "new-game confirmation setup has backup bytes")

	var original_router := root.get_node_or_null("ScreenRouter")
	if original_router != null:
		root.remove_child(original_router)
	var navigation := NavigationProbe.new()
	navigation.name = "ScreenRouter"
	root.add_child(navigation)

	var menu_scene: PackedScene = load("res://scenes/MainMenu.tscn")
	var menu := menu_scene.instantiate()
	root.add_child(menu)
	await process_frame
	navigation.current_screen = menu
	var app_scene: PackedScene = load("res://scenes/App.tscn")
	var app := app_scene.instantiate()
	root.add_child(app)
	await process_frame
	menu.call("_on_play")
	await process_frame

	var dialog = menu.get("_new_game_dialog")
	_assert_true(dialog is ConfirmationDialog, "new game with save opens native confirmation")
	var i18n := root.get_node_or_null("I18nManager")
	if dialog is ConfirmationDialog and i18n != null:
		_assert_true(
			(dialog as ConfirmationDialog).dialog_text == str(i18n.call("t", "confirm_new_game_text")),
			"new-game confirmation uses localized warning text"
		)
		_assert_true(
			(dialog as ConfirmationDialog).ok_button_text == str(i18n.call("t", "start_new_game_confirm")),
			"new-game confirmation uses localized confirm action"
		)
		_assert_true(
			(dialog as ConfirmationDialog).cancel_button_text == str(i18n.call("t", "cancel")),
			"new-game confirmation uses localized cancel action"
		)
		var confirm := dialog as ConfirmationDialog
		var max_w: int = int(menu.get_viewport_rect().size.x)
		_assert_true(
			confirm.size.x <= max_w,
			"new-game confirmation fits viewport width"
		)
		var ok_btn := confirm.get_ok_button()
		var cancel_btn := confirm.get_cancel_button()
		_assert_true(ok_btn != null and cancel_btn != null, "new-game confirmation has both actions")
		if ok_btn != null and cancel_btn != null:
			_assert_true(
				not ok_btn.clip_text and not cancel_btn.clip_text,
				"new-game confirmation does not clip action labels"
			)
			_assert_true(
				ok_btn.size.x > 0.0 and cancel_btn.size.x > 0.0,
				"new-game confirmation action buttons have positive width"
			)
			_assert_true(
				ok_btn.global_position.x + ok_btn.size.x <= max_w + 1.0,
				"new-game confirm button stays inside viewport"
			)
			_assert_true(
				cancel_btn.global_position.x + cancel_btn.size.x <= max_w + 1.0,
				"new-game cancel button stays inside viewport"
			)
			var font_size := ok_btn.get_theme_font_size("font_size")
			var font := ok_btn.get_theme_font("font")
			if font != null:
				var ok_need := font.get_string_size(ok_btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				var cancel_need := font.get_string_size(cancel_btn.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
				_assert_true(
					ok_btn.size.x + 1.0 >= ok_need,
					"new-game confirm label fits button width"
				)
				_assert_true(
					cancel_btn.size.x + 1.0 >= cancel_need,
					"new-game cancel label fits button width"
				)
	_assert_true(FileAccess.file_exists(primary), "primary remains before explicit confirmation")
	_assert_true(FileAccess.file_exists(backup), "backup remains before explicit confirmation")
	_assert_true(_read_file(primary) == primary_before, "primary bytes unchanged before confirmation")
	_assert_true(_read_file(backup) == backup_before, "backup bytes unchanged before confirmation")
	_assert_true(navigation.pushed_screen.is_empty(), "new game does not navigate before confirmation")

	app.notification(Node.NOTIFICATION_WM_GO_BACK_REQUEST)
	await process_frame
	await process_frame
	if dialog is ConfirmationDialog:
		_assert_true(not (dialog as ConfirmationDialog).visible, "Android Back dismisses new-game confirmation")
	var exit_dialog: ConfirmationDialog = app.get("_exit_dialog") as ConfirmationDialog
	var exit_visible: bool = exit_dialog != null and exit_dialog.visible
	_assert_false(exit_visible, "Android Back does not stack App exit confirmation over new-game modal")
	_assert_false(bool(app.get("_back_busy")), "Android Back delegation completes")
	_assert_true(_read_file(primary) == primary_before, "cancel leaves primary untouched")
	_assert_true(_read_file(backup) == backup_before, "cancel leaves backup untouched")
	_assert_true(navigation.pushed_screen.is_empty(), "cancel does not start a new game")

	menu.call("_on_play")
	await process_frame
	if dialog is ConfirmationDialog:
		(dialog as ConfirmationDialog).confirmed.emit()
	await process_frame
	_assert_false(FileAccess.file_exists(primary), "confirmation deletes primary save")
	_assert_false(FileAccess.file_exists(backup), "confirmation deletes backup save")
	_assert_true(navigation.pushed_screen == "game", "confirmation starts a clean game")

	if audio != null and audio.has_method("stop_music"):
		audio.call("stop_music")
		var music_player: AudioStreamPlayer = audio.get("_music_player") as AudioStreamPlayer
		_assert_true(music_player.stream == null, "new-game smoke releases settings music stream")
		for sfx_player in audio.get("_sfx_players"):
			sfx_player.stop()
			sfx_player.stream = null
		audio.set("_streams", {})

	var menu_ref: WeakRef = weakref(menu)
	var app_ref: WeakRef = weakref(app)
	var dialog_ref: WeakRef = weakref(dialog) if dialog is Object else null
	menu.queue_free()
	app.queue_free()
	await process_frame
	await process_frame
	_assert_true(menu_ref.get_ref() == null, "new-game smoke frees MainMenu")
	_assert_true(app_ref.get_ref() == null, "new-game smoke frees App shell")
	if dialog_ref != null:
		_assert_true(dialog_ref.get_ref() == null, "new-game smoke frees confirmation dialog")

	navigation.current_screen = null
	root.remove_child(navigation)
	navigation.free()
	if original_router != null:
		root.add_child(original_router)
	await process_frame


func _test_wheel_without_save_does_not_create_session() -> void:
	_save.delete_save()
	var before_has_save := _save.has_save()
	var wheel_scene: PackedScene = load("res://scenes/Wheel.tscn")
	var wheel := wheel_scene.instantiate()
	wheel.set_meta("suppress_invalid_session_navigation", true)
	root.add_child(wheel)
	await process_frame

	_assert_false(before_has_save, "wheel no-save setup starts without save")
	_assert_true(bool(wheel.get("_invalid_session")), "wheel blocks direct launch without save")
	_assert_true(wheel.get("_state") == null, "wheel does not create fallback game state")
	_assert_false(_save.has_save(), "wheel direct launch without save does not write save")

	root.remove_child(wheel)
	wheel.free()


func _test_old_save_defaults() -> void:
	_save.delete_save()
	var state = GameStateScript.new()
	state.start_new_game(1)
	state.grant_bonus("shuffle", 1)
	state.active_bonus = "destroy"
	state.daily_quests = {"date": "2099-01-01", "completed": {"useBonus": true}, "list": []}
	state.progress.leaderboard = {
		"best_level": 5,
		"opt_in": true,
		"pending_submits": [{"board": "best_level", "score": 5}],
	}
	_assert_true(_save.save_game(state), "meta save for defaults test")

	var loaded = _save.load_game()
	_assert_true(loaded != null, "meta save loads")
	_assert_eq(int(loaded.get_bonus_count("shuffle")), 1, "bonus count preserved")
	_assert_true(loaded.active_bonus.is_empty(), "active_bonus cleared on load")
	_assert_true(bool(loaded.daily_quests.get("completed", {}).get("useBonus", false)), "daily completed preserved")
	_assert_true(bool(loaded.progress.leaderboard.get("opt_in", false)), "leaderboard opt_in preserved")
	_assert_true(typeof(loaded.progress.leaderboard.get("pending_submits")) == TYPE_ARRAY, "pending_submits array")
	_assert_true(loaded.progress.leaderboard.has("best_xp"), "leaderboard defaults merged")


func _test_minimal_legacy_save() -> void:
	_save.delete_save()
	var legacy := {
		"version": 2,
		"current_level": 2,
		"xp": 40,
		"carry_number": 0,
		"max_reached_number": 16,
		"grid": [],
		"pending_transition": {},
		"xp_multiplier": 1,
		"xp_multiplier_turns": 0,
		"bonus_inventory": {"destroy": 1},
	}
	_write_file("%s/lost_number_save.json" % _test_dir, JSON.stringify(legacy))

	var loaded = _save.load_game()
	_assert_true(loaded != null, "minimal legacy save loads")
	_assert_eq(int(loaded.xp), 40, "legacy xp preserved")
	_assert_eq(int(loaded.get_bonus_count("destroy")), 1, "partial bonus inventory preserved")
	_assert_eq(int(loaded.get_bonus_count("shuffle")), 0, "missing bonus defaults to 0")
	_assert_true(loaded.daily_quests.is_empty(), "missing daily_quests defaults empty")
	_assert_true(loaded.progress.achievements.has("first_game"), "achievement defaults present")
	_assert_false(bool(loaded.progress.leaderboard.get("opt_in", true)), "leaderboard opt_in default false")


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


func _cleanup() -> void:
	if _save != null:
		if _save_added_to_root:
			root.remove_child(_save)
			_save.free()
		_save = null


func _test_save_manager() -> SaveManagerScript:
	var existing := root.get_node_or_null("SaveManager")
	if existing != null and existing.has_method("enable_test_root"):
		return existing as SaveManagerScript
	var save := SaveManagerScript.new()
	save.name = "SaveManager"
	root.add_child(save)
	_save_added_to_root = true
	return save


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


func _assert_false(value: bool, message: String) -> void:
	_assert_true(not value, message)
