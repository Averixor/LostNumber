extends Control
class_name TileView

## Themed grid cell with 2.5D bevel, shadow, chain glow, and press lift.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const PRESS_LIFT := 4.0

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _shadow: ColorRect = $Shadow
@onready var _bg: Control = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _top_edge: ColorRect = $Bg/TopEdge
@onready var _bottom_edge: ColorRect = $Bg/BottomEdge
@onready var _label: Label = $Bg/Label
@onready var _chain_highlight: PanelContainer = $ChainHighlight
@onready var _chain_fill: ColorRect = $ChainHighlight/Fill
@onready var _carry_badge: Label = $CarryBadge

var _crown_icon: TextureRect

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0
var _base_position: Vector2 = Vector2.ZERO

var _selected: bool = false
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
	_ensure_crown_icon()
	_apply_panel_style()
	_refresh_visual()


func _ensure_crown_icon() -> void:
	if _crown_icon != null:
		return
	var crown_path := "res://assets/ui/icons/neon/tile-crown.svg"
	if not ResourceLoader.exists(crown_path):
		crown_path = "res://assets/ui/icons/tile-crown.svg"
	if not ResourceLoader.exists(crown_path):
		return
	_crown_icon = TextureRect.new()
	_crown_icon.name = "CrownIcon"
	_crown_icon.texture = load(crown_path)
	_crown_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_crown_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_crown_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_crown_icon.visible = false
	_crown_icon.modulate = Color(ThemeTokensLib.TILE_GOLD_RIM, 0.88)
	_crown_icon.z_index = 2
	_bg.add_child(_crown_icon)
	_bg.move_child(_crown_icon, _label.get_index())
	_layout_crown_and_label()


func setup(pos: Vector2i, number: int) -> void:
	grid_pos = pos
	if _crown_icon != null:
		_layout_crown_and_label()
	set_value(number)


func _layout_crown_and_label() -> void:
	if _crown_icon == null:
		return
	var crown_side := minf(cell_size.x, cell_size.y) * 0.28
	var crown_size := Vector2(crown_side, crown_side)
	_crown_icon.custom_minimum_size = crown_size
	_crown_icon.size = crown_size
	var top_pad := maxf(2.0, cell_size.y * 0.08)
	_crown_icon.position = Vector2(
		(cell_size.x - crown_side) * 0.5,
		top_pad
	)
	if _label != null:
		_label.z_index = 3


func set_value(number: int) -> void:
	var changed := value != number
	value = number
	if number <= 0:
		_label.text = ""
	else:
		_label.text = str(number)
	_refresh_visual()
	if changed and number > 0 and is_inside_tree():
		var tween := create_tween()
		scale = Vector2.ONE
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func set_chain_selected(selected: bool, _valid_finish: bool = true) -> void:
	_selected = selected
	_chain_highlight.visible = false
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
	_shadow.color = Color(0, 0, 0, 0.35)


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
	if _target and not _frozen and not _bonus_mode:
		rim = ThemeTokensLib.TILE_GOLD_RIM
	var rect := Rect2(Vector2.ZERO, size - Vector2(0, 3))
	if _target and not _frozen and not _bonus_mode:
		draw_rect(rect.grow(1.5), Color(rim, 0.32), false, 3.0)
		draw_rect(rect, Color(rim, 0.92), false, 2.5)
	elif ThemeTokensLib.is_legendary_tile_value(value):
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
		face_color = _color_for_value(value)
		if _target:
			face_color = face_color.lightened(0.06)

	_inner.color = face_color
	var top_lift := 0.28 if _target else 0.22
	var bottom_shade := 0.18 if _target else 0.28
	_top_edge.color = Color(face_color.lightened(top_lift), 0.9 if _target else 0.85)
	_bottom_edge.color = Color(face_color.darkened(bottom_shade), 0.85 if _target else 0.9)

	var text_color := ThemeTokensLib.tile_text_color_for(face_color, value)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", _tile_font_size())
	if _crown_icon != null:
		_crown_icon.visible = _target and not _frozen and not _bonus_mode
		var crown_alpha := 0.88 if _target else 0.0
		_crown_icon.modulate = Color(ThemeTokensLib.TILE_GOLD_RIM, crown_alpha)
	if _label != null:
		if _target and not _frozen and not _bonus_mode:
			var crown_side := minf(cell_size.x, cell_size.y) * 0.28
			_label.offset_top = crown_side * 0.55
			_label.offset_bottom = 0.0
		else:
			_label.offset_top = 0.0
			_label.offset_bottom = 0.0
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
