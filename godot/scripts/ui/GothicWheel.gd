extends "res://scripts/ui/Wheel.gd"
class_name GothicWheel

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")


func _ready() -> void:
	super._ready()
	_apply_gothic_visuals()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self)
	for button in [spin_button, back_button, result_close]:
		GothicScreenMixinLib.style_button(self, button)
	GothicScreenMixinLib.style_panel(self, result_card)
	title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	cost_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
	result_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
