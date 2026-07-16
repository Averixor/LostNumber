extends Control
class_name TileView

## Themed grid cell with 2.5D bevel, shadow, chain glow, and press lift.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const GOTHIC_FACE_SHADER := preload("res://themes/skins/gothic_tile_face.gdshader")
const PRESS_LIFT := 3.0
const BEVEL_THICKNESS := 4.0
const SIDE_BEVEL := 3.5
const FACE_DARKEN := 0.30
const Z_FACE := 0
const Z_CROWN := 1
const Z_SELECTION := 2
const Z_LABEL := 3
## Carry crown: ~30% of tile height, centered in the top band above the digit.
const CROWN_SIZE_RATIO := 0.30
const CROWN_TOP_BAND_RATIO := 0.34
const CROWN_MIN_PX := 20.0
const CROWN_MAX_PX := 56.0
const CROWN_WATERMARK_ALPHA := 0.92
const CROWN_LABEL_PUSH_RATIO := 0.16

@export var cell_size: Vector2 = Vector2(72, 72)

@onready var _shadow: ColorRect = $Shadow
@onready var _bg: Control = $Bg
@onready var _inner: ColorRect = $Bg/Inner
@onready var _material_background: PanelContainer = $Bg/MaterialBackground
@onready var _top_edge: ColorRect = $Bg/TopEdge
@onready var _bottom_edge: ColorRect = $Bg/BottomEdge
@onready var _left_edge: ColorRect = $Bg/LeftEdge
@onready var _right_edge: ColorRect = $Bg/RightEdge
@onready var _crystal_overlay: Control = $Bg/CrystalOverlay
@onready var _label: Label = $Bg/Label
@onready var _chain_highlight: PanelContainer = $ChainHighlight
@onready var _chain_fill: ColorRect = $ChainHighlight/Fill
@onready var _carry_badge: Label = $CarryBadge

var _crown_icon: TextureRect
var _crystal_accents: Array[Polygon2D] = []
var _face_material: ShaderMaterial

var grid_pos: Vector2i = Vector2i.ZERO
var value: int = 0
var _base_position: Vector2 = Vector2.ZERO

var _selected: bool = false
var _chain_preview: String = ""
var _frozen: bool = false
var _bonus_mode: bool = false
var _carry: bool = false
var _target: bool = false
var _pressed: bool = false
var _lift_tween: Tween = null

func _ready() -> void:
	custom_minimum_size = cell_size
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_base_position = position
	_apply_bevelling()
	_ensure_crystal_accents()
	_ensure_crown_icon()
	_apply_panel_style()
	_apply_label_depth()
	_stack_chain_highlight_under_label()
	_chain_highlight.visible = false
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_refresh_visual)
	_refresh_visual()


func _ensure_crystal_accents() -> void:
	if not _crystal_accents.is_empty():
		return
	for index in 3:
		var crystal := Polygon2D.new()
		crystal.name = "Crystal%d" % (index + 1)
		crystal.polygon = PackedVector2Array([
			Vector2(0, -7), Vector2(4, -1), Vector2(2, 7), Vector2(-3, 4), Vector2(-5, -2),
		])
		_crystal_overlay.add_child(crystal)
		_crystal_accents.append(crystal)
	_layout_crystal_accents()


func _layout_crystal_accents() -> void:
	if _crystal_accents.size() < 3:
		return
	_crystal_accents[0].position = Vector2(cell_size.x * 0.82, cell_size.y * 0.22)
	_crystal_accents[1].position = Vector2(cell_size.x * 0.18, cell_size.y * 0.77)
	_crystal_accents[2].position = Vector2(cell_size.x * 0.75, cell_size.y * 0.78)


