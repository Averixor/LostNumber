extends Control

## Fullscreen background/skin preview with carousel and apply/cancel flow.

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const ImagePickerHelperLib := preload("res://scripts/ui/ImagePickerHelper.gd")

@onready var bg_texture: TextureRect = $BackgroundTexture
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var title_label: Label = $TitleLabel
@onready var bottom_panel: PanelContainer = $BottomPanel
@onready var carousel_scroll: ScrollContainer = $BottomPanel/VBox/CarouselScroll
@onready var carousel_row: HBoxContainer = $BottomPanel/VBox/CarouselScroll/CarouselRow
@onready var custom_button: Button = $BottomPanel/VBox/ButtonRow/CustomButton
@onready var cancel_button: Button = $BottomPanel/VBox/ButtonRow/CancelButton
@onready var apply_button: Button = $BottomPanel/VBox/ButtonRow/ApplyButton

var _backgrounds: Array[String] = []
var _preview_path: String = ""
var _saved_path: String = ""
var _cards: Array[PanelContainer] = []


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	_load_background_list()
	_saved_path = _current_saved_path()
	_preview_path = _saved_path
	if _preview_path.is_empty() and not _backgrounds.is_empty():
		_preview_path = _backgrounds[0]
	_apply_preview_texture(_preview_path)
	_style_ui()
	_build_carousel()
	_adapt_layout()

	title_label.text = _i18n("game_logo")
	var logo := LnUiLib.try_add_logo(self, LnUiLib.LOGO_PATH, Vector2(220, 80))
	if logo != null:
		logo.set_anchors_preset(Control.PRESET_CENTER_TOP)
		logo.offset_top = 28.0
		title_label.visible = false
		LnUiLib.wire_logo_glow(logo)
	custom_button.text = _i18n("skin_custom_bg")
	cancel_button.text = _i18n("skin_cancel")
	apply_button.text = _i18n("skin_apply")

	custom_button.pressed.connect(_on_custom_pressed)
	cancel_button.pressed.connect(_on_cancel)
	apply_button.pressed.connect(_on_apply)

	call_deferred("_adapt_layout")


func _load_background_list() -> void:
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("get_carousel_backgrounds"):
		_backgrounds = settings.call("get_carousel_backgrounds")
		return
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("discover_builtin_backgrounds"):
		var bucket := "dark"
		if theme_mgr.has_method("theme_bucket"):
			bucket = str(theme_mgr.call("theme_bucket"))
		for path in theme_mgr.call("discover_builtin_backgrounds", bucket):
			_backgrounds.append(str(path))


func _current_saved_path() -> String:
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("current_background_for_theme"):
		return str(settings.call("current_background_for_theme"))
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_background_texture_path"):
		return str(theme_mgr.call("get_background_texture_path"))
	return ""


func _style_ui() -> void:
	LnUiLib.apply_title(title_label, mini(28, ThemeTokensLib.FONT_SIZE_TITLE))
	for btn in [custom_button, cancel_button, apply_button]:
		LnUiLib.apply_compact_button(btn, 15, 40.0)
	apply_button.add_theme_color_override("font_color", LnUiLib.ACCENT)
	bottom_panel.add_theme_stylebox_override("panel", LnUiLib.glass_box(18, 1, Color(0.10, 0.05, 0.14, 0.78), LnUiLib.BORDER))
	bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	dim_overlay.color = LnUiLib.DIM_DARK


func _build_carousel() -> void:
	for child in carousel_row.get_children():
		child.queue_free()
	_cards.clear()

	for i in _backgrounds.size():
		var path := _backgrounds[i]
		var card := _make_card(path, i)
		carousel_row.add_child(card)
		_cards.append(card)

	_refresh_selection()


func _make_card(path: String, index: int) -> PanelContainer:
	var card := PanelContainer.new()
	card.custom_minimum_size = Vector2(72, 88)
	card.mouse_filter = Control.MOUSE_FILTER_STOP

	var vbox := VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 4)

	var preview := TextureRect.new()
	preview.custom_minimum_size = Vector2(64, 48)
	preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_set_card_texture(preview, path)
	vbox.add_child(preview)

	var badge := Label.new()
	badge.name = "Badge"
	badge.text = _i18n("skin_selected_badge")
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", LnUiLib.ACCENT)
	badge.visible = false
	vbox.add_child(badge)

	card.add_child(vbox)
	card.set_meta("bg_path", path)
	card.gui_input.connect(func(event: InputEvent): _on_card_input(index, event))
	return card


func _set_card_texture(target: TextureRect, path: String) -> void:
	target.texture = null
	if path.begins_with("user://"):
		if FileAccess.file_exists(path):
			var img := Image.load_from_file(path)
			if img != null:
				target.texture = ImageTexture.create_from_image(img)
	elif ResourceLoader.exists(path):
		target.texture = load(path)


