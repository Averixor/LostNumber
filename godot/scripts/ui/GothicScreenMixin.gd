extends RefCounted
class_name GothicScreenMixin

## Shared Gothic Crystal presentation helpers.
## Resource paths are case-sensitive and must match repository filenames exactly.

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const DEFAULT_BACKDROP := "res://assets/ui/skins/gothic_crystal/game-backdrop.png"


static func apply_background(
	host: Control,
	backdrop_path: String = "",
	dim_alpha: float = 0.34,
	screen_kind: StringName = &"menu"
) -> void:
	if host == null:
		return
	var resolved_path := backdrop_path
	if resolved_path.is_empty():
		var theme := host.get_node_or_null("/root/ThemeManager")
		if theme != null and theme.has_method("get_visual_background_path"):
			resolved_path = str(theme.call("get_visual_background_path", screen_kind))
	if resolved_path.is_empty() or not ResourceLoader.exists(resolved_path):
		resolved_path = DEFAULT_BACKDROP
	if ResourceLoader.exists(resolved_path):
		LnUiLib.set_background(host, resolved_path, dim_alpha)


static func palette(host: Node) -> Dictionary:
	if host == null:
		return {}
	var theme := host.get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		return theme.call("get_palette")
	return {}


static func style_panel(host: Node, panel: PanelContainer) -> void:
	if panel == null:
		return
	panel.add_theme_stylebox_override("panel", GothicVisualsLib.hud_panel(palette(host)))


static func style_button(host: Node, button: Button) -> void:
	if button == null:
		return
	var colors := palette(host)
	button.add_theme_stylebox_override("normal", GothicVisualsLib.icon_button(colors, "normal"))
	button.add_theme_stylebox_override("hover", GothicVisualsLib.icon_button(colors, "hover"))
	button.add_theme_stylebox_override("pressed", GothicVisualsLib.icon_button(colors, "pressed"))
	button.add_theme_stylebox_override("disabled", GothicVisualsLib.icon_button(colors, "disabled"))
	button.add_theme_stylebox_override("focus", GothicVisualsLib.icon_button(colors, "hover"))
	button.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_hover_color", GothicVisualsLib.GOLD_LIGHT)
	button.add_theme_color_override("font_pressed_color", GothicVisualsLib.TEXT_IVORY)
	button.add_theme_color_override("font_disabled_color", GothicVisualsLib.TEXT_MUTED)


static func style_subtree(host: Node, root: Node) -> void:
	if root == null:
		return
	if root is PanelContainer:
		style_panel(host, root as PanelContainer)
	elif root is Button:
		style_button(host, root as Button)
	elif root is Label:
		(root as Label).add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	for child in root.get_children():
		style_subtree(host, child)
