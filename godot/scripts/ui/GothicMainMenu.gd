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
	# Dock and quick-row buttons use stone-framed gothic chrome (same chrome/size).
	for button in [quick_daily, quick_achievements, quick_about]:
		GothicScreenMixinLib.style_button(self, button)
	for button in [dock_premium, dock_tournaments, dock_bonuses, dock_stats]:
		GothicScreenMixinLib.style_button(self, button)
	_refresh_cta_styles()

	tagline_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	version_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)


func _refresh_cta_styles() -> void:
	for button in [play_button, continue_button, wheel_button, settings_button, exit_button]:
		if button == null:
			continue
		button.variant = "primary"
		if button.has_method("set_gothic_cta"):
			button.call("set_gothic_cta", true)
