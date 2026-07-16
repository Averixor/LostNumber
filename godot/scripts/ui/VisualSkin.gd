extends Resource
class_name VisualSkin

## Data-driven container for one visual art skin.
## User-facing text is never baked into these textures.
## Tile face colors are always per-value (ThemeTokens); rarity colors are chrome fallbacks only.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

## Cropped forged frame inside the stone_frame.webp atlas (v13 gameplay reference).
const TILE_FRAME_ATLAS_REGION := Rect2(140, 130, 1320, 1340)

@export var skin_id: StringName
@export var name_key: StringName = &"visual_skin_1"
@export var description_key: StringName = &"visual_skin_1"
@export var supports_light_mode: bool = false

@export_group("Backgrounds")
@export var menu_background: Texture2D
@export var game_background: Texture2D
@export var overlay_color_value: Color = Color(0.031, 0.024, 0.051, 0.72)

@export_group("Panels")
@export var panel_style: StyleBox
@export var modal_style: StyleBox
@export var hud_style: StyleBox

@export_group("Buttons")
@export var button_normal: StyleBox
@export var button_hover: StyleBox
@export var button_pressed: StyleBox
@export var button_disabled: StyleBox

@export_group("Tiles")
@export var tile_common: Texture2D
@export var tile_rare: Texture2D
@export var tile_epic: Texture2D
@export var tile_legendary: Texture2D
@export var tile_frozen_overlay: Texture2D

@export_group("Palette")
@export var background_color: Color = Color(0.035, 0.019, 0.055, 1.0)
@export var panel_color: Color = Color(0.090, 0.047, 0.125, 0.94)
@export var primary_color: Color = Color(0.655, 0.333, 0.969, 1.0)
@export var secondary_color: Color = Color(0.855, 0.667, 0.329, 1.0)
@export var accent_color: Color = Color(0.725, 0.365, 0.925, 1.0)
@export var danger_color: Color = Color(0.900, 0.286, 0.380, 1.0)
@export var success_color: Color = Color(0.310, 0.835, 0.620, 1.0)
@export var text_dark_color: Color = Color(0.969, 0.925, 0.863, 1.0)
@export var text_light_color: Color = Color(0.161, 0.114, 0.188, 1.0)
@export var rim_color: Color = Color(0.843, 0.667, 0.329, 1.0)
@export var crystal_color: Color = Color(0.620, 0.329, 0.902, 1.0)
@export var chain_valid_color: Color = Color(0.439, 0.871, 0.761, 1.0)
@export var chain_invalid_color: Color = Color(0.925, 0.310, 0.404, 1.0)
@export var chain_continue_color: Color = Color(0.843, 0.667, 0.329, 1.0)
@export var chain_core_color: Color = Color(0.961, 0.980, 1.0, 0.95)
@export var particle_color: Color = Color(0.745, 0.392, 0.945, 1.0)
@export_range(0.0, 3.0, 0.05) var glow_intensity: float = 1.0

@export_group("Tile Faces")
@export var tile_common_color: Color = Color(0.227, 0.153, 0.314, 1.0)
@export var tile_rare_color: Color = Color(0.404, 0.227, 0.553, 1.0)
@export var tile_epic_color: Color = Color(0.337, 0.188, 0.525, 1.0)
@export var tile_legendary_color: Color = Color(0.541, 0.392, 0.169, 1.0)

@export_group("Effects")
@export var chain_texture: Texture2D
@export var merge_frames: SpriteFrames
@export var explosion_frames: SpriteFrames


func background_for(screen_kind: StringName) -> Texture2D:
	if screen_kind == &"game" and game_background != null:
		return game_background
	if menu_background != null:
		return menu_background
	return game_background


func style_for(kind: StringName) -> StyleBox:
	match kind:
		&"panel":
			return panel_style
		&"modal":
			return modal_style
		&"hud":
			return hud_style
		&"button_normal":
			return button_normal
		&"button_hover":
			return button_hover
		&"button_pressed":
			return button_pressed
		&"button_disabled":
			return button_disabled
		_:
			return null


