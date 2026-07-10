extends Control
class_name ChainLineLayer

## Soft neon laser chain — glow + beam + white core, above tile faces.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const STROKE_GLOW := 5.5
const STROKE_BEAM := 2.5
const STROKE_CORE := 1.0
const JOINT_GLOW_R := 4.0
const JOINT_BEAM_R := 2.2
const JOINT_CORE_R := 1.1

var _points: PackedVector2Array = PackedVector2Array()
var _state: String = "valid"
var _line_color: Color = ThemeTokensLib.COLOR_CHAIN_VALID


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Above tile faces (z=0), below selection (z=2) and labels (z=3).
	z_index = 1


func set_chain_points(points: PackedVector2Array, state: String = "valid", _label: String = "", _label_pos: Vector2 = Vector2.ZERO) -> void:
	_points = points
	_state = state
	_refresh_colors()
	queue_redraw()


func clear_chain() -> void:
	_points = PackedVector2Array()
	queue_redraw()


func _refresh_colors() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	match _state:
		"valid":
			if theme != null and theme.has_method("get_chain_valid_color"):
				_line_color = theme.call("get_chain_valid_color")
			else:
				_line_color = ThemeTokensLib.COLOR_CHAIN_VALID
		"invalid":
			if theme != null and theme.has_method("get_chain_invalid_color"):
				_line_color = theme.call("get_chain_invalid_color")
			else:
				_line_color = ThemeTokensLib.COLOR_CHAIN_INVALID
		_:
			if theme != null and theme.has_method("get_chain_continue_color"):
				_line_color = theme.call("get_chain_continue_color")
			else:
				_line_color = ThemeTokensLib.COLOR_CHAIN_CONTINUE


func _draw() -> void:
	if _points.size() < 2:
		return

	var glow := Color(_line_color, 0.28)
	var beam := Color(_line_color, 0.85)
	var core := Color(0.96, 0.98, 1.0, 0.95)

	draw_polyline(_points, glow, STROKE_GLOW, true)
	draw_polyline(_points, beam, STROKE_BEAM, true)
	draw_polyline(_points, core, STROKE_CORE, true)

	for i in _points.size():
		var p: Vector2 = _points[i]
		draw_circle(p, JOINT_GLOW_R, glow)
		draw_circle(p, JOINT_BEAM_R, beam)
		draw_circle(p, JOINT_CORE_R, core)
