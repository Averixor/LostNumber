extends RefCounted
class_name LnUi

## Shared Dark Neon Fantasy glass UI styles.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const BG_DARK := Color("#0a0e27")
const BG_SECONDARY := Color("#141829")
const BG_TERTIARY := Color("#1a1f3a")
const DIM_DARK := Color(Color("#0a0e27"), 0.70)
const PANEL := Color(Color("#141829"), 0.72)
const PANEL_HOVER := Color(Color("#1a1f3a"), 0.82)
const PANEL_PRESSED := Color(Color("#0a0e27"), 0.92)
const BORDER := Color(Color("#b83dff"), 0.40)
const BORDER_ACTIVE := Color("#b83dff")
const BORDER_LIGHT := Color(Color("#b83dff"), 0.25)
const TEXT := Color("#ffffff")
const TEXT_MUTED := Color("#c0b8d8")
const TEXT_DISABLED := Color("#8a7a9e")
const ACCENT := Color("#b83dff")
const ACCENT_2 := Color("#ff1b9e")
const VALID := Color("#00ff6b")
const INVALID := Color("#ff3366")
const XP := Color("#b83dff")
const GOAL := Color("#00ff6b")
const GOLD := Color("#ffb800")
const CYAN := Color("#00f0ff")

const BG_MAIN_MENU := "res://assets/ui/backgrounds/dark/menu-bg-1.png"
const BG_GAME := "res://assets/ui/backgrounds/dark/menu-bg-3.png"
const BG_WHEEL := "res://assets/ui/backgrounds/dark/menu-bg-4.png"
const BG_SETTINGS := "res://assets/ui/backgrounds/dark/menu-bg-5.png"
const BG_DAILY := "res://assets/ui/backgrounds/dark/menu-bg-4.png"
const BG_STATS := "res://assets/ui/backgrounds/dark/menu-bg-2.png"
const BG_ABOUT := "res://assets/ui/backgrounds/dark/menu-bg-5.png"
const BG_ACHIEVEMENTS := "res://assets/ui/backgrounds/dark/menu-bg-3.png"
const BG_BOOT := "res://assets/boot/boot-bg.png"
const BOOT_LOGO_PATH := "res://assets/boot/boot-logo.png"
const LOGO_PATH := "res://assets/ui/logo/lost-number-logo.png"
const LOGO_GLOW_PATH := "res://assets/ui/logo/lost-number-logo-glow.png"
const ICON_DIR := "res://assets/ui/icons/neon/"
const WHEEL_ICON_DIR := "res://assets/ui/icons/wheel/"

const LIGHT_BACKGROUNDS := [
	"res://assets/ui/backgrounds/light/bg-light-01.png",
	"res://assets/ui/backgrounds/light/bg-light-02.png",
	"res://assets/ui/backgrounds/light/bg-light-03.png",
	"res://assets/ui/backgrounds/light/bg-light-04.png",
	"res://assets/ui/backgrounds/light/bg-light-05.png",
	"res://assets/ui/backgrounds/light/bg-light-06.png",
]

const _SCREEN_DARK_BG := {
	"main_menu": BG_MAIN_MENU,
	"game": BG_GAME,
	"wheel": BG_WHEEL,
	"daily": BG_DAILY,
	"settings": BG_SETTINGS,
	"stats": BG_STATS,
	"about": BG_ABOUT,
	"achievements": BG_ACHIEVEMENTS,
	"boot": BG_BOOT,
}

const _SCREEN_LIGHT_INDEX := {
	"main_menu": 0,
	"stats": 1,
	"game": 2,
	"wheel": 3,
	"daily": 3,
	"settings": 4,
	"about": 4,
	"achievements": 2,
	"boot": 0,
}


static func apply_screen_background(root: Control, screen: String, dim_alpha: float = 0.70) -> void:
	set_background(root, screen_bg(screen), dim_alpha)


static func make_glass_panel(radius: int = ThemeTokensLib.RADIUS_PANEL, border_width: int = 1) -> StyleBoxFlat:
	return glass_box(radius, border_width, PANEL, BORDER, Color(ACCENT, ThemeTokensLib.GLOW_SOFT), ThemeTokensLib.SHADOW_MEDIUM)


