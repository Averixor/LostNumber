extends Control
class_name TileView

## Themed grid cell with 2.5D bevel, shadow, chain glow, and press lift.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const PRESS_LIFT := 3.0
const BEVEL_THICKNESS := 3.0
const SIDE_BEVEL := 2.5
## Mirrors css/grid.css .tile-crown — small watermark at top, number stays centered.
const CROWN_SIZE_RATIO := 0.22
const CROWN_TOP_RATIO := 0.06
const CROWN_MIN_PX := 11.0
const CROWN_MAX_PX := 14.0
const CROWN_WATERMARK_ALPHA := 0.38

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _shadow: ColorRect = $Shadow
@onready var _bg: Control = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _top_edge: ColorRect = $Bg/TopEdge
@onready var _bottom_edge: ColorRect = $Bg/BottomEdge
@onready var _left_edge: ColorRect = $Bg/LeftEdge
@onready var _right_edge: ColorRect = $Bg/RightEdge
@onready var _label: Label = $Bg/Label
@onready var _chain_highlight: PanelContainer = $ChainHighlight
@onready var _chain_fill: ColorRect = $ChainHighlight/Fill
@onready var _carry_badge: Label = $CarryBadge

var _crown_icon: TextureRect

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0
var _base_position: Vector2 = Vector2.ZERO

var _selected: bool = false
var _chain_preview: String = ""
var _frozen: bool = false
var _bonus_mode: bool = false
var _carry: bool = false
var _target: bool = false
var _pressed: bool = false
var _lift_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_position = position
	_apply_bevelling()
	_ensure_crown_icon()
	_apply_panel_style()
	_apply_label_depth()
	_chain_highlight.visible = false
	_refresh_visual()


func _apply_bevelling() -> void:
	_top_edge.offset_bottom = BEVEL_THICKNESS
	_bottom_edge.offset_top = -BEVEL_THICKNESS
	_left_edge.offset_right = SIDE_BEVEL
	_right_edge.offset_left = cell_size.x - SIDE_BEVEL


func _apply_label_depth() -> void:
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))


func _ensure_crown_icon() -> void:
	if _crown_icon != null:
		return

	var crown_texture: Texture2D = _load_crown_texture()
	if crown_texture == null:
		return

	_crown_icon = _make_crown_layer("CrownIcon", crown_texture)
	_crown_icon.visible = false
	_crown_icon.z_index = 0
	_crown_icon.modulate = Color(1.0, 1.0, 1.0, CROWN_WATERMARK_ALPHA)
	_bg.add_child(_crown_icon)
	_bg.move_child(_crown_icon, 0)
	_label.z_index = 2
	_layout_crown_and_label()


func _load_crown_texture() -> Texture2D:
	var png_path := "res://assets/ui/icons/neon/tile-crown.png"
	if ResourceLoader.exists(png_path):
		return load(png_path)
	var svg_path := "res://assets/ui/icons/neon/tile-crown.svg"
	if ResourceLoader.exists(svg_path):
		return load(svg_path)
	svg_path = "res://assets/ui/icons/tile-crown.svg"
	if ResourceLoader.exists(svg_path):
		return load(svg_path)
	return null


func _make_crown_layer(layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer


func setup(pos: Vector2i, number: int) -> void:
	grid_pos = pos
	if _crown_icon != null:
		_layout_crown_and_label()
	set_value(number)


func _layout_crown_and_label() -> void:
	if _crown_icon == null:
		return

	var tile_side := minf(cell_size.x, cell_size.y)
	var crown_side := clampf(tile_side * CROWN_SIZE_RATIO, CROWN_MIN_PX, CROWN_MAX_PX)
	var crown_top := clampf(tile_side * CROWN_TOP_RATIO, 2.0, 6.0)
	var crown_size := Vector2(crown_side, crown_side)

	_crown_icon.custom_minimum_size = crown_size
	_crown_icon.size = crown_size
	_crown_icon.position = Vector2((cell_size.x - crown_side) * 0.5, crown_top)


func set_value(number: int) -> void:
	var changed := value != number
	value = number
	_label.text = "" if number <= 0 else str(number)
	_refresh_visual()
	if changed and number > 0 and is_inside_tree():
		var tween := create_tween()
		scale = Vector2.ONE
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func set_chain_selected(selected: bool, preview: String = "") -> void:
	_selected = selected
	_chain_preview = preview if selected else ""
	_refresh_visual()


func set_chain_selected(_active: bool, _ok: bool = true) -> void:
	_chain_highlight.visible = false

func set_pressed_visual(pressed: bool) -> void:
	if _pressed == pressed:
		return
	_pressed = pressed
	var target_y := _base_position.y - PRESS_LIFT if pressed else _base_position.y
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, "position:y", target_y, 0.08) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func set_target_highlight(active: bool) -> void:
	_target = active
	_refresh_visual()