func _stack_chain_highlight_under_label() -> void:
	# Stack vs Board ChainLineLayer (z=1): face → laser → selection → label.
	_bg.z_index = Z_FACE
	if _chain_highlight.get_parent() != _bg:
		var insert_at := _label.get_index()
		_chain_highlight.reparent(_bg)
		_bg.move_child(_chain_highlight, insert_at)
		_chain_highlight.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		_chain_highlight.offset_bottom = 0.0
	_chain_highlight.z_as_relative = false
	_chain_highlight.z_index = Z_SELECTION
	_label.z_as_relative = false
	_label.z_index = Z_LABEL


func _apply_bevelling() -> void:
	_top_edge.offset_bottom = BEVEL_THICKNESS
	_bottom_edge.offset_top = -BEVEL_THICKNESS
	_left_edge.offset_right = SIDE_BEVEL
	_right_edge.offset_left = cell_size.x - SIDE_BEVEL


func _apply_label_depth() -> void:
	_label.add_theme_constant_override("outline_size", 2)
	_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))
	_label.add_theme_constant_override("shadow_offset_x", 0)
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.45))


func _ensure_crown_icon() -> void:
	if _crown_icon != null:
		return

	var crown_texture: Texture2D = _load_crown_texture()
	if crown_texture == null:
		return

	_crown_icon = _make_crown_layer("CrownIcon", crown_texture)
	_crown_icon.visible = false
	_crown_icon.z_as_relative = false
	_crown_icon.z_index = Z_CROWN
	_crown_icon.modulate = Color(1.0, 1.0, 1.0, CROWN_WATERMARK_ALPHA)
	_bg.add_child(_crown_icon)
	_bg.move_child(_crown_icon, _label.get_index())
	_label.z_as_relative = false
	_label.z_index = Z_LABEL
	_layout_crown_and_label()


func _load_crown_texture() -> Texture2D:
	var paths := [
		"res://assets/ui/icons/neon/tile-crown.png",
		"res://assets/ui/icons/tile-crown.png",
		"res://assets/ui/icons/neon/tile-crown.svg",
		"res://assets/ui/icons/tile-crown.svg",
	]
	for path in paths:
		if ResourceLoader.exists(path):
			return load(path)
	return null


func _make_crown_layer(layer_name: String, texture: Texture2D) -> TextureRect:
	var layer := TextureRect.new()
	layer.name = layer_name
	layer.texture = texture
	layer.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	layer.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	layer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return layer


func setup(pos: Vector2i, number: int) -> void:
	grid_pos = pos
	_layout_crystal_accents()
	if _crown_icon != null:
		_layout_crown_and_label()
	set_value(number)


func _layout_crown_and_label() -> void:
	if _crown_icon == null:
		return

	var tile_side := minf(cell_size.x, cell_size.y)
	var crown_side := clampf(tile_side * CROWN_SIZE_RATIO, CROWN_MIN_PX, CROWN_MAX_PX)
	var top_band := tile_side * CROWN_TOP_BAND_RATIO
	var crown_top := clampf((top_band - crown_side) * 0.5, 3.0, top_band - crown_side)
	var crown_size := Vector2(crown_side, crown_side)

	_crown_icon.custom_minimum_size = crown_size
	_crown_icon.size = crown_size
	_crown_icon.position = Vector2((cell_size.x - crown_side) * 0.5, crown_top)

	# Push digit slightly down so layout reads as “crown above number”.
	if _crown_icon.visible:
		var push := clampf(tile_side * CROWN_LABEL_PUSH_RATIO, 8.0, crown_side * 0.7)
		_label.offset_top = push
		_label.offset_bottom = 0.0
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	else:
		_label.offset_top = 0.0
		_label.offset_bottom = 0.0
		_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


func set_value(number: int) -> void:
	var changed := value != number
	value = number
	_label.text = "" if number <= 0 else str(number)
	_refresh_visual()
	if changed and number > 0 and is_inside_tree() and _effects_enabled():
		var tween := create_tween()
		scale = Vector2.ONE
		tween.tween_property(self, "scale", Vector2(1.08, 1.08), 0.08)
		tween.tween_property(self, "scale", Vector2.ONE, 0.1)


