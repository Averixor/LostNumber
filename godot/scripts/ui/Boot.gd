extends Control

## Boot/splash screen with fullscreen gothic art and logo pulse.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const APP_SCENE := "res://scenes/App.tscn"

@onready var logo_image: TextureRect = $Center/VBox/LogoStack/LogoImage
@onready var subtitle_label: Label = $Center/VBox/Subtitle
@onready var progress_bar: ProgressBar = $Center/VBox/Progress
@onready var background: ColorRect = $Background
@onready var background_art: TextureRect = $BackgroundArt


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("boot"), 0.55)
	_wire_static_boot_logo()
	_apply_theme()
	subtitle_label.text = _i18n("boot_loading")
	_style_progress_bar()
	_boot()


func _wire_static_boot_logo() -> void:
	var main_logo := LnUiLib.BOOT_LOGO_PATH if ResourceLoader.exists(LnUiLib.BOOT_LOGO_PATH) else LnUiLib.LOGO_PATH
	if logo_image != null and ResourceLoader.exists(main_logo):
		var tex: Texture2D = load(main_logo)
		logo_image.texture = tex
		logo_image.modulate = Color.WHITE
		_fit_boot_logo(tex)
	var glow := get_node_or_null("Center/VBox/LogoStack/LogoGlow") as TextureRect
	if glow != null:
		glow.visible = false
	var anim := get_node_or_null("AnimationPlayer") as AnimationPlayer
	if anim != null:
		anim.stop()
		anim.autoplay = ""


func _fit_boot_logo(tex: Texture2D) -> void:
	var stack := logo_image.get_parent() as Control
	if stack == null or tex == null:
		return
	var tex_size := tex.get_size()
	if tex_size.x <= 0.0 or tex_size.y <= 0.0:
		return
	var vp := get_viewport_rect().size
	var aspect := tex_size.x / tex_size.y
	var max_w := vp.x * 0.88
	var max_h := vp.y * 0.68
	var w := max_w
	var h := w / aspect
	if h > max_h:
		h = max_h
		w = h * aspect
	stack.custom_minimum_size = Vector2(w, h)
	logo_image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _apply_theme() -> void:
	var theme_mgr := _autoload("ThemeManager")
	var bg := ThemeTokensLib.COLOR_BG
	if theme_mgr != null and theme_mgr.has_method("get_background_color"):
		bg = theme_mgr.call("get_background_color")
	background.color = Color(bg, 0.42)
	subtitle_label.add_theme_color_override("font_color", ThemeTokensLib.LOADING_TEXT_COLOR)

	if background_art != null:
		background_art.visible = true
		var tex_path := ""
		if theme_mgr != null and theme_mgr.has_method("get_background_texture_path"):
			tex_path = str(theme_mgr.call("get_background_texture_path"))
		var tex := LnUiLib.load_background_texture(tex_path)
		if tex == null:
			tex = LnUiLib.load_background_texture("res://icon.png")
		if tex != null:
			background_art.texture = tex
		background_art.modulate = Color(1.0, 1.0, 1.0, 0.92)


func _style_progress_bar() -> void:
	var theme_mgr := _autoload("ThemeManager")
	var panel := LnUiLib.PANEL
	var primary := LnUiLib.ACCENT
	if theme_mgr != null:
		if theme_mgr.has_method("get_panel_color"):
			panel = theme_mgr.call("get_panel_color")
		if theme_mgr.has_method("get_primary_color"):
			primary = theme_mgr.call("get_primary_color")
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.10)
	bg.set_corner_radius_all(4)
	bg.set_border_width_all(1)
	bg.border_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.25)
	var fill := StyleBoxFlat.new()
	fill.bg_color = LnUiLib.GOAL
	fill.set_corner_radius_all(4)
	fill.shadow_color = Color(LnUiLib.GOAL, 0.55)
	fill.shadow_size = 8
	progress_bar.add_theme_stylebox_override("background", bg)
	progress_bar.add_theme_stylebox_override("fill", fill)


func _boot() -> void:
	progress_bar.value = 0.0
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(progress_bar, "value", 55.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save"):
		save.call("has_save")

	var migration := _autoload("LegacySaveMigration")
	if migration != null and migration.has_method("try_migrate_on_startup"):
		migration.call("try_migrate_on_startup")

	load(APP_SCENE)
	await tween.finished

	var finish := create_tween()
	finish.tween_property(progress_bar, "value", 100.0, 0.45) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await finish.finished

	var fade := create_tween()
	fade.tween_property(self, "modulate:a", 0.0, 0.22)
	await fade.finished

	get_tree().change_scene_to_file(APP_SCENE)
