extends Control
class_name ChainLineLayer

## Thin neon chain connector — soft glow + light core (Dark Neon Fantasy).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const STROKE_CORE := 1.75
const STROKE_GLOW_MID := 3.5
const STROKE_GLOW_OUTER := 5.5

var _points: PackedVector2Array = PackedVector2Array()
var _valid := true
var _line_color: Color = ThemeTokensLib.COLOR_CHAIN_VALID
var _pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Behind tiles so the line sits in gaps and does not cover numbers.
	z_index = -1
	set_process(true)


func _process(delta: float) -> void:
	if _points.size() < 2:
		return
	_pulse += delta * 2.4
	queue_redraw()


func set_chain_points(points: PackedVector2Array, valid: bool = true, _label: String = "", _label_pos: Vector2 = Vector2.ZERO) -> void:
	_points = points
	_valid = valid
	_refresh_colors()
	queue_redraw()


func clear_chain() -> void:
	_points = PackedVector2Array()
	queue_redraw()


func _refresh_colors() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null:
		if _valid and theme.has_method("get_chain_valid_color"):
			_line_color = theme.call("get_chain_valid_color")
			return
		if not _valid and theme.has_method("get_chain_invalid_color"):
			_line_color = theme.call("get_chain_invalid_color")
			return
	_line_color = ThemeTokensLib.COLOR_CHAIN_VALID if _valid else ThemeTokensLib.COLOR_CHAIN_INVALID


func _draw() -> void:
	if _points.size() < 2:
		return

	var pulse_boost := 0.06 * sin(_pulse)
	var outer := Color(_line_color, 0.16 + pulse_boost)
	var mid := Color(_line_color, 0.38 + pulse_boost)
	var core := Color(_line_color.lightened(0.55), 0.92)

	draw_polyline(_points, outer, STROKE_GLOW_OUTER, true)
	draw_polyline(_points, mid, STROKE_GLOW_MID, true)
	draw_polyline(_points, core, STROKE_CORE, true)
