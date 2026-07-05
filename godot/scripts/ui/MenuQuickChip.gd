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
	caption.clip_text = true
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	if ResourceLoader.exists(icon_path):
		icon_rect.texture = load(icon_path)
	icon_rect.custom_minimum_size = Vector2(14, 14)


func _apply_style() -> void:
	custom_minimum_size = Vector2(72, 40)
	add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_CHIP)
	var normal := StyleBoxFlat.new()
	normal.bg_color = ThemeTokensLib.MENU_CHIP_BG
	normal.set_corner_radius_all(4)
	normal.set_border_width_all(1)
	normal.border_color = ThemeTokensLib.MENU_CHIP_BORDER
	normal.set_content_margin_all(6)
	normal.content_margin_left = 6
	normal.content_margin_right = 6
	add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color(ThemeTokensLib.ICON_PINK, 0.55)
	hover.shadow_color = Color(ThemeTokensLib.ICON_VIOLET, 0.35)
	hover.shadow_size = 6
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", normal.duplicate())
	add_theme_stylebox_override("focus", hover.duplicate())
	caption.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_CHIP)
	caption.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	caption.add_theme_color_override("font_color", Color.WHITE)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
