extends "res://scripts/ui/MainMenu.gd"
class_name GothicMainMenu

const GothicScreenMixin := preload("res://scripts/ui/GothicScreenMixin.gd")

var _mixin := GothicScreenMixin.new()

func _ready() -> void:
	_mixin._apply_gothic_background("menu")
	_style_buttons()
	super._ready()

func _style_buttons() -> void:
	for btn in [play_button, wheel_button, settings_button, stats_button, achievements_button]:
		btn.add_theme_stylebox_override("normal", GothicVisuals.icon_button({}, "normal"))
		btn.add_theme_stylebox_override("hover", GothicVisuals.icon_button({}, "hover"))
		btn.add_theme_stylebox_override("pressed", GothicVisuals.icon_button({}, "pressed"))
