extends RefCounted
class_name LnUi

## Shared gothic-neon glass UI styles (Lost Number restyle spec).

const BG_DARK := Color("#08030F")
const DIM_DARK := Color(0.03, 0.01, 0.06, 0.62)
const PANEL := Color(0.14, 0.07, 0.19, 0.82)
const PANEL_HOVER := Color(0.26, 0.13, 0.31, 0.90)
const PANEL_PRESSED := Color(0.10, 0.05, 0.13, 0.95)
const BORDER := Color(0.55, 0.30, 0.57, 0.55)
const BORDER_ACTIVE := Color(1.00, 0.37, 0.70, 0.85)
const TEXT := Color("#F8EFFF")
const TEXT_MUTED := Color("#CDBBDD")
const TEXT_DISABLED := Color("#7B6A86")
const ACCENT := Color("#FF5FB3")
const ACCENT_2 := Color("#B45CFF")
const VALID := Color("#4DFF7A")
const INVALID := Color("#FF4D6D")
const XP := Color("#FF5FB3")
const GOAL := Color("#57F26D")

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


static func glass_box(radius: int = 22, border_width: int = 2, bg: Color = PANEL, border: Color = BORDER) -> StyleBoxFlat:
	var sb := StyleBoxFlat.new()
	sb.bg_color = bg
	sb.border_color = border
	sb.set_border_width_all(border_width)
	sb.set_corner_radius_all(radius)
	sb.shadow_color = Color(0, 0, 0, 0.35)
	sb.shadow_size = 8
	sb.shadow_offset = Vector2(0, 4)
	sb.content_margin_left = 18
	sb.content_margin_right = 18
	sb.content_margin_top = 12
	sb.content_margin_bottom = 12
	return sb


static func button_normal() -> StyleBoxFlat:
	return glass_box(22, 2, PANEL, BORDER)


static func button_hover() -> StyleBoxFlat:
	return glass_box(22, 2, PANEL_HOVER, BORDER_ACTIVE)


static func button_pressed() -> StyleBoxFlat:
	return glass_box(22, 2, PANEL_PRESSED, BORDER_ACTIVE)


static func button_disabled() -> StyleBoxFlat:
	return glass_box(22, 2, Color(0.10, 0.07, 0.13, 0.58), Color(0.35, 0.23, 0.39, 0.38))


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
	btn.add_theme_font_size_override("font_size", 22)
	if btn.custom_minimum_size.y < 68.0:
		btn.custom_minimum_size.y = 74
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
	var sb := glass_box(12, 1, PANEL, BORDER)
	sb.content_margin_left = 8
	sb.content_margin_right = 8
	sb.content_margin_top = 6
	sb.content_margin_bottom = 6
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
	var sb := glass_box(12 if compact else 14, 1, Color(0.157, 0.078, 0.216, 0.75), BORDER)
	var margin := 8 if compact else 10
	sb.content_margin_left = margin
	sb.content_margin_right = margin
	sb.content_margin_top = 6 if compact else 8
	sb.content_margin_bottom = 6 if compact else 8
	if compact:
		sb.shadow_size = 4
		sb.shadow_offset = Vector2(0, 2)
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
	check.add_theme_color_override("icon_normal_color", Color(0.45, 0.38, 0.52))
	check.add_theme_color_override("icon_hover_color", ACCENT_2)
	check.add_theme_color_override("icon_pressed_color", ACCENT)
	check.add_theme_color_override("icon_hover_pressed_color", ACCENT)
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
	glow.modulate = Color(1, 1, 1, 0.55)
	host.move_child(glow, 0)


static func _center_texture_rect(rect: TextureRect, size: Vector2) -> void:
	rect.set_anchors_preset(Control.PRESET_CENTER)
	rect.offset_left = -size.x * 0.5
	rect.offset_top = -size.y * 0.5
	rect.offset_right = size.x * 0.5
	rect.offset_bottom = size.y * 0.5
	rect.custom_minimum_size = size


static func set_background(root: Control, bg_path: String, dim_alpha: float = 0.62) -> void:
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
	dim.color = Color(0.03, 0.01, 0.06, dim_alpha)
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