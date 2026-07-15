extends Button
class_name NeonButton

## Dark Neon Fantasy button — primary / secondary / ghost / success variants.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const PRESS_SCALE := 0.98
const PRESS_TIME := 0.15

@export_enum("primary", "secondary", "ghost", "success") var variant: String = "secondary":
	set(value):
		variant = value
		if is_inside_tree():
			_apply_styles()

var _press_tween: Tween = null


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


func _focus_ring(radius: int, color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.draw_center = false
	style.set_corner_radius_all(radius)
	style.set_border_width_all(2)
	style.border_color = color
	style.set_expand_margin_all(3.0)
	style.shadow_color = Color(color, 0.35)
	style.shadow_size = 8
	return style


func _apply_primary() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var themed := LnUiLib.primary_button_normal()
	if themed is StyleBoxTexture:
		var hover := LnUiLib.button_hover()
		var pressed := LnUiLib.button_pressed()
		var disabled := LnUiLib.button_disabled()
		_set_styleboxes(themed, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.MENU_PRIMARY_BORDER))
		_set_font_colors(Color.WHITE, Color.WHITE)
		add_theme_font_size_override("font_size", 16)
		return
	var normal := _base_stylebox(radius)
	normal.bg_color = ThemeTokensLib.MENU_PRIMARY_BG_START.lerp(ThemeTokensLib.MENU_PRIMARY_BG_END, 0.5)
	normal.set_border_width_all(2)
	normal.border_color = ThemeTokensLib.MENU_PRIMARY_BORDER
	normal.shadow_color = ThemeTokensLib.MENU_PRIMARY_GLOW
	normal.shadow_size = 12

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.border_color = ThemeTokensLib.COLOR_SECONDARY
	hover.shadow_size = 18

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.06)
	pressed.shadow_size = 6

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(normal.bg_color, 0.35)
	disabled.shadow_size = 0

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.MENU_PRIMARY_BORDER))
	_set_font_colors(Color.WHITE, Color.WHITE)
	add_theme_font_size_override("font_size", 16)


func _apply_success() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var themed := LnUiLib.success_button_normal()
	if themed is StyleBoxTexture:
		var hover := LnUiLib.button_hover()
		var pressed := LnUiLib.button_pressed()
		var disabled := LnUiLib.button_disabled()
		_set_styleboxes(themed, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.MENU_SUCCESS_BORDER))
		_set_font_colors(Color.WHITE, Color.WHITE)
		add_theme_font_size_override("font_size", 16)
		return
	var normal := _base_stylebox(radius)
	normal.bg_color = ThemeTokensLib.MENU_SUCCESS_BG_START.lerp(ThemeTokensLib.MENU_SUCCESS_BG_END, 0.5)
	normal.set_border_width_all(2)
	normal.border_color = ThemeTokensLib.MENU_SUCCESS_BORDER
	normal.shadow_color = ThemeTokensLib.MENU_SUCCESS_GLOW
	normal.shadow_size = 12

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.08)
	hover.shadow_size = 18

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.06)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(normal.bg_color, 0.35)
	disabled.shadow_size = 0

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.MENU_SUCCESS_BORDER))
	_set_font_colors(Color.WHITE, Color.WHITE)
	add_theme_font_size_override("font_size", 16)


func _apply_secondary() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var normal := LnUiLib.button_normal()
	normal.content_margin_top = 12.0
	normal.content_margin_bottom = 12.0

	var hover := LnUiLib.button_hover()
	hover.content_margin_top = 12.0
	hover.content_margin_bottom = 12.0

	var pressed := LnUiLib.button_pressed()
	pressed.content_margin_top = 12.0
	pressed.content_margin_bottom = 12.0

	var disabled := LnUiLib.button_disabled()

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.COLOR_PRIMARY))
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
