extends Control

@onready var board_view: BoardView = $VBox/BoardView
@onready var level_label: Label = $VBox/HUD/LevelLabel
@onready var target_label: Label = $VBox/HUD/TargetLabel
@onready var xp_label: Label = $VBox/HUD/XPLabel
@onready var level_complete_panel: PanelContainer = $LevelCompleteOverlay
@onready var continue_button: Button = $LevelCompleteOverlay/Center/VBox/ContinueButton
@onready var menu_button: Button = $VBox/HUD/MenuButton
@onready var sound_button: Button = $VBox/HUD/SoundButton
@onready var overlay_title: Label = $LevelCompleteOverlay/Center/VBox/Title
@onready var shuffle_button: Button = $VBox/BonusRow/ShuffleButton
@onready var destroy_button: Button = $VBox/BonusRow/DestroyButton
@onready var explosion_button: Button = $VBox/BonusRow/ExplosionButton
@onready var message_label: Label = $VBox/MessageLabel
@onready var background: ColorRect = $Background

var state: GameState = GameState.new()
var _bonus: BonusManager
var _daily: DailyQuestManager


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	_apply_theme()
	level_complete_panel.visible = false
	message_label.text = ""
	continue_button.pressed.connect(_on_continue_level)
	menu_button.pressed.connect(_on_back_to_menu)
	sound_button.pressed.connect(_on_sound_toggle)
	shuffle_button.pressed.connect(func(): _on_bonus_pressed("shuffle"))
	destroy_button.pressed.connect(func(): _on_bonus_pressed("destroy"))
	explosion_button.pressed.connect(func(): _on_bonus_pressed("explosion"))

	board_view.chain_finished.connect(_on_chain_finished)
	board_view.chain_cancelled.connect(_on_chain_cancelled)
	board_view.cell_picked.connect(_on_cell_picked)

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
	_update_sound_button()
	level_complete_panel.visible = state.should_show_level_complete()

	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "ambient")


func _apply_theme() -> void:
	if background == null:
		return
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_to_menu()


func _refresh_hud() -> void:
	level_label.text = _i18n("level_label", [state.current_level + 1])
	target_label.text = _i18n("target_label", [state.format_value(state.get_target())])
	xp_label.text = _i18n("xp_label", [state.format_value(state.xp)])
	overlay_title.text = _i18n("level_complete")
	continue_button.text = _i18n("next_level")
	menu_button.text = _i18n("hud_menu")
	shuffle_button.text = "%s (%d)" % [_i18n("bonus_shuffle"), state.get_bonus_count("shuffle")]
	destroy_button.text = "%s (%d)" % [_i18n("bonus_destroy"), state.get_bonus_count("destroy")]
	explosion_button.text = "%s (%d)" % [_i18n("bonus_explosion"), state.get_bonus_count("explosion")]
	board_view.bonus_pick_mode = not state.active_bonus.is_empty()
	_update_sound_button()


func _update_sound_button() -> void:
	var audio := _autoload("AudioManager")
	var enabled: bool = audio != null and audio.has_method("is_audio_enabled") and bool(audio.call("is_audio_enabled"))
	sound_button.text = "🔊" if enabled else "🔇"


func _show_message(key: String) -> void:
	if key.is_empty():
		message_label.text = ""
		return
	message_label.text = _i18n(key)


func _play_sfx(name: String) -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", name)


func _save_game() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", state)


func _on_sound_toggle() -> void:
	_play_sfx("button")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("toggle_all_audio"):
		audio.call("toggle_all_audio")
	_update_sound_button()


func _on_bonus_pressed(type: String) -> void:
	_play_sfx("button")
	var result := _bonus.activate(type)
	if not result.ok:
		if result.get("reason", "") == "empty":
			_show_message("no_bonus")
			_play_sfx("error")
		return
	_show_message(str(result.get("message_key", "")))
	if type == "shuffle":
		_daily.on_bonus_used()
		_play_sfx("bonus")
		board_view.refresh_all()
		_save_game()
	_refresh_hud()


func _on_cell_picked(cell: Vector2i) -> void:
	var result := _bonus.apply_at_cell(cell)
	if not result.ok:
		_play_sfx("error")
		return
	_daily.on_bonus_used()
	_play_sfx("bonus")
	_show_message(str(result.get("message_key", "")))
	board_view.refresh_all()
	_refresh_hud()
	_save_game()


func _on_chain_finished(_path: Array[Vector2i]) -> void:
	var chain_len := state.selected_path.size()
	var result := state.merge_current_chain()
	if not result.ok:
		_play_sfx("error")
		board_view.refresh_all()
		return

	_play_sfx("merge")
	_daily.on_chain_merged(chain_len)
	_daily.on_session_xp_changed()
	_refresh_hud()
	board_view.refresh_all()
	_save_game()

	var leaderboard := _autoload("LeaderboardService")
	if leaderboard != null and leaderboard.has_method("queue_best_scores"):
		leaderboard.call("queue_best_scores", state.progress)

	if result.get("level_complete", false):
		_daily.on_level_complete()
		_play_sfx("level_complete")
		level_complete_panel.visible = state.should_show_level_complete()


func _on_chain_cancelled() -> void:
	_play_sfx("error")


func _on_continue_level() -> void:
	_play_sfx("button")
	if state.should_show_level_complete():
		state.complete_level_transition()
	else:
		state.sanitize_win_phase()

	level_complete_panel.visible = false
	_refresh_hud()
	board_view.refresh_all()
	_save_game()


func _on_back_to_menu() -> void:
	_play_sfx("button")
	_save_game()
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
