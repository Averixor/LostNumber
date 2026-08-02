extends "res://scripts/ui/Settings.gd"
class_name GothicSettings

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const GOTHIC_VISUAL_SKIN_ID := "gothic_crystal"


func _ready() -> void:
	_ensure_gothic_skin()
	super._ready()
	_apply_gothic_visuals()
	call_deferred("_apply_gothic_visuals")
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_gothic_visuals)


func _ensure_gothic_skin() -> void:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme == null or not theme.has_method("set_visual_skin_id"):
		return
	if theme.has_method("uses_visual_skin") and bool(theme.call("uses_visual_skin")):
		return
	theme.call("set_visual_skin_id", GOTHIC_VISUAL_SKIN_ID)


func _style_controls() -> void:
	## Keep base sizing/icon wiring, then replace every legacy neon override.
	super._style_controls()
	_apply_gothic_visuals()


func _save() -> void:
	## Settings are autosaved. Successful writes are intentionally silent;
	## a global "Saved" toast after every tap obscures the next screen.
	var settings = _settings()
	if settings != null and settings.has_method("save_settings"):
		settings.call("save_settings")


func _on_leaderboard_toggled(_enabled: bool) -> void:
	## The placeholder setting has no persisted backing field yet. Do not show a
	## false success toast for an action that currently changes nothing.
	pass


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	var colors := _palette()

	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	if import_status != null:
		import_status.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)

	for button in [back_button, theme_button, skin_pick_button, background_pick_button, import_button, exit_button]:
		if button != null:
			GothicScreenMixinLib.style_button(self, button)
			button.focus_mode = Control.FOCUS_NONE

	if back_button != null:
		back_button.custom_minimum_size = Vector2(180, 48)
	if exit_button != null:
		exit_button.custom_minimum_size.y = maxf(exit_button.custom_minimum_size.y, 48.0)

	for check in [sound_check, music_check, bg_effects_check, leaderboard_check, background_auto_check]:
		_style_check(check, colors)

	for option in [sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option]:
		_style_option(option, colors)

	_style_labels()
	_suppress_stray_scroll_chrome()


func _palette() -> Dictionary:
	return GothicVisualsLib.resolve_palette(get_node_or_null("/root/ThemeManager"))


func _row_style(colors: Dictionary, active: bool = false) -> StyleBoxFlat:
	var rim: Color = colors.get("rim", GothicVisualsLib.GOLD)
	var crystal: Color = colors.get("crystal", GothicVisualsLib.CRYSTAL)
	var style := GothicVisualsLib.hud_panel(colors)
	style.bg_color = Color(GothicVisualsLib.STONE_DEEP, 0.90)
	style.border_color = Color(rim, 0.78 if active else 0.48)
	style.set_border_width_all(2 if active else 1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 10
	style.content_margin_bottom = 10
	style.shadow_color = Color(crystal, 0.12 if active else 0.06)
	style.shadow_size = 6 if active else 3
	style.shadow_offset = Vector2(0, 2)
	return style


func _style_check(check: CheckButton, colors: Dictionary) -> void:
	if check == null:
		return
	var normal := _row_style(colors, false)
	var hover := _row_style(colors, true)
	var pressed := _row_style(colors, true)
	var disabled := _row_style(colors, false)
	disabled.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.55)
	disabled.border_color = Color(GothicVisualsLib.IRON, 0.45)

	check.add_theme_stylebox_override("normal", normal)
	check.add_theme_stylebox_override("hover", hover)
	check.add_theme_stylebox_override("pressed", pressed)
	check.add_theme_stylebox_override("hover_pressed", pressed.duplicate(true))
	check.add_theme_stylebox_override("disabled", disabled)
	check.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	check.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	check.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	check.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	check.add_theme_color_override("icon_normal_color", GothicVisualsLib.TEXT_MUTED)
	check.add_theme_color_override("icon_hover_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("icon_pressed_color", GothicVisualsLib.GOLD)
	check.add_theme_color_override("icon_hover_pressed_color", GothicVisualsLib.GOLD_LIGHT)
	check.add_theme_color_override("icon_disabled_color", GothicVisualsLib.TEXT_MUTED)
	check.focus_mode = Control.FOCUS_NONE
	check.custom_minimum_size.y = maxf(check.custom_minimum_size.y, 50.0)


func _style_option(option: OptionButton, colors: Dictionary) -> void:
	if option == null:
		return
	var normal := _row_style(colors, false)
	var hover := _row_style(colors, true)
	var pressed := _row_style(colors, true)
	var disabled := _row_style(colors, false)
	disabled.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.55)
	disabled.border_color = Color(GothicVisualsLib.IRON, 0.45)

	option.add_theme_stylebox_override("normal", normal)
	option.add_theme_stylebox_override("hover", hover)
	option.add_theme_stylebox_override("pressed", pressed)
	option.add_theme_stylebox_override("focus", hover.duplicate(true))
	option.add_theme_stylebox_override("disabled", disabled)
	option.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	option.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	option.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	option.add_theme_color_override("font_focus_color", GothicVisualsLib.GOLD_LIGHT)
	option.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)
	option.add_theme_color_override("icon_normal_color", GothicVisualsLib.GOLD)
	option.add_theme_color_override("icon_hover_color", GothicVisualsLib.GOLD_LIGHT)
	option.add_theme_color_override("icon_pressed_color", GothicVisualsLib.GOLD_LIGHT)
	option.focus_mode = Control.FOCUS_NONE
	option.custom_minimum_size.y = maxf(option.custom_minimum_size.y, 48.0)

	var popup := option.get_popup()
	if popup != null:
		popup.add_theme_stylebox_override("panel", _row_style(colors, false))
		popup.add_theme_stylebox_override("hover", _row_style(colors, true))
		popup.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
		popup.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
		popup.add_theme_color_override("font_separator_color", GothicVisualsLib.TEXT_MUTED)


func _style_labels() -> void:
	if vbox == null:
		return
	for child in vbox.get_children():
		if child is Label:
			var label := child as Label
			label.add_theme_color_override(
				"font_color",
				GothicVisualsLib.TEXT_MUTED if label == import_status else GothicVisualsLib.TEXT_IVORY
			)


func _suppress_stray_scroll_chrome() -> void:
	if scroll == null:
		return
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var horizontal := scroll.get_h_scroll_bar()
	if horizontal != null:
		horizontal.visible = false
		horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
