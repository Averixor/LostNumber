extends "res://scripts/ui/Wheel.gd"
class_name GothicWheel

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


func _refresh_ui() -> void:
	super._refresh_ui()
	_apply_gothic_visuals()


func _style_action_buttons() -> void:
	_apply_gothic_visuals()


func _apply_gothic_visuals() -> void:
	if title_label == null:
		return
	GothicScreenMixinLib.apply_background(self, "", 0.42, &"menu")
	_ensure_radial_vignette()
	GothicScreenMixinLib.style_cta_button(self, spin_button)
	for button in [back_button, result_close]:
		if button != null:
			button.icon = null
			button.expand_icon = false
		GothicScreenMixinLib.style_button(self, button)
		if button != null:
			button.focus_mode = Control.FOCUS_NONE
			button.icon = null
	GothicScreenMixinLib.style_panel(self, result_card)
	title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	_style_cost_pill_gothic()
	if result_label != null:
		result_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	if spin_button != null:
		spin_button.icon = null
		spin_button.custom_minimum_size = Vector2(260, 56)
		spin_button.add_theme_font_size_override("font_size", 18)
		spin_button.focus_mode = Control.FOCUS_NONE
		if spin_button.has_method("set_gothic_cta"):
			spin_button.call("set_gothic_cta", true)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(200, 44)
		back_button.add_theme_font_size_override("font_size", 15)
		back_button.icon = null
	if wheel_canvas != null:
		wheel_canvas.custom_minimum_size = Vector2(384, 384)
		wheel_canvas.queue_redraw()


func _style_cost_pill_gothic() -> void:
	if cost_pill == null or cost_label == null:
		return
	var border := Color(GothicVisualsLib.GOLD, 0.70)
	var fill := Color(GothicVisualsLib.STONE_DEEP, 0.90)
	var pill := LnUiLib.small_pill(fill, border)
	cost_pill.add_theme_stylebox_override("panel", pill)
	cost_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	cost_label.add_theme_font_size_override("font_size", 14)


func _ensure_radial_vignette() -> void:
	if vignette == null:
		return
	if vignette.texture != null:
		return
	var gradient := Gradient.new()
	gradient.offsets = PackedFloat32Array([0.0, 0.45, 1.0])
	gradient.colors = PackedColorArray([
		Color(0.02, 0.01, 0.06, 0.38),
		Color(0.02, 0.01, 0.05, 0.22),
		Color(0.0, 0.0, 0.0, 0.50),
	])
	var tex := GradientTexture2D.new()
	tex.gradient = gradient
	tex.fill = GradientTexture2D.FILL_RADIAL
	tex.fill_from = Vector2(0.5, 0.42)
	tex.fill_to = Vector2(0.95, 0.95)
	tex.width = 256
	tex.height = 256
	vignette.texture = tex
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
