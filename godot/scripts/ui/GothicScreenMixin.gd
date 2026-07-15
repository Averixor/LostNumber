extends Node

## Mixin for applying gothic crystal visuals to full‑screen UI scenes.
## Usage: `class_name GothicScreenMixin` in a script, then `extends GothicScreenMixin` *plus* `extends` of logic script via multiple inheritance (GDScript supports only single extends, so we use `load()` trick or composition).

func _apply_gothic_background(screen_id: String) -> void:
	var bg_path := "res://assets/ui/skins/gothic_crystal/%s-backdrop.svg" % screen_id
	LnUiLib.set_background(self, bg_path, 0.34)

func _style_glass_panel(panel: PanelContainer) -> void:
	if panel == null:
		return
	var palette := {}
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		palette = theme.call("get_palette")
	panel.add_theme_stylebox_override("panel", GothicVisuals.hud_panel(palette))
