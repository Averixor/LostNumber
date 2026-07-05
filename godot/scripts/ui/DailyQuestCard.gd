extends Control
class_name DailyQuestCard

## Gothic daily quest card with progress and reward.

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var status_icon: Label = $Panel/HBox/Content/Header/Status
@onready var text_label: Label = $Panel/HBox/Content/Header/Title
@onready var progress_label: Label = $Panel/HBox/Content/Progress
@onready var reward_label: Label = $Panel/HBox/Reward
@onready var panel: PanelContainer = $Panel


func setup(done: bool, text: String, progress_text: String, reward_text: String, status_text: String = "") -> void:
	text_label.text = text
	progress_label.text = progress_text
	reward_label.text = reward_text
	status_icon.text = "✓" if done else "○"
	status_icon.add_theme_color_override("font_color", LnUiLib.VALID if done else LnUiLib.TEXT_DISABLED)
	if done and not status_text.is_empty():
		reward_label.text = status_text
		reward_label.add_theme_color_override("font_color", LnUiLib.TEXT_DISABLED)

	panel.add_theme_stylebox_override("panel", LnUiLib.glass_box(14, 1,
		Color(0.157, 0.078, 0.216, 0.78 if not done else 0.62),
		LnUiLib.BORDER_ACTIVE if done else LnUiLib.BORDER))
	text_label.add_theme_color_override("font_color", LnUiLib.TEXT)
	progress_label.add_theme_color_override("font_color", LnUiLib.TEXT_MUTED)
	reward_label.add_theme_color_override("font_color", LnUiLib.ACCENT if not done else LnUiLib.TEXT_DISABLED)
	text_label.add_theme_font_size_override("font_size", 18)
	progress_label.add_theme_font_size_override("font_size", 14)
	reward_label.add_theme_font_size_override("font_size", 14)
