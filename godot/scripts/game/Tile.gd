extends Control
class_name TileView

@export var cell_size: Vector2 = Vector2(72, 72)

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0

var _label: Label
var _bg: ColorRect
var _chain_highlight: ColorRect


func _ready() -> void:
	_ensure_ui()


func _ensure_ui() -> void:
	if _label != null and _bg != null and _chain_highlight != null:
		return

	custom_minimum_size = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE

	_bg = ColorRect.new()
	_bg.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_bg.set_anchors_preset(Control.PRESET_FULL_RECT)
	_bg.color = Color(0.18, 0.2, 0.28, 1.0)
	add_child(_bg)

	_chain_highlight = ColorRect.new()
	_chain_highlight.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_chain_highlight.set_anchors_preset(Control.PRESET_FULL_RECT)
	_chain_highlight.color = Color(0.35, 0.55, 0.95, 0.45)
	_chain_highlight.visible = false
	add_child(_chain_highlight)

	_label = Label.new()
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	_label.add_theme_font_size_override("font_size", 22)
	add_child(_label)


func setup(pos: Vector2i, number: int) -> void:
	_ensure_ui()
	grid_pos = pos
	set_value(number)


func set_value(number: int) -> void:
	_ensure_ui()
	value = number
	if number <= 0:
		_label.text = ""
		_bg.color = Color(0.12, 0.13, 0.18, 0.5)
	else:
		_label.text = str(number)
		_bg.color = _color_for_value(number)


func set_chain_selected(selected: bool, valid_finish: bool = true) -> void:
	_ensure_ui()
	_chain_highlight.visible = selected
	if selected:
		_chain_highlight.color = Color(0.3, 0.75, 0.45, 0.5) if valid_finish else Color(0.85, 0.35, 0.3, 0.5)


func set_target_highlight(active: bool) -> void:
	_ensure_ui()
	if active:
		_bg.color = Color(0.55, 0.42, 0.12, 1.0)


func _color_for_value(n: int) -> Color:
	var log_val := 0
	var t := n
	while t > 1:
		t /= 2
		log_val += 1
	var hue := fmod(log_val * 0.11, 1.0)
	return Color.from_hsv(hue, 0.45, 0.38)
