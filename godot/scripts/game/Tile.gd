extends Control
class_name TileView

## Themed grid cell with 2.5D bevel, shadow, chain glow, and press lift.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const PRESS_LIFT := 3.0
const BEVEL_THICKNESS := 4.0
const SIDE_BEVEL := 3.5
const FACE_DARKEN := 0.30
const Z_FACE := 0
const Z_CROWN := 1
const Z_SELECTION := 2
const Z_LABEL := 3
## Mirrors css/grid.css .tile-crown — crown in top free space, number centered below.
const CROWN_SIZE_RATIO := 0.24
const CROWN_TOP_RATIO := 0.08
const CROWN_MIN_PX := 14.0
const CROWN_MAX_PX := 20.0
const CROWN_LABEL_PUSH_RATIO := 0.12
const CROWN_LABEL_PUSH_MIN_PX := 4.0
const CROWN_LABEL_PUSH_MAX_PX := 6.0
const CROWN_GLOW_COLOR := Color(1.0, 0.36, 0.86, 0.75)

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
	_stack_chain_highlight_under_label()
	_chain_highlight.visible = false
	_refresh_visual()


func _stack_chain_highlight_under_label() -> void:
	# Stack vs Board ChainLineLayer (z=1): face → laser → selection → label.
	_bg.z_index = Z_FACE
	if _chain_highlight.get_parent() != _bg:
		var insert_at := _label.get_index()
		_chain_highlight.reparent(_bg)
		_bg.move_child(_chain_highlight, insert_at)
		_chain_highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_chain_highlight.offset_bottom = 0.0
	_chain_highlight.z_as_relative = false
	_chain_highlight.z_index = Z_SELECTION
	_label.z_as_relative = false
	_label.z_index = Z_LABEL


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
	_crown_icon.z_as_relative = false
	_crown_icon.z_index = Z_CROWN
	_crown_icon.modulate = CROWN_GLOW_COLOR
	_bg.add_child(_crown_icon)
	_bg.move_child(_crown_icon, _label.get_index())
	_label.z_as_relative = false
	_label.z_index = Z_LABEL
	_layout_crown_and_label()


func _load_crown_texture() -> Texture2D:
	var paths := [
		"res://assets/ui/icons/neon/tile-crown.png",
		"res://assets/ui/icons/tile-crown.png",
		"res://assets/ui/icons/neon/tile-crown.svg",
		"res://assets/ui/icons/tile-crown.svg",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
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


func _crown_label_push() -> float:
	var tile_side := minf(cell_size.x, cell_size.y)
	return clampf(
		tile_side * CROWN_LABEL_PUSH_RATIO,
		CROWN_LABEL_PUSH_MIN_PX,
		CROWN_LABEL_PUSH_MAX_PX
	)


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


func _apply_crown_label_offset(crown_visible: bool) -> void:
	_label.offset_top = _crown_label_push() if crown_visible else 0.0
	_label.offset_bottom = 0.0


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
	_shadow.color = Color(0, 0, 0, 0.55)
	_shadow.offset_top = 8.0
	_shadow.offset_left = 2.0
	_shadow.offset_right = cell_size.x + 2.0
	_shadow.offset_bottom = cell_size.y + 2.0


func _get_rim_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var palette: Dictionary = theme.call("get_palette")
		return Color(palette.get("rim", Color("#D4AF37")), 0.65)
	return Color("#D4AF37", 0.55)


func _draw() -> void:
	if value <= 0:
		return
	var face := _inner.color if _inner.color.a > 0.01 else _color_for_value(value)
	var glow := Color(face, 0.35)
	var rect := Rect2(Vector2(2, 2), size - Vector2(4, 6))
	draw_rect(rect.grow(2.0), glow, false, 3.0)
	var rim := _get_rim_color()
	var border_rect := Rect2(Vector2.ZERO, size - Vector2(0, 4))
	if ThemeTokensLib.is_legendary_tile_value(value):
		draw_rect(border_rect, Color(rim, 0.65), false, 2.0)
	else:
		draw_rect(border_rect, Color(face.lightened(0.15), 0.75), false, 2.0)


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
	else:
		# Keep value palette; chain state is border + light fill only (no face recolor).
		face_color = _color_for_value(value)

	# Darker center + stronger 3D bevel (light top, dark bottom/right).
	_inner.color = face_color.darkened(FACE_DARKEN)
	_top_edge.color = Color(face_color.lightened(0.28), 0.95)
	_bottom_edge.color = Color(face_color.darkened(0.42), 0.96)
	_left_edge.color = Color(face_color.lightened(0.12), 0.82)
	_right_edge.color = Color(face_color.darkened(0.32), 0.92)

	var text_color := ThemeTokensLib.tile_text_color_for(face_color, value)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", _tile_font_size())
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))

	var crown_visible := _target and not _frozen and not _bonus_mode
	if _crown_icon != null:
		_crown_icon.visible = crown_visible
	_apply_crown_label_offset(crown_visible)

	_chain_highlight.visible = false
	if _selected and not _frozen and not _bonus_mode and not _chain_preview.is_empty():
		_chain_highlight.visible = true
		var border_color := _chain_border_color(_chain_preview)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0, 0, 0, 0)
		panel_style.border_color = Color(border_color, 0.95)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		panel_style.shadow_color = Color(border_color, 0.35)
		panel_style.shadow_size = 4
		_chain_highlight.add_theme_stylebox_override("panel", panel_style)
		if _chain_fill != null:
			_chain_fill.color = Color(border_color, 0.12)
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


func _chain_border_color(preview: String) -> Color:
	match preview:
		"valid":
			return ThemeTokensLib.COLOR_CHAIN_VALID
		"invalid":
			return ThemeTokensLib.COLOR_CHAIN_INVALID
		_:
			return ThemeTokensLib.COLOR_CHAIN_CONTINUE


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
