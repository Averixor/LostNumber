extends Control

@onready var sound_check: CheckButton = $VBox/SoundCheck
@onready var music_check: CheckButton = $VBox/MusicCheck
@onready var back_button: Button = $VBox/BackButton


func _ready() -> void:
	sound_check.button_pressed = SettingsManager.sound_enabled
	music_check.button_pressed = SettingsManager.music_enabled
	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	back_button.pressed.connect(_on_back)


func _on_sound_toggled(on: bool) -> void:
	SettingsManager.sound_enabled = on
	SettingsManager.save_settings()


func _on_music_toggled(on: bool) -> void:
	SettingsManager.music_enabled = on
	SettingsManager.save_settings()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
