extends Control

@onready var body: RichTextLabel = $Scroll/Body
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Title
@onready var background: ColorRect = $Background


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _navigate_back() -> void:
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("btn_about")
	back_button.text = _i18n("menu_back")
	back_button.pressed.connect(_on_back)

	var version := str(ProjectSettings.get_setting("application/config/version", ""))
	body.text = "[center][b]%s[/b][/center]\n\n%s\n\n• %s\n• %s\n• %s\n• %s\n\n%s" % [
		_i18n("game_logo"),
		_i18n("main_subtitle"),
		_i18n("feature_1"),
		_i18n("feature_2"),
		_i18n("feature_3"),
		_i18n("feature_4"),
		_i18n("version_label") % version,
	]


func _on_back() -> void:
	var audio := _autoload("AudioManager")
	if audio != null:
		audio.call("play_sfx", "button_click")
	_navigate_back()
