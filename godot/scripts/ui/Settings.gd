extends Control

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const MUSIC_TRACKS := ["ambient", "crystal_flow", "digital_horizon", "neon_drift", "stellar_logic"]
const VOLUME_LEVELS := [0.25, 0.5, 0.75, 1.0]
const TILE_FONT_SCALES := [0.85, 1.0, 1.1, 1.2]

@onready var scroll: ScrollContainer = get_node_or_null("Scroll") as ScrollContainer
@onready var vbox: VBoxContainer = get_node_or_null("Scroll/VBox") as VBoxContainer
@onready var sound_check: CheckButton = get_node_or_null("Scroll/VBox/SoundCheck") as CheckButton
@onready var music_check: CheckButton = get_node_or_null("Scroll/VBox/MusicCheck") as CheckButton
@onready var sfx_volume_option: OptionButton = get_node_or_null("Scroll/VBox/SfxVolumeOption") as OptionButton
@onready var music_volume_option: OptionButton = get_node_or_null("Scroll/VBox/MusicVolumeOption") as OptionButton
@onready var music_track_option: OptionButton = get_node_or_null("Scroll/VBox/MusicTrackOption") as OptionButton
@onready var bg_effects_check: CheckButton = get_node_or_null("Scroll/VBox/BgEffectsCheck") as CheckButton
@onready var tile_font_size_option: OptionButton = get_node_or_null("Scroll/VBox/TileFontSizeOption") as OptionButton
@onready var language_option: OptionButton = get_node_or_null("Scroll/VBox/LanguageOption") as OptionButton
@onready var leaderboard_check: CheckButton = get_node_or_null("Scroll/VBox/LeaderboardCheck") as CheckButton
@onready var theme_button: Button = get_node_or_null("Scroll/VBox/ThemeButton") as Button
@onready var skin_label: Label = get_node_or_null("Scroll/VBox/SkinLabel") as Label
@onready var skin_pick_button: Button = get_node_or_null("Scroll/VBox/SkinPickButton") as Button
@onready var background_label: Label = get_node_or_null("Scroll/VBox/BackgroundLabel") as Label
@onready var background_pick_button: Button = get_node_or_null("Scroll/VBox/BackgroundPickButton") as Button
@onready var background_auto_check: CheckButton = get_node_or_null("Scroll/VBox/BackgroundAutoCheck") as CheckButton
@onready var import_button: Button = get_node_or_null("Scroll/VBox/ImportLegacyButton") as Button
@onready var import_status: Label = get_node_or_null("Scroll/VBox/ImportStatus") as Label
@onready var exit_button: Button = get_node_or_null("Scroll/VBox/ExitButton") as Button
@onready var back_button: Button = get_node_or_null("BackButton") as Button
@onready var title_label: Label = get_node_or_null("Title") as Label
@onready var background: ColorRect = get_node_or_null("Background") as ColorRect


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("settings"))
	_setup_labels()
	_setup_options()
	_load_settings()
	_style_controls()
	_connect_signals()
	call_deferred("_adapt_layout")


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_adapt_layout()


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _get_value(obj: Object, key: String, default_value):
	if obj == null:
		return default_value
	var value = obj.get(key)
	if value == null:
		return default_value
	return value


func _settings():
	return _autoload("SettingsManager")


func _theme():
	return _autoload("ThemeManager")


func _audio():
	return _autoload("AudioManager")


func _save():
	var settings = _settings()
	if settings != null and settings.has_method("save_settings"):
		settings.call("save_settings")
	LnUiLib.show_toast(self, _i18n("save_indicator"))


