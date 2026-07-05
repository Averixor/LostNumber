extends Control
class_name DailyQuestCard

## Styled daily quest row card.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var status_icon: Label = $Panel/HBox/Status
@onready var text_label: Label = $Panel/HBox/Text
@onready var panel: PanelContainer = $Panel


func setup(done: bool, text: String, completed_label: String = "") -> void:
	text_label.text = text
	status_icon.text = "✓" if done else "○"
	status_icon.modulate = Color(0.4, 0.9, 0.5) if done else Color(ThemeTokensLib.COLOR_MUTED)
	if done and not completed_label.is_empty():
		text_label.text = "%s — %s" % [text, completed_label]

	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokensLib.COLOR_PANEL
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_HUD)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER if not done else Color(ThemeTokensLib.COLOR_PRIMARY, 0.4)
	style.set_content_margin_all(10)
	panel.add_theme_stylebox_override("panel", style)
