extends Control
class_name WheelCanvas

## Gothic fortune wheel — dark sectors, purple rim, crystal hub, top pointer.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const WheelManagerLib := preload("res://scripts/meta/WheelManager.gd")

signal spin_finished(sector: Dictionary, index: int)

var rotation_angle: float = 0.0
var _spinning := false
var _wheel_colors: Array[Color] = []
var _hub_pulse: float = 0.0


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(300, 300)
	_refresh_theme_colors()
	set_process(true)


func _process(delta: float) -> void:
	if _spinning or _wheel_colors.is_empty():
		_hub_pulse += delta * 2.2
		queue_redraw()


func _refresh_theme_colors() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	_wheel_colors.clear()
	if theme != null and theme.has_method("get_wheel_colors"):
		for c in theme.call("get_wheel_colors"):
			var sector := Color(c)
			sector = sector.darkened(0.48)
			sector.s = sector.s * 0.72
			_wheel_colors.append(sector)
	if _wheel_colors.is_empty():
		for c in ThemeTokensLib.WHEEL_SECTOR_COLORS:
			var sector := Color(c).darkened(0.52)
			sector.s = sector.s * 0.65
			_wheel_colors.append(sector)


func _draw() -> void:
	_refresh_theme_colors()
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.42
	var sectors: Array = WheelManagerLib.SECTORS
	var count := sectors.size()
	if count == 0:
		return

	var slice := TAU / float(count)
	var pointer_index := _sector_under_pointer(count, slice)
	var rim := _rim_color()
	var neon := LnUiLib.ACCENT_2
	var glass := LnUiLib.PANEL

	# Drop shadow under wheel
	draw_circle(center + Vector2(0, 8), radius + 10.0, Color(0, 0, 0, 0.5))

	# Dark glass backing disc
	draw_circle(center, radius + 6.0, Color(glass, 0.94))
	draw_arc(center, radius + 6.0, 0.0, TAU, 64, Color(LnUiLib.BORDER, 0.55), 2.0, true)

	# Neon outer rim
	draw_arc(center, radius + 14.0, 0.0, TAU, 72, Color(neon, 0.22), 8.0, true)
	draw_arc(center, radius + 11.0, 0.0, TAU, 64, Color(LnUiLib.ACCENT, 0.55), 2.5, true)
	draw_arc(center, radius + 8.0, 0.0, TAU, 48, Color(rim.lightened(0.12), 0.75), 1.5, true)
	draw_arc(center, radius + 2.0, 0.0, TAU, 48, Color(0, 0, 0, 0.45), 2.0, true)

	for i in count:
		var start := rotation_angle + slice * float(i) - PI * 0.5
		var end := start + slice
		var base: Color = _wheel_colors[i % _wheel_colors.size()]
		if i == pointer_index:
			base = base.lightened(0.12)
		_draw_sector_wedge(center, radius, start, end, base, i == pointer_index)

		# Sector divider
		var div_end := center + Vector2(cos(end), sin(end)) * (radius + 2.0)
		draw_line(center, div_end, Color(0.03, 0.02, 0.08, 0.9), 1.5)

		var mid := (start + end) * 0.5
		var label_pos := center + Vector2(cos(mid), sin(mid)) * radius * 0.68
		var sector: Dictionary = sectors[i]
		var label := _sector_label(sector)
		_draw_sector_label(label_pos, label, mid, i == pointer_index)

	# Inner vignette ring
	draw_arc(center, radius * 0.94, 0.0, TAU, 48, Color(0, 0, 0, 0.32), radius * 0.06, true)

	# Crystal hub with soft pulse
	var crystal := _crystal_color()
	var pulse := 0.85 + sin(_hub_pulse) * 0.15
	draw_circle(center, radius * 0.2, Color(0.04, 0.03, 0.08, 0.98))
	draw_circle(center, radius * 0.16, Color(LnUiLib.PANEL_PRESSED, 0.96))
	draw_circle(center, radius * 0.11, Color(crystal.darkened(0.35), 0.92))
	draw_circle(center, radius * 0.07 * pulse, Color(crystal.darkened(0.1), 0.95))
	draw_circle(center, radius * 0.035, Color(crystal.lightened(0.25), 0.85))
	draw_arc(center, radius * 0.1, 0.0, TAU, 32, Color(LnUiLib.ACCENT, 0.18 + sin(_hub_pulse) * 0.1), 2.0, true)

	_draw_pointer(center, radius)