func set_chain_selected(selected: bool, preview: String = "") -> void:
	var next_preview := preview if selected else ""
	if _selected == selected and _chain_preview == next_preview:
		return
	_selected = selected
	_chain_preview = next_preview
	_refresh_visual()

func set_pressed_visual(pressed: bool) -> void:
	if _pressed == pressed:
		return
	_pressed = pressed
	var target_y := _base_position.y - PRESS_LIFT if pressed else _base_position.y
	if _lift_tween != null and _lift_tween.is_valid():
		_lift_tween.kill()
	if not _effects_enabled():
		position.y = _base_position.y
		return
	_lift_tween = create_tween()
	_lift_tween.tween_property(self, "position:y", target_y, 0.08) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func set_target_highlight(active: bool) -> void:
	_target = active
	_refresh_visual()

func set_frozen(frozen: bool) -> void:
	_frozen = frozen
	_refresh_visual()

func set_bonus_mode(active: bool) -> void:
	_bonus_mode = active
	_refresh_visual()

func set_carry(active: bool) -> void:
	_carry = active
	_carry_badge.visible = false
	_refresh_visual()

func _apply_panel_style() -> void:
	_shadow.color = Color(0, 0, 0, 0.34)
	_shadow.offset_top = 2.0
	_shadow.offset_left = 1.0
	_shadow.offset_right = cell_size.x + 1.0
	_shadow.offset_bottom = cell_size.y


func _apply_material_face(face_color: Color) -> void:
	if _face_material == null:
		_face_material = ShaderMaterial.new()
		_face_material.shader = GOTHIC_FACE_SHADER
	_inner.material = _face_material
	_face_material.set_shader_parameter("face_color", Color(face_color.lightened(0.08), 0.96))
	_inner.color = Color.WHITE


func _get_rim_color() -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method("get_palette"):
		var palette: Dictionary = theme.call("get_palette", true)
		return Color(palette.get("rim", Color("#D4AF37")), 0.65)
	return Color("#D4AF37", 0.55)


func _draw() -> void:
	if value <= 0:
		return
	if _material_background.visible:
		# The authored forged frame already defines each cell. Extra neon outlines
		# made the board read as a purple spreadsheet, so only rare tiers get a
		# restrained metallic rarity rim.
		if value >= 128:
			var rarity_rim := _get_rim_color()
			var rim_alpha := 0.72 if ThemeTokensLib.is_legendary_tile_value(value) else 0.30
			draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 6)), Color(rarity_rim, rim_alpha), false, 1.0)
		return
	var face := _inner.color if _inner.color.a > 0.01 else _color_for_value(value)
	var glow := Color(face, 0.28 if _effects_enabled() else 0.12)
	var rect := Rect2(Vector2(2, 2), size - Vector2(4, 6))
	draw_rect(rect.grow(2.0), glow, false, 3.0)
	var rim := _get_rim_color()
	var border_rect := Rect2(Vector2.ZERO, size - Vector2(0, 4))
	if ThemeTokensLib.is_legendary_tile_value(value):
		draw_rect(border_rect, Color(rim, 0.65), false, 2.0)
	elif _material_background.visible:
		draw_rect(border_rect, Color(face.lightened(0.12), 0.48), false, 1.0)
	else:
		draw_rect(border_rect, Color(face.lightened(0.15), 0.75), false, 2.0)