func _setup_labels() -> void:
	if title_label != null:
		title_label.text = _i18n("settings_title")
	if sound_check != null:
		sound_check.text = _i18n("settings_sound")
	if music_check != null:
		music_check.text = _i18n("settings_music")
	if bg_effects_check != null:
		bg_effects_check.text = _i18n("settings_bg_effects")
	if back_button != null:
		back_button.text = _i18n("menu_back")
	if leaderboard_check != null:
		leaderboard_check.text = _i18n("leaderboard_opt_in")
	if skin_label != null:
		skin_label.text = _i18n("settings_visual_skin_label")
	if skin_pick_button != null:
		skin_pick_button.text = _i18n("settings_visual_skin_pick")
	if background_label != null:
		background_label.text = _i18n("settings_background_label")
	if background_pick_button != null:
		background_pick_button.text = _i18n("settings_pick_background")
	if background_auto_check != null:
		background_auto_check.text = _i18n("settings_background_auto")
	if import_button != null:
		import_button.text = _i18n("settings_import_legacy")
	if import_status != null:
		import_status.text = ""
	if exit_button != null:
		exit_button.text = _i18n("btn_exit")

	_ensure_option_label(sfx_volume_option, "settings_sfx_volume_label")
	_ensure_option_label(music_volume_option, "settings_music_volume_label")
	_ensure_option_label(music_track_option, "settings_music_track_label")
	_ensure_option_label(tile_font_size_option, "settings_tile_font_size_label")
	_ensure_option_label(language_option, "settings_language_label")


func _ensure_option_label(option: OptionButton, key: String) -> void:
	if option == null or option.get_parent() == null:
		return
	var parent := option.get_parent()
	var label_name := "Label_%s" % option.name
	var label := parent.get_node_or_null(label_name) as Label
	if label == null:
		label = Label.new()
		label.name = label_name
		parent.add_child(label)
		parent.move_child(label, option.get_index())
	label.text = _i18n(key)
	label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY)
	label.add_theme_color_override("font_color", ThemeTokensLib.COLOR_TEXT)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	if font != null:
		label.add_theme_font_override("font", font)


func _setup_options() -> void:
	if language_option != null:
		language_option.clear()
		language_option.add_item(_i18n("settings_language_ua"))
		language_option.add_item(_i18n("settings_language_ru"))
		language_option.add_item(_i18n("settings_language_en"))

	if sfx_volume_option != null:
		sfx_volume_option.clear()
	if music_volume_option != null:
		music_volume_option.clear()

	for level in VOLUME_LEVELS:
		var pct := int(round(level * 100.0))
		if sfx_volume_option != null:
			sfx_volume_option.add_item("%d%%" % pct)
		if music_volume_option != null:
			music_volume_option.add_item("%d%%" % pct)

	if music_track_option != null:
		music_track_option.clear()
		for track in MUSIC_TRACKS:
			var track_key := "settings_music_track_%s" % track
			var track_label := _i18n(track_key)
			music_track_option.add_item(track_label if track_label != track_key else track.capitalize())

	if tile_font_size_option != null:
		tile_font_size_option.clear()
		var font_keys := [
			"settings_tile_font_85",
			"settings_tile_font_100",
			"settings_tile_font_110",
			"settings_tile_font_120",
		]
		for i in TILE_FONT_SCALES.size():
			var scale: float = TILE_FONT_SCALES[i]
			var key: String = font_keys[i] if i < font_keys.size() else ""
			var label := _i18n(key) if not key.is_empty() else "%d%%" % int(round(scale * 100.0))
			tile_font_size_option.add_item(label if label != key else "%d%%" % int(round(scale * 100.0)))


func _load_settings() -> void:
	var settings = _settings()

	if sound_check != null:
		sound_check.button_pressed = bool(_get_value(settings, "sound_enabled", true))
	if music_check != null:
		music_check.button_pressed = bool(_get_value(settings, "music_enabled", true))
	if bg_effects_check != null:
		bg_effects_check.button_pressed = bool(_get_value(settings, "bg_effects_enabled", true))

	if sfx_volume_option != null:
		sfx_volume_option.select(_volume_to_index(float(_get_value(settings, "sfx_volume", 0.5))))
	if music_volume_option != null:
		music_volume_option.select(_volume_to_index(float(_get_value(settings, "music_volume", 0.5))))

	if music_track_option != null:
		var track := str(_get_value(settings, "music_track", "ambient"))
		music_track_option.select(maxi(0, MUSIC_TRACKS.find(track)))

	if tile_font_size_option != null:
		var scale := float(_get_value(settings, "tile_font_scale", 1.0))
		tile_font_size_option.select(_scale_to_index(scale))

	if language_option != null:
		var lang := str(_get_value(settings, "language", "uk"))
		var idx := 0
		if lang == "ru":
			idx = 1
		elif lang == "en":
			idx = 2
		language_option.select(idx)

	var theme_mgr = _theme()
	if background_auto_check != null:
		background_auto_check.button_pressed = bool(_get_value(theme_mgr, "skin_auto", false))

	_refresh_theme_button()


