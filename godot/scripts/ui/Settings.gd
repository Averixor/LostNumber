extends Control

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var scroll: ScrollContainer = $Scroll
@onready var vbox: VBoxContainer = $Scroll/VBox
@onready var sound_check: CheckButton = $Scroll/VBox/SoundCheck
@onready var music_check: CheckButton = $Scroll/VBox/MusicCheck
@onready var sfx_volume_option: OptionButton = $Scroll/VBox/SfxVolumeOption
@onready var music_volume_option: OptionButton = $Scroll/VBox/MusicVolumeOption
@onready var music_track_option: OptionButton = $Scroll/VBox/MusicTrackOption
@onready var bg_effects_check: CheckButton = $Scroll/VBox/BgEffectsCheck
@onready var tile_font_size_option: OptionButton = $Scroll/VBox/TileFontSizeOption
@onready var language_option: OptionButton = $Scroll/VBox/LanguageOption
@onready var leaderboard_check: CheckButton = $Scroll/VBox/LeaderboardCheck
@onready var theme_button: Button = $Scroll/VBox/ThemeButton
@onready var skin_label: Label = $Scroll/VBox/SkinLabel
@onready var skin_pick_button: Button = $Scroll/VBox/SkinPickButton
@onready var skin_auto_check: CheckButton = $Scroll/VBox/SkinAutoCheck
@onready var import_button: Button = $Scroll/VBox/ImportLegacyButton
@onready var import_status: Label = $Scroll/VBox/ImportStatus
@onready var back_button: Button = $Scroll/VBox/BackButton
@onready var title_label: Label = $Scroll/VBox/Title
@onready var background: ColorRect = $Background

const MUSIC_TRACKS := ["ambient", "crystal_flow", "digital_horizon", "neon_drift", "stellar_logic"]
const VOLUME_LEVELS := [0.25, 0.5, 0.75, 1.0]
const TILE_FONT_SCALES := [0.85, 1.0, 1.1, 1.2]


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
	LnUiLib.set_background(self, LnUiLib.screen_bg("settings"))
	_apply_background()
	_style_controls()
	_adapt_layout()

	title_label.text = _i18n("settings_title")
	sound_check.text = _i18n("settings_sound")
	music_check.text = _i18n("settings_music")
	bg_effects_check.text = _i18n("settings_bg_effects")
	back_button.text = _i18n("menu_back")
	leaderboard_check.text = _i18n("leaderboard_opt_in")
	skin_label.text = _i18n("settings_visual_skin_label")
	skin_pick_button.text = _i18n("settings_pick_background")
	skin_auto_check.text = _i18n("settings_visual_skin_auto")
	import_button.text = _i18n("settings_import_legacy")
	import_status.text = ""
	_refresh_theme_button()

	var settings := _autoload("SettingsManager")
	if settings != null:
		sound_check.button_pressed = bool(settings.get("sound_enabled"))
		music_check.button_pressed = bool(settings.get("music_enabled"))
		bg_effects_check.button_pressed = bool(settings.get("bg_effects_enabled"))

	_setup_audio_options(settings)
	_setup_tile_font_size_option(settings)

	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null:
		skin_auto_check.button_pressed = bool(theme_mgr.get("skin_auto"))

	_setup_language_option()
	_refresh_skin_summary()

	sound_check.toggled.connect(_on_sound_toggled)
	music_check.toggled.connect(_on_music_toggled)
	sfx_volume_option.item_selected.connect(_on_sfx_volume_selected)
	music_volume_option.item_selected.connect(_on_music_volume_selected)
	music_track_option.item_selected.connect(_on_music_track_selected)
	bg_effects_check.toggled.connect(_on_bg_effects_toggled)
	tile_font_size_option.item_selected.connect(_on_tile_font_size_selected)
	language_option.item_selected.connect(_on_language_selected)
	leaderboard_check.toggled.connect(_on_leaderboard_toggled)
	theme_button.pressed.connect(_on_theme_cycle)
	skin_pick_button.pressed.connect(_on_skin_pick_pressed)
	skin_auto_check.toggled.connect(_on_skin_auto_toggled)
	import_button.pressed.connect(_on_import_legacy)
	back_button.pressed.connect(_on_back)

	_load_leaderboard_opt_in()

	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_on_theme_changed)

	_adapt_layout()
	_animate_entrance()
	call_deferred("_adapt_layout")


func _animate_entrance() -> void:
	var items: Array = [
		back_button,
		title_label,
		sound_check,
		music_check,
		sfx_volume_option,
		music_volume_option,
		music_track_option,
		bg_effects_check,
		tile_font_size_option,
		language_option,
		leaderboard_check,
		theme_button,
		skin_label,
		skin_pick_button,
		skin_auto_check,
		import_button,
	]
	await LnUiLib.animate_entrance(items)