func tile_frame_for_value(value: int) -> Texture2D:
	match rarity_for_value(value):
		&"legendary":
			return tile_legendary if tile_legendary != null else tile_common
		&"epic":
			return tile_epic if tile_epic != null else tile_common
		&"rare":
			return tile_rare if tile_rare != null else tile_common
		_:
			return tile_common


func tile_style_for_value(value: int, frozen: bool = false) -> StyleBox:
	if frozen and tile_frozen_overlay != null:
		return _make_tile_style(tile_frozen_overlay, Color(0.64, 0.74, 0.78, 0.9))
	var texture := tile_frame_for_value(value)
	if texture == null:
		return null
	return _make_tile_style(texture, _tile_frame_modulate(value))


func _make_tile_style(texture: Texture2D, modulate: Color) -> StyleBoxTexture:
	var style := StyleBoxTexture.new()
	style.texture = texture
	style.region_rect = TILE_FRAME_ATLAS_REGION
	style.modulate_color = modulate
	style.set_content_margin_all(6.0)
	return style


func _tile_frame_modulate(value: int) -> Color:
	match rarity_for_value(value):
		&"legendary":
			return Color(0.86, 0.72, 0.48, 0.98)
		&"epic":
			return Color(0.64, 0.55, 0.7, 0.96)
		&"rare":
			return Color(0.56, 0.59, 0.68, 0.94)
		&"uncommon":
			return Color(0.57, 0.53, 0.57, 0.92)
		_:
			return Color(0.54, 0.51, 0.5, 0.9)


static func rarity_for_value(value: int) -> StringName:
	if value >= 8192:
		return &"legendary"
	if value >= 1024:
		return &"epic"
	if value >= 128:
		return &"rare"
	if value >= 16:
		return &"uncommon"
	return &"common"


func tile_face_color_for_value(value: int) -> Color:
	# Distinct face per tile value — never collapse 2/4/8/16 into one rarity bucket.
	if ThemeTokensLib.TILE_COLORS.has(value):
		return ThemeTokensLib.TILE_COLORS[value]
	if ThemeTokensLib.TILE_GRADIENTS.has(value):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[value]
		return pair[0].lerp(pair[1], 0.5)
	match rarity_for_value(value):
		&"legendary":
			return tile_legendary_color
		&"epic":
			return tile_epic_color
		&"rare":
			return tile_rare_color
		_:
			return tile_common_color


func palette(dark_mode: bool = true) -> Dictionary:
	var bg := background_color if dark_mode or not supports_light_mode else Color(0.957, 0.910, 0.980, 1.0)
	var panel := panel_color if dark_mode or not supports_light_mode else Color(0.988, 0.961, 1.0, 0.94)
	return {
		"bg": bg,
		"panel": panel,
		"primary": primary_color,
		"secondary": secondary_color,
		"accent": accent_color,
		"danger": danger_color,
		"success": success_color,
		"title_top": secondary_color.lightened(0.18),
		"title_mid": text_color(dark_mode),
		"title_end": accent_color.lightened(0.12),
		"glow": glow_intensity,
		"rim": rim_color,
		"crystal": crystal_color,
	}


func text_color(dark_mode: bool = true) -> Color:
	return text_dark_color if dark_mode or not supports_light_mode else text_light_color


func overlay_color(dark_mode: bool = true) -> Color:
	if dark_mode or not supports_light_mode:
		return overlay_color_value
	return Color(overlay_color_value.r, overlay_color_value.g, overlay_color_value.b, minf(overlay_color_value.a, 0.20))


func is_valid() -> bool:
	return not skin_id.is_empty() and (menu_background != null or game_background != null)


func is_valid_skin() -> bool:
	return is_valid()
