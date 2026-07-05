extends Control

const GameHudScene := preload("res://scenes/components/GameHud.tscn")
const NeonButtonScene := preload("res://scenes/components/NeonButton.tscn")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var game_hud: GameHud = $VBox/GameHud
@onready var board_view: BoardView = $VBox/BoardView
@onready var level_complete_panel: PanelContainer = $LevelCompleteOverlay
@onready var continue_button: Button = $LevelCompleteOverlay/Center/VBox/ContinueButton
@onready var overlay_title: Label = $LevelCompleteOverlay/Center/VBox/Title
@onready var pause_overlay: PanelContainer = $PauseOverlay
@onready var pause_title: Label = $PauseOverlay/Center/VBox/PauseTitle
@onready var resume_button: NeonButton = $PauseOverlay/Center/VBox/ResumeButton
@onready var pause_menu_button: NeonButton = $PauseOverlay/Center/VBox/MainMenuButton
@onready var background: ColorRect = $Background

var state: GameState = GameState.new()
var _bonus: BonusManager
var _daily: DailyQuestManager


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("game"))
	_apply_theme()
	level_complete_panel.visible = false
	pause_overlay.visible = false
	continue_button.pressed.connect(_on_continue_level)
	resume_button.pressed.connect(_on_pause_resume)
	pause_menu_button.pressed.connect(_on_back_to_menu)

	game_hud.menu_pressed.connect(_on_menu_pressed)
	game_hud.sound_pressed.connect(_on_sound_toggle)
	game_hud.save_pressed.connect(_on_save_pressed)
	game_hud.theme_pressed.connect(_on_theme_toggle)
	game_hud.bonus_pressed.connect(_on_bonus_pressed)

	board_view.chain_finished.connect(_on_chain_finished)
	board_view.chain_cancelled.connect(_on_chain_cancelled)
	board_view.cell_picked.connect(_on_cell_picked)
	board_view.chain_updated.connect(_on_chain_updated)

	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var loaded_state = save.call("load_game", state)
		if loaded_state != null:
			state = loaded_state
		else:
			state.start_new_game()
	else:
		state.start_new_game()

	_bonus = BonusManager.new(state)
	_daily = DailyQuestManager.new(state)
	_daily.ensure_loaded()
	state.progress.flush_leaderboard_queue()

	board_view.bind_state(state)
	_refresh_hud()
	_style_pause_overlay()
	level_complete_panel.visible = state.should_show_level_complete()

	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_settings_music"):
		audio.call("play_settings_music")

	_animate_entrance()


func _animate_entrance() -> void:
	await LnUiLib.animate_entrance([game_hud, board_view])


func handle_back() -> bool:
	if pause_overlay.visible:
		_hide_pause()
		return true
	if level_complete_panel.visible:
		return true
	_show_pause()
	return true


func _style_pause_overlay() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ThemeTokensLib.COLOR_OVERLAY_BG, 0.92)
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_OVERLAY)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(20)
	pause_overlay.add_theme_stylebox_override("panel", style)
	pause_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE)
	pause_title.text = _i18n("pause_title")
	resume_button.text = _i18n("btn_resume")
	pause_menu_button.text = _i18n("hud_menu")


func _apply_theme() -> void:
	if background == null:
		return
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _exit_tree() -> void:
	_save_game()


func _refresh_hud() -> void:
	game_hud.refresh(state, Callable(self, "_i18n"))
	overlay_title.text = _i18n("level_complete")
	continue_button.text = _i18n("next_level")
	board_view.bonus_pick_mode = not state.active_bonus.is_empty()
	_update_sound_button()


func _update_sound_button() -> void:
	var audio := _autoload("AudioManager")
	var settings := _autoload("SettingsManager")
	var sound_on := settings == null or bool(settings.get("sound_enabled"))
	var music_on := settings == null or bool(settings.get("music_enabled"))
	game_hud.set_sound_icon(sound_on or music_on)


func _show_message(key: String) -> void:
	game_hud.set_message("" if key.is_empty() else _i18n(key))


func _play_sfx(name: String) -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", name)