func _style_controls() -> void:
	if background != null:
		background.color = Color(0, 0, 0, 0.55)

	if title_label != null:
		LnUiLib.apply_title(title_label, 24)

	for btn in [back_button, theme_button, skin_pick_button, background_pick_button, import_button, exit_button]:
		if btn != null:
			LnUiLib.apply_button(btn, btn.disabled)

	if back_button != null:
		LnUiLib.apply_button_icon(back_button, "back.png")

	for check in [sound_check, music_check, bg_effects_check, leaderboard_check, background_auto_check]:
		if check != null:
			LnUiLib.apply_toggle_switch(check, false)

	for option in [sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option]:
		if option != null:
			LnUiLib.apply_option_row_style(option, false)

	_apply_unified_font()


func _apply_unified_font() -> void:
	## One theme font family + body size across Settings labels, toggles, options.
	var font: Font = get_theme_default_font()
	if font == null:
		font = ThemeDB.fallback_font
	var body_size := ThemeTokensLib.FONT_SIZE_BODY
	var title_size := ThemeTokensLib.FONT_SIZE_TITLE + 4

	if title_label != null:
		if font != null:
			title_label.add_theme_font_override("font", font)
		title_label.add_theme_font_size_override("font_size", title_size)

	var controls: Array = [
		sound_check, music_check, bg_effects_check, leaderboard_check, background_auto_check,
		sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option,
		theme_button, skin_pick_button, background_pick_button, import_button, exit_button, back_button,
		skin_label, background_label, import_status,
	]
	if vbox != null:
		for child in vbox.get_children():
			if child is Label and child not in controls:
				controls.append(child)

	for ctrl in controls:
		if ctrl == null:
			continue
		if font != null:
			ctrl.add_theme_font_override("font", font)
		ctrl.add_theme_font_size_override("font_size", body_size)
		ctrl.add_theme_color_override("font_color", ThemeTokensLib.COLOR_TEXT)


func _connect_signals() -> void:
	if sound_check != null:
		sound_check.toggled.connect(_on_sound_toggled)
	if music_check != null:
		music_check.toggled.connect(_on_music_toggled)
	if bg_effects_check != null:
		bg_effects_check.toggled.connect(_on_bg_effects_toggled)
	if sfx_volume_option != null:
		sfx_volume_option.item_selected.connect(_on_sfx_volume_selected)
	if music_volume_option != null:
		music_volume_option.item_selected.connect(_on_music_volume_selected)
	if music_track_option != null:
		music_track_option.item_selected.connect(_on_music_track_selected)
	if tile_font_size_option != null:
		tile_font_size_option.item_selected.connect(_on_tile_font_size_selected)
	if language_option != null:
		language_option.item_selected.connect(_on_language_selected)
	if leaderboard_check != null:
		leaderboard_check.toggled.connect(_on_leaderboard_toggled)
	if theme_button != null:
		theme_button.pressed.connect(_on_theme_cycle)
	if skin_pick_button != null:
		skin_pick_button.pressed.connect(_on_skin_pick_pressed)
	if background_pick_button != null:
		background_pick_button.pressed.connect(_on_background_pick_pressed)
	if background_auto_check != null:
		background_auto_check.toggled.connect(_on_background_auto_toggled)
	if import_button != null:
		import_button.pressed.connect(_on_import_legacy)
	if exit_button != null:
		exit_button.pressed.connect(_on_exit)
	if back_button != null:
		back_button.pressed.connect(_on_back)


