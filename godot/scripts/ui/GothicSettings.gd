extends "res://scripts/ui/Settings.gd"
class_name GothicSettings

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const GOTHIC_VISUAL_SKIN_ID := "gothic_crystal"


func _ready() -> void:
	GothicScreenMixinLib.ensure_default_visual_skin(self, GOTHIC_VISUAL_SKIN_ID)
	super._ready()
	_apply_gothic_visuals()
	call_deferred("_apply_gothic_visuals")
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_gothic_visuals)


func _style_controls() -> void:
	if not GothicScreenMixinLib.uses_gothic_chrome(self):
		super._style_controls()
		return
	## Own gothic chrome — do not call LnUi neon apply_button / toggle / option styles.
	if background != null:
		background.color = Color(0, 0, 0, 0.55)
	_apply_gothic_control_chrome()
	_apply_unified_font()


func _apply_gothic_visuals() -> void:
	if not GothicScreenMixinLib.uses_gothic_chrome(self):
		## Skin Preview switched to procedural_neon — restore base Settings chrome.
		super._style_controls()
		LnUiLib.set_background(self, LnUiLib.screen_bg("settings"))
		return
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

	for slider in [sfx_volume_slider, music_volume_slider]:
		_style_volume_slider(slider)

	for option in [music_track_option, tile_font_size_option, language_option]:
		GothicScreenMixinLib.style_settings_option(self, option, false)


func _style_volume_slider(slider: HSlider) -> void:
	if slider == null:
		return
	var colors := GothicVisualsLib.resolve_palette(get_node_or_null("/root/ThemeManager"))
	var rim: Color = colors.get("rim", GothicVisualsLib.GOLD)
	var track := StyleBoxFlat.new()
	track.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.88)
	track.border_color = Color(rim, 0.55)
	track.set_border_width_all(1)
	track.set_corner_radius_all(6)
	track.content_margin_top = 10
	track.content_margin_bottom = 10
	track.content_margin_left = 4
	track.content_margin_right = 4
	var fill := StyleBoxFlat.new()
	fill.bg_color = Color(rim.lerp(GothicVisualsLib.BRONZE, 0.25), 0.92)
	fill.set_corner_radius_all(6)
	fill.content_margin_top = 10
	fill.content_margin_bottom = 10
	var fill_hi := fill.duplicate(true) as StyleBoxFlat
	fill_hi.bg_color = Color(GothicVisualsLib.GOLD_LIGHT.lerp(rim, 0.35), 0.95)
	slider.custom_minimum_size.y = maxf(slider.custom_minimum_size.y, 48.0)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.add_theme_constant_override("center_grabber", 1)
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", fill)
	slider.add_theme_stylebox_override("grabber_area_highlight", fill_hi)
	var grabber: Texture2D = _slider_grabber_texture(rim)
	var grabber_hi: Texture2D = _slider_grabber_texture(GothicVisualsLib.GOLD_LIGHT)
	slider.add_theme_icon_override("grabber", grabber)
	slider.add_theme_icon_override("grabber_highlight", grabber_hi)
	slider.add_theme_icon_override("grabber_disabled", grabber)


func _slider_grabber_texture(fill: Color, grabber_px: int = 28) -> Texture2D:
	var img := Image.create(grabber_px, grabber_px, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center := Vector2(grabber_px * 0.5, grabber_px * 0.5)
	var outer_r := grabber_px * 0.5 - 1.0
	var rim_r := outer_r - 2.0
	var core_r := outer_r * 0.45
	for y in grabber_px:
		for x in grabber_px:
			var d := Vector2(x + 0.5, y + 0.5).distance_to(center)
			if d > outer_r:
				continue
			if d >= rim_r:
				img.set_pixel(x, y, Color(GothicVisualsLib.STONE_BLACK, 0.95))
			elif d <= core_r:
				img.set_pixel(x, y, Color(fill.lightened(0.18), 1.0))
			else:
				var t := clampf((d - core_r) / maxf(0.001, rim_r - core_r), 0.0, 1.0)
				img.set_pixel(x, y, Color(fill.lerp(GothicVisualsLib.BRONZE, t * 0.35), 1.0))
	return ImageTexture.create_from_image(img)


func _style_labels() -> void:
	if vbox == null:
		return
	_style_labels_under(vbox)


func _style_labels_under(root: Node) -> void:
	for child in root.get_children():
		if child is Label:
			var label := child as Label
			var muted := label == import_status or label == gallery_status or label == account_status
			label.add_theme_color_override(
				"font_color",
				GothicVisualsLib.TEXT_MUTED if muted else GothicVisualsLib.TEXT_IVORY
			)
		_style_labels_under(child)


func _suppress_stray_scroll_chrome() -> void:
	if scroll == null:
		return
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	var horizontal := scroll.get_h_scroll_bar()
	if horizontal != null:
		horizontal.visible = false
		horizontal.mouse_filter = Control.MOUSE_FILTER_IGNORE
