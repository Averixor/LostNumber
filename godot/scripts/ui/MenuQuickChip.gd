extends Button
class_name MenuQuickChip

## Quick-row chip (web .menu-quick-btn--chip).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var icon_rect: TextureRect = $HBox/Icon
@onready var caption: Label = $HBox/Label


func _ready() -> void:
	focus_mode = Control.FOCUS_ALL
	_apply_style()


func setup(text: String, icon_path: String) -> void:
	caption.text = text
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	icon_rect.custom_minimum_size = Vector2(16, 16)


func _apply_style() -> void:
	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeTokensLib.MENU_CHIP_BG
	normal.set_corner_radius_all(ThemeTokensLib.RADIUS_PILL)
	normal.set_border_width_all(1)
	normal.border_color = ThemeTokensLib.MENU_CHIP_BORDER
	normal.set_content_margin_all(6)
	normal.content_margin_left = 10
	normal.content_margin_right = 10
	add_theme_stylebox_override("normal", normal)
	add_theme_stylebox_override("hover", normal.duplicate())
	add_theme_stylebox_override("pressed", normal.duplicate())
	add_theme_stylebox_override("focus", normal.duplicate())
	caption.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL - 1)
	caption.add_theme_color_override("font_color", Color.WHITE)
