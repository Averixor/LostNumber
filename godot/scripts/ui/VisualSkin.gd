extends Resource
class_name VisualSkin

## Data-driven container for one visual art skin.
## User-facing text is never baked into these textures.

@export var skin_id: StringName

@export_group("Backgrounds")
@export var menu_background: Texture2D
@export var game_background: Texture2D
@export var overlay_color: Color = Color(0, 0, 0, 0.60)

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


func tile_frame_for_value(value: int) -> Texture2D:
	if value >= 2048 and tile_legendary != null:
		return tile_legendary
	if value >= 512 and tile_epic != null:
		return tile_epic
	if value >= 128 and tile_rare != null:
		return tile_rare
	return tile_common


func is_valid() -> bool:
	return not skin_id.is_empty() and (menu_background != null or game_background != null)
