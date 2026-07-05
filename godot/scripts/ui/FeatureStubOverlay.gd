extends PanelContainer
class_name FeatureStubOverlay

## Web feature-stub dialog (premium / tournaments / bonuses).

signal closed

@onready var title_label: Label = $Margin/VBox/Title
@onready var body_label: RichTextLabel = $Margin/VBox/Body
@onready var ok_button: Button = $Margin/VBox/OkButton

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")


func _ready() -> void:
	visible = false
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokensLib.COLOR_OVERLAY_BG
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_OVERLAY)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(16)
	add_theme_stylebox_override("panel", style)
	ok_button.pressed.connect(_on_ok)


func show_stub(title: String, body: String, ok_text: String) -> void:
	title_label.text = title
	body_label.text = body
	ok_button.text = ok_text
	visible = true


func hide_stub() -> void:
	visible = false
	closed.emit()


func _on_ok() -> void:
	hide_stub()
