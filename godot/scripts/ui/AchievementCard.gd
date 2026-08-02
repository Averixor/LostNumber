extends Control
class_name AchievementCard

const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")

@onready var status_label: Label = get_node_or_null("Panel/HBox/Status") as Label
@onready var name_label: Label = get_node_or_null("Panel/HBox/Name") as Label
@onready var progress_label: Label = get_node_or_null("Panel/HBox/Progress") as Label
@onready var panel: PanelContainer = get_node_or_null("Panel") as PanelContainer


func _resolve_nodes() -> void:
	if status_label == null:
		status_label = get_node_or_null("Panel/HBox/Status") as Label
	if name_label == null:
		name_label = get_node_or_null("Panel/HBox/Name") as Label
	if progress_label == null:
		progress_label = get_node_or_null("Panel/HBox/Progress") as Label
	if panel == null:
		panel = get_node_or_null("Panel") as PanelContainer


func _theme_manager() -> Node:
	return get_node_or_null("/root/ThemeManager")


func _base_panel_style(theme: Node) -> StyleBox:
	if theme != null and theme.has_method("get_visual_style"):
		return theme.call("get_visual_style", &"panel") as StyleBox
	return null


func setup(arg0 = null, arg1 = "", arg2 = 0, arg3 = 1, arg4 = "✓", arg5 = "○") -> void:
	_resolve_nodes()
	if status_label == null or name_label == null or progress_label == null or panel == null:
		return

	var unlocked := false
	var name_text := ""
	var progress := 0
	var max_val := 1
	var status_unlocked := "✓"
	var status_locked := "○"

	if arg0 is Dictionary:
		var data: Dictionary = arg0
		unlocked = bool(data.get("unlocked", false))
		name_text = str(data.get("name", data.get("title", "")))
		progress = int(data.get("progress", 0))
		max_val = int(data.get("max", 1))
		status_unlocked = str(data.get("status_unlocked", "✓"))
		status_locked = str(data.get("status_locked", "○"))
	else:
		unlocked = bool(arg0)
		name_text = str(arg1)
		progress = int(arg2)
		max_val = int(arg3)
		status_unlocked = str(arg4)
		status_locked = str(arg5)

	status_label.text = status_unlocked if unlocked else status_locked
	name_label.text = name_text
	progress_label.text = "%d / %d" % [progress, max_val]

	var theme := _theme_manager()
	var palette := GothicVisualsLib.resolve_palette(theme)
	panel.add_theme_stylebox_override(
		"panel",
		GothicVisualsLib.card_panel(palette, unlocked, _base_panel_style(theme))
	)

	var success: Color = palette.get("success", Color("#4A9152"))
	status_label.add_theme_color_override(
		"font_color",
		success.lightened(0.16) if unlocked else GothicVisualsLib.TEXT_MUTED
	)
	name_label.add_theme_color_override("font_color", GothicVisualsLib.TEXT_IVORY)
	progress_label.add_theme_color_override(
		"font_color",
		GothicVisualsLib.GOLD_LIGHT if unlocked else GothicVisualsLib.TEXT_MUTED
	)
