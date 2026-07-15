extends Resource
class_name VisualSkin

## One complete visual-art kit. Brightness mode and background variant remain
## owned by ThemeManager so the same skin can be rendered in dawn or dusk.

const RARITY_COMMON := &"common"
const RARITY_UNCOMMON := &"uncommon"
const RARITY_RARE := &"rare"
const RARITY_EPIC := &"epic"
const RARITY_LEGENDARY := &"legendary"

@export var skin_id: StringName = &""
@export var name_key: StringName = &""
@export var description_key: StringName = &""
@export var supports_light_mode := true

@export_group("Backgrounds")
@export var menu_background: Texture2D
@export var game_background: Texture2D
@export var dark_overlay_color := Color(0.025, 0.015, 0.04, 0.42)
@export var light_overlay_color := Color(0.92, 0.86, 0.94, 0.28)

@export_group("Palette")
@export var dark_background_color := Color("#09070d")
@export var light_background_color := Color("#eee6f0")
@export var dark_panel_color := Color(0.055, 0.04, 0.075, 0.92)
@export var light_panel_color := Color(0.94, 0.89, 0.95, 0.92)
@export var primary_color := Color("#9c4dff")
@export var secondary_color := Color("#d7aa54")
@export var accent_color := Color("#7b3fbd")
@export var danger_color := Color("#ff4d5e")
@export var success_color := Color("#38e875")
@export var dark_text_color := Color("#f5ead8")
@export var light_text_color := Color("#291d30")
@export var rim_color := Color("#c79a52")
@export var crystal_color := Color("#a855f7")
@export_range(0.0, 2.0, 0.05) var glow_intensity := 1.0

@export_group("Panels")
@export var panel_style: StyleBox
@export var modal_style: StyleBox
@export var hud_style: StyleBox
@export var board_style: StyleBox

@export_group("Buttons")
@export var button_normal: StyleBox
@export var button_hover: StyleBox
@export var button_pressed: StyleBox
@export var button_disabled: StyleBox

@export_group("Tiles")
@export var tile_common: StyleBox
@export var tile_uncommon: StyleBox
@export var tile_rare: StyleBox
@export var tile_epic: StyleBox
@export var tile_legendary: StyleBox
@export var tile_frozen: StyleBox

@export_group("Tile Palette")
@export var tile_2_color := Color("#386a4b")
@export var tile_4_color := Color("#7a3853")
@export var tile_8_color := Color("#9a661f")
@export var tile_16_color := Color("#286c78")
@export var tile_32_color := Color("#5b438d")
@export var tile_64_color := Color("#8e3c42")
@export var tile_128_color := Color("#314e86")
@export var tile_256_color := Color("#704080")
@export var tile_512_color := Color("#89512c")
@export var tile_epic_color := Color("#51407d")
@export var tile_legendary_color := Color("#8a642d")

@export_group("Effects")
@export var chain_valid_color := Color("#39f27b")
@export var chain_invalid_color := Color("#ff4d5e")
@export var chain_continue_color := Color("#a855f7")
@export var chain_core_color := Color("#fff4d6")
@export var particle_color := Color("#a855f7")


func is_valid_skin() -> bool:
	return not skin_id.is_empty() and game_background != null


func background_for(screen: String) -> Texture2D:
	if screen == "game" and game_background != null:
		return game_background
	if menu_background != null:
		return menu_background
	return game_background


func overlay_color(dark_mode: bool) -> Color:
	return dark_overlay_color if dark_mode else light_overlay_color


func palette(dark_mode: bool) -> Dictionary:
	return {
		"bg": dark_background_color if dark_mode else light_background_color,
		"panel": dark_panel_color if dark_mode else light_panel_color,
		"primary": primary_color,
		"secondary": secondary_color,
		"accent": accent_color,
		"danger": danger_color,
		"success": success_color,
		"glow": glow_intensity if dark_mode else glow_intensity * 0.68,
		"rim": rim_color,
		"crystal": crystal_color,
		"title_top": dark_text_color if dark_mode else light_text_color,
		"title_mid": secondary_color,
		"title_end": crystal_color,
	}


func text_color(dark_mode: bool) -> Color:
	return dark_text_color if dark_mode else light_text_color


func style_for(kind: StringName) -> StyleBox:
	match kind:
		&"panel":
			return panel_style
		&"modal":
			return modal_style
		&"hud":
			return hud_style
		&"board":
			return board_style
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


func tile_style_for_value(value: int, frozen: bool = false) -> StyleBox:
	if frozen and tile_frozen != null:
		return tile_frozen
	match rarity_for_value(value):
		RARITY_UNCOMMON:
			return tile_uncommon if tile_uncommon != null else tile_common
		RARITY_RARE:
			return tile_rare if tile_rare != null else tile_common
		RARITY_EPIC:
			return tile_epic if tile_epic != null else tile_common
		RARITY_LEGENDARY:
			return tile_legendary if tile_legendary != null else tile_common
		_:
			return tile_common


func tile_face_color_for_value(value: int) -> Color:
	match value:
		2:
			return tile_2_color
		4:
			return tile_4_color
		8:
			return tile_8_color
		16:
			return tile_16_color
		32:
			return tile_32_color
		64:
			return tile_64_color
		128:
			return tile_128_color
		256:
			return tile_256_color
		512:
			return tile_512_color
		_:
			return tile_legendary_color if value >= 8192 else tile_epic_color


static func rarity_for_value(value: int) -> StringName:
	if value >= 8192:
		return RARITY_LEGENDARY
	if value >= 1024:
		return RARITY_EPIC
	if value >= 128:
		return RARITY_RARE
	if value >= 16:
		return RARITY_UNCOMMON
	return RARITY_COMMON
