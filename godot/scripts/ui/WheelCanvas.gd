extends Control
class_name WheelCanvas

## Unified gothic fortune wheel — ornate rim, jewel sectors, icon-zone + short disk labels.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const WheelManagerLib := preload("res://scripts/meta/WheelManager.gd")

const WHEEL_ICON_DIR := "res://assets/ui/icons/wheel/"
## Slightly smaller than prior 48–64 so icons clear labels/hub on 420×920.
const ICON_SIZE_MIN := 36.0
const ICON_SIZE_MAX := 48.0
## Radial layout: icon mid-inner band, short caption toward rim (never stacked on icon).
const ICON_RADIUS_FACTOR := 0.44
const ICON_ONLY_RADIUS_FACTOR := 0.56
const LABEL_RADIUS_FACTOR := 0.84

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
var _highlight_index: int = -1
var _sector_textures: Dictionary = {}
var _sector_icon_slots: Dictionary = {}


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	custom_minimum_size = Vector2(320, 320)
	_refresh_theme_colors()
	_load_sector_icons()
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


func _refresh_theme_colors() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	_wheel_colors.clear()
	if theme != null and theme.has_method("get_wheel_colors"):
		for c in theme.call("get_wheel_colors"):
			var sector := Color(c)
			# Cohesive jewel wedges — muted, scene-matched (not flat MS-paint greens).
			sector = sector.darkened(0.28)
			sector.s = clampf(sector.s * 0.62, 0.22, 0.58)
			sector.v = clampf(sector.v * 0.92, 0.28, 0.62)
			_wheel_colors.append(sector)
	if _wheel_colors.is_empty():
		for c in ThemeTokensLib.WHEEL_SECTOR_COLORS:
			var sector := Color(c)
			sector.s = clampf(sector.s * 0.75, 0.22, 0.55)
			_wheel_colors.append(sector)


func _draw() -> void:
	_refresh_theme_colors()
	var center := size * 0.5
	var radius := minf(size.x, size.y) * 0.40
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
			base = base.lightened(0.12)
		_draw_sector_wedge(center, radius, start, end, base, i == pointer_index, crystal)

	# Shared outer vignette — blends wedges into one painted disc.
	draw_arc(center, radius * 0.97, 0.0, TAU, 64, Color(0, 0, 0, 0.42), radius * 0.10, true)
	draw_arc(center, radius * 0.55, 0.0, TAU, 48, Color(0, 0, 0, 0.18), radius * 0.08, true)

	# Engraved dividers (grooves, not hard segment cuts).
	for i in count:
		var end := rotation_angle + slice * float(i + 1) - PI * 0.5
		var outer := center + Vector2(cos(end), sin(end)) * (radius - 1.0)
		var inner := center + Vector2(cos(end), sin(end)) * (radius * 0.22)
		draw_line(inner, outer, Color(0.06, 0.04, 0.05, 0.72), 1.8)
		draw_line(inner, outer, Color(gold, 0.12), 0.7)

	# Sector icons + labels (after wedges, under rim/hub).
	# Separate radial zones so rotated text never sits on the icon.
	var icon_size := _icon_size_for_radius(radius)
	for i in count:
		var start := rotation_angle + slice * float(i) - PI * 0.5
		var end := start + slice
		var mid := (start + end) * 0.5
		var dir := Vector2(cos(mid), sin(mid))
		var disk_label := _sector_label(sectors[i])
		var icon_r := radius * (ICON_ONLY_RADIUS_FACTOR if disk_label.is_empty() else ICON_RADIUS_FACTOR)
		var icon_pos := center + dir * icon_r
		var label_pos := center + dir * (radius * LABEL_RADIUS_FACTOR)
		_draw_sector_content(icon_pos, label_pos, sectors[i], disk_label, mid, i == pointer_index, icon_size)

	# Ornate outer rim (spikes + bronze/gold bands) — frames the whole wheel.
	_draw_ornate_rim(center, radius, bronze, gold, crystal, effects)

	# Crystal / metal hub.
	_draw_hub(center, radius, bronze, gold, crystal, effects)

	_draw_pointer(center, radius, bronze, gold, crystal, effects)


func _icon_size_for_radius(radius: float) -> float:
	return clampf(radius * 0.28, ICON_SIZE_MIN, ICON_SIZE_MAX)


func _palette() -> Dictionary:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var use_skin := theme.has_method("get_visual_skin") and theme.call("get_visual_skin") != null
		return theme.call("get_palette", use_skin)
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
		draw_arc(center, radius + 13.0, 0.0, TAU, 48, Color(crystal, 0.16), 1.4, true)

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
		pulse = 0.88 + sin(_hub_pulse) * 0.10
	draw_circle(center, radius * 0.22, Color(GothicVisualsLib.STONE_BLACK, 0.98))
	draw_circle(center, radius * 0.185, Color(GothicVisualsLib.STONE_DEEP, 0.96))
	draw_arc(center, radius * 0.185, 0.0, TAU, 40, Color(bronze, 0.65), 2.2, true)
	draw_circle(center, radius * 0.13, Color(bronze.darkened(0.30), 0.95))
	draw_circle(center, radius * 0.09 * pulse, Color(crystal.darkened(0.15), 0.92 if effects else 0.82))
	draw_circle(center, radius * 0.055, Color(gold.lightened(0.12), 0.90))
	draw_circle(center, radius * 0.022, Color(GothicVisualsLib.TEXT_IVORY, 0.85))
	if effects:
		draw_arc(center, radius * 0.11, 0.0, TAU, 32, Color(crystal, 0.35), 1.6, true)


