extends Button
class_name MenuDockButton

## Bottom dock item (web .menu-dock-btn): icon above label.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var icon_rect: TextureRect = $VBox/Icon
@onready var caption: Label = $VBox/Label


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	_apply_style()


func setup(text: String, icon_path: String) -> void:
	caption.text = text
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(28, 28)


func _apply_style() -> void:
	caption.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL - 2)
	caption.add_theme_color_override("font_color", ThemeTokensLib.COLOR_TEXT)
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
