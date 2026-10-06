extends Control
class_name WheelCanvas

## Unified gothic fortune wheel — ornate rim, alternating purple sectors, icons + labels.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const WheelManagerLib := preload("res://scripts/meta/WheelManager.gd")

## Label sits mid-sector for readability on larger 384 canvas.
const LABEL_RADIUS_FACTOR := 0.62
const ICON_RADIUS_FACTOR := 0.78
const ICON_SIZE := 32.0
const DISK_RADIUS_FACTOR := 0.46

const SECTOR_ICON_FILES := {
	"xp25": "wheel-xp-25.png",
	"xp50": "wheel-xp-50.png",
	"xp75": "wheel-xp-75.png",
	"xp100": "wheel-xp-100.png",
	"xp_multiplier": "wheel-x2.png",
	"explosion": "wheel-explosion.png",
	"shuffle": "wheel-shuffle.png",
	"destroy": "wheel-break.png",
}

signal spin_finished(sector: Dictionary, index: int)

var rotation_angle: float = 0.0
var _spinning := false
var _wheel_colors: Array[Color] = []
var _hub_pulse: float = 0.0
var _sector_icons: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(384, 384)
	_refresh_theme_colors()
	_preload_sector_icons()
	set_process(true)


func _process(delta: float) -> void:
	if _spinning:
		return
	if not _effects_enabled():
		return
	_hub_pulse += delta * 2.2
	queue_redraw()


func _effects_enabled() -> bool:
	return LnUiLib.effects_enabled()


func _preload_sector_icons() -> void:
	_sector_icons.clear()
	for sector_type in SECTOR_ICON_FILES:
		var tex := LnUiLib.load_wheel_icon(str(SECTOR_ICON_FILES[sector_type]))
		if tex != null:
			# Source PNGs are display-sized (~128px); avoid shipping full-res 1k+ textures.
			_sector_icons[sector_type] = tex


func _refresh_theme_colors() -> void:
	## Two alternating dark-violet stones — readable wedges, not near-black.
	var purple_a := Color(GothicVisualsLib.CRYSTAL).darkened(0.42)
	purple_a.s = clampf(purple_a.s * 0.70, 0.22, 0.48)
	purple_a.v = clampf(purple_a.v, 0.28, 0.42)
	var purple_b := Color(GothicVisualsLib.CRYSTAL).darkened(0.55).lerp(GothicVisualsLib.STONE_DEEP, 0.35)
	purple_b.s = clampf(purple_b.s * 0.55, 0.18, 0.40)
	purple_b.v = clampf(purple_b.v, 0.22, 0.34)
	_wheel_colors = [purple_a, purple_b]

	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_wheel_colors"):
		var themed: Array = theme_mgr.call("get_wheel_colors")
		if themed.size() >= 2:
			var a := Color(themed[0])
			a = a.lerp(purple_a, 0.55)
			a.s = clampf(a.s * 0.55, 0.18, 0.45)
			a.v = clampf(a.v * 0.90, 0.26, 0.44)
			var b := Color(themed[1 % themed.size()])
			b = b.lerp(purple_b, 0.55)
			b.s = clampf(b.s * 0.50, 0.16, 0.40)
			b.v = clampf(b.v * 0.85, 0.22, 0.36)
			_wheel_colors = [a, b]


