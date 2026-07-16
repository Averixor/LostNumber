extends RefCounted
class_name GothicVisuals

## Runtime-safe gothic crystal visual layer.
## The concept artwork remains a composition reference; this helper exposes scalable,
## text-free materials that work with any tile value and all three localizations.

const TILE_FRAME_PATH := "res://assets/ui/skins/gothic_crystal/tile-frame.png"

const STONE_BLACK := Color("#100d16")
const STONE_DEEP := Color("#18131f")
const STONE_MID := Color("#27202d")
const IRON := Color("#3a323c")
const BRONZE := Color("#8f6a36")
const BRONZE_DARK := Color("#4d351f")
const GOLD := Color("#d6ad58")
const GOLD_LIGHT := Color("#f3d58b")
const CRYSTAL := Color("#a85cff")
const CRYSTAL_LIGHT := Color("#d8b4ff")
const TEXT_IVORY := Color("#f7ead5")
const TEXT_MUTED := Color("#bbaec4")

const TILE_PALETTE := {
	2: Color("#19352d"),
	4: Color("#17343a"),
	8: Color("#1b3044"),
	16: Color("#362033"),
	32: Color("#421f31"),
	64: Color("#302140"),
	128: Color("#281d3c"),
	256: Color("#43341d"),
	512: Color("#472b1c"),
	1024: Color("#48231f"),
	2048: Color("#51421f"),
	4096: Color("#34333b"),
}


static func tile_face_color(value: int) -> Color:
	if TILE_PALETTE.has(value):
		return TILE_PALETTE[value]
	if value <= 0:
		return Color.TRANSPARENT

	var exponent := 0
	var cursor := value
	while cursor > 1:
		cursor /= 2
		exponent += 1

	var hue := fmod(0.73 + float(exponent) * 0.045, 1.0)
	return Color.from_hsv(hue, 0.42, 0.29)


static func tile_text_color(face: Color, value: int) -> Color:
	if value >= 256:
		return GOLD_LIGHT
	if face.get_luminance() > 0.58:
		return STONE_BLACK
	return TEXT_IVORY


static func tile_frame_tint(value: int, frozen: bool, rim: Color) -> Color:
	if frozen:
		return Color("#d9e8ef")
	if value >= 2048:
		return Color(rim.lightened(0.20), 1.0)
	if value >= 128:
		return Color(GOLD_LIGHT.lerp(CRYSTAL_LIGHT, 0.28), 0.98)
	return Color(GOLD.lerp(rim, 0.35), 0.92)


static func hud_panel(palette: Dictionary = {}) -> StyleBoxFlat:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(STONE_DEEP, 0.90)
	style.border_color = Color(rim, 0.78)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.set_content_margin_all(8)
	style.shadow_color = Color(crystal, 0.20)
	style.shadow_size = 10
	style.shadow_offset = Vector2(0, 3)
	return style


static func icon_button(palette: Dictionary = {}, state: String = "normal") -> StyleBoxFlat:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(STONE_MID, 0.86)
	style.border_color = Color(rim, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(9)
	style.set_content_margin_all(9)
	style.shadow_color = Color(crystal, 0.18)
	style.shadow_size = 6
	style.shadow_offset = Vector2(0, 2)

	match state:
		"hover":
			style.bg_color = Color(STONE_MID.lightened(0.08), 0.94)
			style.border_color = Color(crystal.lightened(0.18), 0.95)
			style.shadow_color = Color(crystal, 0.34)
			style.shadow_size = 10
		"pressed":
			style.bg_color = Color(STONE_BLACK, 0.96)
			style.border_color = Color(rim.darkened(0.10), 0.90)
		"disabled":
			style.bg_color = Color(STONE_BLACK, 0.55)
			style.border_color = Color(IRON, 0.45)
			style.shadow_size = 0
	return style


static func booster_button(palette: Dictionary, active: bool, available: bool) -> StyleBoxFlat:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(crystal, 0.18) if active else Color(STONE_MID, 0.88)
	style.border_color = Color(crystal, 0.95) if active else Color(rim, 0.72)
	if not available and not active:
		style.bg_color = Color(STONE_BLACK, 0.58)
		style.border_color = Color(IRON, 0.42)
	style.set_border_width_all(2)
	style.set_corner_radius_all(10)
	style.content_margin_left = 7
	style.content_margin_right = 9
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	style.shadow_color = Color(crystal, 0.38 if active else 0.14)
	style.shadow_size = 11 if active else 5
	style.shadow_offset = Vector2(0, 2)
	return style
