extends Control
class_name ChainLineLayer

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

var _points: PackedVector2Array = PackedVector2Array()
var _ok := false
var _label := ""
var _label_pos := Vector2.ZERO

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	z_index = 10

func set_chain_points(points: PackedVector2Array, ok: bool = false, label: String = "", label_pos: Vector2 = Vector2.ZERO) -> void:
	_points = points
	_ok = ok
	_label = label
	_label_pos = label_pos
	queue_redraw()

func clear_chain() -> void:
	_points = PackedVector2Array()
	_label = ""
	queue_redraw()

func _draw() -> void:
	var c := ThemeTokensLib.COLOR_CHAIN_VALID if _ok else ThemeTokensLib.COLOR_CHAIN_INVALID
	if _points.size() >= 2:
		draw_polyline(_points, Color(c, 0.22), 18.0, true)
		draw_polyline(_points, Color(c, 0.65), 9.0, true)
		draw_polyline(_points, c, 3.0, true)
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
	draw_rect(r, Color(0.08, 0.03, 0.11, 0.88), true)
	draw_rect(r, Color(c, 0.65), false, 2.0)
	draw_string(font, Vector2(r.position.x, r.position.y + 21.0), _label, HORIZONTAL_ALIGNMENT_CENTER, w, fs, c)
