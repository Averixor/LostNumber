extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const CARD_SIZE := Vector2(178, 226)
const TILE_PREVIEW_VALUES := [2, 16, 128]

@onready var bg_texture: TextureRect = get_node_or_null("BackgroundTexture") as TextureRect
@onready var dim_overlay: ColorRect = get_node_or_null("DimOverlay") as ColorRect
@onready var title_label: Label = get_node_or_null("TitleLabel") as Label
@onready var bottom_panel: PanelContainer = get_node_or_null("BottomPanel") as PanelContainer
@onready var carousel_scroll: ScrollContainer = get_node_or_null("BottomPanel/VBox/CarouselScroll") as ScrollContainer
@onready var carousel_row: HBoxContainer = get_node_or_null("BottomPanel/VBox/CarouselScroll/CarouselRow") as HBoxContainer
@onready var mode_button: Button = get_node_or_null("BottomPanel/VBox/ButtonRow/CustomButton") as Button
@onready var cancel_button: Button = get_node_or_null("BottomPanel/VBox/ButtonRow/CancelButton") as Button
@onready var apply_button: Button = get_node_or_null("BottomPanel/VBox/ButtonRow/ApplyButton") as Button

var _dark_mode := true
var _selected_skin_id := ""
var _skin_ids := PackedStringArray()
var _cards: Array[PanelContainer] = []


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	# Dark-only release: never offer a light preview that cannot stick on apply.
	_dark_mode = true
	var theme := _autoload("ThemeManager")
	if theme != null:
		if theme.has_method("get_visual_skin_ids"):
			_skin_ids = theme.call("get_visual_skin_ids") as PackedStringArray
		var active_id = theme.get("visual_skin_id")
		if active_id != null:
			_selected_skin_id = str(active_id)

	if _skin_ids.is_empty():
		_skin_ids = PackedStringArray(["procedural_neon"])
	if not _skin_ids.has(_selected_skin_id):
		_selected_skin_id = _skin_ids[0]

	if bg_texture != null:
		bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if title_label != null:
		LnUiLib.apply_title(title_label, 26)

	if mode_button != null:
		mode_button.visible = false
		mode_button.disabled = true
		mode_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if cancel_button != null:
		cancel_button.pressed.connect(_on_cancel)
	if apply_button != null:
		apply_button.pressed.connect(_on_apply)

	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_signal("settings_saved"):
		settings.settings_saved.connect(_on_settings_saved)

	_refresh_localized_text()
	_build_cards()
	_apply_preview()
	call_deferred("_adapt_layout")


func _t(key: String) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _refresh_localized_text() -> void:
	if title_label != null:
		title_label.text = _t("skin_preview_title")
	if mode_button != null:
		mode_button.visible = false
		mode_button.disabled = true
		mode_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		mode_button.text = ""
	if cancel_button != null:
		cancel_button.text = _t("skin_cancel")
	if apply_button != null:
		apply_button.text = _t("skin_apply")


func _background_for(skin_id: String) -> String:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_skin_background_path"):
		return str(theme.call("get_visual_skin_background_path", skin_id, "game", _dark_mode))
	return ""


func _set_texture(texture_rect: TextureRect, path: String) -> void:
	if texture_rect == null:
		return
	texture_rect.texture = null
	if not path.is_empty() and ResourceLoader.exists(path):
		texture_rect.texture = load(path) as Texture2D


func _style_for(kind: StringName, skin_id: String) -> StyleBox:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_style"):
		return theme.call("get_visual_style", kind, skin_id) as StyleBox
	return null


func _tile_style_for(value: int, skin_id: String) -> StyleBox:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_tile_style_for_value"):
		var style := theme.call("get_tile_style_for_value", value, false, skin_id) as StyleBox
		if style != null:
			return style

	var colors := {
		8: Color("#3a2750"),
		128: Color("#673a8d"),
		8192: Color("#8a642b"),
	}
	return _flat_style(colors.get(value, Color("#3a2750")), Color("#d7aa54"), 8, 1)


func _skin_text_color(skin_id: String) -> Color:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_skin"):
		var skin = theme.call("get_visual_skin", skin_id)
		if skin != null and skin.has_method("text_color"):
			return skin.call("text_color", _dark_mode) as Color
	return Color("#f7ecdc") if _dark_mode else Color("#291d30")


func _skin_overlay_color(skin_id: String) -> Color:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_skin"):
		var skin = theme.call("get_visual_skin", skin_id)
		if skin != null and skin.has_method("overlay_color"):
			return skin.call("overlay_color", _dark_mode) as Color
	return Color(0.02, 0.01, 0.05, 0.58 if _dark_mode else 0.14)


func _skin_supports_light_mode(skin_id: String) -> bool:
	var theme := _autoload("ThemeManager")
	return theme == null or not theme.has_method("visual_skin_supports_light_mode") or bool(theme.call("visual_skin_supports_light_mode", skin_id))


func _flat_style(bg: Color, border: Color, radius: int, border_width: int = 1) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = bg
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.set_content_margin_all(6)
	return style


