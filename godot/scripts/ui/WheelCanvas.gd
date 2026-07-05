extends Control
class_name WheelCanvas

## Fortune wheel canvas with rotation animation (~3.1s web parity).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const WheelManagerLib := preload("res://scripts/meta/WheelManager.gd")

signal spin_finished(sector: Dictionary, index: int)

var rotation_angle: float = 0.0
var _spinning := false
var _highlight_index: int = -1


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(280, 280)


func _draw() -> void:
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.45
	var sectors: Array = WheelManagerLib.SECTORS
	var count := sectors.size()
	if count == 0:
		return

	var slice := TAU / float(count)
	for i in count:
		var start := rotation_angle + slice * float(i) - PI * 0.5
		var end := start + slice
		var color: Color = ThemeTokensLib.WHEEL_SECTOR_COLORS[i % ThemeTokensLib.WHEEL_SECTOR_COLORS.size()]
		if i == _highlight_index:
			color = color.lightened(0.15)
		draw_colored_polygon(_arc_points(center, radius, start, end), color)
		draw_arc(center, radius, start, end, 24, Color.WHITE, 2.0, true)

	# Hub
	draw_circle(center, radius * 0.12, Color(0.12, 0.1, 0.18, 0.95))
	draw_circle(center, radius * 0.08, ThemeTokensLib.COLOR_PRIMARY)

	# Pointer at top
	var pointer := PackedVector2Array([
		center + Vector2(-10, -radius - 6),
		center + Vector2(10, -radius - 6),
		center + Vector2(0, -radius + 8),
	])
	draw_colored_polygon(pointer, ThemeTokensLib.COLOR_PRIMARY)


func _arc_points(center: Vector2, radius: float, start: float, end: float, steps: int = 16) -> PackedVector2Array:
	var pts := PackedVector2Array()
	pts.append(center)
	for s in range(steps + 1):
		var t := float(s) / float(steps)
		var ang := lerpf(start, end, t)
		pts.append(center + Vector2(cos(ang), sin(ang)) * radius)
	return pts


func animate_to_sector(index: int, duration: float = WheelManagerLib.SPIN_DURATION_SEC) -> void:
	if _spinning:
		return
	_spinning = true

	var count := WheelManagerLib.SECTORS.size()
	var slice := TAU / float(count)
	var target := TAU * 4.0 + (TAU - slice * (float(index) + 0.5))

	if duration <= 0.0:
		rotation_angle = fmod(target, TAU)
		_highlight_index = index
		queue_redraw()
		_spinning = false
		spin_finished.emit(WheelManagerLib.SECTORS[index], index)
		return

	var tween := create_tween()
	tween.tween_method(_set_rotation, rotation_angle, target, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

	rotation_angle = fmod(target, TAU)
	_highlight_index = index
	queue_redraw()
	_spinning = false
	spin_finished.emit(WheelManagerLib.SECTORS[index], index)


func _set_rotation(angle: float) -> void:
	rotation_angle = angle
	queue_redraw()


func is_spinning() -> bool:
	return _spinning
