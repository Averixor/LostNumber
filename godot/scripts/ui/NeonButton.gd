extends Button
class_name NeonButton

## Dark Neon Fantasy button — primary / secondary / ghost / success variants.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")

const PRESS_SCALE := 0.98
const PRESS_TIME := 0.15

@export_enum("primary", "secondary", "ghost", "success") var variant: String = "secondary":
	set(value):
		variant = value
		if is_inside_tree():
			_apply_styles()

var _press_tween: Tween = null
var _gothic_cta: bool = false


func set_gothic_cta(value: bool) -> void:
	_gothic_cta = value
	if is_inside_tree():
		_apply_styles()


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	custom_minimum_size.y = maxf(custom_minimum_size.y, 48.0)
	_apply_styles()
	resized.connect(_update_pivot)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_styles)
	_update_pivot()


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _on_button_down() -> void:
	_animate_scale(PRESS_SCALE)


func _on_button_up() -> void:
	_animate_scale(1.0)


func _animate_scale(target: float) -> void:
	if not LnUiLib.effects_enabled():
		scale = Vector2.ONE
		return
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2.ONE * target, PRESS_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_styles() -> void:
	if _gothic_cta:
		_apply_gothic_cta()
		return
	match variant:
		"primary":
			_apply_primary()
		"success":
			_apply_success()
		"ghost":
			_apply_ghost()
		_:
			_apply_secondary()


func _base_stylebox(radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(radius)
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	return style


func _focus_ring(radius: int, color: Color, glow: bool = true) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = color
	style.set_expand_margin_all(3.0)
	if glow:
		style.shadow_color = Color(color, 0.35)
		style.shadow_size = 8
	return style


func _apply_primary() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var use_skin := _uses_visual_skin()
	var themed := LnUiLib.primary_button_normal(use_skin)
	if themed is StyleBoxTexture:
		var hover := LnUiLib.button_hover(use_skin)
		var pressed := LnUiLib.button_pressed(use_skin)
		var disabled := LnUiLib.button_disabled(use_skin)
		_set_styleboxes(themed, hover, pressed, disabled, _focus_ring(radius, _menu_primary_border(), false))
		_set_font_colors(Color.WHITE, Color.WHITE)
		add_theme_font_size_override("font_size", 16)
		return
	var normal := _base_stylebox(radius)
	var bg_start := _menu_primary_bg_start()
	var bg_end := _menu_primary_bg_end()
	normal.bg_color = bg_start.lerp(bg_end, 0.5)
	normal.set_border_width_all(2)
	normal.border_color = _menu_primary_border()
	normal.shadow_color = Color(_menu_primary_border(), 0.12)
	normal.shadow_size = 4

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = ThemeTokensLib.COLOR_SECONDARY
	hover.shadow_size = 6

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.06)
	pressed.shadow_size = 2

	var disabled: StyleBoxFlat = _gothic_disabled_stylebox(radius)

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, _menu_primary_border(), false))
	_set_font_colors(Color.WHITE, Color.WHITE)
	add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	add_theme_font_size_override("font_size", 16)


func _apply_gothic_cta() -> void:
	var palette := _gothic_palette()
	_set_styleboxes(
		GothicVisualsLib.cta_button(palette, "normal"),
		GothicVisualsLib.cta_button(palette, "hover"),
		GothicVisualsLib.cta_button(palette, "pressed"),
		GothicVisualsLib.cta_button(palette, "disabled"),
		GothicVisualsLib.cta_button(palette, "hover")
	)
	_set_font_colors(GothicVisualsLib.TEXT_IVORY, GothicVisualsLib.GOLD_LIGHT)
	add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	add_theme_font_size_override("font_size", 16)


func _gothic_palette() -> Dictionary:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_palette"):
		var use_skin := theme_mgr.has_method("get_visual_skin") and theme_mgr.call("get_visual_skin") != null
		return theme_mgr.call("get_palette", use_skin)
	return {}


func _gothic_disabled_stylebox(radius: int) -> StyleBoxFlat:
	var disabled := _base_stylebox(radius)
	disabled.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.55)
	disabled.border_color = Color(GothicVisualsLib.IRON, 0.45)
	disabled.shadow_size = 0
	return disabled


