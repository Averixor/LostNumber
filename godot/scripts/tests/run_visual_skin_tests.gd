extends SceneTree

## Gothic Crystal vertical-slice contract tests.
## These stay headless and exercise only resource loading plus safe UI instances.

const VisualSkinLib := preload("res://scripts/ui/VisualSkin.gd")
const ThemeManagerScript := preload("res://scripts/managers/ThemeManager.gd")

const SKIN_PATH := "res://themes/skins/gothic_crystal.tres"
const TILE_SCENE_PATH := "res://scenes/components/Tile.tscn"

const VISUAL_SCENES := [
	"res://scenes/Game.tscn",
	"res://scenes/SkinPreview.tscn",
	"res://scenes/BackgroundPreview.tscn",
	"res://scenes/components/BackgroundLayer.tscn",
	"res://scenes/components/Tile.tscn",
	"res://scenes/components/ChainLineLayer.tscn",
	"res://scenes/components/GameHud.tscn",
]

const SAFE_INSTANCE_SCENES := [
	"res://scenes/Settings.tscn",
	"res://scenes/components/Tile.tscn",
	"res://scenes/components/ChainLineLayer.tscn",
	"res://scenes/components/GameHud.tscn",
	"res://scenes/SkinPreview.tscn",
	"res://scenes/BackgroundPreview.tscn",
]

class LowEffectsSettings:
	extends Node
	var bg_effects_enabled := false

class ManualImportSave:
	extends Node
	var saved_state: Variant = null
	func save_game(state: Variant) -> bool:
		saved_state = state
		return true

var failed := 0
var _theme_fixture: Node = null
var _owns_theme_fixture := false
var _audio_settings_modified := false
var _previous_music_enabled := true
var _previous_sound_enabled := true


func _init() -> void:
	print("Lost Number Gothic Crystal visual-skin tests...")
	if not _isolated_user_data_is_safe():
		push_error(
			"Visual-skin tests refused: user:// '%s' is not inside isolated root '%s'" % [
				ProjectSettings.globalize_path("user://").simplify_path(),
				OS.get_environment("LOSTNUMBER_ISOLATED_USER_ROOT").simplify_path(),
			]
		)
		quit(2)
		return
	# Project autoloads are attached after SceneTree._init(). Waiting first avoids
	# creating a duplicate ThemeManager that can race the real autoload.
	await process_frame
	_install_theme_fixture()
	await process_frame
	_theme_fixture.set("visual_skin_id", "gothic_crystal")
	_theme_fixture.set("theme_id", "dusk")
	_suppress_test_audio()

	_test_skin_resource()
	_test_rarity_boundaries()
	_test_duplicated_styles()
	_test_theme_scope_and_migration()
	_test_visual_scenes_load()
	_test_settings_visual_controls()
	await _test_settings_manual_import()
	await _test_tile_public_states()
	await _test_low_effects_contract()
	await _test_game_board_composition()
	await _test_game_overlays()
	await _test_localized_visual_scenes()
	await _test_safe_scene_instances()
	await _cleanup_test_audio()

	if failed > 0:
		push_error("Visual-skin tests failed: %s" % failed)
		_cleanup_theme_fixture()
		quit(1)
		return

	print("Visual-skin tests passed")
	_cleanup_theme_fixture()
	quit(0)


func _isolated_user_data_is_safe() -> bool:
	var expected := OS.get_environment("LOSTNUMBER_ISOLATED_USER_ROOT").simplify_path()
	var actual := ProjectSettings.globalize_path("user://").simplify_path()
	return not expected.is_empty() and actual.begins_with(expected + "/")


func _install_theme_fixture() -> void:
	_theme_fixture = root.get_node_or_null("ThemeManager")
	if _theme_fixture == null:
		_theme_fixture = ThemeManagerScript.new()
		_theme_fixture.name = "ThemeManager"
		root.add_child(_theme_fixture)
		_owns_theme_fixture = true
	# The target skin is forced after the first process frame so _ready() cannot
	# overwrite it. No mutating ThemeManager setter is used.


func _cleanup_theme_fixture() -> void:
	if _owns_theme_fixture and is_instance_valid(_theme_fixture):
		root.remove_child(_theme_fixture)
		_theme_fixture.free()
	_theme_fixture = null
	_owns_theme_fixture = false