func _on_theme_changed() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("settings"))
	_apply_background()
	_refresh_theme_button()
	_refresh_skin_summary()


func _style_controls() -> void:
	var compact := _is_compact_layout()
	LnUiLib.apply_title(title_label, ThemeTokensLib.FONT_SIZE_TITLE)
	for btn in [back_button, theme_button, import_button, skin_pick_button]:
		LnUiLib.apply_button(btn)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LnUiLib.apply_button_icon(back_button, "back.svg")
	for check in [sound_check, music_check, bg_effects_check, leaderboard_check, skin_auto_check]:
		LnUiLib.apply_toggle_switch(check, compact)
	for option in [sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option]:
		option.custom_minimum_size.y = 42.0 if compact else 44.0
	LnUiLib.apply_check_icon(sound_check, "sound.svg")
	LnUiLib.apply_check_icon(music_check, "music.svg")
	LnUiLib.apply_check_icon(bg_effects_check, "animations.svg")
	LnUiLib.apply_button_icon(theme_button, "theme.svg")
	_style_language_row()
	_style_skin_label_row()
	_style_audio_option_row(sfx_volume_option, _i18n("settings_sfx_volume_label"), "volume.svg")
	_style_audio_option_row(music_volume_option, _i18n("settings_music_volume_label"), "music.svg")
	_style_audio_option_row(music_track_option, _i18n("settings_music_track_label"), "track.svg")
	_style_audio_option_row(tile_font_size_option, _i18n("settings_tile_font_size_label"), "theme.svg")


func _style_language_row() -> void:
	var row := language_option.get_parent() as VBoxContainer
	if row == null:
		return
	var wrap := HBoxContainer.new()
	wrap.name = "LanguageRow"
	wrap.add_theme_constant_override("separation", 8)
	row.add_child(wrap)
	row.move_child(wrap, language_option.get_index())
	wrap.add_child(language_option)
	language_option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := LnUiLib.load_icon("language.svg")
	if tex != null:
		icon.texture = tex
	wrap.add_child(icon)
	wrap.move_child(icon, 0)
	LnUiLib.apply_option_row_style(language_option, _is_compact_layout())


func _setup_audio_options(settings: Node) -> void:
	sfx_volume_option.clear()
	music_volume_option.clear()
	music_track_option.clear()

	for level in VOLUME_LEVELS:
		var pct := int(round(level * 100.0))
		sfx_volume_option.add_item(_i18n("settings_volume_%d" % pct), sfx_volume_option.item_count)
		music_volume_option.add_item(_i18n("settings_volume_%d" % pct), music_volume_option.item_count)

	for track in MUSIC_TRACKS:
		music_track_option.add_item(_i18n("settings_music_track_%s" % track), music_track_option.item_count)

	var sfx_volume := 0.5
	var music_volume := 0.3
	var music_track := "ambient"
	if settings != null:
		sfx_volume = float(settings.get("sfx_volume"))
		music_volume = float(settings.get("music_volume"))
		music_track = str(settings.get("music_track"))

	sfx_volume_option.select(_volume_to_option_index(sfx_volume))
	music_volume_option.select(_volume_to_option_index(music_volume))
	music_track_option.select(maxi(0, MUSIC_TRACKS.find(_normalize_music_track(music_track))))


func _setup_tile_font_size_option(settings: Node) -> void:
	tile_font_size_option.clear()
	for scale in TILE_FONT_SCALES:
		var pct := int(round(scale * 100.0))
		tile_font_size_option.add_item(
			_i18n("settings_tile_font_%d" % pct),
			tile_font_size_option.item_count
		)

	var index := 1
	if settings != null and settings.has_method("tile_font_scale_to_index"):
		index = int(settings.call("tile_font_scale_to_index"))
	tile_font_size_option.select(clampi(index, 0, TILE_FONT_SCALES.size() - 1))


func _volume_to_option_index(volume: float) -> int:
	var pct := int(round(clampf(volume, 0.0, 1.0) * 100.0))
	if pct <= 25:
		return 0
	if pct <= 50:
		return 1
	if pct <= 75:
		return 2
	return 3


func _normalize_music_track(track: String) -> String:
	var key := str(track)
	if key in MUSIC_TRACKS:
		return key
	match key:
		"crystalFlow":
			return "crystal_flow"
		"digitalHorizon":
			return "digital_horizon"
		"neonDrift":
			return "neon_drift"
		"stellarLogic":
			return "stellar_logic"
		_:
			return "ambient"