func _adapt_layout() -> void:
	if not is_node_ready():
		return

	if scroll != null:
		scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	if vbox != null:
		vbox.add_theme_constant_override("separation", 8)
		for child in vbox.get_children():
			if child is Control:
				(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _volume_to_index(volume: float) -> int:
	var pct := int(round(clampf(volume, 0.0, 1.0) * 100.0))
	if pct <= 25:
		return 0
	elif pct <= 50:
		return 1
	elif pct <= 75:
		return 2
	return 3


func _scale_to_index(scale: float) -> int:
	var best := 1
	var best_diff := 999.0
	for i in range(TILE_FONT_SCALES.size()):
		var diff := absf(TILE_FONT_SCALES[i] - scale)
		if diff < best_diff:
			best = i
			best_diff = diff
	return best


func _refresh_theme_button() -> void:
	if theme_button == null:
		return
	var theme_mgr = _theme()
	var theme_id := "dusk"
	if theme_mgr != null:
		theme_id = str(_get_value(theme_mgr, "theme_id", "dusk"))
	var theme_key := "settings_theme_%s" % theme_id
	var theme_name := _i18n(theme_key)
	if theme_name == theme_key:
		theme_name = theme_id
	theme_button.text = "%s: %s" % [_i18n("settings_theme_label").trim_suffix(":"), theme_name]
	# Global brightness belongs to meta screens and remains independent from a
	# dark-only gameplay art kit.
	theme_button.disabled = false
	theme_button.tooltip_text = ""


func _apply_audio() -> void:
	var audio = _audio()
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")


func _on_sound_toggled(enabled: bool) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("sound_enabled", enabled)
	_save()
	_apply_audio()


func _on_music_toggled(enabled: bool) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("music_enabled", enabled)
	_save()
	_apply_audio()


func _on_bg_effects_toggled(enabled: bool) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("bg_effects_enabled", enabled)
		_save()
	var theme_mgr = _theme()
	if theme_mgr != null and theme_mgr.has_method("notify_visual_settings_changed"):
		theme_mgr.call("notify_visual_settings_changed")


func _on_sfx_volume_selected(index: int) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("sfx_volume", VOLUME_LEVELS[clampi(index, 0, VOLUME_LEVELS.size() - 1)])
	_save()


func _on_music_volume_selected(index: int) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("music_volume", VOLUME_LEVELS[clampi(index, 0, VOLUME_LEVELS.size() - 1)])
	_save()
	_apply_audio()


func _on_music_track_selected(index: int) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("music_track", MUSIC_TRACKS[clampi(index, 0, MUSIC_TRACKS.size() - 1)])
	_save()
	_apply_audio()


func _on_tile_font_size_selected(index: int) -> void:
	var settings = _settings()
	if settings != null:
		settings.set("tile_font_scale", TILE_FONT_SCALES[clampi(index, 0, TILE_FONT_SCALES.size() - 1)])
	_save()


func _on_language_selected(index: int) -> void:
	var langs := ["uk", "ru", "en"]
	var settings = _settings()
	if settings != null:
		settings.set("language", langs[clampi(index, 0, langs.size() - 1)])
		_save()
		# Refresh visible labels and option entries without reopening Settings.
		_setup_labels()
		_setup_options()
		_load_settings()


func _on_leaderboard_toggled(enabled: bool) -> void:
	LnUiLib.show_toast(self, _i18n("save_indicator"))


func _on_theme_cycle() -> void:
	var theme_mgr = _theme()
	if theme_mgr != null and theme_mgr.has_method("cycle_theme"):
		theme_mgr.call("cycle_theme")
	_refresh_theme_button()
	_save()


func _on_skin_pick_pressed() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		await router.call("push", "skin_preview")


func _on_background_pick_pressed() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		await router.call("push", "background_preview")


func _on_background_auto_toggled(enabled: bool) -> void:
	var theme_mgr = _theme()
	if theme_mgr != null and theme_mgr.has_method("set_skin_auto"):
		theme_mgr.call("set_skin_auto", enabled)
	_save()


func _on_import_legacy() -> void:
	var migration := _autoload("LegacySaveMigration")
	if migration == null or not migration.has_method("try_manual_import"):
		if import_status != null:
			import_status.text = _i18n("settings_import_legacy_failed")
		return
	if import_button != null:
		import_button.disabled = true
	var imported := bool(migration.call("try_manual_import"))
	if import_button != null:
		import_button.disabled = false
	if import_status != null:
		import_status.text = _i18n(
			"settings_import_legacy_success" if imported else "settings_import_legacy_none"
		)


func _on_exit() -> void:
	var app := get_tree().root.get_node_or_null("App")
	if app != null and app.has_method("request_exit"):
		app.call("request_exit")
		return
	if OS.get_name() == "Android":
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		return
	get_tree().quit()


func _on_back() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("go_back"):
		var handled: bool = await router.go_back()
		if not handled and router.has_method("replace"):
			router.call("replace", "main_menu")
	else:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
