extends Control
class_name DailyQuestCard

## Gothic daily quest card with progress and reward.

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const MIN_HEIGHT_ACTIVE := 58
const MIN_HEIGHT_DONE := 48

@onready var status_icon: Label = $Panel/HBox/Content/Header/Status
@onready var text_label: Label = $Panel/HBox/Content/Header/Title
@onready var progress_label: Label = $Panel/HBox/Content/Progress
@onready var reward_label: Label = $Panel/HBox/Reward
@onready var panel: PanelContainer = $Panel


func setup(done: bool, text: String, progress_text: String, reward_text: String, status_text: String = "") -> void:
	# Resolve nodes at call time — setup may run before @onready when called pre add_child.
	var title := text_label if text_label != null else get_node_or_null("Panel/HBox/Content/Header/Title") as Label
	var progress := progress_label if progress_label != null else get_node_or_null("Panel/HBox/Content/Progress") as Label
	var reward := reward_label if reward_label != null else get_node_or_null("Panel/HBox/Reward") as Label
	var status := status_icon if status_icon != null else get_node_or_null("Panel/HBox/Content/Header/Status") as Label
	var card_panel := panel if panel != null else get_node_or_null("Panel") as PanelContainer
	if title == null or progress == null or reward == null or status == null or card_panel == null:
		return

	title.text = text
	progress.text = progress_text
	reward.text = reward_text
	status.text = "✓" if done else "○"
	status.add_theme_color_override("font_color", LnUiLib.VALID if done else LnUiLib.TEXT_DISABLED)

	progress.visible = not done
	if done and not status_text.is_empty():
		reward.text = status_text

	var panel_style := LnUiLib.glass_box(12, 1,
		Color(0.157, 0.078, 0.216, 0.78 if not done else 0.62),
		LnUiLib.BORDER_ACTIVE if done else LnUiLib.BORDER)
	panel_style.content_margin_left = 10
	panel_style.content_margin_right = 10
	panel_style.content_margin_top = 6 if done else 8
	panel_style.content_margin_bottom = 6 if done else 8
	card_panel.add_theme_stylebox_override("panel", panel_style)

	title.add_theme_color_override("font_color", LnUiLib.TEXT)
	progress.add_theme_color_override("font_color", LnUiLib.TEXT_MUTED)
	reward.add_theme_color_override("font_color", LnUiLib.ACCENT if not done else LnUiLib.TEXT_DISABLED)
	title.add_theme_font_size_override("font_size", 16 if done else 17)
	progress.add_theme_font_size_override("font_size", 13)
	reward.add_theme_font_size_override("font_size", 13 if not done else 12)

	custom_minimum_size.y = MIN_HEIGHT_DONE if done else MIN_HEIGHT_ACTIVE


func apply_layout(compact: bool) -> void:
	var done := not progress_label.visible
	var min_h := (MIN_HEIGHT_DONE if done else MIN_HEIGHT_ACTIVE) - 4 if compact else (MIN_HEIGHT_DONE if done else MIN_HEIGHT_ACTIVE)
	custom_minimum_size.y = min_h
	var title_size := 15 if compact else (16 if done else 17)
	text_label.add_theme_font_size_override("font_size", title_size)
	progress_label.add_theme_font_size_override("font_size", 12 if compact else 13)
	reward_label.add_theme_font_size_override("font_size", 12 if compact or done else 13)
