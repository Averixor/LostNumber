extends Control

## Main menu: logo hero, ≤2 primary CTAs, single pedestal dock row.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var logo_image: TextureRect = $Layout/RootVBox/Hero/LogoImage
@onready var tagline_label: Label = $Layout/RootVBox/Hero/Tagline
@onready var play_button: NeonButton = $Layout/RootVBox/Actions/Buttons/PlayButton
@onready var continue_button: NeonButton = $Layout/RootVBox/Actions/Buttons/ContinueButton
@onready var exit_button: NeonButton = $Layout/RootVBox/TopBar/ExitButton
@onready var dock_wheel: Button = $Layout/RootVBox/DockRows/DockRow/DockWheel
@onready var dock_settings: Button = $Layout/RootVBox/DockRows/DockRow/DockSettings
@onready var dock_stats: Button = $Layout/RootVBox/DockRows/DockRow/DockStats
@onready var dock_about: Button = $Layout/RootVBox/DockRows/DockRow/DockAbout
@onready var dock_daily: Button = $Layout/RootVBox/DockRows/DockRowSecondary/DockDaily
@onready var dock_achievements: Button = $Layout/RootVBox/DockRows/DockRowSecondary/DockAchievements
@onready var version_label: Label = $Layout/RootVBox/VersionLabel


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


func _dock_buttons() -> Array:
	return [dock_wheel, dock_settings, dock_stats, dock_about, dock_daily, dock_achievements]


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("main_menu"))
	_apply_safe_area_top()
	_wire_static_logo()
	tagline_label.text = _i18n("main_subtitle")
	tagline_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	tagline_label.gui_input.connect(_on_tagline_input)

	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))

	play_button.text = _i18n("menu_new_game") if has_save else _i18n("menu_play")
	continue_button.text = _i18n("menu_continue")
	continue_button.visible = has_save
	continue_button.disabled = not has_save
	if exit_button != null:
		# Compact chrome control (VISUAL_TARGET: corner sigil, not a primary CTA).
		exit_button.text = ""
		exit_button.tooltip_text = _i18n("btn_exit")
		exit_button.variant = "ghost"
	version_label.text = _i18n("version_label", [str(ProjectSettings.get_setting("application/config/version", ""))])
	version_label.add_theme_font_size_override("font_size", 11)

	_set_button_icon(play_button, LnUiLib.icon_path("home.png"))
	_set_button_icon(continue_button, LnUiLib.icon_path("save.png"))
	if exit_button != null:
		_set_button_icon(exit_button, LnUiLib.icon_path("exit.png"))

	# VISUAL_TARGET pedestal row: wheel · settings · stats · about (+ working daily/achievements).
	dock_wheel.call("setup", _i18n("dock_wheel"), LnUiLib.wheel_icon_path("wheel-x2.png"))
	dock_settings.call("setup", _i18n("dock_settings"), LnUiLib.icon_path("settings.png"))
	dock_stats.call("setup", _i18n("btn_stats"), LnUiLib.icon_path("statistics.png"))
	dock_about.call("setup", _i18n("btn_about"), LnUiLib.icon_path("about.png"))
	dock_daily.call("setup", _i18n("dock_daily"), LnUiLib.icon_path("daily-tasks.png"))
	dock_achievements.call("setup", _i18n("dock_achievements"), LnUiLib.icon_path("achievements.png"))
	dock_wheel.disabled = not has_save
	if dock_wheel.has_method("refresh_enabled_visual"):
		dock_wheel.call("refresh_enabled_visual")
	const CTA_HEIGHT := 60.0
	for cta in [play_button, continue_button]:
		cta.variant = "primary"
		cta.custom_minimum_size = Vector2(0, CTA_HEIGHT)
		cta.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	if exit_button != null:
		exit_button.custom_minimum_size = Vector2(52, 44)
		exit_button.size_flags_horizontal = Control.SIZE_SHRINK_END

	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	if exit_button != null:
		exit_button.pressed.connect(_on_exit)
	dock_wheel.pressed.connect(_on_wheel)
	dock_settings.pressed.connect(_on_settings)
	dock_stats.pressed.connect(_on_stats)
	dock_about.pressed.connect(_on_about)
	dock_daily.pressed.connect(_on_daily)
	dock_achievements.pressed.connect(_on_achievements)

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
	_refresh_logo_visibility()


func _refresh_logo_visibility() -> void:
	if logo_image == null:
		return
	# Use the background actually shown (App BackgroundLayer / ThemeManager path),
	# not the gothic VisualSkin menu asset — that art is game-only under App.tscn.
	var path := LnUiLib.current_background_path("main_menu")
	# Exactly one logo: baked-in art XOR overlay — never both, never neither.
	logo_image.visible = not LnUiLib.background_has_embedded_logo(path)


func _apply_title_style() -> void:
	var theme_mgr := _autoload("ThemeManager")
	var is_dark := true
	if theme_mgr != null and theme_mgr.has_method("is_dark"):
		is_dark = bool(theme_mgr.call("is_dark"))
	var tagline_color := ThemeTokensLib.COLOR_TEXT if is_dark else ThemeTokensLib.DAWN_COLOR_TEXT
	var version_color := ThemeTokensLib.COLOR_MUTED if is_dark else ThemeTokensLib.DAWN_COLOR_MUTED
	if theme_mgr != null and theme_mgr.has_method("get_text_color"):
		tagline_color = theme_mgr.call("get_text_color")
	tagline_label.add_theme_color_override("font_color", Color(tagline_color, 0.92 if is_dark else 1.0))
	version_label.add_theme_color_override("font_color", Color(version_color, 0.85 if is_dark else 0.92))
	if exit_button != null:
		var exit_color := tagline_color if is_dark else ThemeTokensLib.DAWN_COLOR_TEXT
		exit_button.add_theme_color_override("font_color", exit_color)
		exit_button.add_theme_color_override("icon_normal_color", exit_color)
		exit_button.add_theme_color_override("icon_hover_color", exit_color)
		exit_button.add_theme_color_override("icon_pressed_color", exit_color)

func _set_button_icon(button: Button, path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true


func _animate_entrance() -> void:
	var items: Array[Control] = [logo_image, tagline_label]
	items.append(play_button)
	if continue_button.visible:
		items.append(continue_button)
	for dock in _dock_buttons():
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
		var target_a := 1.0
		if item is BaseButton and (item as BaseButton).disabled:
			target_a = 0.38
		tween.tween_property(item, "modulate:a", target_a, 0.24).set_delay(delay)
		var y := item.position.y
		item.position.y = y + 14.0
		tween.tween_property(item, "position:y", y, 0.24).set_delay(delay)


func _play_button_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "button_click")


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


func _on_achievements() -> void:
	_play_button_sfx()
	_navigate("achievements")


func _on_daily() -> void:
	_play_button_sfx()
	_navigate("daily")