static func make_neon_panel(accent: Color = ACCENT, radius: int = ThemeTokensLib.RADIUS_PANEL) -> StyleBoxFlat:
	var sb := glass_box(radius, 2, Color(BG_TERTIARY, 0.68), accent, Color(accent, ThemeTokensLib.GLOW_MEDIUM), ThemeTokensLib.SHADOW_STRONG)
	sb.content_margin_left = ThemeTokensLib.SPACE_LG
	sb.content_margin_right = ThemeTokensLib.SPACE_LG
	sb.content_margin_top = ThemeTokensLib.SPACE_MD
	sb.content_margin_bottom = ThemeTokensLib.SPACE_MD
	return sb


static func make_primary_button() -> StyleBoxFlat:
	return primary_button_normal()


static func make_secondary_button() -> StyleBoxFlat:
	return button_normal()


static func make_icon_button() -> StyleBoxFlat:
	var sb := glass_box(ThemeTokensLib.RADIUS_BUTTON, 2, Color(ACCENT, 0.10), BORDER_ACTIVE, Color(ACCENT, 0.25), ThemeTokensLib.SHADOW_MEDIUM)
	sb.content_margin_left = ThemeTokensLib.SPACE_SM
	sb.content_margin_right = ThemeTokensLib.SPACE_SM
	sb.content_margin_top = ThemeTokensLib.SPACE_SM
	sb.content_margin_bottom = ThemeTokensLib.SPACE_SM
	return sb


static func make_booster_button(active: bool = false, available: bool = true) -> StyleBoxFlat:
	var accent := VALID if active else ACCENT
	var bg := Color(accent, 0.18 if active else 0.10)
	var border := accent if available or active else Color(BORDER_LIGHT, 0.55)
	var sb := glass_box(ThemeTokensLib.RADIUS_BUTTON, 2, bg, border, Color(accent, 0.32 if active else 0.18), ThemeTokensLib.SHADOW_MEDIUM)
	sb.content_margin_left = ThemeTokensLib.SPACE_SM
	sb.content_margin_right = ThemeTokensLib.SPACE_SM
	sb.content_margin_top = ThemeTokensLib.SPACE_XS
	sb.content_margin_bottom = ThemeTokensLib.SPACE_XS
	return sb


static func make_tile_style(value: int = 0, selected: bool = false) -> StyleBoxFlat:
	var face := ThemeTokensLib.COLOR_CELL
	if value > 0 and ThemeTokensLib.TILE_COLORS.has(value):
		face = ThemeTokensLib.TILE_COLORS[value]
	elif value > 0 and ThemeTokensLib.TILE_GRADIENTS.has(value):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[value]
		face = pair[0].lerp(pair[1], 0.5)
	var border := VALID if selected else Color(face.lightened(0.12), 0.78)
	var glow := Color(border, 0.38 if selected else 0.22)
	var sb := glass_box(ThemeTokensLib.TILE_RADIUS, 2, face, border, glow, 8)
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	return sb


static func make_progress_bar_style(fill_color: Color = VALID) -> Dictionary:
	return {
		"track": progress_track(),
		"fill": progress_fill(fill_color, true),
	}


static func make_toggle_style(checked: bool = false) -> StyleBoxFlat:
	var accent := VALID if checked else ACCENT
	return glass_box(ThemeTokensLib.RADIUS_BUTTON, 1, Color(BG_TERTIARY, 0.58), Color(accent, 0.42), Color(accent, 0.12), ThemeTokensLib.SHADOW_SOFT)


static func make_dropdown_style() -> StyleBoxFlat:
	return option_glass_row(false)


static func make_header_title(size: int = ThemeTokensLib.FONT_SIZE_TITLE, color: Color = TEXT) -> LabelSettings:
	var settings := LabelSettings.new()
	settings.font_size = size
	settings.font_color = color
	settings.outline_size = 2
	settings.outline_color = Color(0, 0, 0, 0.45)
	settings.shadow_color = Color(ACCENT_2, 0.35)
	settings.shadow_offset = Vector2(0, 2)
	return settings