func _refresh_visual() -> void:
	if not is_inside_tree():
		return

	if value <= 0:
		_material_background.visible = false
		_crystal_overlay.visible = false
		_inner.material = null
		_inner.color = Color.TRANSPARENT
		_top_edge.color = Color.TRANSPARENT
		_bottom_edge.color = Color.TRANSPARENT
		_left_edge.color = Color.TRANSPARENT
		_right_edge.color = Color.TRANSPARENT
		_shadow.visible = false
		_label.text = ""
		if _crown_icon != null:
			_crown_icon.visible = false
		queue_redraw()
		return

	_shadow.visible = true
	var face_color: Color
	if _frozen:
		face_color = ThemeTokensLib.TILE_FROZEN_BG
	else:
		# Keep value palette; bonus pick uses outline only (no face recolor).
		face_color = _color_for_value(value)

	var material_style := _tile_material_style()
	_material_background.visible = material_style != null
	if material_style != null:
		_material_background.add_theme_stylebox_override("panel", material_style)
		# Keep the source frame neutral and wash only its calm inner face with the
		# live value colour. This preserves a single scalable frame while making
		# 2, 4, 8… immediately distinguishable.
		_inner.offset_left = 6.0
		_inner.offset_top = 6.0
		_inner.offset_right = -6.0
		_inner.offset_bottom = -6.0
		_apply_material_face(face_color)
		_top_edge.color = Color.TRANSPARENT
		_bottom_edge.color = Color.TRANSPARENT
		_left_edge.color = Color.TRANSPARENT
		_right_edge.color = Color.TRANSPARENT
	else:
		# Procedural fallback keeps the original value palette and 2.5D bevel.
		_inner.material = null
		_inner.offset_left = 0.0
		_inner.offset_top = 0.0
		_inner.offset_right = 0.0
		_inner.offset_bottom = 0.0
		_inner.color = face_color.darkened(FACE_DARKEN)
		_top_edge.color = Color(face_color.lightened(0.28), 0.95)
		_bottom_edge.color = Color(face_color.darkened(0.42), 0.96)
		_left_edge.color = Color(face_color.lightened(0.12), 0.82)
		_right_edge.color = Color(face_color.darkened(0.32), 0.92)

	var text_color := ThemeTokensLib.tile_text_color_for(face_color, value)
	_label.add_theme_color_override("font_color", text_color)
	_label.add_theme_font_size_override("font_size", _tile_font_size() + (3 if material_style != null else 0))
	_label.add_theme_constant_override("outline_size", 3 if material_style != null else 2)
	_label.add_theme_color_override("font_outline_color", Color("#120d18"))
	_label.add_theme_constant_override("shadow_offset_y", 2)
	_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.62))

	if _crown_icon != null:
		# Crown marks the singular carry tile from the previous level — never board-max.
		_crown_icon.visible = _carry and not _frozen
		_layout_crown_and_label()
	else:
		_label.offset_top = 0.0
		_label.offset_bottom = 0.0

	_refresh_crystal_accents()

	_chain_highlight.visible = false
	if _bonus_mode and not _frozen:
		_chain_highlight.visible = true
		var pick_color := ThemeTokensLib.COLOR_ACCENT_ORANGE
		var pick_style := StyleBoxFlat.new()
		pick_style.bg_color = Color(0, 0, 0, 0)
		pick_style.border_color = Color(pick_color, 0.85)
		pick_style.set_border_width_all(2)
		pick_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		pick_style.shadow_color = Color(pick_color, 0.28)
		pick_style.shadow_size = 4
		_chain_highlight.add_theme_stylebox_override("panel", pick_style)
		if _chain_fill != null:
			_chain_fill.color = Color(pick_color, 0.08)
	elif _selected and not _frozen and not _chain_preview.is_empty():
		_chain_highlight.visible = true
		var border_color := _chain_border_color(_chain_preview)
		var panel_style := StyleBoxFlat.new()
		panel_style.bg_color = Color(0, 0, 0, 0)
		panel_style.border_color = Color(border_color, 0.95)
		panel_style.set_border_width_all(3)
		panel_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		panel_style.shadow_color = Color(border_color, 0.5)
		panel_style.shadow_size = 8
		_chain_highlight.add_theme_stylebox_override("panel", panel_style)
		if _chain_fill != null:
			_chain_fill.color = Color(border_color, 0.16)
	elif _target and not _frozen:
		_chain_highlight.visible = true
		var target_color := _get_rim_color()
		var target_style := StyleBoxFlat.new()
		target_style.bg_color = Color(target_color, 0.06)
		target_style.border_color = Color(target_color, 0.9)
		target_style.set_border_width_all(2)
		target_style.set_corner_radius_all(ThemeTokensLib.TILE_INNER_RADIUS)
		_chain_highlight.add_theme_stylebox_override("panel", target_style)
		if _chain_fill != null:
			_chain_fill.color = Color(target_color, 0.08)
	queue_redraw()


