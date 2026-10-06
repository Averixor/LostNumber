extends PanelContainer
class_name FeatureStubOverlay

## Feature-stub dialog (premium / tournaments / bonuses) — stone/gold modal chrome.

signal closed

@onready var title_label: Label = $Margin/VBox/Title
@onready var body_label: RichTextLabel = $Margin/VBox/Body
@onready var ok_button: Button = $Margin/VBox/OkButton

const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const GothicScreenMixinLib := preload("res://scripts/ui/GothicScreenMixin.gd")


func _ready() -> void:
	visible = false
	_apply_gothic_chrome()
	ok_button.pressed.connect(_on_ok)


func _apply_gothic_chrome() -> void:
	var palette := GothicVisualsLib.resolve_palette(get_node_or_null("/root/ThemeManager"))
	var rim: Color = palette.get("rim", GothicVisualsLib.GOLD)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.96)
	style.set_corner_radius_all(14)
	style.set_border_width_all(2)
	style.border_color = Color(rim, 0.78)
	style.set_content_margin_all(18)
	style.shadow_color = Color(GothicVisualsLib.STONE_BLACK, 0.55)
	style.shadow_size = 14
	add_theme_stylebox_override("panel", style)
	if title_label != null:
		title_label.add_theme_color_override("font_color", GothicVisualsLib.GOLD_LIGHT)
	if body_label != null:
		body_label.add_theme_color_override("default_color", GothicVisualsLib.TEXT_IVORY)
	GothicScreenMixinLib.style_cta_button(self, ok_button)


func show_stub(title: String, body: String, ok_text: String) -> void:
	_apply_gothic_chrome()
	title_label.text = title
	body_label.text = body
	ok_button.text = ok_text
	visible = true


func hide_stub() -> void:
	visible = false
	closed.emit()


func _on_ok() -> void:
	hide_stub()
