extends Control

@onready var new_game_button: Button = $VBox/NewGameButton
@onready var continue_button: Button = $VBox/ContinueButton
@onready var settings_button: Button = $VBox/SettingsButton


func _ready() -> void:
	continue_button.visible = SaveManager.has_save()
	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_on_settings)


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_new_game() -> void:
	SaveManager.delete_save()
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")