func _draw() -> void:
	_refresh_theme_colors()
	var center := size * 0.5
	var radius := minf(size.x, size.y) * DISK_RADIUS_FACTOR
	var sectors: Array = WheelManagerLib.SECTORS
	var count := sectors.size()
	if count == 0:
		return
	var slice := TAU / float(count)
	var pointer_index := _sector_under_pointer(count, slice)
	var effects := _effects_enabled()
	var rim_colors := GothicVisualsLib.wheel_rim_colors(_palette())
	var bronze: Color = rim_colors["bronze"]
	var gold: Color = rim_colors["gold"]
	var crystal: Color = rim_colors["crystal"]

	# Soft ground shadow (ties wheel into the scene).
	var shadow_a := 0.58 if effects else 0.40
	draw_circle(center + Vector2(0, 10), radius + 18.0, Color(0, 0, 0, shadow_a))

	# Outer metal backing disc — one plate under sectors + rim.
	draw_circle(center, radius + 18.0, Color(GothicVisualsLib.STONE_BLACK, 0.96))
	draw_circle(center, radius + 14.0, Color(rim_colors["stone"], 0.98))
	draw_arc(center, radius + 14.0, 0.0, TAU, 72, Color(bronze.darkened(0.35), 0.75), 2.4, true)

	# Sector wedges on the shared disc.
	for i in count:
		var start := rotation_angle + slice * float(i) - PI * 0.5
		var end := start + slice
		var base: Color = _wheel_colors[i % _wheel_colors.size()]
		if i == pointer_index:
			base = base.lightened(0.14).lerp(gold, 0.12)
		_draw_sector_wedge(center, radius, start, end, base, i == pointer_index, crystal)

	# Shared outer vignette — blends wedges into one painted disc.
	draw_arc(center, radius * 0.97, 0.0, TAU, 64, Color(0, 0, 0, 0.36), radius * 0.10, true)
	draw_arc(center, radius * 0.55, 0.0, TAU, 48, Color(0, 0, 0, 0.16), radius * 0.08, true)

	# Engraved dividers (grooves, not hard segment cuts).
	for i in count:
		var end := rotation_angle + slice * float(i + 1) - PI * 0.5
		var outer := center + Vector2(cos(end), sin(end)) * (radius - 1.0)
		var inner := center + Vector2(cos(end), sin(end)) * (radius * 0.22)
		draw_line(inner, outer, Color(0.06, 0.04, 0.05, 0.72), 1.8)
		draw_line(inner, outer, Color(gold, 0.12), 0.7)

	# Icons + localized captions — upright, consistent radial band.
	for i in count:
		var start := rotation_angle + slice * float(i) - PI * 0.5
		var end := start + slice
		var mid := (start + end) * 0.5
		var dir := Vector2(cos(mid), sin(mid))
		var sector: Dictionary = sectors[i]
		var icon_pos := center + dir * (radius * ICON_RADIUS_FACTOR)
		_draw_sector_icon(icon_pos, sector, i == pointer_index)
		var disk_label := _label_for_disk(sector)
		var label_pos := center + dir * (radius * LABEL_RADIUS_FACTOR)
		_draw_sector_label(label_pos, disk_label, mid, i == pointer_index)

	# Ornate outer rim (spikes + bronze/gold bands) — frames the whole wheel.
	_draw_ornate_rim(center, radius, bronze, gold, crystal, effects)

	# Crystal / metal hub.
	_draw_hub(center, radius, bronze, gold, crystal, effects)

	_draw_pointer(center, radius, bronze, gold, crystal, effects)


func _palette() -> Dictionary:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_palette"):
		var use_skin := theme_mgr.has_method("get_visual_skin") and theme_mgr.call("get_visual_skin") != null
		return theme_mgr.call("get_palette", use_skin)
	return {}


func _draw_ornate_rim(
	center: Vector2,
	radius: float,
	bronze: Color,
	gold: Color,
	crystal: Color,
	effects: bool
) -> void:
	var outer_r := radius + 16.0
	# Spike ring
	var spike_count := 24
	for s in spike_count:
		var ang := TAU * float(s) / float(spike_count) - PI * 0.5
		var tip := center + Vector2(cos(ang), sin(ang)) * (outer_r + 7.0)
		var a1 := ang - 0.055
		var a2 := ang + 0.055
		var base_l := center + Vector2(cos(a1), sin(a1)) * (outer_r - 1.0)
		var base_r := center + Vector2(cos(a2), sin(a2)) * (outer_r - 1.0)
		var spike := PackedVector2Array([tip, base_l, base_r])
		draw_colored_polygon(spike, Color(bronze.darkened(0.05), 0.95))
		draw_polyline(spike, Color(gold, 0.55), 1.0, true)

	# Layered metal bands
	draw_arc(center, outer_r, 0.0, TAU, 80, Color(bronze.darkened(0.25), 0.92), 7.0, true)
	draw_arc(center, radius + 12.5, 0.0, TAU, 72, Color(gold, 0.82), 3.4, true)
	draw_arc(center, radius + 9.0, 0.0, TAU, 64, Color(bronze, 0.70), 2.0, true)
	draw_arc(center, radius + 2.5, 0.0, TAU, 56, Color(0, 0, 0, 0.55), 2.2, true)
	if effects:
		draw_arc(center, radius + 13.0, 0.0, TAU, 48, Color(crystal, 0.22), 1.6, true)

	# Rivets / studs on the rim
	var stud_count := 16
	for s in stud_count:
		var ang := TAU * float(s) / float(stud_count) - PI * 0.5 + (TAU / float(stud_count)) * 0.5
		var p := center + Vector2(cos(ang), sin(ang)) * (radius + 12.5)
		draw_circle(p, 2.4, Color(bronze.darkened(0.2), 0.95))
		draw_circle(p, 1.2, Color(gold.lightened(0.15), 0.9))