func _cleanup_test_audio() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio == null:
		return
	if audio.has_method("stop_music"):
		audio.call("stop_music")
	var music_player := audio.get("_music_player") as AudioStreamPlayer
	if music_player != null:
		music_player.stop()
		music_player.stream = null
	var sfx_players: Array = audio.get("_sfx_players")
	for player in sfx_players:
		if player is AudioStreamPlayer:
			(player as AudioStreamPlayer).stop()
			(player as AudioStreamPlayer).stream = null
	await process_frame
	if _audio_settings_modified:
		var settings := root.get_node_or_null("SettingsManager")
		if settings != null:
			settings.set("music_enabled", _previous_music_enabled)
			settings.set("sound_enabled", _previous_sound_enabled)
	_audio_settings_modified = false


func _suppress_test_audio() -> void:
	var settings := root.get_node_or_null("SettingsManager")
	if settings == null:
		return
	_previous_music_enabled = bool(settings.get("music_enabled"))
	_previous_sound_enabled = bool(settings.get("sound_enabled"))
	settings.set("music_enabled", false)
	settings.set("sound_enabled", false)
	_audio_settings_modified = true


func _test_skin_resource() -> void:
	_assert_true(ResourceLoader.exists(SKIN_PATH), "Gothic Crystal resource exists")
	var loaded := load(SKIN_PATH)
	_assert_true(loaded is VisualSkinLib, "Gothic Crystal loads as VisualSkin")
	if not (loaded is VisualSkinLib):
		return

	var skin := loaded as VisualSkinLib
	_assert_true(skin.is_valid_skin(), "Gothic Crystal resource is valid")
	_assert_eq_string(str(skin.skin_id), "gothic_crystal", "skin id")
	_assert_true(skin.menu_background != null, "menu background is assigned")
	_assert_true(skin.game_background != null, "game background is assigned")
	_assert_true(not skin.supports_light_mode, "Gothic Crystal declares its dark-only contract")
	var representative_faces := {
		skin.tile_face_color_for_value(2): true,
		skin.tile_face_color_for_value(4): true,
		skin.tile_face_color_for_value(8): true,
		skin.tile_face_color_for_value(64): true,
		skin.tile_face_color_for_value(128): true,
	}
	_assert_eq_int(representative_faces.size(), 5, "representative values have distinct material colours")

	for style_name in [
		&"panel",
		&"modal",
		&"hud",
		&"board",
		&"button_normal",
		&"button_hover",
		&"button_pressed",
		&"button_disabled",
	]:
		_assert_true(skin.style_for(style_name) != null, "style is assigned: %s" % style_name)

	var tier_style_ids: Dictionary = {}
	for value in [2, 16, 128, 1024, 8192]:
		var tier_style := skin.tile_style_for_value(value)
		_assert_true(tier_style is StyleBoxTexture, "textured tile style is assigned: %s" % value)
		if tier_style != null:
			tier_style_ids[tier_style.get_instance_id()] = true
	_assert_eq_int(tier_style_ids.size(), 5, "all five rarity tiers use distinct styles")
	var frozen_style := skin.tile_style_for_value(2, true)
	_assert_true(frozen_style is StyleBoxTexture, "textured frozen tile style is assigned")
	if frozen_style != null:
		_assert_true(
			not tier_style_ids.has(frozen_style.get_instance_id()),
			"frozen tile style is distinct from rarity tiers",
		)


func _test_rarity_boundaries() -> void:
	var cases := {
		2: &"common",
		8: &"common",
		16: &"uncommon",
		64: &"uncommon",
		128: &"rare",
		512: &"rare",
		1024: &"epic",
		4096: &"epic",
		8192: &"legendary",
		16384: &"legendary",
	}
	for value in cases:
		_assert_eq_string(
			str(VisualSkinLib.rarity_for_value(value)),
			str(cases[value]),
			"rarity for %s" % value,
		)