func _maybe_vibrate(duration_ms: int = 35) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null and not bool(settings.get("sound_enabled")):
		return
	Input.vibrate_handheld(duration_ms)


func _save_game() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", state)
		game_hud.flash_save_indicator(_i18n("save_indicator"))


func _show_pause() -> void:
	pause_overlay.visible = true


func _hide_pause() -> void:
	pause_overlay.visible = false


func _on_pause_resume() -> void:
	_play_sfx("button_click")
	_hide_pause()


func _on_menu_pressed() -> void:
	_play_sfx("button_click")
	_show_pause()


func _on_sound_toggle() -> void:
	_play_sfx("button_click")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("toggle_all_audio"):
		audio.call("toggle_all_audio")
	_update_sound_button()


func _on_save_pressed() -> void:
	_play_sfx("button_click")
	_save_game()


func _on_theme_toggle() -> void:
	_play_sfx("button_click")
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("cycle_theme"):
		theme.call("cycle_theme")


func _on_bonus_pressed(type: String) -> void:
	_play_sfx("button_click")
	var result := _bonus.activate(type)
	if not result.ok:
		if result.get("reason", "") == "empty":
			_show_message("no_bonus")
			_play_sfx("invalid")
		return
	_show_message(str(result.get("message_key", "")))
	if type == "shuffle":
		_daily.on_bonus_used()
		_play_sfx("button_click")
		board_view.refresh_all()
		_save_game()
	_refresh_hud()


func _on_cell_picked(cell: Vector2i) -> void:
	var result := _bonus.apply_at_cell(cell)
	if not result.ok:
		_play_sfx("invalid")
		return
	_daily.on_bonus_used()
	_play_sfx("button_click")
	_show_message(str(result.get("message_key", "")))
	board_view.reset_all_highlights()
	board_view.refresh_all()
	_refresh_hud()
	_save_game()


func _on_chain_updated(can_finish: bool) -> void:
	game_hud.update_chain_sum(state, can_finish, board_view.is_chain_dragging())
	board_view.update_preview_bubble(can_finish, board_view.get_chain_pointer_local())


func _on_chain_finished(path: Array[Vector2i]) -> void:
	var chain_len := path.size()
	var float_pos := Vector2.INF
	if not path.is_empty():
		float_pos = board_view.get_cell_center_local(path.back())
	var result := state.merge_current_chain(true)
	if not result.ok:
		_play_sfx("invalid")
		board_view.reset_all_highlights()
		board_view.refresh_all()
		return

	_play_sfx("merge")
	_play_sfx("chain_complete")
	_maybe_vibrate(55)
	var removed: Array = result.get("removed", [])
	var anchor: Vector2i = result.get("anchor", Vector2i.ZERO)
	await board_view.animate_merge_settle(removed, anchor)
	var xp_earned := int(result.get("xp", 0)) + int(result.get("surplus", 0))
	if xp_earned > 0 and float_pos.is_finite():
		LnUiLib.show_floating_text(board_view, "+%d XP" % xp_earned, float_pos, LnUiLib.XP)
	_daily.on_chain_merged(chain_len)
	_daily.on_session_xp_changed()
	_refresh_hud()
	board_view.reset_all_highlights()
	_save_game()

	var leaderboard := _autoload("LeaderboardService")
	if leaderboard != null and leaderboard.has_method("queue_best_scores"):
		leaderboard.call("queue_best_scores", state.progress)

	if result.get("level_complete", false):
		_daily.on_level_complete()
		_play_sfx("level_up")
		_play_sfx("victory")
		level_complete_panel.visible = state.should_show_level_complete()


func _on_chain_cancelled() -> void:
	_play_sfx("invalid")
	board_view.reset_all_highlights()
	board_view.refresh_all()
	game_hud.update_chain_sum(state, false)


func _on_continue_level() -> void:
	_play_sfx("button_click")
	if state.should_show_level_complete():
		state.complete_level_transition()
	else:
		state.sanitize_win_phase()

	level_complete_panel.visible = false
	_refresh_hud()
	board_view.refresh_all()
	_save_game()


func _on_back_to_menu() -> void:
	_play_sfx("button_click")
	_hide_pause()
	_save_game()
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")
