extends Control

## Main menu: logo hero, primary actions, circular dock row.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const _FEATURE_STUBS := {
	"premium": {
		"title": "feature_premium_title",
		"intro": "feature_premium_intro",
		"bullets": [
			"feature_premium_bullet_ad",
			"feature_premium_bullet_themes",
			"feature_premium_bullet_tournaments",
			"feature_premium_bullet_bonuses",
			"feature_premium_bullet_stats",
		],
		"note": "feature_premium_note",
	},
	"tournaments": {
		"title": "feature_tournaments_title",
		"intro": "feature_tournaments_intro",
		"bullets": [
			"feature_tournaments_bullet_weekly",
			"feature_tournaments_bullet_records",
			"feature_tournaments_bullet_rewards",
		],
		"note": "feature_tournaments_note",
	},
	"bonuses": {
		"title": "feature_bonuses_title",
		"intro": "feature_bonuses_text",
		"bullets": [],
		"note": "",
	},
}

@onready var logo_image: TextureRect = $Layout/RootVBox/Hero/LogoImage
@onready var tagline_label: Label = $Layout/RootVBox/Hero/Tagline
@onready var play_button: NeonButton = $Layout/RootVBox/Actions/Buttons/PlayButton
@onready var continue_button: NeonButton = $Layout/RootVBox/Actions/Buttons/ContinueButton
@onready var wheel_button: NeonButton = $Layout/RootVBox/Actions/Buttons/WheelButton
@onready var quick_settings: Button = $Layout/RootVBox/QuickRow/QuickSettings
@onready var quick_stats: Button = $Layout/RootVBox/QuickRow/QuickStats
@onready var quick_about: Button = $Layout/RootVBox/QuickRow/QuickAbout
@onready var dock_premium: Button = $Layout/RootVBox/DockRow/DockPremium
@onready var dock_tournaments: Button = $Layout/RootVBox/DockRow/DockTournaments
@onready var dock_achievements: Button = $Layout/RootVBox/DockRow/DockAchievements
@onready var dock_daily: Button = $Layout/RootVBox/DockRow/DockDaily
@onready var dock_bonuses: Button = $Layout/RootVBox/DockRow/DockBonuses
@onready var exit_button: NeonButton = $Layout/RootVBox/ExitRow/ExitButton
@onready var version_label: Label = $Layout/RootVBox/VersionLabel
@onready var feature_dim: ColorRect = $FeatureDim
@onready var feature_stub: FeatureStubOverlay = $FeatureStub


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _navigate(screen_id: String) -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		router.call("push", screen_id)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("main_menu"))
	_apply_safe_area_top()
	_wire_static_logo()
	tagline_label.text = _i18n("main_subtitle")
	tagline_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	tagline_label.gui_input.connect(_on_tagline_input)

	play_button.text = _i18n("menu_play")
	continue_button.text = _i18n("menu_continue")
	wheel_button.text = _i18n("menu_wheel")
	if exit_button != null:
		exit_button.text = _i18n("btn_exit")
	version_label.text = _i18n("version_label", [str(ProjectSettings.get_setting("application/config/version", ""))])
	version_label.add_theme_font_size_override("font_size", 11)

	_set_wheel_button_icon(wheel_button, "wheel-x2.png", 28)

	quick_settings.call("setup", _i18n("btn_settings"), LnUiLib.icon_path("settings.png"))
	quick_stats.call("setup", _i18n("btn_stats"), LnUiLib.icon_path("statistics.png"))
	quick_about.call("setup", _i18n("btn_about"), LnUiLib.icon_path("about.png"))

	dock_premium.call("setup", _i18n("dock_premium"), LnUiLib.icon_path("premium.png"))
	dock_tournaments.call("setup", _i18n("dock_tournaments"), LnUiLib.icon_path("tournaments.png"))
	dock_achievements.call("setup", _i18n("dock_achievements"), LnUiLib.icon_path("achievements.png"))
	dock_daily.call("setup", _i18n("dock_daily"), LnUiLib.icon_path("daily-tasks.png"))
	dock_bonuses.call("setup", _i18n("dock_bonuses"), LnUiLib.icon_path("bonus.png"))

	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))
	continue_button.visible = true
	continue_button.disabled = not has_save
	play_button.text = _i18n("menu_new_game") if has_save else _i18n("menu_play")

	play_button.variant = "primary"
	continue_button.variant = "success"
	wheel_button.variant = "secondary"
	if exit_button != null:
		exit_button.variant = "secondary"

	for btn in [play_button, continue_button, wheel_button]:
		if btn == continue_button or btn == wheel_button:
			btn.disabled = not has_save
		else:
			btn.disabled = false

	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	wheel_button.pressed.connect(_on_wheel)
	if exit_button != null:
		exit_button.pressed.connect(_on_exit)
	quick_settings.pressed.connect(_on_settings)
	quick_stats.pressed.connect(_on_stats)
	quick_about.pressed.connect(_on_about)
	dock_premium.pressed.connect(_on_premium)
	dock_tournaments.pressed.connect(_on_tournaments)
	dock_achievements.pressed.connect(_on_achievements)
	dock_daily.pressed.connect(_on_daily)
	dock_bonuses.pressed.connect(_on_bonuses)
	feature_stub.connect("closed", func(): feature_dim.visible = false)

	feature_dim.visible = false
	feature_stub.visible = false

	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_title_style)
	_apply_title_style()

	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_settings_music"):
		audio.call("play_settings_music")

	_animate_entrance()


