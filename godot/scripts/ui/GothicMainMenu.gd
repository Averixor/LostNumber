extends "res://scripts/ui/MainMenu.gd"
class_name GothicMainMenu

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GOTHIC_VISUAL_SKIN_ID := "gothic_crystal"


func _ready() -> void:
	_ensure_gothic_skin()
	super._ready()
	_apply_gothic_visuals()
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_gothic_visuals)


func _ensure_gothic_skin() -> void:
	## Existing installs may still carry the pre-foundation procedural_neon id.
	## The current release is Gothic-first; procedural neon remains an internal
	## fallback only when the Gothic resource cannot be loaded.
	var theme := get_node_or_null("/root/ThemeManager")
	if theme == null or not theme.has_method("set_visual_skin_id"):
		return
	if theme.has_method("uses_visual_skin") and bool(theme.call("uses_visual_skin")):
		return
	theme.call("set_visual_skin_id", GOTHIC_VISUAL_SKIN_ID)


func _apply_gothic_visuals() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.28, &"menu")
	# Pedestal dock uses stone-framed gothic chrome (same chrome/size).
	for button in _dock_buttons():
		GothicScreenMixinLib.style_button(self, button)
		if button.has_method("refresh_enabled_visual"):
			button.call("refresh_enabled_visual")
	_refresh_cta_styles()
	_refresh_exit_control()
	_refresh_logo_visibility()
	_apply_title_style()


func _refresh_cta_styles() -> void:
	for button in [play_button, continue_button]:
		if button == null or not button.visible:
			continue
		if button.has_method("set_gothic_cta"):
			button.call("set_gothic_cta", true)


func _refresh_exit_control() -> void:
	if exit_button == null:
		return
	# Readable labeled control — not a mystery corner speck.
	exit_button.text = _i18n("btn_exit")
	exit_button.tooltip_text = _i18n("btn_exit")
	exit_button.variant = "secondary"
	exit_button.icon = null
	exit_button.custom_minimum_size = Vector2(96, 44)
	exit_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	GothicScreenMixinLib.style_button(self, exit_button)