func _test_duplicated_styles() -> void:
	var theme := _theme_fixture
	_assert_true(theme != null, "headless ThemeManager fixture is available")
	if theme == null:
		return

	var first := theme.call("get_visual_style", &"panel", "gothic_crystal") as StyleBox
	var second := theme.call("get_visual_style", &"panel", "gothic_crystal") as StyleBox
	_assert_true(first != null and second != null, "ThemeManager returns panel style copies")
	if first != null and second != null:
		_assert_true(
			first.get_instance_id() != second.get_instance_id(),
			"panel styles are independently duplicated",
		)
		if first is StyleBoxTexture and second is StyleBoxTexture:
			var untouched_color := (second as StyleBoxTexture).modulate_color
			(first as StyleBoxTexture).modulate_color = Color.RED
			_assert_true(
				(second as StyleBoxTexture).modulate_color == untouched_color,
				"mutating one panel copy does not affect another",
			)

	var tile_first := theme.call("get_tile_style_for_value", 128, false, "gothic_crystal") as StyleBox
	var tile_second := theme.call("get_tile_style_for_value", 128, false, "gothic_crystal") as StyleBox
	_assert_true(tile_first != null and tile_second != null, "ThemeManager returns tile style copies")
	if tile_first != null and tile_second != null:
		_assert_true(
			tile_first.get_instance_id() != tile_second.get_instance_id(),
			"tile styles are independently duplicated",
		)


func _test_theme_scope_and_migration() -> void:
	var theme := _theme_fixture
	_assert_true(theme != null, "ThemeManager fixture is available for scope checks")
	if theme == null:
		return
	var procedural: Dictionary = theme.call("get_palette")
	var gothic: Dictionary = theme.call("get_palette", true)
	_assert_true(
		procedural.get("primary") != gothic.get("primary"),
		"meta palette stays procedural while gameplay explicitly opts into Gothic",
	)
	var game_background := str(theme.call("get_background_texture_path", "game"))
	var settings_background := str(theme.call("get_background_texture_path", "settings"))
	_assert_true(not game_background.is_empty(), "game background resolves")
	_assert_true(not settings_background.is_empty(), "settings background resolves")
	_assert_true(game_background != settings_background, "Gothic background is scoped to gameplay")
	_assert_eq_string(
		str(theme.call("_resolve_saved_visual_skin_id", {})),
		"procedural_neon",
		"pre-VisualSkin theme JSON preserves the procedural look",
	)
	_assert_eq_string(
		str(theme.call("_resolve_saved_visual_skin_id", {"visual_skin_id": "missing"})),
		"procedural_neon",
		"invalid saved skin falls back safely",
	)
	_assert_eq_string(
		str(theme.call("_resolve_saved_visual_skin_id", {"visual_skin_id": "gothic_crystal"})),
		"gothic_crystal",
		"valid saved Gothic skin is preserved",
	)
	_assert_true(FileAccess.file_exists("user://lost_number_theme.json"), "first-install skin decision is persisted")
	_assert_eq_string(str(theme.call("_default_visual_skin_for_install")), "gothic_crystal", "fresh install defaults to Gothic")
	for marker_path in [
		"user://lost_number_save.json",
		"user://lost_number_save.bak.json",
		"user://legacy_capacitor_save.json",
		"user://imported_save.json",
	]:
		var marker := FileAccess.open(marker_path, FileAccess.WRITE)
		if marker != null:
			marker.store_string("{}")
			marker.close()
		_assert_eq_string(
			str(theme.call("_default_visual_skin_for_install")),
			"procedural_neon",
			"existing user marker preserves procedural skin: %s" % marker_path,
		)
		DirAccess.remove_absolute(ProjectSettings.globalize_path(marker_path))
	theme.call("set_theme_mode", false)
	_assert_eq_string(str(theme.get("theme_id")), "dawn", "global dawn remains independent from Gothic gameplay")
	var meta_dawn: Dictionary = theme.call("get_palette")
	var gothic_game: Dictionary = theme.call("get_palette", true)
	var gothic_skin := load(SKIN_PATH) as VisualSkinLib
	_assert_true(meta_dawn.get("bg") != gothic_game.get("bg"), "meta dawn palette stays distinct from Gothic gameplay")
	_assert_true(
		gothic_skin != null and gothic_game.get("bg") == gothic_skin.dark_background_color,
		"dark-only Gothic renders its game palette dark without changing global dawn",
	)
	theme.call("set_visual_skin_id", "gothic_crystal")
	_assert_eq_string(str(theme.get("theme_id")), "dawn", "reselecting Gothic does not rewrite meta brightness")
	theme.call("set_skin_profile", 0, false)
	_assert_eq_string(str(theme.get("theme_id")), "dawn", "legacy profile API preserves requested meta brightness")
	var original_index := int(theme.get("background_index"))
	theme.call("cycle_background")
	_assert_eq_string(str(theme.get("visual_skin_id")), "gothic_crystal", "background variant does not replace the component skin")
	theme.set("background_index", original_index)
	theme.call("set_skin_auto", true)
	var settings := root.get_node_or_null("SettingsManager")
	if settings != null and settings.has_method("get_selected_background_path"):
		var active_bucket := str(theme.call("theme_bucket"))
		var selected_auto := str(settings.call("get_selected_background_path", active_bucket))
		var expected_auto := str(theme.call("get_background_texture_path_for", int(theme.call("get_daily_index")), bool(theme.call("is_dark"))))
		_assert_eq_string(selected_auto, expected_auto, "daily background rotation refreshes today's selected path")
	theme.call("apply_background_path", "")
	_assert_eq_int(int(theme.get("background_index")), 0, "restoring the default background resets the procedural preview index")


