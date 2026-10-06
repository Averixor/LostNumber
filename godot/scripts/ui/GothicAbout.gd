extends "res://scripts/ui/About.gd"
class_name GothicAbout

## Gothic Crystal presentation for About — stone/gold chrome, shared backdrop rules.

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const GOTHIC_VISUAL_SKIN_ID := "gothic_crystal"


func _ready() -> void:
	GothicScreenMixinLib.ensure_default_visual_skin(self, GOTHIC_VISUAL_SKIN_ID)
	super._ready()
	_apply_gothic_visuals()
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	if not GothicScreenMixinLib.uses_gothic_chrome(self):
		return
	GothicScreenMixinLib.apply_background(self, "", 0.30, &"menu")
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
		title_label.add_theme_font_size_override("font_size", 26)
	if body != null:
		body.add_theme_color_override("default_color", GothicVisualsLib.TEXT_IVORY)
		body.add_theme_color_override("font_shadow_color", Color(GothicVisualsLib.STONE_BLACK, 0.55))
	GothicScreenMixinLib.style_button(self, back_button)
	if back_button != null:
		back_button.custom_minimum_size = Vector2(180, 48)
		back_button.icon = null