func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	_refresh_visual()

func set_bonus_mode(active: bool) -> void:
	_bonus_mode = active
	_refresh_visual()

func set_carry(active: bool) -> void:
	_carry = active
	_carry_badge.visible = false
	_refresh_visual()

func _apply_panel_style() -> void:
	_shadow.color = Color(0, 0, 0, 0.28)


func _get_rim_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var palette: Dictionary = theme.call("get_palette")
		return Color(palette.get("rim", Color("#D4AF37")), 0.65)
	return Color("#D4AF37", 0.55)


func _draw() -> void:
	if value <= 0:
		return
	var rim := _get_rim_color()
	var rect := Rect2(Vector2.ZERO, size - Vector2(0, 4))
	if ThemeTokensLib.is_legendary_tile_value(value):
		draw_rect(rect, Color(rim, 0.55), false, 2.0)
	else:
		draw_rect(rect, Color(rim, 0.42), false, 1.5)


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	if value <= 0:
		_inner.color = Color.TRANSPARENT
		_top_edge.color = Color.TRANSPARENT
		_bottom_edge.color = Color.TRANSPARENT
		_left_edge.color = Color.TRANSPARENT
		_right_edge.color = Color.TRANSPARENT
		_shadow.visible = false
		_label.text = ""
		if _crown_icon != null:
			_crown_icon.visible = false
		queue_redraw()
		return

	_shadow.visible = true
	var face_color: Color
	if _frozen:
		face_color = ThemeTokensLib.TILE_FROZEN_BG
	elif _bonus_mode:
		face_color = ThemeTokensLib.COLOR_PREVIEW_INVALID.lightened(0.05)
	elif _selected and not _chain_preview.is_empty():
		face_color = _chain_face_color(_chain_preview)
	else:
		face_color = _color_for_value(value)

	_inner.color = face_color
	var top_lift := 0.18
	var bottom_shade := 0.22
	var side_lift := 0.08
	_top_edge.color = Color(face_color.lightened(top_lift), 0.88)
	_bottom_edge.color = Color(face_color.darkened(bottom_shade), 0.92)
	_left_edge.color = Color(face_color.lightened(side_lift), 0.78)
	_right_edge.color = Color(face_color.darkened(side_lift + 0.06), 0.82)

	var text_color := Color.WHITE if _selected else ThemeTokensLib.tile_text_color_for(face_color, value)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", _tile_font_size())
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))

	_label.offset_top = 0.0
	_label.offset_bottom = 0.0

	if _crown_icon != null:
		_crown_icon.visible = _target and not _frozen and not _bonus_mode

	_chain_highlight.visible = false
	if _selected and not _frozen and not _bonus_mode and not _chain_preview.is_empty():
		_chain_highlight.visible = true
		var border_color := _chain_border_color(_chain_preview)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(border_color, 0.08)
		panel_style.border_color = Color(border_color, 0.92)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		panel_style.shadow_color = Color(border_color, 0.35)
		panel_style.shadow_size = 6
		_chain_highlight.add_theme_stylebox_override("panel", panel_style)
	queue_redraw()


func refresh_font_size() -> void:
	_refresh_visual()


func _tile_font_size() -> int:
	var digits := 1
	if value > 0:
		digits = str(value).length()
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_tile_font_size"):
		return int(settings.call("get_tile_font_size", cell_size, digits))
	return ThemeTokensLib.tile_font_size_for_cell(cell_size, digits, 1.0)


func _chain_face_color(preview: String) -> Color:
	match preview:
		"valid":
			var pair: Array = ThemeTokensLib.TILE_VALID_GRADIENT
			return pair[0].lerp(pair[1], 0.5)
		"invalid":
			var bad: Array = ThemeTokensLib.TILE_INVALID_GRADIENT
			return bad[0].lerp(bad[1], 0.5)
		_:
			return ThemeTokensLib.TILE_SELECTED_BG


func _chain_border_color(preview: String) -> Color:
	match preview:
		"valid":
			return ThemeTokensLib.COLOR_PREVIEW_VALID
		"invalid":
			return ThemeTokensLib.COLOR_PREVIEW_INVALID
		_:
			return ThemeTokensLib.COLOR_SECONDARY


func _color_for_value(n: int) -> Color:
	if ThemeTokensLib.TILE_COLORS.has(n):
		return ThemeTokensLib.TILE_COLORS[n]
	if ThemeTokensLib.TILE_GRADIENTS.has(n):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[n]
		return pair[0].lerp(pair[1], 0.5)
	var log_val := 0
	var t := n
	while t > 1:
		t /= 2
		log_val += 1
	return Color.from_hsv(fmod(log_val * 0.09 + 0.08, 1.0), 0.52, 0.78)