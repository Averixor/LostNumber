extends RefCounted
class_name GothicVisuals

## Runtime-safe gothic crystal visual layer.
## The concept artwork remains a composition reference; this helper exposes scalable,
## text-free materials that work with any tile value and all three localizations.
## Tile face hues stay value-distinct (ThemeTokens); gothic contributes frame/HUD chrome only.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

## Border-only atlas frame: transparent center so per-value face colors show through.
const TILE_FRAME_PATH := "res://assets/ui/skins/gothic_crystal/tiles/stone_frame.webp"
const TILE_FRAME_ATLAS_REGION := Rect2(140, 130, 1320, 1340)
## Full-frame concept art; not used on the live board (opaque crystal center).
const TILE_FRAME_ART_PATH := "res://assets/ui/skins/gothic_crystal/tile-frame.png"
## Ornate purple-gold VIP frame for the current board-max tile (transparent center).
const MAX_TILE_FRAME_PATH := "res://assets/ui/skins/gothic_crystal/tiles/max_tile_frame.png"

const STONE_BLACK := Color("#100d16")
const STONE_DEEP := Color("#18131f")
const STONE_MID := Color("#27202d")
const IRON := Color("#3a323c")
const BRONZE := Color("#8f6a36")
const BRONZE_DARK := Color("#4d351f")
const GOLD := Color("#d6ad58")
const GOLD_LIGHT := Color("#f3d58b")
const CRYSTAL := Color("#8F55D6")
const CRYSTAL_LIGHT := Color("#C9A6F0")
const TEXT_IVORY := Color("#f7ead5")
const TEXT_MUTED := Color("#bbaec4")


static func tile_face_color(value: int) -> Color:
	if value <= 0:
		return Color.TRANSPARENT
	if ThemeTokensLib.TILE_COLORS.has(value):
		return ThemeTokensLib.TILE_COLORS[value]
	if ThemeTokensLib.TILE_GRADIENTS.has(value):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[value]
		return pair[0].lerp(pair[1], 0.5)

	var exponent := 0
	var cursor := value
	while cursor > 1:
		cursor /= 2
		exponent += 1

	# Bright HSV fallback for unknown powers of two (pre-gothic Tile.gd parity).
	return Color.from_hsv(fmod(float(exponent) * 0.09 + 0.08, 1.0), 0.52, 0.78)


static func tile_text_color(_face: Color, _value: int) -> Color:
	# Match ThemeTokens jewel rule: dark digits on saturated faces.
	return STONE_BLACK


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
	var style := _stone_button_base(palette, 9, 9)
	_apply_stone_button_state(style, palette, state)
	return style


static func cta_button(palette: Dictionary = {}, state: String = "normal") -> StyleBoxFlat:
	var rim: Color = palette.get("rim", GOLD)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(STONE_MID.lightened(0.05), 0.92)
	style.border_color = Color(rim, 0.82)
	style.set_corner_radius_all(10)
	style.content_margin_top = 14.0
	style.content_margin_bottom = 14.0
	style.content_margin_left = 16.0
	style.content_margin_right = 16.0
	style.shadow_color = Color(STONE_BLACK, 0.42)
	style.shadow_size = 5
	style.shadow_offset = Vector2(0, 3)
	_apply_cta_button_state(style, palette, state)
	return style


static func _stone_button_base(palette: Dictionary, radius: int, vertical_margin: float) -> StyleBoxFlat:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(STONE_MID, 0.86)
	style.border_color = Color(rim, 0.72)
	style.set_border_width_all(2)
	style.set_corner_radius_all(radius)
	style.content_margin_top = vertical_margin
	style.content_margin_bottom = vertical_margin
	style.content_margin_left = 9.0
	style.content_margin_right = 9.0
	style.shadow_color = Color(crystal, 0.12)
	style.shadow_size = 4
	style.shadow_offset = Vector2(0, 2)
	return style


static func _apply_stone_button_state(style: StyleBoxFlat, palette: Dictionary, state: String) -> void:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	match state:
		"hover":
			style.bg_color = Color(STONE_MID.lightened(0.08), 0.94)
			style.border_color = Color(crystal.lightened(0.18), 0.95)
			style.shadow_color = Color(crystal, 0.20)
			style.shadow_size = 6
		"pressed":
			style.bg_color = Color(STONE_BLACK, 0.96)
			style.border_color = Color(rim.darkened(0.10), 0.90)
			style.shadow_size = 2
		"disabled":
			style.bg_color = Color(STONE_BLACK, 0.55)
			style.border_color = Color(IRON, 0.45)
			style.shadow_color = Color.TRANSPARENT
			style.shadow_size = 0


static func _apply_cta_button_state(style: StyleBoxFlat, palette: Dictionary, state: String) -> void:
	var rim: Color = palette.get("rim", GOLD)
	var highlight := Color(GOLD_LIGHT.lerp(rim, 0.30), 0.92)
	var shadow_edge := Color(BRONZE_DARK.lerp(STONE_BLACK, 0.35), 0.88)
	match state:
		"normal":
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_bottom = 2
			style.border_width_right = 2
			style.border_color = highlight
		"hover":
			style.bg_color = Color(STONE_MID.lightened(0.10), 0.96)
			style.border_width_top = 3
			style.border_width_left = 3
			style.border_width_bottom = 2
			style.border_width_right = 2
			style.border_color = Color(GOLD_LIGHT, 0.95)
			style.shadow_color = Color(STONE_BLACK, 0.48)
			style.shadow_size = 6
			style.shadow_offset = Vector2(0, 4)
		"pressed":
			style.bg_color = Color(STONE_BLACK, 0.96)
			style.border_width_top = 1
			style.border_width_left = 1
			style.border_width_bottom = 3
			style.border_width_right = 3
			style.border_color = shadow_edge
			style.shadow_color = Color(STONE_BLACK, 0.28)
			style.shadow_size = 2
			style.shadow_offset = Vector2(0, 1)
		"disabled":
			style.bg_color = Color(STONE_BLACK, 0.55)
			style.border_color = Color(IRON, 0.45)
			style.set_border_width_all(2)
			style.shadow_color = Color.TRANSPARENT
			style.shadow_size = 0
			style.shadow_offset = Vector2.ZERO


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


static func wheel_rim_colors(palette: Dictionary = {}) -> Dictionary:
	var rim: Color = palette.get("rim", GOLD)
	var crystal: Color = palette.get("crystal", CRYSTAL)
	return {
		"bronze": BRONZE.lerp(rim.darkened(0.25), 0.35),
		"gold": GOLD.lerp(rim.lightened(0.05), 0.40),
		"crystal": crystal,
		"stone": STONE_DEEP,
	}
