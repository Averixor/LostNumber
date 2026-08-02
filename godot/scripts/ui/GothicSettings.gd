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
	## Own gothic chrome — do not call LnUi neon apply_button / toggle / option styles.
	if background != null:
		background.color = Color(0, 0, 0, 0.55)
	_apply_gothic_control_chrome()
	_apply_unified_font()


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	_apply_gothic_control_chrome()
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	if import_status != null:
		import_status.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	_style_labels()
	_suppress_stray_scroll_chrome()


func _apply_gothic_control_chrome() -> void:
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for btn in [back_button, theme_button, skin_pick_button, background_pick_button, import_button, exit_button]:
		if btn == null:
			continue
		btn.icon = null
		GothicScreenMixinLib.style_button(self, btn)
		btn.focus_mode = Control.FOCUS_NONE

	if back_button != null:
		back_button.custom_minimum_size = Vector2(180, 48)
	if exit_button != null:
		exit_button.custom_minimum_size.y = maxf(exit_button.custom_minimum_size.y, 48.0)

	for check in [sound_check, music_check, bg_effects_check, leaderboard_check, background_auto_check]:
		GothicScreenMixinLib.style_settings_toggle(self, check, false)

	for option in [sfx_volume_option, music_volume_option, music_track_option, tile_font_size_option, language_option]:
		GothicScreenMixinLib.style_settings_option(self, option, false)


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
