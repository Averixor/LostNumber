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
	# Full-screen scrim only (transparent to content until pause is shown).
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.72)
	scrim.set_content_margin_all(0)
	pause_overlay.add_theme_stylebox_override("panel", scrim)

	GothicScreenMixinLib.style_modal(self, pause_modal)

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
	# Dim the playfield; put the solid gothic card on ModalFrame only.
	var scrim := StyleBoxFlat.new()
	scrim.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.72)
	scrim.set_content_margin_all(0)
	level_complete_panel.add_theme_stylebox_override("panel", scrim)
	GothicScreenMixinLib.style_modal(self, level_complete_modal)
	var card := level_complete_modal.get_theme_stylebox("panel")
	if card is StyleBoxFlat:
		var flat := (card as StyleBoxFlat).duplicate(true) as StyleBoxFlat
		flat.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.96)
		flat.set_content_margin_all(24)
		flat.shadow_size = 20
		level_complete_modal.add_theme_stylebox_override("panel", flat)
	overlay_title.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	overlay_title.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_TITLE + 4)
	overlay_title.add_theme_constant_override("outline_size", 2)
	overlay_title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.80))
	_style_action_button(continue_button, true)


func _style_action_button(button: Button, primary: bool) -> void:
	if primary:
		GothicScreenMixinLib.style_cta_button(self, button)
	else:
		GothicScreenMixinLib.style_button(self, button)
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	# Drop legacy neon/crystal button icons — text labels carry meaning.
	button.icon = null
	if primary:
		button.custom_minimum_size.y = maxf(button.custom_minimum_size.y, 52.0)
