extends RefCounted
class_name LnUi

## Shared gothic UI helper for Lost Number.
## Keeps every screen on one visual language: dark gothic background,
## glass panels, pink/violet neon accents and soft mobile-safe animation.

const BG_DARK := Color("#08030F")
const DIM_DARK := Color(0.03, 0.01, 0.06, 0.66)
const PANEL := Color(0.14, 0.07, 0.19, 0.84)
const PANEL_2 := Color(0.20, 0.10, 0.25, 0.88)
const PANEL_HOVER := Color(0.26, 0.13, 0.31, 0.92)
const PANEL_PRESSED := Color(0.10, 0.05, 0.13, 0.96)
const BORDER := Color(0.55, 0.30, 0.57, 0.55)
const BORDER_ACTIVE := Color(1.0, 0.37, 0.70, 0.85)
const TEXT := Color("#F8EFFF")
const TEXT_MUTED := Color("#CDBBDD")
const TEXT_DISABLED := Color("#7B6A86")
const ACCENT := Color("#FF5FB3")
const ACCENT_2 := Color("#B45CFF")
const ACCENT_SOFT := Color("#E186FF")
const VALID := Color("#4DFF7A")
const INVALID := Color("#FF4D6D")
const XP := Color("#FF5FB3")
const GOAL := Color("#57F26D")

const RADIUS_PANEL := 22
const RADIUS_BUTTON := 22
const RADIUS_SMALL := 14

static func glass_box(radius: int = RADIUS_PANEL, border_width: int = 2, bg: Color = PANEL, border: Color = BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.38)
	sb.shadow_size = 10
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb

static func glass_panel(radius: int = RADIUS_PANEL) -> StyleBoxFlat:
	return glass_box(radius, 2, PANEL, BORDER)

static func active_panel(radius: int = RADIUS_PANEL) -> StyleBoxFlat:
	return glass_box(radius, 2, PANEL_2, BORDER_ACTIVE)

static func button_normal() -> StyleBoxFlat:
	return glass_box(RADIUS_BUTTON, 2, PANEL, BORDER)

static func button_hover() -> StyleBoxFlat:
	return glass_box(RADIUS_BUTTON, 2, PANEL_HOVER, BORDER_ACTIVE)

static func button_pressed() -> StyleBoxFlat:
	return glass_box(RADIUS_BUTTON, 2, PANEL_PRESSED, BORDER_ACTIVE)

static func button_disabled() -> StyleBoxFlat:
	return glass_box(RADIUS_BUTTON, 2, Color(0.10, 0.07, 0.13, 0.58), Color(0.35, 0.23, 0.39, 0.38))

static func pill(bg: Color = PANEL_2, border: Color = BORDER_ACTIVE) -> StyleBoxFlat:
	var sb := glass_box(999, 2, bg, border)
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb

static func apply_button(btn: Button, big: bool = true) -> void:
	if btn == null:
		return
	btn.add_theme_stylebox_override("normal", button_normal())
	btn.add_theme_stylebox_override("hover", button_hover())
	btn.add_theme_stylebox_override("pressed", button_pressed())
	btn.add_theme_stylebox_override("disabled", button_disabled())
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", TEXT)
	btn.add_theme_color_override("font_pressed_color", TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	btn.add_theme_font_size_override("font_size", 22 if big else 16)
	btn.custom_minimum_size.y = 68 if big else 46
	btn.focus_mode = Control.FOCUS_NONE
	btn.expand_icon = true

static func apply_icon_button(btn: Button) -> void:
	apply_button(btn, false)
	btn.custom_minimum_size = Vector2(46, 46)

static func apply_title(label: Label, size: int = 40) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

static func apply_body(label: Label, size: int = 18) -> void:
	if label == null:
		return
	label.add_theme_color_override("font_color", TEXT_MUTED)
	label.add_theme_font_size_override("font_size", size)

static func apply_panel(panel: PanelContainer, active: bool = false) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", active_panel() if active else glass_panel())

static func apply_progress_bar(bar: ProgressBar, fill_color: Color) -> void:
	if bar == null:
		return
	var bg := StyleBoxFlat.new()
	bg.bg_color = Color(0.08, 0.04, 0.11, 0.72)
	bg.set_corner_radius_all(999)
	bg.set_border_width_all(1)
	bg.border_color = Color(BORDER, 0.55)
	var fill := StyleBoxFlat.new()
	fill.bg_color = fill_color
	fill.set_corner_radius_all(999)
	fill.shadow_color = Color(fill_color, 0.36)
	fill.shadow_size = 7
	bar.add_theme_stylebox_override("background", bg)
	bar.add_theme_stylebox_override("fill", fill)
	bar.show_percentage = false

static func apply_check(check: CheckButton) -> void:
	if check == null:
		return
	check.add_theme_color_override("font_color", TEXT)
	check.add_theme_color_override("font_pressed_color", TEXT)
	check.add_theme_color_override("font_hover_color", TEXT)
	check.add_theme_font_size_override("font_size", 18)
	check.custom_minimum_size.y = 52

static func set_icon(button: Button, path: String) -> void:
	if button == null or not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true

static func set_background(root: Control, bg_path: String, dim_alpha: float = 0.66) -> void:
	if root == null:
		return
	var bg := root.get_node_or_null("LN_Background") as TextureRect
	if bg == null:
		bg = TextureRect.new()
		bg.name = "LN_Background"
		root.add_child(bg)
		root.move_child(bg, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if ResourceLoader.exists(bg_path):
		bg.texture = load(bg_path)

	var dim := root.get_node_or_null("LN_BackdropDim") as ColorRect
	if dim == null:
		dim = ColorRect.new()
		dim.name = "LN_BackdropDim"
		root.add_child(dim)
		root.move_child(dim, min(1, root.get_child_count() - 1))
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = 0
	dim.offset_top = 0
	dim.offset_right = 0
	dim.offset_bottom = 0
	dim.color = Color(0.03, 0.01, 0.06, dim_alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

static func fade_in(control: Control, lift: float = 12.0, time: float = 0.22) -> void:
	if control == null or not control.is_inside_tree():
		return
	var target_y := control.position.y
	control.modulate.a = 0.0
	control.position.y = target_y + lift
	var tween := control.create_tween().set_parallel(true)
	tween.tween_property(control, "modulate:a", 1.0, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.tween_property(control, "position:y", target_y, time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