func _style_audio_option_row(option: OptionButton, label_text: String, icon_name: String) -> void:
	var row := option.get_parent() as VBoxContainer
	if row == null:
		return
	var wrap := VBoxContainer.new()
	wrap.name = "%sRow" % option.name
	wrap.add_theme_constant_override("separation", 4)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(wrap)
	row.move_child(wrap, option.get_index())

	var label := Label.new()
	label.text = label_text
	label.add_theme_color_override("font_color", LnUiLib.TEXT)
	label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(label)

	var control_row := HBoxContainer.new()
	control_row.add_theme_constant_override("separation", 6)
	control_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wrap.add_child(control_row)

	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := LnUiLib.load_icon(icon_name)
	if tex != null:
		icon.texture = tex
	control_row.add_child(icon)

	row.remove_child(option)
	control_row.add_child(option)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	LnUiLib.apply_option_row_style(option, _is_compact_layout())


func _style_skin_label_row() -> void:
	var row := skin_label.get_parent() as VBoxContainer
	if row == null:
		return
	var wrap := HBoxContainer.new()
	wrap.name = "SkinLabelRow"
	wrap.add_theme_constant_override("separation", 8)
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(wrap)
	row.move_child(wrap, skin_label.get_index())
	var icon := TextureRect.new()
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tex := LnUiLib.load_icon("theme.svg")
	if tex != null:
		icon.texture = tex
	wrap.add_child(icon)
	wrap.add_child(skin_label)
	skin_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	skin_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	skin_label.add_theme_color_override("font_color", LnUiLib.TEXT)
	skin_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY)


func _theme_text_color() -> Color:
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_text_color"):
		return theme_mgr.call("get_text_color")
	return ThemeTokensLib.COLOR_TEXT


func _apply_background() -> void:
	if background == null:
		return
	var theme_mgr := _autoload("ThemeManager")
	var color := ThemeTokensLib.COLOR_BG
	if theme_mgr != null and theme_mgr.has_method("get_background_color"):
		color = theme_mgr.call("get_background_color")
	background.color = Color(color, 0.6)


func _show_saved_toast() -> void:
	LnUiLib.show_toast(self, _i18n("save_indicator"))


func _refresh_theme_button() -> void:
	var theme_mgr := _autoload("ThemeManager")
	var theme_name := "dusk"
	if theme_mgr != null:
		theme_name = str(theme_mgr.get("theme_id"))
	var theme_key := "settings_theme_dusk"
	match theme_name:
		"dawn":
			theme_key = "settings_theme_dawn"
		"twilight":
			theme_key = "settings_theme_twilight"
	var label := _i18n("settings_theme_label")
	theme_button.text = "%s %s" % [label, _i18n(theme_key)]


func _refresh_skin_summary() -> void:
	var theme_mgr := _autoload("ThemeManager")
	var auto := false
	if theme_mgr != null:
		auto = bool(theme_mgr.get("skin_auto"))
	if auto:
		skin_pick_button.text = "%s (%s)" % [_i18n("settings_pick_background"), _i18n("settings_state_auto")]
	else:
		skin_pick_button.text = _i18n("settings_pick_background")


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


func _is_compact_layout() -> bool:
	return get_viewport_rect().size.y <= 920.0


func _content_width() -> float:
	var width := scroll.size.x
	if width > 0.0:
		return width
	var vp := get_viewport_rect().size
	return maxf(0.0, vp.x - 32.0)