func _apply_success() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var use_skin := _uses_visual_skin()
	var themed := LnUiLib.success_button_normal(use_skin)
	if themed is StyleBoxTexture:
		var hover := LnUiLib.button_hover(use_skin)
		var pressed := LnUiLib.button_pressed(use_skin)
		var disabled := LnUiLib.button_disabled(use_skin)
		_set_styleboxes(themed, hover, pressed, disabled, _focus_ring(radius, _menu_success_border()))
		_set_font_colors(Color.WHITE, Color.WHITE)
		add_theme_font_size_override("font_size", 16)
		return
	var normal := _base_stylebox(radius)
	var bg_start := _menu_success_bg_start()
	var bg_end := _menu_success_bg_end()
	normal.bg_color = bg_start.lerp(bg_end, 0.5)
	normal.set_border_width_all(2)
	normal.border_color = _menu_success_border()
	normal.shadow_color = _menu_success_glow()
	normal.shadow_size = 12

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.shadow_size = 18

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.06)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(normal.bg_color, 0.35)
	disabled.shadow_size = 0

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, _menu_success_border()))
	_set_font_colors(Color.WHITE, Color.WHITE)
	add_theme_font_size_override("font_size", 16)


func _apply_secondary() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var use_skin := _uses_visual_skin()
	var normal := LnUiLib.button_normal(use_skin)
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0

	var hover := LnUiLib.button_hover(use_skin)
	hover.content_margin_top = 12.0
	hover.content_margin_bottom = 12.0

	var pressed := LnUiLib.button_pressed(use_skin)
	pressed.content_margin_top = 12.0
	pressed.content_margin_bottom = 12.0

	var disabled := LnUiLib.button_disabled(use_skin)

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, _menu_primary_border()))
	_set_font_colors(ThemeTokensLib.COLOR_TEXT, ThemeTokensLib.COLOR_SECONDARY)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY)


func _apply_ghost() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var normal := _base_stylebox(radius)
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_top = 8.0
	normal.content_margin_bottom = 8.0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.08)
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.14)
	var disabled: StyleBoxFlat = normal.duplicate()

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.COLOR_ACCENT))
	_set_font_colors(ThemeTokensLib.COLOR_PRIMARY, ThemeTokensLib.COLOR_SECONDARY)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)


func _set_styleboxes(normal: StyleBox, hover: StyleBox, pressed: StyleBox, disabled: StyleBox, focus: StyleBox) -> void:
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled)
	add_theme_stylebox_override("focus", focus)


func _set_font_colors(base: Color, active: Color) -> void:
	add_theme_color_override("font_color", base)
	add_theme_color_override("font_hover_color", base.lightened(0.08))
	add_theme_color_override("font_pressed_color", active)
	add_theme_color_override("font_focus_color", base)
	add_theme_color_override("font_disabled_color", Color(base, 0.45))


func _uses_visual_skin() -> bool:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	return theme_mgr != null and theme_mgr.has_method("get_visual_skin") and theme_mgr.call("get_visual_skin") != null


func _theme_color(method: String, fallback: Color) -> Color:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method(method):
		return theme_mgr.call(method, true)
	return fallback


func _menu_primary_border() -> Color:
	return _theme_color("get_primary_color", ThemeTokensLib.MENU_PRIMARY_BORDER)


func _menu_primary_glow() -> Color:
	return Color(_menu_primary_border(), 0.45)


func _menu_primary_bg_start() -> Color:
	return Color(_menu_primary_border(), 0.18)


func _menu_primary_bg_end() -> Color:
	return Color(ThemeTokensLib.MENU_PRIMARY_BG_END)


func _menu_success_border() -> Color:
	return _theme_color("get_success_color", ThemeTokensLib.MENU_SUCCESS_BORDER)


func _menu_success_glow() -> Color:
	return Color(_menu_success_border(), 0.40)


func _menu_success_bg_start() -> Color:
	return Color(_menu_success_border(), 0.14)


func _menu_success_bg_end() -> Color:
	return Color(ThemeTokensLib.MENU_SUCCESS_BG_END)
