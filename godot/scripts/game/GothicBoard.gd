extends "res://scripts/game/Board.gd"

## Decorative board shell for the Gothic Crystal vertical slice.
## Core grid construction and input stay in Board.gd.

const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")

var _gothic_frame: PanelContainer


func _ready() -> void:
	super._ready()
	_ensure_gothic_frame()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_style_gothic_frame)


func _ensure_gothic_frame() -> void:
	_gothic_frame = get_node_or_null("GothicBoardFrame") as PanelContainer
	if _gothic_frame == null:
		_gothic_frame = PanelContainer.new()
		_gothic_frame.name = "GothicBoardFrame"
		_gothic_frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
		# Keep the frame in the board's canvas layer; child order places it behind tiles.
		_gothic_frame.z_index = 0
		add_child(_gothic_frame)
		move_child(_gothic_frame, 0)

	_gothic_frame.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_gothic_frame.offset_left = -10.0
	_gothic_frame.offset_top = -10.0
	_gothic_frame.offset_right = 10.0
	_gothic_frame.offset_bottom = 10.0
	_style_gothic_frame()


func _style_gothic_frame() -> void:
	if _gothic_frame == null:
		return

	var palette: Dictionary = {}
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		palette = theme.call("get_palette")

	var rim: Color = palette.get("rim", GothicVisualsLib.GOLD)
	var crystal: Color = palette.get("crystal", GothicVisualsLib.CRYSTAL)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(GothicVisualsLib.STONE_BLACK, 0.94)
	style.border_color = Color(rim, 0.84)
	style.set_border_width_all(3)
	style.set_corner_radius_all(12)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 8
	style.content_margin_bottom = 8
	style.shadow_color = Color(crystal, 0.24)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 5)
	_gothic_frame.add_theme_stylebox_override("panel", style)