func _adapt_layout() -> void:
	var vp := get_viewport_rect().size
	var compact := _is_compact_layout()
	var content_w := _content_width()

	scroll.offset_left = 16.0
	scroll.offset_right = -16.0
	scroll.offset_top = 8.0
	scroll.offset_bottom = -8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED

	vbox.add_theme_constant_override("separation", 6 if compact else 8)
	if content_w > 0.0:
		vbox.custom_minimum_size.x = content_w
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	title_label.add_theme_font_size_override(
		"font_size",
		mini(20, ThemeTokensLib.FONT_SIZE_TITLE) if compact else mini(24, ThemeTokensLib.FONT_SIZE_TITLE)
	)
	title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	var row_h := 38.0 if compact else 44.0
	var option_h := 38.0 if compact else 42.0
	var btn_font := 16 if compact else 18
	var icon_sz := Vector2(22, 22) if compact else Vector2(24, 24)
	var label_font := 12 if compact else ThemeTokensLib.FONT_SIZE_SMALL

	for check in [sound_check, music_check, bg_effects_check, leaderboard_check, skin_auto_check]:
		LnUiLib.apply_toggle_switch(check, compact)
		check.custom_minimum_size = Vector2(0, row_h)
		check.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for btn in [back_button, theme_button, import_button, skin_pick_button]:
		btn.custom_minimum_size = Vector2(0, row_h)
		btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		btn.add_theme_font_size_override("font_size", btn_font)

	for option in [sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option]:
		LnUiLib.apply_option_row_style(option, compact)
		option.custom_minimum_size = Vector2(0, option_h)

	_adapt_option_rows(compact, icon_sz, label_font)

	skin_pick_button.custom_minimum_size = Vector2(0, row_h)
	skin_pick_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	import_status.size_flags_horizontal = Control.SIZE_EXPAND_FILL

	for child in vbox.get_children():
		if child is Control:
			(child as Control).size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _adapt_option_rows(compact: bool, icon_sz: Vector2, label_font: int) -> void:
	for row_name in [
		"SfxVolumeOptionRow",
		"MusicVolumeOptionRow",
		"MusicTrackOptionRow",
		"TileFontSizeOptionRow",
	]:
		_adapt_option_row(vbox.get_node_or_null(row_name), compact, icon_sz, label_font)

	var language_row := vbox.get_node_or_null("LanguageRow") as HBoxContainer
	if language_row != null:
		language_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		language_row.add_theme_constant_override("separation", 6 if compact else 8)
		for child in language_row.get_children():
			if child is TextureRect:
				child.custom_minimum_size = icon_sz

	var skin_label_row := vbox.get_node_or_null("SkinLabelRow") as HBoxContainer
	if skin_label_row != null:
		skin_label_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		skin_label_row.add_theme_constant_override("separation", 6 if compact else 8)
		for child in skin_label_row.get_children():
			if child is TextureRect:
				child.custom_minimum_size = icon_sz


func _adapt_option_row(wrap: Node, compact: bool, icon_sz: Vector2, label_font: int) -> void:
	if wrap == null:
		return
	wrap.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for child in wrap.get_children():
		if child is Label:
			var label := child as Label
			label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			label.add_theme_font_size_override("font_size", label_font)
		elif child is HBoxContainer:
			var hbox := child as HBoxContainer
			hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			hbox.add_theme_constant_override("separation", 6 if compact else 8)
			for row_child in hbox.get_children():
				if row_child is TextureRect:
					row_child.custom_minimum_size = icon_sz
				elif row_child is OptionButton:
					row_child.size_flags_horizontal = Control.SIZE_EXPAND_FILL


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_adapt_layout()


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
	_show_saved_toast()


func _on_music_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("music_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")
	_show_saved_toast()


func _on_sfx_volume_selected(index: int) -> void:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return
	settings.set("sfx_volume", VOLUME_LEVELS[mini(index, VOLUME_LEVELS.size() - 1)])
	if settings.has_method("save_settings"):
		settings.call("save_settings")
	_show_saved_toast()


func _on_music_volume_selected(index: int) -> void:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return
	settings.set("music_volume", VOLUME_LEVELS[mini(index, VOLUME_LEVELS.size() - 1)])
	if settings.has_method("save_settings"):
		settings.call("save_settings")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")
	_show_saved_toast()


func _on_music_track_selected(index: int) -> void:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return
	settings.set("music_track", MUSIC_TRACKS[mini(index, MUSIC_TRACKS.size() - 1)])
	if settings.has_method("save_settings"):
		settings.call("save_settings")
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("apply_audio_settings"):
		audio.call("apply_audio_settings")
	_show_saved_toast()


func _on_bg_effects_toggled(enabled: bool) -> void:
	var settings := _autoload("SettingsManager")
	if settings != null:
		settings.set("bg_effects_enabled", enabled)
		if settings.has_method("save_settings"):
			settings.call("save_settings")
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("notify_visual_settings_changed"):
		theme_mgr.call("notify_visual_settings_changed")
	_show_saved_toast()


func _on_tile_font_size_selected(index: int) -> void:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return
	var scale: float = TILE_FONT_SCALES[mini(index, TILE_FONT_SCALES.size() - 1)]
	if settings.has_method("set_tile_font_scale"):
		settings.call("set_tile_font_scale", scale)
	else:
		settings.set("tile_font_scale", scale)
	if settings.has_method("save_settings"):
		settings.call("save_settings")
	_show_saved_toast()


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
	_show_saved_toast()


func _on_theme_cycle() -> void:
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("cycle_theme"):
		theme_mgr.call("cycle_theme")
	_refresh_skin_summary()
	_adapt_layout()
	_show_saved_toast()


func _on_skin_pick_pressed() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		await router.call("push", "skin_preview")
	else:
		get_tree().change_scene_to_file("res://scenes/SkinPreview.tscn")


func _on_skin_auto_toggled(enabled: bool) -> void:
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("set_skin_auto"):
		theme_mgr.call("set_skin_auto", enabled)
	_refresh_skin_summary()
	_show_saved_toast()


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