func _apply_safe_area_top() -> void:
	var layout := $Layout as MarginContainer
	if layout == null:
		return
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	var top_inset := safe.position.y
	if top_inset <= 0:
		return
	var base_top := layout.get_theme_constant("margin_top")
	layout.add_theme_constant_override("margin_top", base_top + top_inset)


func _wire_static_logo() -> void:
	if logo_image == null:
		return
	# Single static logo — no glow stack, no pulse (avoids doubled/blurry look on device).
	var glow := logo_image.get_parent().get_node_or_null("LogoGlow") if logo_image.get_parent() else null
	if glow != null:
		glow.visible = false
	if ResourceLoader.exists(LnUiLib.LOGO_PATH):
		logo_image.texture = load(LnUiLib.LOGO_PATH)
	logo_image.custom_minimum_size = Vector2(300, 120)
	logo_image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo_image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo_image.modulate = Color.WHITE
	logo_image.scale = Vector2.ONE


func _apply_title_style() -> void:
	var theme_mgr := _autoload("ThemeManager")
	tagline_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_TEXT, 0.9))
	version_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_MUTED, 0.8))
	if theme_mgr != null and theme_mgr.has_method("get_text_color"):
		tagline_label.add_theme_color_override("font_color", Color(theme_mgr.call("get_text_color"), 0.9))


func _set_button_icon(button: Button, path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true


func _set_wheel_button_icon(button: Button, file_name: String, max_size: int = 28) -> void:
	var tex := LnUiLib.load_wheel_icon(file_name)
	if tex == null:
		return
	button.icon = tex
	button.expand_icon = true
	button.add_theme_constant_override("icon_max_width", max_size)
	button.add_theme_constant_override("icon_max_height", max_size)


func _animate_entrance() -> void:
	var items: Array[Control] = [logo_image, tagline_label]
	if continue_button.visible:
		items.append(continue_button)
	items.append(play_button)
	items.append(wheel_button)
	for quick in [quick_settings, quick_stats, quick_about]:
		items.append(quick)
	for dock in [dock_premium, dock_tournaments, dock_achievements, dock_daily, dock_bonuses]:
		items.append(dock)
	if exit_button != null:
		items.append(exit_button)
	items.append(version_label)
	for item in items:
		item.modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree():
		return
	for i in items.size():
		var item := items[i]
		var tween := create_tween().set_parallel(true)
		var delay := 0.035 * i
		tween.tween_property(item, "modulate:a", 1.0, 0.24).set_delay(delay)
		# Skip vertical slide on top exit — it overlaps Hero (later sibling) and steals taps.
		if item == exit_button:
			continue
		var y := item.position.y
		item.position.y = y + 14.0
		tween.tween_property(item, "position:y", y, 0.24).set_delay(delay)


func _play_button_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "button_click")


func _stub_body(stub_id: String) -> String:
	var spec: Dictionary = _FEATURE_STUBS.get(stub_id, {})
	if spec.is_empty():
		return ""
	var lines: PackedStringArray = PackedStringArray([_i18n(str(spec.get("intro", "")))])
	for key in spec.get("bullets", []):
		lines.append("• %s" % _i18n(str(key)))
	var note := str(spec.get("note", ""))
	if not note.is_empty():
		lines.append(_i18n(note))
	return "\n\n".join(lines)


func _show_feature_stub(stub_id: String) -> void:
	var spec: Dictionary = _FEATURE_STUBS.get(stub_id, {})
	if spec.is_empty():
		return
	feature_dim.visible = true
	feature_stub.show_stub(
		_i18n(str(spec.get("title", ""))),
		_stub_body(stub_id),
		_i18n("feature_stub_ok")
	)


func _on_tagline_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_play_button_sfx()
		_navigate("about")


func _on_play() -> void:
	_play_button_sfx()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("delete_save"):
		save.call("delete_save")
	_navigate("game")


func _on_continue() -> void:
	_play_button_sfx()
	_navigate("game")


func _on_wheel() -> void:
	_play_button_sfx()
	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))
	if not has_save:
		return
	_navigate("wheel")


func _on_exit() -> void:
	_play_button_sfx()
	var app := get_tree().root.get_node_or_null("App")
	if app != null and app.has_method("request_exit"):
		app.call("request_exit")
		return
	if OS.get_name() == "Android":
		# Prefer backgrounding on Android when App shell is unavailable.
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_MINIMIZED)
		return
	get_tree().quit()


func _on_settings() -> void:
	_play_button_sfx()
	_navigate("settings")


func _on_stats() -> void:
	_play_button_sfx()
	_navigate("stats")


func _on_about() -> void:
	_play_button_sfx()
	_navigate("about")


func _on_premium() -> void:
	_play_button_sfx()
	_show_feature_stub("premium")


func _on_tournaments() -> void:
	_play_button_sfx()
	_show_feature_stub("tournaments")


func _on_achievements() -> void:
	_play_button_sfx()
	_navigate("achievements")


func _on_daily() -> void:
	_play_button_sfx()
	_navigate("daily")


func _on_bonuses() -> void:
	_play_button_sfx()
	_show_feature_stub("bonuses")