func _tile_material_style() -> StyleBox:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_tile_style_for_value"):
		return theme_mgr.call("get_tile_style_for_value", value, _frozen) as StyleBox
	return null


func _refresh_crystal_accents() -> void:
	var rarity := &"common"
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_tile_rarity"):
		rarity = theme_mgr.call("get_tile_rarity", value)
	var count := 0
	match rarity:
		&"uncommon":
			count = 1
		&"rare":
			count = 1
		&"epic":
			count = 2
		&"legendary":
			count = 3
	if _frozen:
		count = 1
	_crystal_overlay.visible = _material_background.visible and count > 0
	var crystal_color := Color("#a855f7")
	if _frozen:
		crystal_color = Color("#bcecff")
	else:
		crystal_color = _theme_palette_color("crystal", crystal_color)
	for index in _crystal_accents.size():
		var crystal := _crystal_accents[index]
		crystal.visible = index < count
		crystal.color = Color(crystal_color.lightened(float(index) * 0.08), 0.78 if _effects_enabled() else 0.55)
		crystal.scale = Vector2.ONE * (0.72 + float(index) * 0.12)


func _theme_palette_color(key: String, fallback: Color) -> Color:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_palette"):
		var palette: Dictionary = theme_mgr.call("get_palette", true)
		return palette.get(key, fallback)
	return fallback


func _theme_text_color() -> Color:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_text_color"):
		return theme_mgr.call("get_text_color", true)
	return ThemeTokensLib.TILE_TEXT_LIGHT


func _effects_enabled() -> bool:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	return theme_mgr == null or not theme_mgr.has_method("effects_enabled") or bool(theme_mgr.call("effects_enabled"))


func refresh_font_size() -> void:
	_refresh_visual()


func _tile_font_size() -> int:
	var digits := 1
	if value > 0:
		digits = str(value).length()
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("get_tile_font_size"):
		return int(settings.call("get_tile_font_size", cell_size, digits))
	return ThemeTokensLib.tile_font_size_for_cell(cell_size, digits, 1.0)


func _chain_border_color(preview: String) -> Color:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	match preview:
		"valid":
			if theme_mgr != null and theme_mgr.has_method("get_chain_valid_color"):
				return theme_mgr.call("get_chain_valid_color")
			return ThemeTokensLib.COLOR_CHAIN_VALID
		"invalid":
			if theme_mgr != null and theme_mgr.has_method("get_chain_invalid_color"):
				return theme_mgr.call("get_chain_invalid_color")
			return ThemeTokensLib.COLOR_CHAIN_INVALID
		_:
			if theme_mgr != null and theme_mgr.has_method("get_chain_continue_color"):
				return theme_mgr.call("get_chain_continue_color")
			return ThemeTokensLib.COLOR_CHAIN_CONTINUE


func _color_for_value(n: int) -> Color:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_tile_face_color"):
		return theme_mgr.call("get_tile_face_color", n) as Color
	if ThemeTokensLib.TILE_COLORS.has(n):
		return ThemeTokensLib.TILE_COLORS[n]
	if ThemeTokensLib.TILE_GRADIENTS.has(n):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[n]
		return pair[0].lerp(pair[1], 0.5)
	var log_val := 0
	var t := n
	while t > 1:
		t /= 2
		log_val += 1
	return Color.from_hsv(fmod(log_val * 0.09 + 0.08, 1.0), 0.52, 0.78)
