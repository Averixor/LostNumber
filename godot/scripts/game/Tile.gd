extends Control
class_name TileView

## Themed grid cell with gothic crystal frame, 2.5D stone face, chain glow, and press lift.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const PRESS_LIFT := 3.0
const BEVEL_THICKNESS := 4.0
const SIDE_BEVEL := 3.5
const FACE_DARKEN := 0.10
const Z_FACE := 0
const Z_CROWN := 1
const Z_SELECTION := 2
const Z_LABEL := 3
## Carry crown: ~30% of tile height, centered in the top band above the digit.
const CROWN_SIZE_RATIO := 0.30
const CROWN_TOP_BAND_RATIO := 0.34
const CROWN_MIN_PX := 20.0
const CROWN_MAX_PX := 56.0
const CROWN_WATERMARK_ALPHA := 0.92
const CROWN_LABEL_PUSH_RATIO := 0.16

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _shadow: ColorRect = $Shadow
@onready var _bg: Control = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _top_edge: ColorRect = $Bg/TopEdge
@onready var _bottom_edge: ColorRect = $Bg/BottomEdge
@onready var _left_edge: ColorRect = $Bg/LeftEdge
@onready var _right_edge: ColorRect = $Bg/RightEdge
@onready var _frame: TextureRect = $Bg/Frame
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
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_refresh_visual)
	_refresh_visual()


func _stack_chain_highlight_under_label() -> void:
	# Stack vs Board ChainLineLayer (z=1): face/frame → laser → selection → label.
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
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.72))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))


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
	_crown_icon.modulate = Color(1.0, 0.88, 0.48, CROWN_WATERMARK_ALPHA)
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


func _layout_crown_and_label() -> void:
	if _crown_icon == null:
		return

	var tile_side := minf(cell_size.x, cell_size.y)
	var crown_side := clampf(tile_side * CROWN_SIZE_RATIO, CROWN_MIN_PX, CROWN_MAX_PX)
	var top_band := tile_side * CROWN_TOP_BAND_RATIO
	var crown_top := clampf((top_band - crown_side) * 0.5, 3.0, top_band - crown_side)
	var crown_size := Vector2(crown_side, crown_side)

	_crown_icon.custom_minimum_size = crown_size
	_crown_icon.size = crown_size
	_crown_icon.position = Vector2((cell_size.x - crown_side) * 0.5, crown_top)

	# Push digit slightly down so layout reads as “crown above number”.
	if _crown_icon.visible:
		var push := clampf(tile_side * CROWN_LABEL_PUSH_RATIO, 8.0, crown_side * 0.7)
		_label.offset_top = push
		_label.offset_bottom = 0.0
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		_label.offset_top = 0.0
		_label.offset_bottom = 0.0
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


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
	_shadow.color = Color(0, 0, 0, 0.64)
	_shadow.offset_top = 8.0
	_shadow.offset_left = 2.0
	_shadow.offset_right = cell_size.x + 2.0
	_shadow.offset_bottom = cell_size.y + 2.0


func _get_rim_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var palette: Dictionary = theme.call("get_palette")
		return Color(palette.get("rim", GothicVisualsLib.GOLD), 0.78)
	return Color(GothicVisualsLib.GOLD, 0.72)


func _draw() -> void:
	if value <= 0:
		return
	var face := _inner.color if _inner.color.a > 0.01 else _color_for_value(value)
	var rim := _get_rim_color()
	var rect := Rect2(Vector2(2, 2), size - Vector2(4, 6))
	var aura := rim if ThemeTokensLib.is_legendary_tile_value(value) else face.lightened(0.22)
	draw_rect(rect.grow(1.5), Color(aura, 0.30), false, 2.0)


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	if value <= 0:
		_inner.color = Color.TRANSPARENT
		_top_edge.color = Color.TRANSPARENT
		_bottom_edge.color = Color.TRANSPARENT
		_left_edge.color = Color.TRANSPARENT
		_right_edge.color = Color.TRANSPARENT
		_frame.visible = false
		_shadow.visible = false
		_label.text = ""
		if _crown_icon != null:
			_crown_icon.visible = false
		queue_redraw()
		return

	_shadow.visible = true
	_frame.visible = true
	var face_color: Color
	if _frozen:
		face_color = ThemeTokensLib.TILE_FROZEN_BG
	else:
		# Value remains data-driven; the art frame never contains a baked number.
		face_color = _color_for_value(value)

	# Stone center with restrained bevel. The ornate SVG frame carries the material identity.
	_inner.color = face_color.darkened(FACE_DARKEN)
	_top_edge.color = Color(face_color.lightened(0.16), 0.62)
	_bottom_edge.color = Color(face_color.darkened(0.34), 0.88)
	_left_edge.color = Color(face_color.lightened(0.08), 0.54)
	_right_edge.color = Color(face_color.darkened(0.24), 0.76)
	_frame.modulate = GothicVisualsLib.tile_frame_tint(value, _frozen, _get_rim_color())

	var text_color := GothicVisualsLib.tile_text_color(face_color, value)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", _tile_font_size())
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.74))
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.58))

	if _crown_icon != null:
		# Crown marks the singular carry tile from the previous level — never board-max.
		_crown_icon.visible = _carry and not _frozen
		_layout_crown_and_label()
	else:
		_label.offset_top = 0.0
		_label.offset_bottom = 0.0

	_chain_highlight.visible = false
	if _bonus_mode and not _frozen:
		_chain_highlight.visible = true
		var pick_color := ThemeTokensLib.COLOR_ACCENT_ORANGE
		var pick_style := StyleBoxFlat.new()
		pick_style.bg_color = Color(0, 0, 0, 0)
		pick_style.border_color = Color(pick_color, 0.90)
		pick_style.set_border_width_all(2)
		pick_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		pick_style.shadow_color = Color(pick_color, 0.34)
		pick_style.shadow_size = 5
		_chain_highlight.add_theme_stylebox_override("panel", pick_style)
		if _chain_fill != null:
			_chain_fill.color = Color(pick_color, 0.08)
	elif _selected and not _frozen and not _chain_preview.is_empty():
		_chain_highlight.visible = true
		var border_color := _chain_border_color(_chain_preview)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0, 0, 0, 0)
		panel_style.border_color = Color(border_color, 0.98)
		panel_style.set_border_width_all(2)
		panel_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		panel_style.shadow_color = Color(border_color, 0.42)
		panel_style.shadow_size = 6
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
	if ThemeTokensLib.TILE_GRADIENTS.has(n):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[n]
		return pair[0].lerp(pair[1], 0.5).darkened(0.38)
	return GothicVisualsLib.tile_face_color(n)
