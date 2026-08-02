extends RefCounted
class_name GothicScreenMixin

## Shared Gothic Crystal presentation helpers.
## Resource paths are case-sensitive and must match repository filenames exactly.
## Prefer VisualSkin StyleBoxes when gothic_crystal is active; GothicVisuals is the
## procedural stone/gold fallback for the same chrome language (not Dark Neon).

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const DEFAULT_BACKDROP := "res://assets/ui/skins/gothic_crystal/game-backdrop.png"


static func apply_background(
	host: Control,
	backdrop_path: String = "",
	dim_alpha: float = 0.28,
	screen_kind: StringName = &"menu"
) -> void:
	if host == null:
		return
	var resolved_path := backdrop_path
	if resolved_path.is_empty():
		var theme := host.get_node_or_null("/root/ThemeManager")
		# Prefer user-selected / custom photo (Settings → Background) over fixed splash.
		if theme != null and theme.has_method("get_background_texture_path"):
			var selected := str(theme.call("get_background_texture_path", str(screen_kind)))
			if not selected.is_empty():
				if selected.begins_with("user://") and FileAccess.file_exists(selected):
					resolved_path = selected
				elif ResourceLoader.exists(selected):
					resolved_path = selected
		if resolved_path.is_empty() and theme != null and theme.has_method("get_visual_background_path"):
			resolved_path = str(theme.call("get_visual_background_path", screen_kind))
	if resolved_path.is_empty() or (
		not resolved_path.begins_with("user://") and not ResourceLoader.exists(resolved_path)
	) or (resolved_path.begins_with("user://") and not FileAccess.file_exists(resolved_path)):
		resolved_path = DEFAULT_BACKDROP
	if ResourceLoader.exists(resolved_path) or (
		resolved_path.begins_with("user://") and FileAccess.file_exists(resolved_path)
	):
		var use_skin := false
		var theme := host.get_node_or_null("/root/ThemeManager")
		if theme != null and theme.has_method("get_visual_skin"):
			use_skin = theme.call("get_visual_skin") != null
		LnUiLib.set_background(host, resolved_path, dim_alpha, use_skin)


static func palette(host: Node) -> Dictionary:
	if host == null:
		return GothicVisualsLib.resolve_palette(null)
	return GothicVisualsLib.resolve_palette(host.get_node_or_null("/root/ThemeManager"))


static func _visual_style(host: Node, kind: StringName) -> StyleBox:
	if host == null:
		return null
	var theme := host.get_node_or_null("/root/ThemeManager")
	if theme == null or not theme.has_method("get_visual_style"):
		return null
	return theme.call("get_visual_style", kind) as StyleBox


static func style_panel(host: Node, panel: PanelContainer) -> void:
	if panel == null:
		return
	var themed := _visual_style(host, &"panel")
	if themed == null:
		themed = _visual_style(host, &"hud")
	if themed != null:
		panel.add_theme_stylebox_override("panel", themed)
		return
	panel.add_theme_stylebox_override("panel", GothicVisualsLib.hud_panel(palette(host)))


static func style_modal(host: Node, panel: PanelContainer) -> void:
	if panel == null:
		return
	var themed := _visual_style(host, &"modal")
	if themed != null:
		panel.add_theme_stylebox_override("panel", themed)
		return
	var colors := palette(host)
	var rim: Color = colors.get("rim", GothicVisualsLib.GOLD)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.95)
	style.border_color = Color(rim, 0.74)
	style.set_border_width_all(2)
	style.set_corner_radius_all(12)
	style.set_content_margin_all(20)
	style.shadow_color = Color(GothicVisualsLib.STONE_BLACK, 0.55)
	style.shadow_size = 14
	panel.add_theme_stylebox_override("panel", style)


static func style_button(host: Node, button: Button) -> void:
	if button == null:
		return
	# Dock / NeonButton own their chrome; avoid neon→stone override races.
	if button is MenuDockButton:
		if button.has_method("_apply_style"):
			button.call("_apply_style")
		return
	if button is NeonButton:
		if button.has_method("_apply_styles"):
			button.call("_apply_styles")
		return
	var colors := palette(host)
	var normal := _visual_style(host, &"button_normal")
	var hover := _visual_style(host, &"button_hover")
	var pressed := _visual_style(host, &"button_pressed")
	var disabled := _visual_style(host, &"button_disabled")
	if normal == null:
		normal = GothicVisualsLib.icon_button(colors, "normal")
	if hover == null:
		hover = GothicVisualsLib.icon_button(colors, "hover")
	if pressed == null:
		pressed = GothicVisualsLib.icon_button(colors, "pressed")
	if disabled == null:
		disabled = GothicVisualsLib.icon_button(colors, "disabled")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover.duplicate(true) if hover != null else GothicVisualsLib.icon_button(colors, "hover"))
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)