func _test_settings_visual_controls() -> void:
	var settings_scene := load("res://scenes/Settings.tscn") as PackedScene
	var settings := settings_scene.instantiate() if settings_scene != null else null
	_assert_true(settings != null, "Settings scene instantiates for visual-control checks")
	if settings != null:
		_assert_true(settings.get_node_or_null("Scroll/VBox/SkinPickButton") != null, "Settings keeps a visual-style action")
		_assert_true(settings.get_node_or_null("Scroll/VBox/BackgroundPickButton") != null, "Settings keeps a separate background action")
		_assert_true(settings.get_node_or_null("Scroll/VBox/BackgroundAutoCheck") != null, "Settings keeps independent background rotation")
		settings.free()
	var background_scene := load("res://scenes/BackgroundPreview.tscn") as PackedScene
	var background_preview := background_scene.instantiate() if background_scene != null else null
	_assert_true(background_preview != null, "BackgroundPreview scene instantiates")
	if background_preview != null:
		_assert_true(background_preview.has_method("_on_custom_background"), "background picker exposes custom image import")
		_assert_true(background_preview.has_method("_on_apply"), "background picker exposes explicit apply")
		background_preview.free()


func _test_settings_manual_import() -> void:
	var migration := root.get_node_or_null("LegacySaveMigration")
	_assert_true(migration != null and migration.has_method("try_manual_import"), "manual migration singleton is available")
	if migration == null or not migration.has_method("set_save_manager_for_test"):
		return
	var fake_save := ManualImportSave.new()
	var source_path := "user://imported_save.json"
	var archive_path := source_path + ".imported"
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))
	var source_state := GameState.new()
	source_state.start_new_game(20260716)
	var file := FileAccess.open(source_path, FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify(source_state.to_save_dict()))
		file.close()
	migration.call("set_save_manager_for_test", fake_save)
	var settings := (load("res://scenes/Settings.tscn") as PackedScene).instantiate()
	root.add_child(settings)
	await process_frame
	settings.call("_on_import_legacy")
	var status := settings.get_node_or_null("Scroll/VBox/ImportStatus") as Label
	var i18n := root.get_node_or_null("I18nManager")
	var expected := str(i18n.call("t", "settings_import_legacy_success")) if i18n != null else ""
	_assert_true(fake_save.saved_state != null, "Settings import button invokes LegacySaveMigration")
	_assert_true(status != null and status.text == expected, "Settings reports localized manual-import success")
	_assert_true(not FileAccess.file_exists(source_path) and FileAccess.file_exists(archive_path), "Settings manual import archives its source")
	root.remove_child(settings)
	settings.free()
	migration.call("set_save_manager_for_test", null)
	fake_save.free()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(source_path))
	DirAccess.remove_absolute(ProjectSettings.globalize_path(archive_path))