func _fallback_panel_style() -> StyleBoxFlat:
	return _flat_style(
		Color(0.08, 0.025, 0.12, 0.9) if _dark_mode else Color(0.96, 0.89, 1.0, 0.92),
		Color(0.72, 0.34, 0.9, 0.8),
		12,
		1
	)


func _style_ui() -> void:
	if dim_overlay != null:
		dim_overlay.color = _skin_overlay_color(_selected_skin_id)

	if bottom_panel != null:
		var panel_style := _style_for(&"panel", _selected_skin_id)
		bottom_panel.add_theme_stylebox_override("panel", panel_style if panel_style != null else _fallback_panel_style())

	var text_color := _skin_text_color(_selected_skin_id)
	if title_label != null:
		title_label.add_theme_color_override("font_color", text_color)

	for button in [cancel_button, apply_button]:
		if button == null:
			continue
		LnUiLib.apply_compact_button(button, 15, 42)
		_apply_button_kit(button, _selected_skin_id, text_color)
	if mode_button != null:
		mode_button.visible = false
		mode_button.disabled = true
		mode_button.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _apply_button_kit(button: Button, skin_id: String, text_color: Color) -> void:
	var fallbacks := {
		"normal": _flat_style(Color(0.18, 0.08, 0.25, 0.94), Color("#a855f7"), 10),
		"hover": _flat_style(Color(0.27, 0.11, 0.36, 0.96), Color("#d7aa54"), 10, 2),
		"pressed": _flat_style(Color(0.12, 0.045, 0.18, 0.98), Color("#d7aa54"), 10, 2),
		"disabled": _flat_style(Color(0.12, 0.1, 0.14, 0.72), Color(0.4, 0.36, 0.44), 10),
	}
	for state in ["normal", "hover", "pressed", "disabled"]:
		var style := _style_for(StringName("button_" + state), skin_id)
		button.add_theme_stylebox_override(state, style if style != null else fallbacks[state])
	button.add_theme_color_override("font_color", text_color)
	button.add_theme_color_override("font_hover_color", text_color)
	button.add_theme_color_override("font_pressed_color", text_color)


func _build_cards() -> void:
	if carousel_row == null:
		return

	for child in carousel_row.get_children():
		child.queue_free()
	_cards.clear()

	for skin_id in _skin_ids:
		var card := _create_card(skin_id)
		carousel_row.add_child(card)
		_cards.append(card)

	_refresh_cards()


func _create_card(skin_id: String) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = CARD_SIZE
	card.set_meta("visual_skin_id", skin_id)
	card.tooltip_text = _skin_name(skin_id)
	card.gui_input.connect(_on_card_gui_input.bind(skin_id))

	var box := VBoxContainer.new()
	box.name = "VBox"
	box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_theme_constant_override("separation", 5)
	card.add_child(box)

	var stage := Control.new()
	stage.name = "MiniStage"
	stage.custom_minimum_size = Vector2(164, 116)
	stage.clip_contents = true
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	box.add_child(stage)

	var background := TextureRect.new()
	background.name = "Background"
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(background)
	stage.add_child(background)

	var shade := ColorRect.new()
	shade.name = "Shade"
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(shade)
	stage.add_child(shade)

	var center := CenterContainer.new()
	center.name = "Center"
	center.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fill(center)
	stage.add_child(center)

	var kit_panel := PanelContainer.new()
	kit_panel.name = "KitPanel"
	kit_panel.custom_minimum_size = Vector2(142, 98)
	kit_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	center.add_child(kit_panel)

	var kit_box := VBoxContainer.new()
	kit_box.name = "KitVBox"
	kit_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	kit_box.alignment = BoxContainer.ALIGNMENT_CENTER
	kit_box.add_theme_constant_override("separation", 4)
	kit_panel.add_child(kit_box)

	var tiles := HBoxContainer.new()
	tiles.name = "Tiles"
	tiles.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tiles.alignment = BoxContainer.ALIGNMENT_CENTER
	tiles.add_theme_constant_override("separation", 3)
	kit_box.add_child(tiles)
	for value in TILE_PREVIEW_VALUES:
		var tile := PanelContainer.new()
		tile.name = "Tile%d" % value
		tile.custom_minimum_size = Vector2(36, 36)
		tile.mouse_filter = Control.MOUSE_FILTER_IGNORE
		tile.add_theme_stylebox_override("panel", _tile_style_for(value, skin_id))
		tiles.add_child(tile)

		var number := Label.new()
		number.text = str(value)
		number.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		number.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		number.mouse_filter = Control.MOUSE_FILTER_IGNORE
		number.add_theme_font_size_override("font_size", 9 if value >= 8192 else 11)
		number.add_theme_color_override("font_color", _skin_text_color(skin_id))
		tile.add_child(number)

	var sample_button := Button.new()
	sample_button.name = "SampleButton"
	sample_button.text = _t("skin_preview_button")
	sample_button.custom_minimum_size = Vector2(112, 28)
	sample_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	sample_button.focus_mode = Control.FOCUS_NONE
	sample_button.add_theme_font_size_override("font_size", 11)
	_apply_button_kit(sample_button, skin_id, _skin_text_color(skin_id))
	kit_box.add_child(sample_button)

	var name_label := Label.new()
	name_label.name = "Name"
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	name_label.add_theme_font_size_override("font_size", 14)
	box.add_child(name_label)

	var description := Label.new()
	description.name = "Description"
	description.custom_minimum_size.y = 34
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	description.mouse_filter = Control.MOUSE_FILTER_IGNORE
	description.add_theme_font_size_override("font_size", 10)
	box.add_child(description)

	var selected_label := Label.new()
	selected_label.name = "Selected"
	selected_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	selected_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	selected_label.add_theme_font_size_override("font_size", 10)
	box.add_child(selected_label)

	return card


