extends "res://scripts/game/Game.gd"

## Gothic Crystal presentation for the current Game scene.
## Gameplay state, saves, navigation and localization remain in Game.gd.

const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")


func _apply_theme() -> void:
	GothicScreenMixinLib.apply_background(self, "", 0.28, &"game")
	if background != null:
		background.color = Color.TRANSPARENT
		background.visible = false
	# Keep modal overlays styled; visibility is owned by Game._ready / pause handlers.
	_style_pause_overlay()
	_style_level_complete_overlay()


func _style_pause_overlay() -> void:
	var palette := _theme_palette()
	var rim: Color = palette.get("rim", GothicVisualsLib.GOLD)
	var crystal: Color = palette.get("crystal", GothicVisualsLib.CRYSTAL)

	# Full-screen scrim only (transparent to content until pause is shown).
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.72)
	scrim.set_content_margin_all(0)
	pause_overlay.add_theme_stylebox_override("panel", scrim)

	var modal_style := StyleBoxFlat.new()
	modal_style.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.95)
	modal_style.border_color = Color(rim, 0.74)
	modal_style.set_border_width_all(2)
	modal_style.set_corner_radius_all(12)
	modal_style.set_content_margin_all(20)
	modal_style.shadow_color = Color(crystal, 0.28)
	modal_style.shadow_size = 18
	pause_modal.add_theme_stylebox_override("panel", modal_style)

	pause_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE + 4)
	pause_title.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	pause_title.add_theme_constant_override("outline_size", 2)
	pause_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	pause_title.text = _i18n("pause_title")
	resume_button.text = _i18n("btn_resume")
	pause_menu_button.text = _i18n("hud_menu")
	_style_action_button(resume_button, true)
	_style_action_button(pause_menu_button, false)


func _style_level_complete_overlay() -> void:
	if level_complete_panel == null or continue_button == null or overlay_title == null:
		return
	var palette := _theme_palette()
	# Dim the playfield; put the solid gothic card on ModalFrame only.
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.72)
	scrim.set_content_margin_all(0)
	level_complete_panel.add_theme_stylebox_override("panel", scrim)
	var card := GothicVisualsLib.hud_panel(palette)
	card.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.96)
	card.set_content_margin_all(24)
	card.shadow_size = 20
	level_complete_modal.add_theme_stylebox_override("panel", card)
	overlay_title.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	overlay_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE + 4)
	overlay_title.add_theme_constant_override("outline_size", 2)
	overlay_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	_style_action_button(continue_button, true)


func _style_action_button(button: Button, primary: bool) -> void:
	var palette := _theme_palette()
	var normal := GothicVisualsLib.booster_button(palette, primary, true)
	var hover := normal.duplicate()
	var pressed := normal.duplicate()
	hover.bg_color = hover.bg_color.lightened(0.08)
	hover.shadow_size += 3
	pressed.bg_color = pressed.bg_color.darkened(0.10)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("focus", hover.duplicate())
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)


func _theme_palette() -> Dictionary:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		return theme.call("get_palette")
	return {}
