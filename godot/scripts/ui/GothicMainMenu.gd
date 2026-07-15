extends "res://scripts/ui/MainMenu.gd"
class_name GothicMainMenu

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const MENU_BACKDROP := "res://assets/ui/skins/gothic_crystal/game-backdrop.svg"


func _ready() -> void:
	super._ready()
	_apply_gothic_visuals()
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, MENU_BACKDROP, 0.28)
	for button in [play_button, continue_button, wheel_button, exit_button]:
		GothicScreenMixinLib.style_button(self, button)
	for button in [quick_settings, quick_stats, quick_about]:
		GothicScreenMixinLib.style_button(self, button)
	for button in [dock_premium, dock_tournaments, dock_achievements, dock_daily, dock_bonuses]:
		GothicScreenMixinLib.style_button(self, button)

	tagline_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	version_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_MUTED)