func _test_visual_scenes_load() -> void:
	for path in VISUAL_SCENES:
		_assert_true(ResourceLoader.exists(path), "visual scene exists: %s" % path)
		var loaded := load(path)
		_assert_true(loaded is PackedScene, "visual scene loads: %s" % path)


func _test_game_board_composition() -> void:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		failed += 1
		push_error("FAIL: Game scene is unavailable for board composition checks")
		return
	var game := packed.instantiate()
	var board := game.get_node_or_null("VBox/BoardView") as Control
	_assert_true(board != null, "Game exposes BoardView")
	if board == null:
		game.free()
		return
	board.get_parent().remove_child(board)
	board.owner = null
	root.add_child(board)
	await process_frame
	await process_frame
	var columns: Array = board.get("_tiles")
	_assert_eq_int(columns.size(), 5, "board keeps five columns")
	var tile_count := 0
	for column in columns:
		tile_count += (column as Array).size()
	_assert_eq_int(tile_count, 40, "board keeps the complete 5x8 tile composition")
	var field_fill := board.get_node_or_null("GothicFieldFill") as CanvasItem
	var field_frame := board.get_node_or_null("GothicFieldFrame") as CanvasItem
	_assert_true(field_fill != null, "board has one unified field fill")
	_assert_true(field_frame != null, "board has one unified perimeter frame")
	_assert_true(board.get_node_or_null("ChainLineLayer") != null, "board has one chain layer")
	_assert_true(board.custom_minimum_size.x <= 408.0, "board fits a 420px portrait viewport")
	if field_frame != null and not columns.is_empty() and not (columns[0] as Array).is_empty():
		var first_tile := (columns[0] as Array)[0] as Control
		var label := first_tile.get_node_or_null("Bg/Label") as CanvasItem
		_assert_true(label != null and field_frame.z_index < label.z_index, "field frame renders below tile labels")

	var state := GameState.new()
	state.start_new_game(20260716)
	for x in 5:
		for y in 8:
			state.board.grid[x][y] = 2
	var long_path: Array[Vector2i] = []
	for y in 8:
		if y % 2 == 0:
			for x in 5:
				long_path.append(Vector2i(x, y))
		else:
			for x in range(4, -1, -1):
				long_path.append(Vector2i(x, y))
	state.selected_path = long_path
	board.call("bind_state", state)
	board.set("_dragging", true)
	board.call("_update_chain_visual")
	await process_frame
	var chain_layer := board.get_node_or_null("ChainLineLayer")
	var points: PackedVector2Array = chain_layer.get("_points") if chain_layer != null else PackedVector2Array()
	_assert_eq_int(points.size(), 40, "maximum 40-cell chain reaches the renderer")
	_assert_eq_int((board.get("_highlighted_cells") as Dictionary).size(), 40, "maximum chain highlights all selected cells")
	if chain_layer != null:
		var child_count := chain_layer.get_child_count()
		for iteration in 120:
			chain_layer.call("set_chain_points", points, "invalid" if iteration % 2 == 0 else "continue")
		_assert_eq_int(chain_layer.get_child_count(), child_count, "repeated long-chain redraws do not accumulate nodes")
	root.remove_child(board)
	board.free()
	game.free()


