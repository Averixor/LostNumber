extends Control

@onready var board_view: BoardView = $VBox/BoardView
@onready var level_label: Label = $VBox/HUD/LevelLabel
@onready var target_label: Label = $VBox/HUD/TargetLabel
@onready var xp_label: Label = $VBox/HUD/XPLabel
@onready var level_complete_panel: PanelContainer = $LevelCompleteOverlay
@onready var continue_button: Button = $LevelCompleteOverlay/VBox/ContinueButton
@onready var menu_button: Button = $VBox/HUD/MenuButton

var state: GameState = GameState.new()


func _ready() -> void:
	level_complete_panel.visible = false
	continue_button.pressed.connect(_on_continue_level)
	menu_button.pressed.connect(_on_back_to_menu)

	board_view.bind_state(state)
	board_view.chain_finished.connect(_on_chain_finished)
	board_view.chain_cancelled.connect(_on_chain_cancelled)

	if SaveManager.has_save():
		SaveManager.load_game(state)
	else:
		state.start_new_game()

	_refresh_hud()
	board_view.refresh_all()


func _refresh_hud() -> void:
	level_label.text = "Level %d" % (state.current_level + 1)
	target_label.text = "Target: %d" % state.get_target()
	xp_label.text = "XP: %d" % state.xp


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
		level_complete_panel.visible = true


func _on_chain_cancelled() -> void:
	AudioManager.play_sfx("error")


func _on_continue_level() -> void:
	state.complete_level_transition()
	level_complete_panel.visible = false
	_refresh_hud()
	board_view.refresh_all()
	SaveManager.save_game(state)


func _on_back_to_menu() -> void:
	SaveManager.save_game(state)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
