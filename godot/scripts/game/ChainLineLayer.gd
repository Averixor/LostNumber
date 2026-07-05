extends Control
class_name ChainLineLayer

## Neon chain connector (3-pass glow draw, web chain-line parity).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

var _points: PackedVector2Array = PackedVector2Array()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10


func set_chain_points(points: PackedVector2Array) -> void:
	_points = points
	queue_redraw()


func clear_chain() -> void:
	_points = PackedVector2Array()
	queue_redraw()


func _draw() -> void:
	if _points.size() < 2:
		return

	# Pass 1: wide outer glow
	draw_polyline(_points, Color(ThemeTokensLib.COLOR_CHAIN_GLOW, 0.25), 14.0, true)

	# Pass 2: core neon line
	draw_polyline(_points, ThemeTokensLib.COLOR_NEON_BLUE, 6.0, true)

	# Pass 3: bright inner highlight
	draw_polyline(_points, ThemeTokensLib.COLOR_CHAIN_BRIGHT, 2.0, true)
