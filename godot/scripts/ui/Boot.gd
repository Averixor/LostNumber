extends Control

## Boot/splash screen (web parity: .app-splash + .loading-spinner).
## Preloads the App shell + warms managers, then fades into App.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const APP_SCENE := "res://scenes/App.tscn"

@onready var title_label: Label = $Center/VBox/Title
@onready var subtitle_label: Label = $Center/VBox/Subtitle
@onready var progress_bar: ProgressBar = $Center/VBox/Progress
@onready var background: ColorRect = $Background


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	background.color = ThemeTokensLib.COLOR_BG
	title_label.text = _i18n("app_title").to_upper()
	subtitle_label.text = _i18n("boot_loading")
	subtitle_label.add_theme_color_override("font_color", ThemeTokensLib.LOADING_TEXT_COLOR)
	_style_progress_bar()
	_apply_title_gradient_height()
	_boot()


func _style_progress_bar() -> void:
	var bg := StyleBoxFlat.new()
	bg.bg_color = ThemeTokensLib.COLOR_PANEL
	bg.set_corner_radius_all(ThemeTokensLib.RADIUS_SMALL)
	bg.set_border_width_all(1)
	bg.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	var fill := StyleBoxFlat.new()
	fill.bg_color = ThemeTokensLib.SPINNER_COLOR
	fill.set_corner_radius_all(ThemeTokensLib.RADIUS_SMALL)
	progress_bar.add_theme_stylebox_override("background", bg)
	progress_bar.add_theme_stylebox_override("fill", fill)


func _apply_title_gradient_height() -> void:
	var material := title_label.material
	if material is ShaderMaterial:
		var height: float = maxf(title_label.get_minimum_size().y, 1.0)
		(material as ShaderMaterial).set_shader_parameter("gradient_height", height)


func _boot() -> void:
	progress_bar.value = 0.0
	await get_tree().process_frame

	var tween := create_tween()
	tween.tween_property(progress_bar, "value", 55.0, 0.55) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)

	# Real preload: warm save check, optional legacy import, preload App scene.
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