func _sector_label(sector: Dictionary) -> String:
	## Disk-only caption (short tokens). Full localized names stay in the result modal.
	return _compact_wheel_label("", sector)


func _compact_wheel_label(_text: String, sector: Dictionary) -> String:
	## Compact on-disk labels. Long localized names are result-modal only (Wheel.gd).
	var effect := str(sector.get("effect", ""))
	if effect == "xp":
		return "+%d" % int(sector.get("value", 0))
	if effect == "multiplier":
		return "2× XP"
	if effect == "bonus":
		# Shuffle / Destroy / Explosion: icons only — no long words on the disk.
		return ""
	return ""


func _load_sector_icons() -> void:
	_sector_textures.clear()
	for sector: Dictionary in WheelManagerLib.SECTORS:
		var sector_type := str(sector.get("type", ""))
		var file_name: String = SECTOR_ICON_FILES.get(sector_type, "")
		if file_name.is_empty():
			continue
		var path := WHEEL_ICON_DIR + file_name
		if not ResourceLoader.exists(path):
			continue
		var tex := load(path) as Texture2D
		if tex != null:
			_sector_textures[sector_type] = tex
			_sector_icon_slots[sector_type] = tex


func set_sector_icon_slot(sector_type: String, texture: Texture2D) -> void:
	if texture == null:
		_sector_icon_slots.erase(sector_type)
		_sector_textures.erase(sector_type)
	else:
		_sector_icon_slots[sector_type] = texture
		_sector_textures[sector_type] = texture
	queue_redraw()


func _draw_sector_content(
	icon_pos: Vector2,
	label_pos: Vector2,
	sector: Dictionary,
	label: String,
	angle: float,
	highlighted: bool,
	icon_size: float
) -> void:
	var sector_type := str(sector.get("type", ""))
	var tex: Texture2D = _sector_textures.get(sector_type)
	if tex != null:
		_draw_sector_icon(icon_pos, tex, angle, highlighted, icon_size)
	if not label.is_empty():
		var font_size := 12 if label.length() > 4 else 13
		_draw_sector_label(label_pos if tex != null else icon_pos, label, angle, highlighted, font_size)


func _draw_sector_icon(
	pos: Vector2,
	tex: Texture2D,
	angle: float,
	highlighted: bool,
	icon_size: float
) -> void:
	var readable_angle := angle + PI * 0.5
	if cos(readable_angle) < 0.0:
		readable_angle += PI
	var half := icon_size * 0.5
	var rect := Rect2(-half, -half, icon_size, icon_size)
	draw_set_transform(pos, readable_angle, Vector2.ONE)
	# Compact pedestal — keeps recognition without crowding the label zone.
	draw_circle(Vector2.ZERO, half * 0.82, Color(0, 0, 0, 0.24 if highlighted else 0.16))
	var modulate := Color(1.0, 1.0, 1.0, 1.0 if highlighted else 0.92)
	draw_texture_rect(tex, rect, false, modulate)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


func _draw_sector_label(
	pos: Vector2,
	text: String,
	angle: float,
	highlighted: bool,
	font_size_override: int = -1
) -> void:
	if text.is_empty():
		return
	var font := ThemeDB.fallback_font
	var font_size := font_size_override if font_size_override > 0 else (12 if text.length() > 6 else 14)
	var text_color := Color(GothicVisualsLib.TEXT_IVORY, 0.98 if highlighted else 0.90)
	var shadow := Color(0, 0, 0, 0.88)
	var readable_angle := angle + PI * 0.5
	if cos(readable_angle) < 0.0:
		readable_angle += PI
	draw_set_transform(pos, readable_angle, Vector2.ONE)
	var text_size := font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var origin := Vector2(-text_size.x * 0.5, font_size * 0.32)
	draw_string(font, origin + Vector2(1, 2), text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, shadow)
	draw_string(font, origin, text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, text_color)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


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
	var fill := color.darkened(0.06 if highlighted else 0.14)
	fill.a = 0.96
	draw_colored_polygon(pts, fill)
	# Soft radial depth toward hub (shared look across wedges).
	var mid_pts := _arc_points(center, radius * 0.72, start, end, 16)
	draw_colored_polygon(mid_pts, Color(0, 0, 0, 0.10))
	var inner_pts := _arc_points(center, radius * 0.36, start, end, 12)
	draw_colored_polygon(inner_pts, Color(0, 0, 0, 0.22))
	if highlighted and _effects_enabled():
		draw_polyline(pts, Color(crystal, 0.28), 1.4, true)
	else:
		var edge := Color(color.lightened(0.10), 0.28)
		draw_polyline(pts, edge, 1.0, true)


func _draw_pointer(
	center: Vector2,
	radius: float,
	bronze: Color,
	gold: Color,
	crystal: Color,
	effects: bool
) -> void:
	var tip := center + Vector2(0, -radius - 18)
	var pointer := PackedVector2Array([
		tip,
		center + Vector2(-11, -radius + 4),
		center + Vector2(0, -radius + 14),
		center + Vector2(11, -radius + 4),
	])
	draw_colored_polygon(pointer, Color(bronze.darkened(0.08), 0.97))
	draw_polyline(pointer, Color(gold, 0.92), 1.8, true)
	draw_circle(tip + Vector2(0, 5), 4.0, Color(gold, 0.9))
	draw_circle(tip + Vector2(0, 5), 1.8, Color(GothicVisualsLib.TEXT_IVORY, 0.85))
	if effects:
		draw_circle(tip + Vector2(0, 5), 6.0, Color(crystal, 0.18))


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