func _test_game_overlays() -> void:
	var packed := load("res://scenes/Game.tscn") as PackedScene
	if packed == null:
		failed += 1
		push_error("FAIL: Game scene is unavailable for overlay checks")
		return
	var game := packed.instantiate()
	game.set_meta("visual_capture_no_persistence", true)
	root.add_child(game)
	for _frame in 3:
		await process_frame
	var complete := game.get_node_or_null("LevelCompleteOverlay") as CanvasItem
	var complete_modal := game.get_node_or_null("LevelCompleteOverlay/Center/ModalFrame") as PanelContainer
	var complete_title := game.get_node_or_null("LevelCompleteOverlay/Center/ModalFrame/VBox/Title") as Label
	var next_button := game.get_node_or_null("LevelCompleteOverlay/Center/ModalFrame/VBox/ContinueButton") as Button
	var pause := game.get_node_or_null("PauseOverlay") as CanvasItem
	var pause_modal := game.get_node_or_null("PauseOverlay/Center/ModalFrame") as PanelContainer
	_assert_true(complete != null and complete_modal != null, "level-complete overlay exposes a themed modal")
	_assert_true(pause != null and pause_modal != null, "pause overlay exposes a themed modal")
	_assert_true(complete_modal != null and complete_modal.has_theme_stylebox_override("panel"), "level-complete modal receives the visual-skin frame")
	_assert_true(pause_modal != null and pause_modal.has_theme_stylebox_override("panel"), "pause modal receives the visual-skin frame")
	_assert_true(complete_title != null and not complete_title.text.is_empty() and complete_title.text != "level_complete", "level-complete title is localized at runtime")
	_assert_true(next_button != null and next_button.custom_minimum_size.y >= 48.0, "level-complete action meets the touch target")
	game.call("_show_pause")
	_assert_true(pause != null and pause.visible, "pause overlay opens")
	if complete != null:
		complete.visible = true
	_assert_true(complete != null and complete.visible, "level-complete overlay can be shown")
	root.remove_child(game)
	game.free()


func _test_localized_visual_scenes() -> void:
	var settings := root.get_node_or_null("SettingsManager")
	var i18n := root.get_node_or_null("I18nManager")
	_assert_true(settings != null and i18n != null, "runtime localization singletons are available")
	if settings == null or i18n == null:
		return
	var previous_language := str(settings.get("language"))
	var scene_checks := [
		["res://scenes/SkinPreview.tscn", "TitleLabel", "skin_preview_title"],
		["res://scenes/BackgroundPreview.tscn", "TitleLabel", "background_preview_title"],
	]
	for lang in ["uk", "ru", "en"]:
		settings.set("language", lang)
		for check in scene_checks:
			var instance := (load(str(check[0])) as PackedScene).instantiate()
			root.add_child(instance)
			await process_frame
			var label := instance.get_node_or_null(str(check[1])) as Label
			var expected := str(i18n.call("t", str(check[2])))
			_assert_true(label != null and label.text == expected and label.text != str(check[2]), "%s runtime scene resolves %s" % [lang, check[2]])
			root.remove_child(instance)
			instance.free()
		var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate()
		game.set_meta("visual_capture_no_persistence", true)
		root.add_child(game)
		await process_frame
		var complete_title := game.get_node_or_null("LevelCompleteOverlay/Center/ModalFrame/VBox/Title") as Label
		var expected_complete := str(i18n.call("t", "level_complete"))
		_assert_true(complete_title != null and complete_title.text == expected_complete and complete_title.text != "level_complete", "%s Game overlay resolves runtime text" % lang)
		root.remove_child(game)
		game.free()
	settings.set("language", previous_language)