static func apply_glow(control: Control, color: Color = ACCENT, size: int = ThemeTokensLib.SHADOW_MEDIUM) -> void:
	if control == null:
		return
	if control is PanelContainer:
		var current := control.get_theme_stylebox("panel")
		var sb := current.duplicate() if current is StyleBoxFlat else make_neon_panel(color)
		if sb is StyleBoxFlat:
			(sb as StyleBoxFlat).shadow_color = Color(color, 0.35)
			(sb as StyleBoxFlat).shadow_size = size
			control.add_theme_stylebox_override("panel", sb)
	elif control is Button:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var current := control.get_theme_stylebox(state)
			if current is StyleBoxFlat:
				var sb := (current as StyleBoxFlat).duplicate()
				sb.shadow_color = Color(color, 0.32)
				sb.shadow_size = size
				control.add_theme_stylebox_override(state, sb)


static func add_corner_decorations(parent: Control, color: Color = ACCENT, length: float = 18.0, thickness: float = 2.0) -> void:
	if parent == null or parent.get_node_or_null("LN_CornerDecorations") != null:
		return
	var layer := Control.new()
	layer.name = "LN_CornerDecorations"
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.set_anchors_preset(Control.PRESET_FULL_RECT)
	parent.add_child(layer)
	for spec in [
		["TL_H", 0, 0, length, thickness],
		["TL_V", 0, 0, thickness, length],
		["TR_H", -length, 0, 0, thickness],
		["TR_V", -thickness, 0, 0, length],
		["BL_H", 0, -thickness, length, 0],
		["BL_V", 0, -length, thickness, 0],
		["BR_H", -length, -thickness, 0, 0],
		["BR_V", -thickness, -length, 0, 0],
	]:
		var rect := ColorRect.new()
		rect.name = str(spec[0])
		rect.color = color
		rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		layer.add_child(rect)
		rect.anchor_left = 1.0 if str(spec[0]).begins_with("TR") or str(spec[0]).begins_with("BR") else 0.0
		rect.anchor_right = rect.anchor_left
		rect.anchor_top = 1.0 if str(spec[0]).begins_with("BL") or str(spec[0]).begins_with("BR") else 0.0
		rect.anchor_bottom = rect.anchor_top
		rect.offset_left = float(spec[1])
		rect.offset_top = float(spec[2])
		rect.offset_right = float(spec[3])
		rect.offset_bottom = float(spec[4])


static func add_magic_divider(parent: Control, color: Color = ACCENT_2, height: float = 2.0) -> ColorRect:
	var divider := ColorRect.new()
	divider.name = "LN_MagicDivider"
	divider.custom_minimum_size = Vector2(0, height)
	divider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	divider.color = Color(color, 0.72)
	divider.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(divider)
	return divider


