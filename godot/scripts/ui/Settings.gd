extends Control

@onready var sound_check: CheckButton = $VBox/SoundCheck
@onready var music_check: CheckButton = $VBox/MusicCheck
@onready var back_button: Button = $VBox/BackButton
@onready var title_label: Label = $VBox/Title


func _ready() -> void:
	title_label.text = "Налаштування"
	sound_check.text = "Звук"
	music_check.text = "Музика"
	back_button.text = "Назад"
	sound_check.button_pressed = SettingsManager.sound_enabled
	music_check.button_pressed = SettingsManager.music_enabled
	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	back_button.pressed.connect(_on_back)


func _on_sound_toggled(enabled: bool) -> void:
	SettingsManager.sound_enabled = enabled
	SettingsManager.music_enabled = enabled
	SettingsManager.save_settings()
	music_check.button_pressed = enabled
	AudioManager.apply_audio_settings()


func _on_music_toggled(enabled: bool) -> void:
	SettingsManager.music_enabled = enabled
	SettingsManager.sound_enabled = enabled
	SettingsManager.save_settings()
	sound_check.button_pressed = enabled
	AudioManager.apply_audio_settings()


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
