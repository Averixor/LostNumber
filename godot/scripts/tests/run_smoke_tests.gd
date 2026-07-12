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
	"res://icon.svg",
	"res://scripts/game/Board.gd",
	"res://scripts/managers/SaveManager.gd",
	"res://scripts/core/GameState.gd",
]

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
	_test_meta_managers()
	await _test_wheel_without_save_does_not_create_session()
	_test_old_save_defaults()
	_test_minimal_legacy_save()

	_save.disable_test_root()
	_cleanup_test_dir()

	if failed > 0:
		push_error("Smoke tests failed: %s" % failed)
		_cleanup()
		quit(1)

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
	_assert_true(destroy.ok, "destroy applies")

	state.grant_bonus("explosion", 1)
	bonus.activate("explosion")
	var blast = bonus.apply_at_cell(Vector2i(2, 2))
	_assert_true(blast.ok, "explosion applies")


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


func _test_wheel_without_save_does_not_create_session() -> void:
	_save.delete_save()
	var before_has_save := _save.has_save()
	var wheel_scene: PackedScene = load("res://scenes/Wheel.tscn")
	var wheel := wheel_scene.instantiate()
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