static func style_cta_button(host: Node, button: Button) -> void:
	if button == null:
		return
	if button is NeonButton:
		if button.has_method("set_gothic_cta"):
			button.call("set_gothic_cta", true)
		elif button.has_method("_apply_styles"):
			button.call("_apply_styles")
		return
	var colors := palette(host)
	# Prefer kit button styles when filled; otherwise carved CTA from GothicVisuals.
	var normal := _visual_style(host, &"button_normal")
	var hover := _visual_style(host, &"button_hover")
	var pressed := _visual_style(host, &"button_pressed")
	var disabled := _visual_style(host, &"button_disabled")
	if normal == null:
		normal = GothicVisualsLib.cta_button(colors, "normal")
	if hover == null:
		hover = GothicVisualsLib.cta_button(colors, "hover")
	if pressed == null:
		pressed = GothicVisualsLib.cta_button(colors, "pressed")
	if disabled == null:
		disabled = GothicVisualsLib.cta_button(colors, "disabled")
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", hover.duplicate(true) if hover != null else GothicVisualsLib.cta_button(colors, "hover"))
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	button.add_theme_font_size_override("font_size", 16)


static func style_settings_toggle(host: Node, check: CheckButton, compact: bool = false) -> void:
	if check == null:
		return
	var colors := palette(host)
	var row := GothicVisualsLib.settings_row(colors, compact)
	var hover := row.duplicate(true) as StyleBoxFlat
	hover.bg_color = Color(GothicVisualsLib.STONE_MID.lightened(0.06), 0.94)
	hover.border_color = Color(colors.get("rim", GothicVisualsLib.GOLD), 0.88)
	var pressed := row.duplicate(true) as StyleBoxFlat
	pressed.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.92)
	check.custom_minimum_size = Vector2(0, 44.0 if compact else 52.0)
	check.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	check.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	check.add_theme_stylebox_override("normal", row)
	check.add_theme_stylebox_override("hover", hover)
	check.add_theme_stylebox_override("pressed", pressed)
	check.add_theme_stylebox_override("hover_pressed", pressed.duplicate(true))
	check.add_theme_stylebox_override("disabled", row.duplicate(true))
	check.add_theme_font_size_override("font_size", 15 if compact else 18)
	check.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	check.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	check.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	check.add_theme_constant_override("h_separation", 8 if compact else 12)
	check.add_theme_constant_override("icon_max_width", 22 if compact else 26)
	# Checkbox glyph: muted → gold (never neon pink/green accents).
	check.add_theme_color_override("icon_normal_color", GothicVisualsLib.TEXT_MUTED)
	check.add_theme_color_override("icon_hover_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("icon_pressed_color", GothicVisualsLib.GOLD)
	check.add_theme_color_override("icon_hover_pressed_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("icon_disabled_color", GothicVisualsLib.TEXT_MUTED)


static func style_settings_option(host: Node, option: OptionButton, compact: bool = false) -> void:
	if option == null:
		return
	var colors := palette(host)
	var row := GothicVisualsLib.settings_row(colors, compact)
	row.content_margin_left = 8 if compact else 10
	row.content_margin_right = 8 if compact else 10
	var hover := row.duplicate(true) as StyleBoxFlat
	hover.border_color = Color(colors.get("rim", GothicVisualsLib.GOLD), 0.90)
	option.custom_minimum_size.y = maxf(option.custom_minimum_size.y, 48.0)
	option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	option.add_theme_font_size_override("font_size", 14 if compact else 15)
	option.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	option.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	option.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	option.add_theme_color_override("font_focus_color", GothicVisualsLib.TEXT_IVORY)
	option.add_theme_stylebox_override("normal", row)
	option.add_theme_stylebox_override("hover", hover)
	option.add_theme_stylebox_override("pressed", row.duplicate(true))
	option.add_theme_stylebox_override("focus", hover.duplicate(true))


static func style_subtree(host: Node, root: Node) -> void:
	if root == null:
		return
	# Skip widgets that already own gothic chrome (avoids neon→gothic race).
	if root is NeonButton or root is MenuDockButton:
		pass
	elif root is PanelContainer:
		style_panel(host, root as PanelContainer)
	elif root is Button:
		style_button(host, root as Button)
	elif root is Label:
		(root as Label).add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	for child in root.get_children():
		style_subtree(host, child)
