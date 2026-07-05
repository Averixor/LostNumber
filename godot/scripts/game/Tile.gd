extends Control
class_name TileView

## Themed grid cell (web css/grid.css .cell parity).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _bg: PanelContainer = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _label: Label = $Bg/Inner/Label
@onready var _chain_highlight: ColorRect = $ChainHighlight
@onready var _carry_badge: Label = $CarryBadge

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0

var _selected: bool = false
var _frozen: bool = false
var _bonus_mode: bool = false
var _carry: bool = false
var _target: bool = false


func _ready() -> void:
	custom_minimum_size = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style()
	_refresh_visual()


func setup(pos: Vector2i, number: int) -> void:
	grid_pos = pos
	set_value(number)


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


func set_chain_selected(selected: bool, valid_finish: bool = true) -> void:
	_selected = selected
	_chain_highlight.visible = selected
	if selected:
		var c := ThemeTokensLib.COLOR_PREVIEW_VALID if valid_finish else ThemeTokensLib.COLOR_PREVIEW_INVALID
		_chain_highlight.color = Color(c, 0.45)
	_refresh_visual()


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
	_carry_badge.visible = active
	_refresh_visual()


func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(ThemeTokensLib.TILE_RADIUS)
	style.bg_color = Color(0, 0, 0, 0)
	style.set_content_margin_all(0)
	_bg.add_theme_stylebox_override("panel", style)


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	if _selected:
		_inner.color = ThemeTokensLib.TILE_SELECTED_BG
	elif _frozen:
		_inner.color = ThemeTokensLib.TILE_FROZEN_BG
	elif _bonus_mode:
		_inner.color = ThemeTokensLib.COLOR_PRIMARY.darkened(0.1)
	elif value <= 0:
		_inner.color = Color(ThemeTokensLib.COLOR_CELL, 0.35)
	elif _target:
		_inner.color = Color(0.55, 0.42, 0.12, 1.0)
	else:
		_inner.color = _color_for_value(value)

	var text_color := ThemeTokensLib.COLOR_CELL_NUMBER
	if value >= 8192:
		text_color = Color.WHITE
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TILE)


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
	return Color.from_hsv(fmod(log_val * 0.11, 1.0), 0.45, 0.38)
