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

var state: GameState = GameState.new()


func _ready() -> void:
	level_complete_panel.visible = false
	continue_button.pressed.connect(_on_continue_level)
	menu_button.pressed.connect(_on_back_to_menu)
	sound_button.pressed.connect(_on_sound_toggle)

	board_view.chain_finished.connect(_on_chain_finished)
	board_view.chain_cancelled.connect(_on_chain_cancelled)

	var loaded_from_save := false
	if SaveManager.has_save():
		var loaded_state = SaveManager.load_game(state)
		if loaded_state != null:
			state = loaded_state
			loaded_from_save = true
		else:
			state.start_new_game()
	else:
		state.start_new_game()

	board_view.bind_state(state)


	_refresh_hud()
	_update_sound_button()
	level_complete_panel.visible = state.should_show_level_complete()


	AudioManager.play_music("ambient")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_on_back_to_menu()


func _refresh_hud() -> void:
	level_label.text = "Рівень %d" % (state.current_level + 1)
	target_label.text = "Ціль: %s" % state.format_value(state.get_target())
	xp_label.text = "XP: %s" % state.format_value(state.xp)
	overlay_title.text = "Рівень пройдено!"
	continue_button.text = "Наступний рівень"
	menu_button.text = "Меню"
	_update_sound_button()


func _update_sound_button() -> void:
	sound_button.text = "🔊" if AudioManager.is_audio_enabled() else "🔇"


func _on_sound_toggle() -> void:
	AudioManager.play_sfx("button")
	AudioManager.toggle_all_audio()
	_update_sound_button()


func _on_chain_finished(_path: Array[Vector2i]) -> void:
	var result := state.merge_current_chain()
	if not result.ok:
		AudioManager.play_sfx("error")
		board_view.refresh_all()
		return

	AudioManager.play_sfx("merge")
	_refresh_hud()
	board_view.refresh_all()
	SaveManager.save_game(state)

	if result.get("level_complete", false):
		AudioManager.play_sfx("level_complete")
		level_complete_panel.visible = state.should_show_level_complete()


func _on_chain_cancelled() -> void:
	AudioManager.play_sfx("error")


func _on_continue_level() -> void:

	AudioManager.play_sfx("button")
	var pending_before := state.pending_transition.duplicate(true)
	if state.should_show_level_complete():
		state.complete_level_transition()
	else:
		state.sanitize_win_phase()


	level_complete_panel.visible = false
	_refresh_hud()
	board_view.refresh_all()
	SaveManager.save_game(state)



func _on_back_to_menu() -> void:
	AudioManager.play_sfx("button")
	SaveManager.save_game(state)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
