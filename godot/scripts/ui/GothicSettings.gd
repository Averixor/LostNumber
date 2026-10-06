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
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_gothic_visuals)


func _ensure_gothic_skin() -> void:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr == null or not theme_mgr.has_method("set_visual_skin_id"):
		return
	if theme_mgr.has_method("uses_visual_skin") and bool(theme_mgr.call("uses_visual_skin")):
		return
	theme_mgr.call("set_visual_skin_id", GOTHIC_VISUAL_SKIN_ID)


func _style_controls() -> void:
	## Own gothic chrome — do not call LnUi neon apply_button / toggle / option styles.
	if background != null:
		background.color = Color(0, 0, 0, 0.55)
	_apply_gothic_control_chrome()
	_apply_unified_font()


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	_group_settings_into_panels()
	_apply_gothic_control_chrome()
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	if gallery_status != null:
		gallery_status.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	if import_status != null:
		import_status.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	if account_status != null:
		account_status.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	if account_label != null:
		account_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	_style_labels()
	_suppress_stray_scroll_chrome()


func _group_settings_into_panels() -> void:
	## Group loose rows into carved stone slabs (VISUAL_TARGET: integrated settings panels).
	if vbox == null or vbox.get_meta("gothic_grouped", false):
		return
	vbox.set_meta("gothic_grouped", true)
	var groups: Array = [
		[sound_check, music_check, sfx_volume_option, music_volume_option, music_track_option, bg_effects_check],
		[tile_font_size_option, language_option],
		[account_label, account_status, account_button, delete_account_button, leaderboard_check],
		[skin_label, skin_pick_button, background_label, background_pick_button, background_auto_check, gallery_pick_button, gallery_status],
		[import_button, import_status, exit_button],
	]
	var insert_at := 0
	for group in groups:
		var nodes: Array = []
		for node in group:
			if node != null and is_instance_valid(node) and node.get_parent() == vbox:
				nodes.append(node)
		if nodes.is_empty():
			continue
		var panel := PanelContainer.new()
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_theme_stylebox_override(
			"panel",
			GothicVisualsLib.hud_panel(GothicVisualsLib.resolve_palette(get_node_or_null("/root/ThemeManager")))
		)
		var inner := VBoxContainer.new()
		inner.add_theme_constant_override("separation", 8)
		inner.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		panel.add_child(inner)
		vbox.add_child(panel)
		vbox.move_child(panel, insert_at)
		insert_at += 1
		for node in nodes:
			var control := node as Control
			if control == null:
				continue
			vbox.remove_child(control)
			inner.add_child(control)
			control.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	# Theme cycle stays hidden; drop empty leftover if still a direct child.
	if theme_button != null and theme_button.get_parent() == vbox:
		theme_button.visible = false


func _apply_gothic_control_chrome() -> void:
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
		title_label.add_theme_font_size_override("font_size", 24)
		title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	for btn in [back_button, theme_button, skin_pick_button, background_pick_button, gallery_pick_button, import_button, exit_button, account_button, delete_account_button]:
		if btn == null:
			continue
		btn.icon = null
		GothicScreenMixinLib.style_button(self, btn)
		btn.focus_mode = Control.FOCUS_NONE

	if back_button != null:
		back_button.custom_minimum_size = Vector2(180, 48)
	if account_button != null:
		account_button.custom_minimum_size.y = maxf(account_button.custom_minimum_size.y, 48.0)
	if delete_account_button != null:
		delete_account_button.custom_minimum_size.y = maxf(delete_account_button.custom_minimum_size.y, 48.0)
	if gallery_pick_button != null:
		gallery_pick_button.custom_minimum_size.y = maxf(gallery_pick_button.custom_minimum_size.y, 48.0)
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
			var muted := label == import_status or label == gallery_status
			label.add_theme_color_override(
				"font_color",
				GothicVisualsLib.TEXT_MUTED if muted else GothicVisualsLib.TEXT_IVORY
			)


func _suppress_stray_scroll_chrome() -> void:
	if scroll == null:
		return
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var horizontal := scroll.get_h_scroll_bar()
	if horizontal != null:
		horizontal.visible = false
		horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
