extends Control

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var sound_check: CheckButton = $VBox/SoundCheck
@onready var music_check: CheckButton = $VBox/MusicCheck
@onready var bg_effects_check: CheckButton = $VBox/BgEffectsCheck
@onready var language_option: OptionButton = $VBox/LanguageOption
@onready var leaderboard_check: CheckButton = $VBox/LeaderboardCheck
@onready var theme_button: Button = $VBox/ThemeButton
@onready var import_button: Button = $VBox/ImportLegacyButton
@onready var import_status: Label = $VBox/ImportStatus
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


func _navigate_back() -> void:
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")


func _ready() -> void:
	_apply_background()

	title_label.text = _i18n("settings_title")
	sound_check.text = _i18n("settings_sound")
	music_check.text = _i18n("settings_music")
	bg_effects_check.text = _i18n("settings_bg_effects")
	back_button.text = _i18n("menu_back")
	leaderboard_check.text = _i18n("leaderboard_opt_in")
	theme_button.text = _i18n("settings_theme")
	import_button.text = _i18n("settings_import_legacy")
	import_status.text = ""

	var settings := _autoload("SettingsManager")
	if settings != null:
		sound_check.button_pressed = bool(settings.get("sound_enabled"))
		music_check.button_pressed = bool(settings.get("music_enabled"))
		bg_effects_check.button_pressed = bool(settings.get("bg_effects_enabled"))

	_setup_language_option()
	_load_leaderboard_opt_in()

	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	bg_effects_check.toggled.connect(_on_bg_effects_toggled)
	language_option.item_selected.connect(_on_language_selected)
	leaderboard_check.toggled.connect(_on_leaderboard_toggled)
	theme_button.pressed.connect(_on_theme_cycle)
	import_button.pressed.connect(_on_import_legacy)
	back_button.pressed.connect(_on_back)


func _apply_background() -> void:
	if background == null:
		return
	var theme_mgr := _autoload("ThemeManager")
	var color := ThemeTokensLib.COLOR_BG
	if theme_mgr != null and theme_mgr.has_method("get_background_color"):
		color = theme_mgr.call("get_background_color")
	# Semi-transparent scrim: keeps the App BackgroundLayer art visible.
	background.color = Color(color, 0.6)


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
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")


func _on_music_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("music_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")


func _on_bg_effects_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("bg_effects_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("notify_visual_settings_changed"):
		theme_mgr.call("notify_visual_settings_changed")


func _on_language_selected(index: int) -> void:
	var langs := ["uk", "ru", "en"]
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("language", langs[mini(index, langs.size() - 1)])
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("reload_current"):
		router.call("reload_current")
	else:
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
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("cycle_theme"):
		theme_mgr.call("cycle_theme")
	_apply_background()


func _on_import_legacy() -> void:
	var migration := _autoload("LegacySaveMigration")
	if migration == null:
		import_status.text = _i18n("settings_import_legacy_failed")
		return

	var ok := false
	if OS.has_feature("android") and migration.has_method("try_manual_import"):
		ok = bool(migration.call("try_manual_import"))
	elif OS.has_feature("pc") or OS.has_feature("macos") or OS.has_feature("linux") or OS.has_feature("windows"):
		var dialog := FileDialog.new()
		dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
		dialog.access = FileDialog.ACCESS_FILESYSTEM
		dialog.filters = PackedStringArray(["*.json ; JSON saves"])
		dialog.title = _i18n("settings_import_legacy")
		dialog.size = Vector2i(640, 420)
		add_child(dialog)
		dialog.popup_centered_ratio(0.6)
		var path: String = await dialog.file_selected
		dialog.queue_free()
		if path.is_empty():
			return
		ok = bool(migration.call("import_from_file", path))
	else:
		import_status.text = _i18n("settings_import_legacy_none")
		return

	import_status.text = _i18n("settings_import_legacy_success") if ok else _i18n("settings_import_legacy_failed")


func _on_back() -> void:
	_navigate_back()