func _draw_hub(
	center: Vector2,
	radius: float,
	bronze: Color,
	gold: Color,
	crystal: Color,
	effects: bool
) -> void:
	var pulse := 1.0
	if effects:
		pulse = 0.90 + sin(_hub_pulse) * 0.12
	# Outer dark casing
	draw_circle(center, radius * 0.26, Color(GothicVisualsLib.STONE_BLACK, 0.98))
	draw_circle(center, radius * 0.22, Color(GothicVisualsLib.STONE_DEEP, 0.96))
	draw_arc(center, radius * 0.22, 0.0, TAU, 48, Color(bronze, 0.72), 2.6, true)
	draw_arc(center, radius * 0.22, 0.0, TAU, 48, Color(gold, 0.35), 1.2, true)
	# Crystal core
	draw_circle(center, radius * 0.155, Color(bronze.darkened(0.28), 0.96))
	var jewel := Color(GothicVisualsLib.CRYSTAL_LIGHT).lerp(crystal, 0.35)
	draw_circle(center, radius * 0.11 * pulse, Color(jewel.darkened(0.05), 0.94 if effects else 0.84))
	if effects:
		draw_circle(center, radius * 0.145, Color(GothicVisualsLib.CRYSTAL, 0.16))
		draw_arc(center, radius * 0.135, 0.0, TAU, 40, Color(GothicVisualsLib.CRYSTAL_LIGHT, 0.42), 2.0, true)
	draw_circle(center, radius * 0.055, Color(gold.lightened(0.18), 0.95))
	draw_circle(center, radius * 0.022, Color(GothicVisualsLib.TEXT_IVORY, 0.92))


func _sector_label(sector: Dictionary) -> String:
	## Prefer localized label_key; fall back to compact tokens.
	var key := str(sector.get("label_key", ""))
	if not key.is_empty():
		var i18n := _i18n_manager()
		if i18n != null and i18n.has_method("t"):
			var translated := str(i18n.call("t", key))
			if not translated.is_empty() and translated != key:
				return translated
	return _compact_wheel_label(sector)


func _i18n_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree is SceneTree:
		return (tree as SceneTree).root.get_node_or_null("/root/I18nManager")
	return null


func _label_for_disk(sector: Dictionary) -> String:
	## Disk text must stay short so adjacent UK/RU labels never collide.
	var full := _sector_label(sector)
	if full.length() <= 8:
		return full
	var compact := _compact_wheel_label(sector)
	if not compact.is_empty() and compact.length() < full.length():
		return compact
	return full


func _compact_wheel_label(sector: Dictionary) -> String:
	var effect := str(sector.get("effect", ""))
	if effect == "xp":
		return "+%d" % int(sector.get("value", 0))
	if effect == "multiplier":
		return "×2 XP"
	# Bonus sectors: prefer short localized tokens over long verbs.
	var bonus := str(sector.get("value", ""))
	match bonus:
		"destroy":
			return _short_locale_label("wheel_sector_destroy", "Destroy")
		"shuffle":
			return _short_locale_label("wheel_sector_shuffle", "Shuffle")
		"explosion":
			return "3×3"
		_:
			pass
	var label := str(sector.get("label", ""))
	return label


func _short_locale_label(key: String, fallback: String) -> String:
	var i18n := _i18n_manager()
	if i18n != null and i18n.has_method("t"):
		var translated := str(i18n.call("t", key)).strip_edges()
		if not translated.is_empty() and translated != key:
			if translated.length() <= 8:
				return translated
			# "Перемішати" / "Перемешать" → readable abbreviated disk token.
			return translated.substr(0, mini(6, translated.length())) + "."
	return fallback


func set_sector_icon_slot(sector_type: String, texture: Texture2D) -> void:
	if texture == null:
		_sector_icons.erase(sector_type)
	else:
		_sector_icons[sector_type] = texture
	queue_redraw()


func _draw_sector_icon(pos: Vector2, sector: Dictionary, highlighted: bool) -> void:
	var sector_type := str(sector.get("type", ""))
	var tex: Texture2D = _sector_icons.get(sector_type, null)
	if tex == null:
		return
	var size_px := ICON_SIZE * (1.08 if highlighted else 1.0)
	var rect := Rect2(pos - Vector2(size_px, size_px) * 0.5, Vector2(size_px, size_px))
	if highlighted:
		draw_circle(pos, size_px * 0.55, Color(GothicVisualsLib.GOLD, 0.18))
	draw_texture_rect(tex, rect, false)


