extends Control
class_name AchievementCard

## Styled achievement row card.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var status_label: Label = $Panel/HBox/Status
@onready var name_label: Label = $Panel/HBox/Name
@onready var progress_label: Label = $Panel/HBox/Progress
@onready var panel: PanelContainer = $Panel


func setup(unlocked: bool, name_text: String, progress: int, max_val: int, status_unlocked: String, status_locked: String) -> void:
	status_label.text = status_unlocked if unlocked else status_locked
	name_label.text = name_text
	progress_label.text = "%d / %d" % [progress, max_val]

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokensLib.COLOR_PANEL
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_HUD)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER if not unlocked else Color(ThemeTokensLib.COLOR_PRIMARY, 0.5)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)

	status_label.modulate = Color(0.4, 0.9, 0.5) if unlocked else Color(ThemeTokensLib.COLOR_MUTED)
