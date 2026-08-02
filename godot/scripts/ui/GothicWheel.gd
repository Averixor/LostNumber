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


func _refresh_ui() -> void:
	super._refresh_ui()
	_apply_gothic_visuals()


func _style_action_buttons() -> void:
	_apply_gothic_visuals()


func _apply_gothic_visuals() -> void:
	if title_label == null:
		return
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	GothicScreenMixinLib.style_cta_button(self, spin_button)
	for button in [back_button, result_close]:
		GothicScreenMixinLib.style_button(self, button)
		if button != null:
			button.focus_mode = Control.FOCUS_NONE
	GothicScreenMixinLib.style_panel(self, result_card)
	title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	if cost_label != null:
		cost_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	if result_label != null:
		result_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	if spin_button != null:
		spin_button.custom_minimum_size = Vector2(240, 52)
		spin_button.add_theme_font_size_override("font_size", 17)
		spin_button.focus_mode = Control.FOCUS_NONE
	if back_button != null:
		back_button.custom_minimum_size = Vector2(220, 48)
	if wheel_canvas != null:
		wheel_canvas.custom_minimum_size = Vector2(320, 320)
