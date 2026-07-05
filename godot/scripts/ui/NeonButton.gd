extends Button
class_name NeonButton

## Themed neon button (web .menu-btn parity). Variants:
## - "primary": gradient-pink pill with glow (web .main-menu__actions .menu-btn.primary)
## - "secondary": dark panel button (web .menu-btn)
## - "ghost": borderless text button (web .menu-btn.ghost)
## Focus shows an accent glow ring (important on Android), press scales to 0.97.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const PRESS_SCALE := 0.97
const PRESS_TIME := 0.08

@export_enum("primary", "secondary", "ghost") var variant: String = "secondary":
	set(value):
		variant = value
		if is_inside_tree():
			_apply_styles()

var _press_tween: Tween = null


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_apply_styles()
	resized.connect(_update_pivot)
	button_down.connect(_on_button_down)
	button_up.connect(_on_button_up)
	_update_pivot()


func _update_pivot() -> void:
	pivot_offset = size / 2.0


func _on_button_down() -> void:
	_animate_scale(PRESS_SCALE)


func _on_button_up() -> void:
	_animate_scale(1.0)


func _animate_scale(target: float) -> void:
	if _press_tween != null and _press_tween.is_valid():
		_press_tween.kill()
	_press_tween = create_tween()
	_press_tween.tween_property(self, "scale", Vector2.ONE * target, PRESS_TIME) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _apply_styles() -> void:
	match variant:
		"primary":
			_apply_primary()
		"ghost":
			_apply_ghost()
		_:
			_apply_secondary()


func _base_stylebox(radius: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(10.0)
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
	var radius := ThemeTokensLib.RADIUS_PILL
	var normal := _base_stylebox(radius)
	# Web gradient #ff5ba7 -> #ff7c6f approximated by midpoint fill + neon glow shadow.
	normal.bg_color = ThemeTokensLib.MENU_PRIMARY_BG_START.lerp(ThemeTokensLib.MENU_PRIMARY_BG_END, 0.5)
	normal.set_border_width_all(2)
	normal.border_color = ThemeTokensLib.MENU_PRIMARY_BORDER
	normal.shadow_color = ThemeTokensLib.MENU_PRIMARY_GLOW
	normal.shadow_size = 10
	normal.content_margin_top = 14.0
	normal.content_margin_bottom = 14.0

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.06)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = normal.bg_color.darkened(0.08)
	pressed.shadow_size = 5

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(normal.bg_color, 0.4)
	disabled.shadow_size = 0

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.MENU_PRIMARY_BORDER))
	_set_font_colors(Color.WHITE, Color.WHITE)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY + 2)


func _apply_secondary() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var normal := _base_stylebox(radius)
	normal.bg_color = ThemeTokensLib.COLOR_BTN_BG
	normal.set_border_width_all(2)
	normal.border_color = ThemeTokensLib.COLOR_BTN_BORDER

	var hover: StyleBoxFlat = normal.duplicate()
	hover.bg_color = normal.bg_color.lightened(0.05)
	hover.border_color = Color(ThemeTokensLib.COLOR_TEXT, 0.25)

	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = ThemeTokensLib.COLOR_CELL
	pressed.border_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.6)

	var disabled: StyleBoxFlat = normal.duplicate()
	disabled.bg_color = Color(normal.bg_color, 0.35)
	disabled.border_color = Color(normal.border_color, 0.4)

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.COLOR_ACCENT))
	_set_font_colors(ThemeTokensLib.COLOR_TEXT, ThemeTokensLib.COLOR_ACCENT)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY)


func _apply_ghost() -> void:
	var radius := ThemeTokensLib.RADIUS_BUTTON
	var normal := _base_stylebox(radius)
	normal.bg_color = Color(0, 0, 0, 0)
	normal.content_margin_top = 4.0
	normal.content_margin_bottom = 4.0

	var hover: StyleBoxFlat = normal.duplicate()
	var pressed: StyleBoxFlat = normal.duplicate()
	pressed.bg_color = Color(ThemeTokensLib.COLOR_TEXT, 0.06)
	var disabled: StyleBoxFlat = normal.duplicate()

	_set_styleboxes(normal, hover, pressed, disabled, _focus_ring(radius, ThemeTokensLib.COLOR_ACCENT))
	_set_font_colors(Color(ThemeTokensLib.COLOR_TEXT, 0.92), ThemeTokensLib.COLOR_ACCENT)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)


func _set_styleboxes(normal: StyleBoxFlat, hover: StyleBoxFlat, pressed: StyleBoxFlat, disabled: StyleBoxFlat, focus: StyleBoxFlat) -> void:
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", pressed)
	add_theme_stylebox_override("disabled", disabled)
	add_theme_stylebox_override("focus", focus)


func _set_font_colors(base: Color, active: Color) -> void:
	add_theme_color_override("font_color", base)
	add_theme_color_override("font_hover_color", base.lightened(0.1))
	add_theme_color_override("font_pressed_color", active)
	add_theme_color_override("font_focus_color", base)
	add_theme_color_override("font_disabled_color", Color(base, 0.45))
