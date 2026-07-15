extends Resource
class_name VisualSkin

## Data-driven container for one visual skin (art pack).

@export var skin_id: StringName

@export_group("Backgrounds")
@export var menu_background: Texture2D
@export var game_background: Texture2D
@export var overlay_color: Color = Color(0,0,0,0.6)

@export_group("Panels")
@export var panel_style: StyleBoxTexture
@export var modal_style: StyleBoxTexture
@export var hud_style: StyleBoxTexture

@export_group("Buttons")
@export var button_normal: StyleBoxTexture
@export var button_hover: StyleBoxTexture
@export var button_pressed: StyleBoxTexture
@export var button_disabled: StyleBoxTexture

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
