extends "res://scripts/ui/MainMenu.gd"
class_name GothicMainMenu

const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")
const GOTHIC_VISUAL_SKIN_ID := "gothic_crystal"


func _ready() -> void:
	GothicScreenMixinLib.ensure_default_visual_skin(self, GOTHIC_VISUAL_SKIN_ID)
	super._ready()
	_apply_gothic_visuals()
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_apply_gothic_visuals)


func _apply_gothic_visuals() -> void:
	if not GothicScreenMixinLib.uses_gothic_chrome(self):
		return
	GothicScreenMixinLib.apply_background(self, "", 0.28, &"menu")
	# Pedestal dock uses stone-framed gothic chrome (same chrome/size).
	for button in _dock_buttons():
		GothicScreenMixinLib.style_button(self, button)
		if button.has_method("refresh_enabled_visual"):
			button.call("refresh_enabled_visual")
	_refresh_cta_styles()
	_hide_top_exit()
	_refresh_logo_visibility()
	_apply_title_style()


func _refresh_cta_styles() -> void:
	if not GothicScreenMixinLib.uses_gothic_chrome(self):
		return
	for button in [play_button, continue_button]:
		if button == null or not button.visible:
			continue
		if button.has_method("set_gothic_cta"):
			button.call("set_gothic_cta", true)


func _hide_top_exit() -> void:
	## Exit is a dock pedestal item; keep the legacy top-right control hidden.
	if exit_button != null:
		exit_button.visible = false
		exit_button.disabled = true
	var top_bar := get_node_or_null("Layout/RootVBox/TopBar") as CanvasItem
	if top_bar != null:
		top_bar.visible = false
