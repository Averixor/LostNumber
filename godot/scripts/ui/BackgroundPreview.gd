extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const ImagePickerHelperLib := preload("res://scripts/ui/ImagePickerHelper.gd")

const CARD_SIZE := Vector2(96, 122)

@onready var bg_texture: TextureRect = $BackgroundTexture
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var title_label: Label = $TitleLabel
@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var carousel_scroll: ScrollContainer = $BottomPanel/VBox/CarouselScroll
@onready var carousel_row: HBoxContainer = $BottomPanel/VBox/CarouselScroll/CarouselRow
@onready var custom_button: Button = $BottomPanel/VBox/ButtonRow/CustomButton
@onready var cancel_button: Button = $BottomPanel/VBox/ButtonRow/CancelButton
@onready var apply_button: Button = $BottomPanel/VBox/ButtonRow/ApplyButton

var _paths: Array[String] = []
var _selected_path := ""
var _cards: Array[PanelContainer] = []


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _t(key: String) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _ready() -> void:
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("get_selected_background_path"):
		_selected_path = str(settings.call("get_selected_background_path", _active_bucket()))

	title_label.text = _t("background_preview_title")
	custom_button.text = _t("skin_custom_bg")
	cancel_button.text = _t("skin_cancel")
	apply_button.text = _t("skin_apply")
	LnUiLib.apply_title(title_label, 26)
	for button in [custom_button, cancel_button, apply_button]:
		LnUiLib.apply_compact_button(button, 14, 42)

	custom_button.pressed.connect(_on_custom_background)
	cancel_button.pressed.connect(_on_cancel)
	apply_button.pressed.connect(_on_apply)
	_build_cards()
	_apply_preview()
	call_deferred("_adapt_layout")


func _active_bucket() -> String:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("theme_bucket"):
		return str(theme.call("theme_bucket"))
	return "dark"


func _build_cards() -> void:
	for child in carousel_row.get_children():
		child.queue_free()
	_cards.clear()
	_paths = [""]
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("get_carousel_backgrounds"):
		for entry in settings.call("get_carousel_backgrounds"):
			var path := str(entry)
			if not path.is_empty() and path not in _paths:
				_paths.append(path)
	if not _selected_path.is_empty() and _selected_path not in _paths:
		_paths.append(_selected_path)

	for index in _paths.size():
		var path := _paths[index]
		var card := PanelContainer.new()
		card.custom_minimum_size = CARD_SIZE
		card.set_meta("background_path", path)
		card.gui_input.connect(_on_card_gui_input.bind(path))

		var box := VBoxContainer.new()
		box.name = "VBox"
		box.mouse_filter = Control.MOUSE_FILTER_IGNORE
		box.add_theme_constant_override("separation", 5)
		card.add_child(box)

		var preview := TextureRect.new()
		preview.name = "Preview"
		preview.custom_minimum_size = Vector2(88, 82)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
		preview.texture = LnUiLib.load_background_texture(_preview_path(path))
		box.add_child(preview)

		var label := Label.new()
		label.name = "Label"
		label.text = _card_label(path, index)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 2
		label.custom_minimum_size.y = 28.0
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_font_size_override("font_size", 11)
		label.add_theme_color_override("font_color", Color("#f4e7d3"))
		box.add_child(label)

		carousel_row.add_child(card)
		_cards.append(card)
	_refresh_cards()


func _card_label(path: String, index: int) -> String:
	if path.is_empty():
		return _t("skin_reset_default")
	if path.begins_with("user://"):
		return _t("skin_custom_bg")
	return "%s %d" % [_t("background_variant"), index]


func _preview_path(path: String) -> String:
	if not path.is_empty():
		return path
	var theme := _autoload("ThemeManager")
	if theme != null:
		var skin_id := str(theme.get("visual_skin_id"))
		if skin_id != "procedural_neon" and theme.has_method("get_visual_skin_background_path"):
			var visual_default := str(theme.call("get_visual_skin_background_path", skin_id, "game"))
			if not visual_default.is_empty():
				return visual_default
		if theme.has_method("get_default_background_path"):
			return str(theme.call("get_default_background_path", _active_bucket()))
	return LnUiLib.BG_GAME


func _on_card_gui_input(event: InputEvent, path: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select(path)
	elif event is InputEventScreenTouch and event.pressed:
		_select(path)


func _select(path: String) -> void:
	_selected_path = path
	_apply_preview()
	_refresh_cards()


func _apply_preview() -> void:
	bg_texture.texture = LnUiLib.load_background_texture(_preview_path(_selected_path))
	dim_overlay.color = Color(0.02, 0.01, 0.05, 0.58)
	var panel := LnUiLib.make_glass_panel(10, 1)
	bottom_panel.add_theme_stylebox_override("panel", panel)


func _refresh_cards() -> void:
	for card in _cards:
		var selected := str(card.get_meta("background_path", "")) == _selected_path
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.055, 0.025, 0.08, 0.9)
		style.border_color = Color("#59ef86") if selected else Color(0.66, 0.33, 0.97, 0.58)
		style.set_border_width_all(2 if selected else 1)
		style.set_corner_radius_all(10)
		style.set_content_margin_all(4)
		card.add_theme_stylebox_override("panel", style)


func _on_custom_background() -> void:
	var source := str(await ImagePickerHelperLib.pick_image(self, Callable(self, "_t")))
	if source.is_empty():
		return
	var settings := _autoload("SettingsManager")
	if settings == null or not settings.has_method("add_custom_background"):
		LnUiLib.show_toast(self, _t("skin_bg_load_failed"))
		return
	var imported := str(settings.call("add_custom_background", _active_bucket(), source))
	if imported.is_empty():
		LnUiLib.show_toast(self, _t("skin_bg_load_failed"))
		return
	_selected_path = imported
	_build_cards()
	_apply_preview()


func _on_apply() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("apply_background_path"):
		theme.call("apply_background_path", _selected_path)
	await _on_cancel()


func _on_cancel() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("go_back"):
		var ok: bool = await router.go_back()
		if not ok and router.has_method("replace"):
			router.call("replace", "settings")
	else:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _adapt_layout() -> void:
	var viewport_size := get_viewport_rect().size
	var bottom_height := clampi(int(viewport_size.y * 0.31), 220, 286)
	bottom_panel.offset_left = 12
	bottom_panel.offset_right = -12
	bottom_panel.offset_top = -float(bottom_height)
	bottom_panel.offset_bottom = -14
	carousel_scroll.custom_minimum_size.y = bottom_height - 74
	title_label.offset_top = 24 if viewport_size.y <= 920.0 else 34


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_adapt_layout()