func _test_tile_public_states() -> void:
	var tile_scene := load(TILE_SCENE_PATH) as PackedScene
	if tile_scene == null:
		failed += 1
		push_error("FAIL: Tile scene is unavailable for state checks")
		return

	var tile := tile_scene.instantiate()
	root.add_child(tile)
	await process_frame

	for value in [2, 8, 16, 64, 128, 512, 1024, 4096, 8192]:
		tile.call("setup", Vector2i.ZERO, value)
		_assert_eq_int(int(tile.get("value")), value, "Tile accepts value %s" % value)

	var material := tile.get_node_or_null("Bg/MaterialBackground") as PanelContainer
	_assert_true(material != null, "Tile exposes MaterialBackground layer")
	if material != null:
		_assert_true(material.visible, "active VisualSkin shows the textured tile layer")
		_assert_true(material.has_theme_stylebox_override("panel"), "textured tile layer receives a StyleBox")
	var crystals := tile.get_node_or_null("Bg/CrystalOverlay") as Control
	_assert_true(crystals != null, "Tile exposes CrystalOverlay layer")
	if crystals != null:
		_assert_true(crystals.visible, "legendary tile shows crystal accents")
		var visible_crystals := 0
		for crystal in crystals.get_children():
			if crystal is CanvasItem and (crystal as CanvasItem).visible:
				visible_crystals += 1
		_assert_eq_int(visible_crystals, 3, "legendary tier uses three crystal accents")

	tile.call("set_chain_selected", true, "valid")
	_assert_true(bool(tile.get("_selected")), "Tile selected state")
	var selected_style := tile.get_node("Bg/ChainHighlight").get_theme_stylebox("panel") as StyleBox
	tile.call("set_chain_selected", true, "valid")
	var repeated_style := tile.get_node("Bg/ChainHighlight").get_theme_stylebox("panel") as StyleBox
	_assert_true(
		selected_style != null and repeated_style != null and selected_style.get_instance_id() == repeated_style.get_instance_id(),
		"unchanged chain selection reuses its rendered style",
	)
	var highlight := tile.get_node_or_null("Bg/ChainHighlight") as PanelContainer
	_assert_true(highlight != null and highlight.visible, "valid chain selection renders its highlight")
	tile.call("set_chain_selected", true, "continue")
	_assert_true(str(tile.get("_chain_preview")) == "continue" and highlight.visible, "continue chain state renders distinctly")
	tile.call("set_chain_selected", false)
	tile.call("set_target_highlight", true)
	_assert_true(bool(tile.get("_target")) and highlight.visible, "Tile target state renders its highlight")
	tile.call("set_target_highlight", false)
	tile.call("set_bonus_mode", true)
	_assert_true(bool(tile.get("_bonus_mode")) and highlight.visible, "Tile bonus state renders its highlight")
	tile.call("set_bonus_mode", false)
	tile.call("set_carry", true)
	var crown := tile.get_node_or_null("Bg/CrownIcon") as CanvasItem
	_assert_true(bool(tile.get("_carry")) and crown != null and crown.visible, "Tile carry state renders its crown")
	tile.call("set_frozen", true)
	_assert_true(bool(tile.get("_frozen")) and (crown == null or not crown.visible), "Tile frozen state suppresses the carry crown")
	if material != null:
		_assert_true(material.get_theme_stylebox("panel") is StyleBoxTexture, "frozen state keeps textured material")
	tile.call("set_pressed_visual", true)
	_assert_true(bool(tile.get("_pressed")), "Tile pressed state")
	await process_frame

	root.remove_child(tile)
	tile.free()


func _test_safe_scene_instances() -> void:
	for path in SAFE_INSTANCE_SCENES:
		var packed := load(path) as PackedScene
		if packed == null:
			failed += 1
			push_error("FAIL: safe visual scene cannot instantiate: %s" % path)
			continue
		var instance := packed.instantiate()
		root.add_child(instance)
		await process_frame
		_assert_true(instance.is_inside_tree(), "visual scene instantiates headlessly: %s" % path)
		if path.ends_with("/GameHud.tscn"):
			_assert_neon_buttons_styled(instance)
		elif path.ends_with("/Settings.tscn"):
			_assert_settings_touch_and_language(instance)
		elif path.ends_with("/SkinPreview.tscn"):
			_assert_preview_touch_targets(instance)
			_assert_skin_preview_values(instance)
		elif path.ends_with("/BackgroundPreview.tscn"):
			_assert_preview_touch_targets(instance)
		root.remove_child(instance)
		instance.free()


func _assert_settings_touch_and_language(settings_screen: Node) -> void:
	for option_name in ["SfxVolumeOption", "MusicVolumeOption", "MusicTrackOption", "TileFontSizeOption", "LanguageOption"]:
		var option := settings_screen.get_node_or_null("Scroll/VBox/" + option_name) as OptionButton
		_assert_true(option != null and option.custom_minimum_size.y >= 48.0, "Settings option meets 48px touch target: %s" % option_name)
	var language := settings_screen.get_node_or_null("Scroll/VBox/LanguageOption") as OptionButton
	var i18n := root.get_node_or_null("I18nManager")
	if language != null and i18n != null and i18n.has_method("t"):
		_assert_eq_string(language.get_item_text(0), str(i18n.call("t", "settings_language_ua")), "language selector localizes Ukrainian entry")
		_assert_eq_string(language.get_item_text(1), str(i18n.call("t", "settings_language_ru")), "language selector localizes Russian entry")
		_assert_eq_string(language.get_item_text(2), str(i18n.call("t", "settings_language_en")), "language selector localizes English entry")
		settings_screen.call("_on_language_selected", 1)
		var title := settings_screen.get_node_or_null("Title") as Label
		_assert_true(title != null and title.text == str(i18n.call("t", "settings_title")), "language change refreshes visible Settings text immediately")
		_assert_eq_string(language.get_item_text(1), str(i18n.call("t", "settings_language_ru")), "language entries refresh in the selected locale")
	var theme_button := settings_screen.get_node_or_null("Scroll/VBox/ThemeButton") as Button
	_assert_true(theme_button != null and not theme_button.disabled, "Settings keeps global brightness independent from gameplay skin")


