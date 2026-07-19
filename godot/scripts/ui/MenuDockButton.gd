extends Button
class_name MenuDockButton

## Bottom dock item: circular icon button with label below.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const DISABLED_MODULATE := Color(1, 1, 1, 0.38)

@onready var icon_rect: TextureRect = $VBox/Icon
@onready var caption: Label = $VBox/Label


func _ready() -> void:
	flat = true
	focus_mode = Control.FOCUS_ALL
	_apply_style()
	refresh_enabled_visual()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_on_theme_changed)


func setup(text: String, icon_path: String) -> void:
	caption.text = text
	if ResourceLoader.exists(icon_path):
		var tex: Texture2D = load(icon_path)
		icon_rect.texture = tex
	icon_rect.custom_minimum_size = Vector2(28, 28)
	_fit_caption_font()
	refresh_enabled_visual()


func refresh_enabled_visual() -> void:
	## Mute the whole control (icon + label) when disabled so layout does not jump.
	modulate = Color.WHITE if not disabled else DISABLED_MODULATE


func _on_theme_changed() -> void:
	_apply_style()
	refresh_enabled_visual()


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_fit_caption_font()


func _fit_caption_font() -> void:
	if caption == null:
		return
	var max_width := maxf(size.x - 4.0, custom_minimum_size.x - 4.0)
	if max_width <= 8.0:
		max_width = 64.0
	var font: Font = caption.get_theme_font("font")
	if font == null:
		font = ThemeDB.fallback_font
	if font == null:
		return
	var size_px := 12
	while size_px > 8:
		var text_size := font.get_string_size(caption.text, HORIZONTAL_ALIGNMENT_LEFT, -1, size_px)
		if text_size.x <= max_width:
			break
		size_px -= 1
	caption.add_theme_font_size_override("font_size", size_px)
	# Prefer fitting over ellipsis so UK "Налаштування" stays fully readable at 420×920.
	caption.clip_text = false
	caption.text_overrun_behavior = TextServer.OVERRUN_NO_TRIMMING


func _apply_style() -> void:
	custom_minimum_size = Vector2(72, 76)
	var text_color := ThemeTokensLib.COLOR_TEXT
	var theme := get_node_or_null("/root/ThemeManager")
	var is_dark := true
	if theme != null and theme.has_method("is_dark"):
		is_dark = bool(theme.call("is_dark"))
	if theme != null and theme.has_method("get_text_color"):
		text_color = theme.call("get_text_color")
	elif not is_dark:
		text_color = ThemeTokensLib.DAWN_COLOR_TEXT
	caption.add_theme_color_override("font_color", Color(text_color, 0.92 if is_dark else 1.0))
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.autowrap_mode = TextServer.AUTOWRAP_OFF
	_fit_caption_font()

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

	var disabled_style := normal.duplicate() as StyleBoxFlat
	disabled_style.bg_color = Color(ThemeTokensLib.MENU_DOCK_BG, 0.35)
	disabled_style.border_color = Color(ThemeTokensLib.MENU_CHIP_BORDER, 0.28)
	add_theme_stylebox_override("disabled", disabled_style)