func _apply_preview_texture(path: String) -> void:
	_set_card_texture(bg_texture, path)


func _refresh_selection() -> void:
	for card in _cards:
		var path := str(card.get_meta("bg_path", ""))
		var selected := path == _preview_path
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.08, 0.05, 0.12, 0.82)
		style.set_corner_radius_all(10)
		style.set_border_width_all(3 if selected else 1)
		style.border_color = LnUiLib.BORDER_ACTIVE if selected else LnUiLib.BORDER
		style.set_content_margin_all(4)
		card.add_theme_stylebox_override("panel", style)
		var badge := card.get_node_or_null("VBox/Badge") as Label
		if badge != null:
			badge.visible = selected


func _on_card_input(index: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		_select_index(index)
	elif event is InputEventScreenTouch and event.pressed:
		_select_index(index)


func _select_index(index: int) -> void:
	if index < 0 or index >= _backgrounds.size():
		return
	_preview_path = _backgrounds[index]
	_apply_preview_texture(_preview_path)
	_refresh_selection()


func _on_custom_pressed() -> void:
	var path: String = await ImagePickerHelperLib.pick_image(self, Callable(self, "_i18n"))
	if path.is_empty():
		return
	_import_custom_background(path)


func _import_custom_background(source_path: String) -> void:
	var settings := _autoload("SettingsManager")
	var theme_mgr := _autoload("ThemeManager")
	if settings == null:
		LnUiLib.show_toast(self, _i18n("skin_bg_load_failed"))
		return
	var bucket := "dark"
	if theme_mgr != null and theme_mgr.has_method("theme_bucket"):
		bucket = str(theme_mgr.call("theme_bucket"))
	if not settings.has_method("add_custom_background"):
		LnUiLib.show_toast(self, _i18n("skin_bg_load_failed"))
		return
	var dest: String = str(settings.call("add_custom_background", bucket, source_path))
	if dest.is_empty():
		var ext := source_path.get_extension().to_lower()
		if ext not in ["png", "jpg", "jpeg", "webp"]:
			LnUiLib.show_toast(self, _i18n("skin_bg_format_unsupported"))
		else:
			LnUiLib.show_toast(self, _i18n("skin_bg_load_failed"))
		return
	_load_background_list()
	if dest not in _backgrounds:
		_backgrounds.append(dest)
	_build_carousel()
	_preview_path = dest
	_apply_preview_texture(_preview_path)
	_refresh_selection()
	var idx := _backgrounds.find(dest)
	if idx >= 0:
		call_deferred("_scroll_to_card", idx)


func _scroll_to_card(index: int) -> void:
	if index < 0 or index >= _cards.size():
		return
	var card := _cards[index]
	if carousel_scroll == null or card == null:
		return
	var target_x := maxf(0.0, card.position.x - 24.0)
	carousel_scroll.scroll_horizontal = int(target_x)


func _on_cancel() -> void:
	var router := _autoload("ScreenRouter")
	if router != null:
		await router.go_back()
	else:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _on_apply() -> void:
	if _preview_path.is_empty():
		_on_cancel()
		return
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("apply_background_path"):
		theme_mgr.call("apply_background_path", _preview_path)
	elif theme_mgr != null and theme_mgr.has_method("set_skin_index"):
		var bucket := "dark"
		if theme_mgr.has_method("theme_bucket"):
			bucket = str(theme_mgr.call("theme_bucket"))
		var idx := -1
		if theme_mgr.has_method("path_to_index"):
			idx = int(theme_mgr.call("path_to_index", _preview_path, bucket))
		if idx >= 0:
			theme_mgr.call("set_skin_index", idx)
	var router := _autoload("ScreenRouter")
	if router != null:
		await router.go_back()
	else:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _adapt_layout() -> void:
	var vp := get_viewport_rect().size
	var compact := vp.y <= 920.0
	var bottom_h := clampi(int(vp.y * 0.28), 180, 260)
	var btn_h := 36.0 if compact else 40.0
	var btn_font := 14 if compact else 15
	bottom_panel.offset_left = 12.0
	bottom_panel.offset_right = -12.0
	bottom_panel.offset_bottom = -maxi(12, int(vp.y * 0.02))
	bottom_panel.custom_minimum_size.y = bottom_h
	carousel_scroll.custom_minimum_size.y = bottom_h - (84 if compact else 92)
	for card in _cards:
		card.custom_minimum_size = Vector2(64, 80) if compact else Vector2(72, 88)
	for btn in [custom_button, cancel_button, apply_button]:
		LnUiLib.apply_compact_button(btn, btn_font, btn_h)
	apply_button.add_theme_color_override("font_color", LnUiLib.ACCENT)
	title_label.offset_top = 24.0 if compact else 36.0
	title_label.add_theme_font_size_override("font_size", 22 if compact else 26)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED:
		_adapt_layout()
