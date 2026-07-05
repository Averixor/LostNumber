extends Control
class_name TileView

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _bg: PanelContainer = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _label: Label = $Bg/Inner/Label
@onready var _chain_highlight: ColorRect = $ChainHighlight
@onready var _carry_badge: Label = $CarryBadge

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0
var _frozen := false
var _bonus_mode := false
var _target := false

func _ready() -> void:
	custom_minimum_size = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_apply_panel_style()
	_chain_highlight.visible = false
	_refresh_visual()

func setup(pos: Vector2i, number: int) -> void:
	grid_pos = pos
	set_value(number)

func set_value(number: int) -> void:
	var changed := value != number
	value = number
	_label.text = "" if number <= 0 else str(number)
	_refresh_visual()
	if changed and number > 0 and is_inside_tree():
		var tween := create_tween()
		scale = Vector2.ONE
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.10)

func set_chain_selected(_active: bool, _ok: bool = true) -> void:
	_chain_highlight.visible = false

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
	_carry_badge.visible = active
	_refresh_visual()

func _apply_panel_style() -> void:
	var style := StyleBoxFlat.new()
	style.set_corner_radius_all(ThemeTokensLib.TILE_RADIUS)
	style.bg_color = Color(0.04, 0.02, 0.06, 0.62)
	style.set_border_width_all(1)
	style.border_color = Color(ThemeTokensLib.COLOR_PANEL_BORDER, 0.60)
	style.set_content_margin_all(2)
	style.shadow_color = Color(0, 0, 0, 0.26)
	style.shadow_size = 4
	_bg.add_theme_stylebox_override("panel", style)

func _refresh_visual() -> void:
	if not is_inside_tree():
		return
	if _frozen:
		_inner.color = ThemeTokensLib.TILE_FROZEN_BG
	elif _bonus_mode:
		_inner.color = ThemeTokensLib.COLOR_SECONDARY.darkened(0.10)
	elif value <= 0:
		_inner.color = Color(ThemeTokensLib.COLOR_CELL, 0.36)
	elif _target:
		_inner.color = _color_for_value(value).lightened(0.10)
	else:
		_inner.color = _color_for_value(value)
	_label.add_theme_color_override("font_color", ThemeTokensLib.COLOR_CELL_NUMBER)
	_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TILE)
	_carry_badge.add_theme_color_override("font_color", ThemeTokensLib.COLOR_PRIMARY)

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
	return Color.from_hsv(fmod(log_val * 0.11, 1.0), 0.35, 0.86)