func _sector_label(sector: Dictionary) -> String:
	var key := str(sector.get("message_key", ""))
	if not key.is_empty():
		var i18n := get_node_or_null("/root/I18nManager")
		if i18n != null and i18n.has_method("t"):
			var text := str(i18n.call("t", key))
			if text != key:
				return _compact_wheel_label(text, sector)
	return str(sector.get("label", ""))


func _compact_wheel_label(text: String, sector: Dictionary) -> String:
	var effect := str(sector.get("effect", ""))
	if effect == "xp":
		var digits := ""
		for ch in text:
			if ch.is_valid_int() or ch == "+":
				digits += ch
		return digits if not digits.is_empty() else text
	if effect == "multiplier":
		return "×2 XP"
	if effect == "bonus":
		match str(sector.get("value", "")):
			"explosion":
				return "3×3"
			"destroy":
				return "Розбити"
			"shuffle":
				return "Мікс"
	return text


func _draw_sector_label(pos: Vector2, text: String, angle: float, highlighted: bool) -> void:
	var font := ThemeDB.fallback_font
	var font_size := 13 if text.length() > 4 else 17
	var text_color := Color(0.96, 0.94, 0.99, 0.98 if highlighted else 0.86)
	var shadow := Color(0, 0, 0, 0.8)
	var readable_angle := angle + PI * 0.5
	if cos(readable_angle) < 0.0:
		readable_angle += PI
	draw_set_transform(pos, readable_angle, Vector2.ONE)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var origin := Vector2(-text_size.x * 0.5, font_size * 0.32)
	draw_string(font, origin + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _rim_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var p: Dictionary = theme.call("get_palette")
		return p.get("primary", Color("#6B3FA0"))
	return Color("#6B3FA0")


func _crystal_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var p: Dictionary = theme.call("get_palette")
		return p.get("crystal", ThemeTokensLib.COLOR_PRIMARY)
	return ThemeTokensLib.COLOR_PRIMARY


func _draw_sector_wedge(center: Vector2, radius: float, start: float, end: float, color: Color, highlighted: bool) -> void:
	var pts := _arc_points(center, radius, start, end, 24)
	var fill := color.darkened(0.12 if highlighted else 0.22)
	fill.a = 0.92
	draw_colored_polygon(pts, fill)
	var inner_pts := _arc_points(center, radius * 0.38, start, end, 12)
	draw_colored_polygon(inner_pts, Color(0, 0, 0, 0.24))
	var edge := Color(color.lightened(0.04 if highlighted else 0.0), 0.42 if highlighted else 0.28)
	draw_polyline(pts, edge, 1.0, true)


func _draw_pointer(center: Vector2, radius: float) -> void:
	var crystal := _crystal_color()
	var tip := center + Vector2(0, -radius - 14)
	var pointer := PackedVector2Array([
		tip,
		center + Vector2(-10, -radius + 6),
		center + Vector2(10, -radius + 6),
	])
	draw_colored_polygon(pointer, Color(crystal.darkened(0.25), 0.92))
	draw_polyline(pointer, Color(LnUiLib.ACCENT, 0.85), 1.5, true)
	draw_circle(tip + Vector2(0, 3), 3.5, Color(LnUiLib.ACCENT, 0.75))


func _sector_under_pointer(count: int, slice: float) -> int:
	var ang := fmod(-rotation_angle + PI * 0.5, TAU)
	if ang < 0.0:
		ang += TAU
	return int(floor(ang / slice)) % count


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
	var target := TAU * 5.0 + (TAU - slice * (float(index) + 0.5))

	if duration <= 0.0:
		rotation_angle = fmod(target, TAU)
		queue_redraw()
		_spinning = false
		spin_finished.emit(WheelManagerLib.SECTORS[index], index)
		return

	var tween := create_tween()
	tween.tween_method(_set_rotation, rotation_angle, target, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await tween.finished

	rotation_angle = fmod(target, TAU)
	queue_redraw()
	_spinning = false
	spin_finished.emit(WheelManagerLib.SECTORS[index], index)


func _set_rotation(angle: float) -> void:
	rotation_angle = angle
	queue_redraw()


func is_spinning() -> bool:
	return _spinning
