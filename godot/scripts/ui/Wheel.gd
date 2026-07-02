extends Control

@onready var spin_button: Button = $VBox/SpinButton
@onready var result_label: Label = $VBox/ResultLabel
@onready var back_button: Button = $VBox/BackButton
@onready var title_label: Label = $VBox/Title
@onready var background: ColorRect = $Background

var _state: GameState
var _wheel: WheelManager
var _daily: DailyQuestManager


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _play_sfx(name: String) -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", name)


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")

	title_label.text = _i18n("wheel_title")
	spin_button.text = _i18n("wheel_spin")
	back_button.text = _i18n("menu_back")
	result_label.text = ""
	spin_button.pressed.connect(_on_spin)
	back_button.pressed.connect(_on_back)
	_state = _load_state()
	_wheel = WheelManager.new(_state)
	_daily = DailyQuestManager.new(_state)
	_daily.ensure_loaded()


func _on_spin() -> void:
	_play_sfx("button")
	var result := _wheel.spin()
	if not result.ok:
		return
	var sector: Dictionary = result.sector
	result_label.text = str(sector.get("label", ""))
	_daily.on_wheel_spun()
	_play_sfx("bonus")

	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", _state)


func _load_state() -> GameState:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var loaded = save.call("load_game")
		if loaded != null:
			return loaded
	var state := GameState.new()
	state.start_new_game()
	return state


func _on_back() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", _state)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