func _draw_sector_label(
	pos: Vector2,
	text: String,
	_angle: float,
	highlighted: bool,
	font_size_override: int = -1
) -> void:
	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var lines := _disk_label_lines(text)
	var font_size := font_size_override
	if font_size <= 0:
		var longest := 0
		for line in lines:
			longest = maxi(longest, str(line).length())
		if longest > 10 or lines.size() > 1:
			font_size = 12
		elif longest > 7:
			font_size = 13
		elif longest > 5:
			font_size = 15
		else:
			font_size = 16
	var ivory_gold := GothicVisualsLib.TEXT_IVORY.lerp(GothicVisualsLib.GOLD_LIGHT, 0.48)
	var text_color := Color(ivory_gold, 1.0 if highlighted else 0.96)
	var shadow := Color(0, 0, 0, 0.92)
	# Always upright — never arc-rotated (bottom sectors were upside-down).
	draw_set_transform(pos, 0.0, Vector2.ONE)
	var line_height := float(font_size) + 2.0
	var total_h := line_height * float(lines.size())
	var y0 := -total_h * 0.5 + font_size * 0.78
	for li in lines.size():
		var line := str(lines[li])
		var text_size := font.get_string_size(line, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
		var origin := Vector2(-text_size.x * 0.5, y0 + line_height * float(li))
		draw_string(font, origin + Vector2(1, 2), line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow)
		draw_string(font, origin, line, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _disk_label_lines(text: String) -> PackedStringArray:
	var trimmed := text.strip_edges()
	if trimmed.is_empty():
		return PackedStringArray()
	if " " in trimmed and trimmed.length() > 7:
		var parts := trimmed.split(" ", false)
		if parts.size() >= 2:
			return PackedStringArray([str(parts[0]), " ".join(parts.slice(1))])
	if trimmed.length() > 11:
		var mid := int(ceil(float(trimmed.length()) * 0.5))
		return PackedStringArray([trimmed.substr(0, mid), trimmed.substr(mid)])
	return PackedStringArray([trimmed])


func _draw_sector_wedge(
	center: Vector2,
	radius: float,
	start: float,
	end: float,
	color: Color,
	highlighted: bool,
	crystal: Color
) -> void:
	var pts := _arc_points(center, radius, start, end, 28)
	var fill := color.darkened(0.04 if highlighted else 0.08)
	fill.a = 0.97
	draw_colored_polygon(pts, fill)
	# Soft radial depth toward hub (shared look across wedges).
	var mid_pts := _arc_points(center, radius * 0.72, start, end, 16)
	draw_colored_polygon(mid_pts, Color(0, 0, 0, 0.08))
	var inner_pts := _arc_points(center, radius * 0.36, start, end, 12)
	draw_colored_polygon(inner_pts, Color(0, 0, 0, 0.18))
	if highlighted and _effects_enabled():
		draw_polyline(pts, Color(crystal, 0.34), 1.6, true)
	else:
		var edge := Color(color.lightened(0.14), 0.34)
		draw_polyline(pts, edge, 1.1, true)


func _draw_pointer(
	center: Vector2,
	radius: float,
	bronze: Color,
	gold: Color,
	crystal: Color,
	effects: bool
) -> void:
	var tip := center + Vector2(0, -radius - 22)
	var pointer := PackedVector2Array([
		tip,
		center + Vector2(-14, -radius + 2),
		center + Vector2(0, -radius + 16),
		center + Vector2(14, -radius + 2),
	])
	if effects:
		draw_circle(tip + Vector2(0, 6), 12.0, Color(gold, 0.22))
		draw_circle(tip + Vector2(0, 6), 8.0, Color(GothicVisualsLib.GOLD_LIGHT, 0.18))
	draw_colored_polygon(pointer, Color(bronze.darkened(0.05), 0.98))
	draw_polyline(pointer, Color(gold, 0.95), 2.2, true)
	draw_circle(tip + Vector2(0, 6), 5.0, Color(gold, 0.95))
	draw_circle(tip + Vector2(0, 6), 2.2, Color(GothicVisualsLib.TEXT_IVORY, 0.92))
	if effects:
		draw_circle(tip + Vector2(0, 6), 7.0, Color(crystal, 0.20))


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
	tween.tween_method(_set_rotation, rotation_angle, target, duration).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
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
