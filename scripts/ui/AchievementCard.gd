extends Control
class_name AchievementCard

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

	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.12, 0.07, 0.17, 0.84)
	style.set_corner_radius_all(12)
	style.set_border_width_all(1)
	style.border_color = Color(0.95, 0.25, 0.65, 0.55) if unlocked else Color(0.55, 0.35, 0.75, 0.35)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	status_label.modulate = Color(0.4, 0.95, 0.55, 1.0) if unlocked else Color(0.65, 0.58, 0.72, 1.0)
	name_label.add_theme_color_override("font_color", Color(0.95, 0.9, 1.0, 1.0))
	progress_label.add_theme_color_override("font_color", Color(0.75, 0.68, 0.82, 1.0))
