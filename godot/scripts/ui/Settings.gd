extends Control

@onready var sound_check: CheckButton = $VBox/SoundCheck
@onready var music_check: CheckButton = $VBox/MusicCheck
@onready var language_option: OptionButton = $VBox/LanguageOption
@onready var leaderboard_check: CheckButton = $VBox/LeaderboardCheck
@onready var theme_button: Button = $VBox/ThemeButton
@onready var back_button: Button = $VBox/BackButton
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

	title_label.text = _i18n("settings_title")
	sound_check.text = _i18n("settings_sound")
	music_check.text = _i18n("settings_music")
	back_button.text = _i18n("menu_back")
	leaderboard_check.text = _i18n("leaderboard_opt_in")
	theme_button.text = _i18n("menu_settings") + " / Theme"

	var settings := _autoload("SettingsManager")
	if settings != null:
		sound_check.button_pressed = bool(settings.get("sound_enabled"))
		music_check.button_pressed = bool(settings.get("music_enabled"))

	_setup_language_option()
	_load_leaderboard_opt_in()

	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	language_option.item_selected.connect(_on_language_selected)
	leaderboard_check.toggled.connect(_on_leaderboard_toggled)
	theme_button.pressed.connect(_on_theme_cycle)
	back_button.pressed.connect(_on_back)


func _setup_language_option() -> void:
	language_option.clear()
	language_option.add_item(_i18n("lang_uk"), 0)
	language_option.add_item(_i18n("lang_ru"), 1)
	language_option.add_item(_i18n("lang_en"), 2)

	var language := "uk"
	var settings := _autoload("SettingsManager")
	if settings != null:
		language = str(settings.get("language"))
	var idx: int = int({"uk": 0, "ru": 1, "en": 2}.get(language, 0))
	language_option.select(idx)


func _load_leaderboard_opt_in() -> void:
	var save := _autoload("SaveManager")
	if save == null or not save.has_method("has_save") or not bool(save.call("has_save")):
		return
	var state = save.call("load_game")
	if state != null:
		leaderboard_check.button_pressed = bool(state.progress.leaderboard.get("opt_in", false))


func _on_sound_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("sound_enabled", enabled)
		settings.set("music_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	music_check.button_pressed = enabled
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")


func _on_music_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("music_enabled", enabled)
		settings.set("sound_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	sound_check.button_pressed = enabled
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")


func _on_language_selected(index: int) -> void:
	var langs := ["uk", "ru", "en"]
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("language", langs[mini(index, langs.size() - 1)])
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_leaderboard_toggled(enabled: bool) -> void:
	var save := _autoload("SaveManager")
	if save == null or not save.has_method("has_save") or not bool(save.call("has_save")):
		return
	var state = save.call("load_game")
	if state != null:
		state.progress.leaderboard["opt_in"] = enabled
		if save.has_method("save_game"):
			save.call("save_game", state)


func _on_theme_cycle() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("cycle_theme"):
		theme.call("cycle_theme")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