func _assert_skin_preview_values(preview: Node) -> void:
	for value in [2, 16, 128]:
		_assert_true(preview.find_child("Tile%s" % value, true, false) != null, "SkinPreview kit includes tile %s" % value)
	_assert_true(preview.find_child("Tile8192", true, false) == null, "SkinPreview uses the specified 2/16/128 sample set")


func _assert_preview_touch_targets(preview: Node) -> void:
	var row := preview.get_node_or_null("BottomPanel/VBox/ButtonRow")
	_assert_true(row != null, "preview exposes its bottom action row")
	if row == null:
		return
	for child in row.get_children():
		if child is Button:
			_assert_true((child as Button).custom_minimum_size.y >= 48.0, "preview action meets 48px touch target: %s" % child.name)


func _test_low_effects_contract() -> void:
	var existing := root.get_node_or_null("SettingsManager")
	var settings: Node = existing
	var owns_settings := false
	var previous_value := true
	if settings == null:
		settings = LowEffectsSettings.new()
		settings.name = "SettingsManager"
		root.add_child(settings)
		owns_settings = true
	else:
		previous_value = bool(settings.get("bg_effects_enabled"))
		settings.set("bg_effects_enabled", false)

	_assert_true(not bool(_theme_fixture.call("effects_enabled")), "low-effects setting reaches ThemeManager")
	var background := (load("res://scenes/components/BackgroundLayer.tscn") as PackedScene).instantiate()
	root.add_child(background)
	await process_frame
	var effects := background.get_node_or_null("Effects")
	_assert_true(effects != null and effects.get_child_count() == 0, "low-effects background skips particles")
	var tile := (load(TILE_SCENE_PATH) as PackedScene).instantiate()
	root.add_child(tile)
	await process_frame
	tile.call("setup", Vector2i.ZERO, 128)
	tile.call("set_pressed_visual", true)
	_assert_true(tile.get("_lift_tween") == null, "low-effects tile press skips tween")
	var chain := (load("res://scenes/components/ChainLineLayer.tscn") as PackedScene).instantiate()
	root.add_child(chain)
	await process_frame
	var static_points := PackedVector2Array([Vector2(12, 12), Vector2(42, 42), Vector2(72, 18)])
	chain.call("set_chain_points", static_points, "valid")
	_assert_true(not bool(chain.call("_effects_enabled")), "low-effects chain uses the static single-pass path")
	_assert_eq_int((chain.get("_points") as PackedVector2Array).size(), 3, "low-effects chain remains visible and readable")
	root.remove_child(chain)
	chain.free()
	root.remove_child(tile)
	tile.free()
	root.remove_child(background)
	background.free()

	if owns_settings:
		root.remove_child(settings)
		settings.free()
	else:
		settings.set("bg_effects_enabled", previous_value)


func _assert_neon_buttons_styled(instance: Node) -> void:
	var neon_count := 0
	for node in instance.find_children("*", "Button", true, false):
		var script := node.get_script() as Script
		if script == null or not script.resource_path.ends_with("/NeonButton.gd"):
			continue
		neon_count += 1
		_assert_true(
			node.has_theme_stylebox_override("normal"),
			"GameHud NeonButton has a normal style override: %s" % node.name,
		)
	_assert_true(neon_count > 0, "GameHud exposes styled NeonButton controls")


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq_string(actual: String, expected: String, message: String) -> void:
	_assert_true(actual == expected, "%s (got '%s' expected '%s')" % [message, actual, expected])


func _assert_eq_int(actual: int, expected: int, message: String) -> void:
	_assert_true(actual == expected, "%s (got %s expected %s)" % [message, actual, expected])
