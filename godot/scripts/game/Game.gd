extends Control

const GameHudScene := preload("res://scenes/components/GameHud.tscn")
const NeonButtonScene := preload("res://scenes/components/NeonButton.tscn")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var game_hud: GameHud = $VBox/GameHud
@onready var board_view: BoardView = $VBox/BoardView
@onready var level_complete_panel: PanelContainer = $LevelCompleteOverlay
@onready var level_complete_modal: PanelContainer = $LevelCompleteOverlay/Center/ModalFrame
@onready var continue_button: Button = $LevelCompleteOverlay/Center/ModalFrame/VBox/ContinueButton
@onready var overlay_title: Label = $LevelCompleteOverlay/Center/ModalFrame/VBox/Title
@onready var pause_overlay: PanelContainer = $PauseOverlay
@onready var pause_modal: PanelContainer = $PauseOverlay/Center/ModalFrame
@onready var pause_title: Label = $PauseOverlay/Center/ModalFrame/VBox/PauseTitle
@onready var resume_button: NeonButton = $PauseOverlay/Center/ModalFrame/VBox/ResumeButton
@onready var pause_menu_button: NeonButton = $PauseOverlay/Center/ModalFrame/VBox/MainMenuButton
@onready var background: ColorRect = $Background

var state: GameState = GameState.new()
var _bonus: BonusManager
var _daily: DailyQuestManager

func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)

func _ready() -> void:
	LnUiLib.apply_screen_background(self, "game", 0.62)
	_bind_theme_updates()
	_apply_theme()
	level_complete_panel.visible = false
	pause_overlay.visible = false
	continue_button.pressed.connect(_on_continue_level)
	LnUiLib.apply_button(continue_button, false, true)
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

	var skip_persistence := bool(get_meta("visual_capture_no_persistence", false))
	var save := _autoload("SaveManager")
	if skip_persistence:
		state.start_new_game(20260715)
	elif save != null and save.has_method("has_save") and bool(save.call("has_save")):
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


func _bind_theme_updates() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		var callback := Callable(self, "_apply_theme")
		if not theme.is_connected("theme_changed", callback):
			theme.connect("theme_changed", callback)


func _style_overlays() -> void:
	level_complete_panel.add_theme_stylebox_override("panel", _overlay_dim_style(0.82))
	pause_overlay.add_theme_stylebox_override("panel", _overlay_dim_style(0.78))
	level_complete_modal.add_theme_stylebox_override("panel", _modal_frame_style())
	pause_modal.add_theme_stylebox_override("panel", _modal_frame_style())

	pause_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE)
	overlay_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE)
	var theme := _autoload("ThemeManager")
	var text_color := LnUiLib.TEXT
	var title_color := LnUiLib.ACCENT_2
	if theme != null:
		if theme.has_method("get_text_color"):
			text_color = theme.call("get_text_color", true) as Color
		if theme.has_method("get_secondary_color"):
			title_color = theme.call("get_secondary_color", true) as Color
	pause_title.add_theme_color_override("font_color", title_color)
	overlay_title.add_theme_color_override("font_color", title_color)
	LnUiLib.add_corner_decorations(level_complete_modal, title_color, 24.0, 2.0)
	LnUiLib.add_corner_decorations(pause_modal, title_color, 24.0, 2.0)
	LnUiLib.apply_button(continue_button, false, true)
	LnUiLib.apply_button(resume_button, false, true)
	LnUiLib.apply_button(pause_menu_button, false, true)
	continue_button.add_theme_color_override("font_color", text_color)
	continue_button.add_theme_color_override("font_hover_color", text_color)
	continue_button.add_theme_color_override("font_pressed_color", text_color)

	pause_title.text = _i18n("pause_title")
	resume_button.text = _i18n("btn_resume")
	pause_menu_button.text = _i18n("hud_menu")
	overlay_title.text = _i18n("level_complete")
	continue_button.text = _i18n("next_level")


func _overlay_dim_style(alpha: float) -> StyleBoxFlat:
	var dim_color := Color(ThemeTokensLib.COLOR_OVERLAY_BG, alpha)
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_overlay_color"):
		dim_color = theme.call("get_overlay_color", alpha, true) as Color
	var style := StyleBoxFlat.new()
	style.bg_color = dim_color
	style.set_content_margin_all(0)
	return style


func _modal_frame_style() -> StyleBox:
	var style: StyleBox
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_style"):
		style = theme.call("get_visual_style", &"modal") as StyleBox
	if style == null:
		style = LnUiLib.make_neon_panel(LnUiLib.ACCENT_2, ThemeTokensLib.RADIUS_OVERLAY)
	else:
		style = style.duplicate(true) as StyleBox
	style.content_margin_left = ThemeTokensLib.SPACE_XL
	style.content_margin_right = ThemeTokensLib.SPACE_XL
	style.content_margin_top = ThemeTokensLib.SPACE_XL
	style.content_margin_bottom = ThemeTokensLib.SPACE_XL
	return style

func _apply_theme() -> void:
	LnUiLib.apply_screen_background(self, "game", 0.62)
	if background != null:
		background.color = Color(0, 0, 0, 0)
	_style_overlays()

func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key

func _exit_tree() -> void:
	_save_game()

func _refresh_hud() -> void:
	var was_bonus_pick := board_view.bonus_pick_mode
	game_hud.refresh(state, Callable(self, "_i18n"))
	overlay_title.text = _i18n("level_complete")
	continue_button.text = _i18n("next_level")
	var bonus_pick := not state.active_bonus.is_empty()
	board_view.bonus_pick_mode = bonus_pick
	if was_bonus_pick != bonus_pick:
		if bonus_pick:
			board_view.refresh_all()
		else:
			board_view.reset_all_highlights()
			board_view.refresh_all()
	_update_sound_button()

func _update_sound_button() -> void:
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
	if bool(get_meta("visual_capture_no_persistence", false)):
		return
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
		board_view.reset_all_highlights()
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
	_exit_bonus_pick_mode()
	_save_game()


func _exit_bonus_pick_mode() -> void:
	board_view.reset_all_highlights()
	board_view.refresh_all()
	_refresh_hud()


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
