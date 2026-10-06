extends "res://scripts/ui/Achievements.gd"
class_name GothicAchievements

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")


func _ready() -> void:
	super._ready()
	_apply_gothic_visuals()
	call_deferred("_apply_gothic_visuals")
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	GothicScreenMixinLib.style_button(self, back_button)
	if back_button != null:
		back_button.icon = null
		back_button.custom_minimum_size = Vector2(180, 48)
	GothicScreenMixinLib.style_subtree(self, list)
