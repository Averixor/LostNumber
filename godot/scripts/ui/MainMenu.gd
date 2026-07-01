extends Control

@onready var continue_button: Button = $VBox/ContinueButton
@onready var new_game_button: Button = $VBox/NewGameButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var title_label: Label = $VBox/Title


func _ready() -> void:
	title_label.text = "Lost Number"
	continue_button.text = "Продовжити"
	new_game_button.text = "Нова гра"
	settings_button.text = "Налаштування"
	continue_button.disabled = not SaveManager.has_save()
	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_on_settings)
	AudioManager.play_music("ambient")


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_new_game() -> void:
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