func _fill(control: Control) -> void:
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)


func _skin_metadata(skin_id: String) -> Dictionary:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_visual_skin_metadata"):
		return theme.call("get_visual_skin_metadata", skin_id) as Dictionary
	return {}


func _skin_name(skin_id: String) -> String:
	var metadata := _skin_metadata(skin_id)
	return _t(str(metadata.get("name_key", skin_id)))


func _skin_description(skin_id: String) -> String:
	var metadata := _skin_metadata(skin_id)
	return _t(str(metadata.get("description_key", skin_id)))


func _on_card_gui_input(event: InputEvent, skin_id: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_skin(skin_id)
	elif event is InputEventScreenTouch and event.pressed:
		_select_skin(skin_id)


func _select_skin(skin_id: String) -> void:
	if not _skin_ids.has(skin_id):
		return
	_selected_skin_id = skin_id
	_dark_mode = true
	_refresh_localized_text()
	_apply_preview()
	_refresh_cards()


func _apply_preview() -> void:
	_set_texture(bg_texture, _background_for(_selected_skin_id))
	_style_ui()


func _refresh_cards() -> void:
	for card in _cards:
		var skin_id := str(card.get_meta("visual_skin_id", ""))
		var selected := skin_id == _selected_skin_id

		var background := card.get_node_or_null("VBox/MiniStage/Background") as TextureRect
		_set_texture(background, _background_for(skin_id))

		var shade := card.get_node_or_null("VBox/MiniStage/Shade") as ColorRect
		if shade != null:
			shade.color = _skin_overlay_color(skin_id)

		var kit_panel := card.get_node_or_null("VBox/MiniStage/Center/KitPanel") as PanelContainer
		if kit_panel != null:
			var kit_style := _style_for(&"panel", skin_id)
			kit_panel.add_theme_stylebox_override("panel", kit_style if kit_style != null else _fallback_panel_style())

		var text_color := _skin_text_color(skin_id)
		var name_label := card.get_node_or_null("VBox/Name") as Label
		if name_label != null:
			name_label.text = _skin_name(skin_id)
			name_label.add_theme_color_override("font_color", text_color)

		var description := card.get_node_or_null("VBox/Description") as Label
		if description != null:
			description.text = _skin_description(skin_id)
			description.add_theme_color_override("font_color", Color(text_color, 0.82))

		var selected_label := card.get_node_or_null("VBox/Selected") as Label
		if selected_label != null:
			selected_label.visible = selected
			selected_label.text = _t("skin_selected_badge")
			selected_label.add_theme_color_override("font_color", Color("#59ef86"))

		var card_style := _flat_style(
			Color(0.055, 0.025, 0.08, 0.9) if _dark_mode else Color(0.97, 0.91, 0.98, 0.94),
			Color("#59ef86") if selected else Color(0.66, 0.33, 0.97, 0.58),
			12,
			2 if selected else 1
		)
		card.add_theme_stylebox_override("panel", card_style)


func _on_mode_toggle() -> void:
	# Dark-only release: light preview is a false affordance — keep dusk.
	_dark_mode = true
	_refresh_localized_text()
	_apply_preview()
	_build_cards()


func _on_apply() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null:
		if theme.has_method("set_visual_skin_id"):
			theme.call("set_visual_skin_id", _selected_skin_id)
	_on_cancel()


func _on_cancel() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("go_back"):
		var ok: bool = await router.go_back()
		if not ok and router.has_method("replace"):
			router.call("replace", "settings")
	else:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_settings_saved() -> void:
	_refresh_localized_text()
	_build_cards()
	_apply_preview()


func _adapt_layout() -> void:
	if not is_node_ready():
		return
	if bottom_panel == null or carousel_scroll == null or title_label == null:
		return

	var viewport_size := get_viewport_rect().size
	var compact := viewport_size.y <= 920.0
	var bottom_height := clampi(int(viewport_size.y * 0.42), 300, 382)

	bottom_panel.offset_left = 12
	bottom_panel.offset_right = -12
	bottom_panel.offset_top = -float(bottom_height)
	bottom_panel.offset_bottom = -14
	carousel_scroll.custom_minimum_size.y = bottom_height - 74

	title_label.offset_top = 24 if compact else 34
	title_label.add_theme_font_size_override("font_size", 22 if compact else 26)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_adapt_layout()