static func glass_box(radius: int = 8, border_width: int = 2, bg: Color = PANEL, border: Color = BORDER, glow: Color = Color.TRANSPARENT, glow_size: int = 0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = glow if glow.a > 0.0 else Color(0, 0, 0, 0.35)
	sb.shadow_size = glow_size if glow_size > 0 else 8
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 16
	sb.content_margin_right = 16
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


static func emphasized_panel(radius: int = 8) -> StyleBoxFlat:
	return glass_box(radius, 2, Color(BG_TERTIARY, 0.65), BORDER_ACTIVE, Color(ACCENT, 0.18), 16)


static func progress_track(height: float = 8.0) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(ACCENT, 0.10)
	sb.border_color = BORDER_LIGHT
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(4)
	sb.content_margin_top = 0
	sb.content_margin_bottom = 0
	sb.content_margin_left = 0
	sb.content_margin_right = 0
	return sb


static func progress_fill(color: Color, glow: bool = true) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = color
	sb.set_corner_radius_all(4)
	if glow:
		sb.shadow_color = Color(color, 0.55)
		sb.shadow_size = 6
	return sb


static func button_normal() -> StyleBoxFlat:
	return glass_box(8, 2, Color(ACCENT, 0.10), BORDER_ACTIVE, Color(ACCENT, 0.22), 12)


static func button_hover() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = Color(ACCENT, 0.16)
	sb.border_color = ACCENT_2
	sb.shadow_color = Color(ACCENT, 0.35)
	sb.shadow_size = 16
	return sb


static func button_pressed() -> StyleBoxFlat:
	var sb := button_normal()
	sb.bg_color = Color(ACCENT, 0.22)
	sb.border_color = ACCENT_2
	return sb


static func button_disabled() -> StyleBoxFlat:
	return glass_box(8, 1, Color(BG_TERTIARY, 0.45), Color(BORDER_LIGHT, 0.5), Color.TRANSPARENT, 0)


static func primary_button_normal() -> StyleBoxFlat:
	var sb := glass_box(8, 2, ACCENT.lerp(ACCENT_2, 0.35), BORDER_ACTIVE, Color(ACCENT, 0.40), 12)
	sb.bg_color = Color(ACCENT, 0.15).lerp(Color(ACCENT_2, 0.10), 0.5)
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


static func success_button_normal() -> StyleBoxFlat:
	var sb := glass_box(8, 2, Color(VALID, 0.14), VALID, Color(VALID, 0.35), 12)
	sb.content_margin_top = 14
	sb.content_margin_bottom = 14
	return sb


static func small_pill(bg: Color = Color(0.14, 0.07, 0.19, 0.86), border: Color = BORDER_ACTIVE) -> StyleBoxFlat:
	var sb := glass_box(18, 2, bg, border)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
	return sb


static func apply_button(btn: Button, disabled: bool = false) -> void:
	btn.add_theme_stylebox_override("normal", button_normal())
	btn.add_theme_stylebox_override("hover", button_hover())
	btn.add_theme_stylebox_override("pressed", button_pressed())
	btn.add_theme_stylebox_override("disabled", button_disabled())
	btn.add_theme_color_override("font_color", TEXT)
	btn.add_theme_color_override("font_hover_color", TEXT)
	btn.add_theme_color_override("font_pressed_color", TEXT)
	btn.add_theme_color_override("font_disabled_color", TEXT_DISABLED)
	btn.add_theme_font_size_override("font_size", 16)
	if btn.custom_minimum_size.y < 48.0:
		btn.custom_minimum_size.y = 48
	btn.focus_mode = Control.FOCUS_NONE
	btn.disabled = disabled
	if btn is BaseButton:
		hook_press_scale(btn as BaseButton)


static func apply_compact_button(btn: Button, font_size: int = 15, min_height: float = 42.0, disabled: bool = false) -> void:
	apply_button(btn, disabled)
	btn.add_theme_font_size_override("font_size", font_size)
	btn.custom_minimum_size.y = min_height
	for state in ["normal", "hover", "pressed", "disabled"]:
		var sb := btn.get_theme_stylebox(state)
		if sb is StyleBoxFlat:
			var compact := (sb as StyleBoxFlat).duplicate()
			compact.content_margin_top = 6
			compact.content_margin_bottom = 6
			compact.content_margin_left = 10
			compact.content_margin_right = 10
			compact.set_corner_radius_all(14)
			btn.add_theme_stylebox_override(state, compact)


static func apply_icon_button(btn: Button) -> void:
	apply_button(btn)
	btn.custom_minimum_size = Vector2(56, 56)
	btn.add_theme_font_size_override("font_size", 18)


static func apply_title(label: Label, size: int = 42) -> void:
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", size)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


static func apply_body(label: Label, size: int = 22) -> void:
	label.add_theme_color_override("font_color", TEXT_MUTED)
	label.add_theme_font_size_override("font_size", size)


static func icon_path(name: String) -> String:
	return ICON_DIR + name


static func wheel_icon_path(file_name: String) -> String:
	return WHEEL_ICON_DIR + file_name


static func load_wheel_icon(file_name: String) -> Texture2D:
	var path := wheel_icon_path(file_name)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func apply_wheel_button_icon(btn: Button, file_name: String, max_size: int = 26) -> void:
	var tex := load_wheel_icon(file_name)
	if tex == null:
		return
	btn.icon = tex
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", max_size)
	btn.add_theme_constant_override("icon_max_height", max_size)


static func _theme_manager() -> Node:
	var tree := Engine.get_main_loop()
	if tree == null or not tree is SceneTree:
		return null
	return (tree as SceneTree).root.get_node_or_null("/root/ThemeManager")


static func is_dark_theme() -> bool:
	var theme_mgr := _theme_manager()
	if theme_mgr != null and theme_mgr.has_method("is_dark"):
		return bool(theme_mgr.call("is_dark"))
	return true


static func load_background_texture(path: String) -> Texture2D:
	if path.is_empty():
		return null
	if path.begins_with("user://"):
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null:
				return ImageTexture.create_from_image(img)
		return null
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func current_background_path(screen: String = "") -> String:
	if screen == "boot" and ResourceLoader.exists(BG_BOOT):
		return BG_BOOT
	var theme_mgr := _theme_manager()
	if theme_mgr != null and theme_mgr.has_method("get_background_texture_path"):
		var selected := str(theme_mgr.call("get_background_texture_path"))
		if not selected.is_empty():
			return selected
	return _legacy_screen_bg(screen)


static func screen_bg(screen: String) -> String:
	return current_background_path(screen)


static func _legacy_screen_bg(screen: String) -> String:
	var dark_path: String = str(_SCREEN_DARK_BG.get(screen, BG_MAIN_MENU))
	if is_dark_theme():
		return dark_path
	var idx: int = int(_SCREEN_LIGHT_INDEX.get(screen, 0))
	idx = clampi(idx, 0, LIGHT_BACKGROUNDS.size() - 1)
	var light_path: String = LIGHT_BACKGROUNDS[idx]
	if ResourceLoader.exists(light_path):
		return light_path
	return dark_path


static func load_icon(name: String) -> Texture2D:
	var path := icon_path(name)
	if ResourceLoader.exists(path):
		return load(path) as Texture2D
	return null


static func hud_panel() -> StyleBoxFlat:
	var sb := glass_box(8, 1, Color(BG_TERTIARY, 0.55), BORDER_LIGHT, Color(ACCENT, 0.12), 10)
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 8
	sb.content_margin_bottom = 8
	return sb


static func chain_sum_panel(valid: bool) -> StyleBoxFlat:
	var accent := VALID if valid else CYAN
	var sb := glass_box(8, 2, Color(BG_DARK, 0.92), accent, Color(0, 0, 0, 0.45), 10)
	sb.content_margin_left = 12
	sb.content_margin_right = 12
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	return sb


static func apply_check_icon(check: CheckButton, icon_name: String) -> void:
	var tex := load_icon(icon_name)
	if tex == null:
		return
	check.icon = tex
	check.expand_icon = true
	check.add_theme_constant_override("icon_max_width", 28)


static func apply_button_icon(btn: Button, icon_name: String) -> void:
	var tex := load_icon(icon_name)
	if tex == null:
		return
	btn.icon = tex
	btn.expand_icon = true
	btn.add_theme_constant_override("icon_max_width", 28)


static func settings_glass_row(compact: bool = false) -> StyleBoxFlat:
	var sb := glass_box(8 if compact else 8, 1, Color(BG_TERTIARY, 0.55), BORDER_LIGHT, Color(ACCENT, 0.08), 8)
	var margin := 12 if compact else 14
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = 8 if compact else 10
	sb.content_margin_bottom = 8 if compact else 10
	return sb


static func option_glass_row(compact: bool = false) -> StyleBoxFlat:
	var sb := settings_glass_row(compact)
	sb.content_margin_left = 8 if compact else 10
	sb.content_margin_right = 8 if compact else 10
	return sb


static func apply_settings_row(check: CheckButton, compact: bool = false) -> void:
	var row := settings_glass_row(compact)
	check.custom_minimum_size = Vector2(0, 44.0 if compact else 52.0)
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	check.add_theme_stylebox_override("normal", row)
	check.add_theme_stylebox_override("hover", row.duplicate())
	check.add_theme_stylebox_override("pressed", row.duplicate())
	check.add_theme_stylebox_override("hover_pressed", row.duplicate())
	check.add_theme_stylebox_override("disabled", row.duplicate())
	check.add_theme_font_size_override("font_size", 15 if compact else 18)
	check.add_theme_color_override("font_color", TEXT)
	check.add_theme_color_override("font_pressed_color", TEXT)
	check.add_theme_color_override("font_hover_color", TEXT)


static func apply_option_row_style(option: OptionButton, compact: bool = false) -> void:
	var option_style := option_glass_row(compact)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_theme_font_size_override("font_size", 14 if compact else 15)
	option.add_theme_color_override("font_color", TEXT)
	option.add_theme_stylebox_override("normal", option_style)
	option.add_theme_stylebox_override("hover", option_style.duplicate())
	option.add_theme_stylebox_override("pressed", option_style.duplicate())
	option.add_theme_stylebox_override("focus", option_style.duplicate())


static func apply_settings_row_density(check: CheckButton, compact: bool) -> void:
	apply_settings_row(check, compact)
	check.add_theme_constant_override("h_separation", 8 if compact else 12)
	check.add_theme_constant_override("icon_max_width", 22 if compact else 26)


static func apply_toggle_switch(check: CheckButton, compact: bool = false) -> void:
	apply_settings_row_density(check, compact)
	check.add_theme_color_override("icon_normal_color", TEXT_DISABLED)
	check.add_theme_color_override("icon_hover_color", VALID)
	check.add_theme_color_override("icon_pressed_color", VALID)
	check.add_theme_color_override("icon_hover_pressed_color", VALID)
	check.add_theme_color_override("icon_disabled_color", TEXT_DISABLED)


static func try_add_logo(parent: Control, path: String = LOGO_PATH, min_size: Vector2 = Vector2(300, 110)) -> TextureRect:
	if not ResourceLoader.exists(path):
		return null
	var logo := TextureRect.new()
	logo.name = "LogoImage"
	logo.texture = load(path)
	logo.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.custom_minimum_size = min_size
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(logo)
	parent.move_child(logo, 0)
	return logo


static func wire_logo_glow(logo: TextureRect, main_path: String = LOGO_PATH) -> void:
	if logo == null:
		return
	if ResourceLoader.exists(main_path):
		logo.texture = load(main_path)
	if not ResourceLoader.exists(LOGO_GLOW_PATH):
		return

	var host: Control = logo
	if logo.get_parent() != null and logo.get_parent().name == "LogoStack":
		host = logo.get_parent() as Control
	else:
		var parent := logo.get_parent()
		if parent == null:
			return
		var min_size := logo.custom_minimum_size
		var stack := Control.new()
		stack.name = "LogoStack"
		stack.custom_minimum_size = min_size
		var idx := logo.get_index()
		parent.add_child(stack)
		parent.move_child(stack, idx)
		logo.reparent(stack)
		host = stack
		_center_texture_rect(logo, min_size)

	var glow := host.get_node_or_null("LogoGlow") as TextureRect
	if glow == null:
		glow = TextureRect.new()
		glow.name = "LogoGlow"
		glow.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		glow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		host.add_child(glow)
		host.move_child(glow, 0)
	glow.texture = load(LOGO_GLOW_PATH)
	var glow_size := logo.custom_minimum_size * 1.18
	_center_texture_rect(glow, glow_size)
	glow.modulate = Color(1, 1, 1, 0.72)
	host.move_child(glow, 0)


static func _center_texture_rect(rect: TextureRect, size: Vector2) -> void:
	rect.set_anchors_preset(Control.PRESET_CENTER)
	rect.offset_left = -size.x * 0.5
	rect.offset_top = -size.y * 0.5
	rect.offset_right = size.x * 0.5
	rect.offset_bottom = size.y * 0.5
	rect.custom_minimum_size = size


static func set_background(root: Control, bg_path: String, dim_alpha: float = 0.70) -> void:
	var texture := load_background_texture(bg_path)
	if texture == null:
		return

	var bg := root.get_node_or_null("LN_Background") as TextureRect
	if bg == null:
		bg = TextureRect.new()
		bg.name = "LN_Background"
		root.add_child(bg)
		root.move_child(bg, 0)
	bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	bg.offset_left = 0
	bg.offset_top = 0
	bg.offset_right = 0
	bg.offset_bottom = 0
	bg.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bg.texture = texture

	var dim := root.get_node_or_null("LN_BackdropDim") as ColorRect
	if dim == null:
		dim = ColorRect.new()
		dim.name = "LN_BackdropDim"
		root.add_child(dim)
		root.move_child(dim, 1)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	dim.offset_left = 0
	dim.offset_top = 0
	dim.offset_right = 0
	dim.offset_bottom = 0
	dim.color = Color(BG_DARK, dim_alpha)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE

	# Hide legacy flat ColorRect backgrounds when LN layer is active.
	var legacy := root.get_node_or_null("Background") as ColorRect
	if legacy != null:
		legacy.visible = false


static func animate_entrance(items: Array, stagger: float = 0.05, duration: float = 0.24) -> void:
	if items.is_empty():
		return
	var host := items[0] as Control
	if host == null or not host.is_inside_tree():
		return
	for item in items:
		var ctrl := item as Control
		if ctrl == null:
			continue
		ctrl.modulate.a = 0.0
	await host.get_tree().process_frame
	for i in items.size():
		var ctrl := items[i] as Control
		if ctrl == null or not ctrl.is_inside_tree():
			continue
		var target_y := ctrl.position.y
		ctrl.position.y = target_y + 12.0
		var tween := host.create_tween().set_parallel(true)
		var delay := stagger * i
		tween.tween_property(ctrl, "modulate:a", 1.0, duration) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(ctrl, "position:y", target_y, duration) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


static func hook_press_scale(button: BaseButton) -> void:
	if button.has_meta("_ln_press_hooked"):
		return
	button.set_meta("_ln_press_hooked", true)
	button.button_down.connect(func(): _tween_button_scale(button, 0.97))
	button.button_up.connect(func(): _tween_button_scale(button, 1.0))


static func _tween_button_scale(button: BaseButton, target: float) -> void:
	if not button.is_inside_tree():
		return
	button.pivot_offset = button.size * 0.5
	var tween := button.create_tween()
	tween.tween_property(button, "scale", Vector2.ONE * target, 0.1) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


static func show_toast(host: Control, text: String, duration: float = 1.6) -> void:
	if host == null or text.is_empty():
		return
	var layer: Control = null
	var tree := host.get_tree()
	if tree != null:
		var app := tree.root.get_node_or_null("App")
		if app != null:
			layer = app.get_node_or_null("OverlayRoot/ToastLayer") as Control
	if layer == null:
		layer = host
	var toast := PanelContainer.new()
	toast.name = "LnToast"
	toast.mouse_filter = Control.MOUSE_FILTER_IGNORE
	toast.add_theme_stylebox_override("panel", small_pill(Color(0.12, 0.06, 0.16, 0.92), BORDER_ACTIVE))
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", TEXT)
	label.add_theme_font_size_override("font_size", 14)
	toast.add_child(label)
	layer.add_child(toast)
	toast.set_anchors_preset(Control.PRESET_CENTER_TOP)
	toast.offset_top = 72.0
	toast.modulate.a = 0.0
	var tween := toast.create_tween()
	tween.tween_property(toast, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_interval(maxf(0.4, duration - 0.52))
	tween.tween_property(toast, "modulate:a", 0.0, 0.2)
	tween.tween_callback(toast.queue_free)


static func show_floating_text(parent: Control, text: String, local_pos: Vector2, color: Color = XP) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var label := Label.new()
	label.text = text
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_color_override("font_color", color)
	label.add_theme_font_size_override("font_size", 20)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	parent.add_child(label)
	label.position = local_pos - Vector2(40, 8)
	label.modulate.a = 0.0
	var tween := parent.create_tween().set_parallel(true)
	tween.tween_property(label, "modulate:a", 1.0, 0.12).set_trans(Tween.TRANS_SINE)
	tween.tween_property(label, "position:y", label.position.y - 36.0, 0.85) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	tween.chain().tween_property(label, "modulate:a", 0.0, 0.2)
	tween.chain().tween_callback(label.queue_free)
