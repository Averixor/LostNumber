extends "res://scripts/ui/GameHud.gd"

## Gothic Crystal presentation for the existing GameHud logic.
## The base HUD keeps ownership of signals, localization and gameplay updates.

const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")


func _theme_palette() -> Dictionary:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		return theme.call("get_palette")
	return {}


func _apply_styles() -> void:
	var palette := _theme_palette()
	var rim: Color = palette.get("rim", GothicVisualsLib.GOLD)
	var crystal: Color = palette.get("crystal", GothicVisualsLib.CRYSTAL)
	var hud_font := ThemeTokensLib.FONT_SIZE_HUD

	chain_sum_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_CHAIN_BUBBLE)
	message_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	message_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)

	goal_label.add_theme_font_size_override("font_size", hud_font)
	goal_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	goal_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	xp_label.add_theme_font_size_override("font_size", hud_font)
	xp_label.add_theme_color_override("font_color", GothicVisualsLib.CRYSTAL_LIGHT)
	xp_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	chain_sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", hud_font)
	level_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	level_label.add_theme_constant_override("outline_size", 2)
	level_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.78))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var panel_style := GothicVisualsLib.hud_panel(palette)
	$GoalRow/GoalPanel.add_theme_stylebox_override("panel", panel_style)
	$XpRow/XpPanel.add_theme_stylebox_override("panel", panel_style.duplicate())
	bottom_strip.add_theme_stylebox_override("panel", panel_style.duplicate())

	if _goal_track != null:
		_goal_track.color = Color(GothicVisualsLib.STONE_BLACK, 0.88)
	if _goal_fill != null:
		_goal_fill.color = Color(rim.lightened(0.16), 1.0)
	if _xp_track != null:
		_xp_track.color = Color(GothicVisualsLib.STONE_BLACK, 0.88)
	if _xp_fill != null:
		_xp_fill.color = Color(crystal.lightened(0.14), 1.0)

	_style_icon_buttons()


func _style_badge(badge: Label, count: int) -> void:
	badge.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_XS)
	badge.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GothicVisualsLib.CRYSTAL, 0.92) if count > 0 else Color(GothicVisualsLib.STONE_BLACK, 0.88)
	style.border_color = Color(GothicVisualsLib.GOLD, 0.82)
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.set_content_margin_all(2)
	badge.add_theme_stylebox_override("normal", style)


func _style_icon_buttons() -> void:
	var palette := _theme_palette()
	for btn in [menu_button, save_button, sound_button, theme_button]:
		btn.custom_minimum_size = Vector2(
			float(ThemeTokensLib.TOUCH_TARGET_MIN),
			float(ThemeTokensLib.TOUCH_TARGET_MIN)
		)
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_constant_override("icon_max_width", 26)
		btn.add_theme_constant_override("icon_max_height", 26)
		btn.add_theme_color_override("icon_normal_color", GothicVisualsLib.GOLD_LIGHT)
		btn.add_theme_color_override("icon_hover_color", GothicVisualsLib.CRYSTAL_LIGHT)
		btn.add_theme_color_override("icon_pressed_color", GothicVisualsLib.GOLD)
		btn.add_theme_stylebox_override("normal", GothicVisualsLib.icon_button(palette, "normal"))
		btn.add_theme_stylebox_override("hover", GothicVisualsLib.icon_button(palette, "hover"))
		btn.add_theme_stylebox_override("pressed", GothicVisualsLib.icon_button(palette, "pressed"))
		btn.add_theme_stylebox_override("focus", GothicVisualsLib.icon_button(palette, "hover"))


func _style_bonus_button(button: Button, kind: String, count: int, active_bonus: String) -> void:
	var active := active_bonus == kind
	var available := count > 0
	button.disabled = not available and not active

	var normal := GothicVisualsLib.booster_button(_theme_palette(), active, available)
	var hover := normal.duplicate()
	var pressed := normal.duplicate()
	var disabled := GothicVisualsLib.booster_button(_theme_palette(), false, false)
	hover.bg_color = hover.bg_color.lightened(0.07)
	hover.shadow_size += 3
	pressed.bg_color = pressed.bg_color.darkened(0.10)

	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", normal.duplicate() if active else StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY if available or active else GothicVisualsLib.TEXT_MUTED)
	button.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	button.modulate = Color.WHITE
	_apply_bonus_wheel_icon(button, kind)


func update_chain_sum(state: GameState, can_finish: bool, dragging: bool = false) -> void:
	super.update_chain_sum(state, can_finish, dragging)
	if not bottom_strip.visible:
		return
	var valid := can_finish and state != null and state.selected_path.size() >= 2
	var style := GothicVisualsLib.hud_panel(_theme_palette())
	style.border_color = GothicVisualsLib.GOLD_LIGHT if valid else GothicVisualsLib.CRYSTAL_LIGHT
	style.shadow_color = Color(style.border_color, 0.32)
	style.shadow_size = 12
	bottom_strip.add_theme_stylebox_override("panel", style)
	chain_sum_label.add_theme_color_override(
		"font_color",
		GothicVisualsLib.GOLD_LIGHT if valid else GothicVisualsLib.CRYSTAL_LIGHT
	)
