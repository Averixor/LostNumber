extends Button
class_name MenuDockButton

## Bottom dock item: circular icon button with label below.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var icon_rect: TextureRect = $VBox/Icon
@onready var caption: Label = $VBox/Label


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	_apply_style()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_style)


func setup(text: String, icon_path: String) -> void:
	caption.text = text
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(28, 28)


func _apply_style() -> void:
	custom_minimum_size = Vector2(68, 76)
	caption.add_theme_font_size_override("font_size", 12)
	var text_color := ThemeTokensLib.COLOR_TEXT
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_text_color"):
		text_color = theme.call("get_text_color")
	caption.add_theme_color_override("font_color", Color(text_color, 0.92))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS

	var radius := 36
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(ThemeTokensLib.MENU_DOCK_BG, 0.75)
	normal.set_corner_radius_all(radius)
	normal.set_border_width_all(2)
	normal.border_color = Color(ThemeTokensLib.MENU_CHIP_BORDER, 0.55)
	normal.set_content_margin_all(8)
	add_theme_stylebox_override("normal", normal)

	var hover := normal.duplicate() as StyleBoxFlat
	hover.border_color = Color(ThemeTokensLib.ICON_PINK, 0.7)
	hover.shadow_color = Color(ThemeTokensLib.ICON_VIOLET, 0.4)
	hover.shadow_size = 8
	add_theme_stylebox_override("hover", hover)
	add_theme_stylebox_override("pressed", normal.duplicate())
	add_theme_stylebox_override("focus", hover.duplicate())
