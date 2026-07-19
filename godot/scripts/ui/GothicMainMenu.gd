extends "res://scripts/ui/MainMenu.gd"
class_name GothicMainMenu

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")


func _ready() -> void:
	super._ready()
	_apply_gothic_visuals()
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.28, &"menu")
	# Pedestal dock uses stone-framed gothic chrome (same chrome/size).
	for button in _dock_buttons():
		GothicScreenMixinLib.style_button(self, button)
	_refresh_cta_styles()

	tagline_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	version_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)


func _refresh_cta_styles() -> void:
	for button in [play_button, continue_button]:
		if button == null or not button.visible:
			continue
		if button.has_method("set_gothic_cta"):
			button.call("set_gothic_cta", true)
	if exit_button != null and exit_button.has_method("set_gothic_cta"):
		# Compact chrome control — not a primary CTA strip.
		exit_button.call("set_gothic_cta", false)
