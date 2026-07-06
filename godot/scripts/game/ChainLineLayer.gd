extends Control
class_name ChainLineLayer

## Neon chain connector with validity coloring and pulsing glow.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const STROKE_CORE := 6.0
const STROKE_GLOW := 11.0
const STROKE_BRIGHT := 2.0

var _points: PackedVector2Array = PackedVector2Array()
var _valid: bool = true
var _pulse: float = 0.0
var _line_color: Color = ThemeTokensLib.COLOR_CHAIN_VALID
var _glow_color: Color = ThemeTokensLib.COLOR_CHAIN_VALID
var _label: String = ""
var _label_pos: Vector2 = Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10
	set_process(true)


func set_chain_points(points: PackedVector2Array, valid: bool = true, label: String = "", label_pos: Vector2 = Vector2.ZERO) -> void:
	_points = points
	_valid = valid
	_label = label
	_label_pos = label_pos
	_refresh_colors()
	queue_redraw()

func clear_chain() -> void:
	_points = PackedVector2Array()
	_label = ""
	queue_redraw()


func _process(delta: float) -> void:
	if _points.size() < 2:
		return
	_pulse += delta * 2.4
	queue_redraw()


func _refresh_colors() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null:
		if _valid and theme.has_method("get_chain_valid_color"):
			_line_color = theme.call("get_chain_valid_color")
		elif not _valid and theme.has_method("get_chain_invalid_color"):
			_line_color = theme.call("get_chain_invalid_color")
		else:
			_line_color = ThemeTokensLib.COLOR_CHAIN_VALID if _valid else ThemeTokensLib.COLOR_CHAIN_INVALID
	else:
		_line_color = ThemeTokensLib.COLOR_CHAIN_VALID if _valid else ThemeTokensLib.COLOR_CHAIN_INVALID
	var pulse_alpha := 0.18 + sin(_pulse) * 0.08
	_glow_color = Color(_line_color, pulse_alpha)


func _draw() -> void:
	if _points.size() < 2:
		return

	draw_polyline(_points, _glow_color, STROKE_GLOW, true)
	draw_polyline(_points, Color(_line_color, 0.72 + sin(_pulse) * 0.1), STROKE_CORE, true)
	draw_polyline(_points, Color(_line_color.lightened(0.25), 0.9), STROKE_BRIGHT, true)
	
	if _label.is_empty():
		return
		
	var font := get_theme_default_font()
	var fs := 18
	var w := 54.0
	var h := 30.0
	var p := _label_pos + Vector2(-w * 0.5, -50.0)
	p.x = clampf(p.x, 0.0, maxf(0.0, size.x - w))
	p.y = clampf(p.y, 0.0, maxf(0.0, size.y - h))
	var r := Rect2(p, Vector2(w, h))
	
	var bg_color := Color(0.08, 0.03, 0.11, 0.88)
	draw_rect(r, bg_color, true)
	draw_rect(r, Color(_line_color, 0.65), false, 2.0)
	draw_string(font, Vector2(r.position.x, r.position.y + 21.0), _label, HORIZONTAL_ALIGNMENT_CENTER, w, fs, _line_color)