extends Control

const GameHudScene := preload("res://scenes/components/GameHud.tscn")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var game_hud: GameHud = $VBox/GameHud
@onready var board_view: BoardView = $VBox/BoardView
@onready var level_complete_panel: PanelContainer = $LevelCompleteOverlay
@onready var continue_button: Button = $LevelCompleteOverlay/Center/VBox/ContinueButton
@onready var overlay_title: Label = $LevelCompleteOverlay/Center/VBox/Title
@onready var background: ColorRect = $Background

var state: GameState = GameState.new()
var _bonus: BonusManager
var _daily: DailyQuestManager

func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)

func _ready() -> void:
	_apply_theme()
	level_complete_panel.visible = false
	continue_button.pressed.connect(_on_continue_level)
	LnUiLib.apply_button(continue_button)
	game_hud.menu_pressed.connect(_on_back_to_menu)
	game_hud.sound_pressed.connect(_on_sound_toggle)
	game_hud.bonus_pressed.connect(_on_bonus_pressed)
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
	level_complete_panel.visible = state.should_show_level_complete()
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "ambient")

func _apply_theme() -> void:
	LnUiLib.set_background(self, "res://assets/ui/backgrounds/dark/menu-bg-3.png", 0.68)
	if background != null:
		background.color = Color(0, 0, 0, 0)

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

func _save_game() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", state)

func _on_sound_toggle() -> void:
	_play_sfx("button_click")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("toggle_all_audio"):
		audio.call("toggle_all_audio")
	_update_sound_button()

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
	board_view.refresh_all()
	_refresh_hud()
	_save_game()

func _on_chain_finished(_path: Array[Vector2i]) -> void:
	var chain_len := state.selected_path.size()
	var result := state.merge_current_chain()
	if not result.ok:
		_play_sfx("invalid")
		board_view.refresh_all()
		return
	_play_sfx("merge")
	_play_sfx("chain_complete")
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
		_play_sfx("level_up")
		_play_sfx("victory")
		level_complete_panel.visible = state.should_show_level_complete()

func _on_chain_cancelled() -> void:
	_play_sfx("invalid")

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
	_save_game()
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")
