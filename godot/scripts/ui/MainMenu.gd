extends Control

@onready var continue_button: Button = $VBox/ContinueButton
@onready var new_game_button: Button = $VBox/NewGameButton
@onready var settings_button: Button = $VBox/SettingsButton
@onready var achievements_button: Button = $VBox/AchievementsButton
@onready var daily_button: Button = $VBox/DailyButton
@onready var wheel_button: Button = $VBox/WheelButton
@onready var title_label: Label = $VBox/Title
@onready var background: ColorRect = $Background


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")

	title_label.text = _i18n("app_title")
	continue_button.text = _i18n("menu_continue")
	new_game_button.text = _i18n("menu_new_game")
	settings_button.text = _i18n("menu_settings")
	achievements_button.text = _i18n("menu_achievements")
	daily_button.text = _i18n("menu_daily")
	wheel_button.text = _i18n("menu_wheel")

	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))
	continue_button.disabled = not has_save

	continue_button.pressed.connect(_on_continue)
	new_game_button.pressed.connect(_on_new_game)
	settings_button.pressed.connect(_on_settings)
	achievements_button.pressed.connect(_on_achievements)
	daily_button.pressed.connect(_on_daily)
	wheel_button.pressed.connect(_on_wheel)

	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "ambient")


func _on_continue() -> void:
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_new_game() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("delete_save"):
		save.call("delete_save")
	get_tree().change_scene_to_file("res://scenes/Game.tscn")


func _on_settings() -> void:
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_achievements() -> void:
	get_tree().change_scene_to_file("res://scenes/Achievements.tscn")


func _on_daily() -> void:
	get_tree().change_scene_to_file("res://scenes/DailyQuests.tscn")


func _on_wheel() -> void:
	get_tree().change_scene_to_file("res://scenes/Wheel.tscn")
