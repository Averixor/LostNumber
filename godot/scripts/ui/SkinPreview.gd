extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

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
var _selected_index := 0
var _cards: Array[PanelContainer] = []


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null:
		if theme.has_method("is_dark"):
			_dark_mode = bool(theme.call("is_dark"))
		var idx = theme.get("background_index")
		if idx != null:
			_selected_index = clampi(int(idx), 0, 5)

	if bg_texture != null:
		bg_texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		bg_texture.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED

	if title_label != null:
		title_label.text = "Виберіть скін"
		LnUiLib.apply_title(title_label, 26)

	if mode_button != null:
		mode_button.pressed.connect(_on_mode_toggle)
	if cancel_button != null:
		cancel_button.text = "Назад"
		cancel_button.pressed.connect(_on_cancel)
	if apply_button != null:
		apply_button.text = "Застосувати"
		apply_button.pressed.connect(_on_apply)

	_build_cards()
	_style_ui()
	_apply_preview()
	call_deferred("_adapt_layout")


func _background_for(index: int) -> String:
	var theme := _autoload("ThemeManager")
	if theme != null and theme.has_method("get_background_texture_path_for"):
		return str(theme.call("get_background_texture_path_for", index, _dark_mode))
	var n := index + 1
	return "res://assets/ui/backgrounds/dark/menu-bg-%d.png" % n if _dark_mode else "res://assets/ui/backgrounds/light/bg-light-%02d.png" % n


func _set_texture(t: TextureRect, path: String) -> void:
	if t == null:
		return
	t.texture = null
	if ResourceLoader.exists(path):
		t.texture = load(path) as Texture2D


func _style_ui() -> void:
	if dim_overlay != null:
		dim_overlay.color = Color(0.02, 0.01, 0.05, 0.62 if _dark_mode else 0.12)

	if bottom_panel != null:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.08, 0.02, 0.12, 0.78) if _dark_mode else Color(0.96, 0.88, 1.0, 0.74)
		sb.border_color = Color(0.95, 0.25, 1.0, 0.55)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(18)
		sb.set_content_margin_all(10)
		bottom_panel.add_theme_stylebox_override("panel", sb)

	for btn in [mode_button, cancel_button, apply_button]:
		if btn != null:
			LnUiLib.apply_compact_button(btn, 15, 42)

	if mode_button != null:
		mode_button.text = "Темні скіни" if _dark_mode else "Світлі скіни"


func _build_cards() -> void:
	if carousel_row == null:
		return

	for child in carousel_row.get_children():
		child.queue_free()

	_cards.clear()

	for i in range(6):
		var card := PanelContainer.new()
		card.custom_minimum_size = Vector2(86, 112)
		card.set_meta("skin_index", i)

		var box := VBoxContainer.new()
		box.name = "VBox"
		box.add_theme_constant_override("separation", 5)
		card.add_child(box)

		var preview := TextureRect.new()
		preview.name = "Preview"
		preview.custom_minimum_size = Vector2(78, 76)
		preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		box.add_child(preview)

		var label := Label.new()
		label.name = "Label"
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.add_theme_font_size_override("font_size", 12)
		box.add_child(label)

		card.gui_input.connect(func(event):
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				_select(i)
			elif event is InputEventScreenTouch and event.pressed:
				_select(i)
		)

		carousel_row.add_child(card)
		_cards.append(card)

	_refresh_cards()


func _select(index: int) -> void:
	_selected_index = clampi(index, 0, 5)
	_apply_preview()
	_refresh_cards()


func _apply_preview() -> void:
	_set_texture(bg_texture, _background_for(_selected_index))
	_style_ui()


func _refresh_cards() -> void:
	for card in _cards:
		var idx := int(card.get_meta("skin_index", 0))
		var selected := idx == _selected_index

		var preview := card.get_node_or_null("VBox/Preview") as TextureRect
		_set_texture(preview, _background_for(idx))

		var label := card.get_node_or_null("VBox/Label") as Label
		if label != null:
			label.text = "%s %d" % [("Темний" if _dark_mode else "Світлий"), idx + 1]
			label.add_theme_color_override("font_color", Color.WHITE if _dark_mode else Color(0.18, 0.08, 0.25))

		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.10, 0.03, 0.15, 0.76) if _dark_mode else Color(1.0, 0.92, 1.0, 0.72)
		sb.border_color = Color(0.35, 1.0, 0.35, 0.95) if selected else Color(0.95, 0.25, 1.0, 0.35)
		sb.set_border_width_all(2 if selected else 1)
		sb.set_corner_radius_all(12)
		sb.set_content_margin_all(4)
		card.add_theme_stylebox_override("panel", sb)


func _on_mode_toggle() -> void:
	_dark_mode = not _dark_mode
	_style_ui()
	_apply_preview()
	_refresh_cards()


func _on_apply() -> void:
	var theme := _autoload("ThemeManager")
	if theme != null:
		if theme.has_method("set_skin_profile"):
			theme.call("set_skin_profile", _selected_index, _dark_mode)
		else:
			theme.set("theme_id", "dusk" if _dark_mode else "dawn")
			if theme.has_method("set_skin_index"):
				theme.call("set_skin_index", _selected_index)
	_on_cancel()


func _on_cancel() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("go_back"):
		var ok: bool = await router.go_back()
		if not ok and router.has_method("replace"):
			router.call("replace", "settings")
	else:
		get_tree().change_scene_to_file("res://scenes/Settings.tscn")


func _adapt_layout() -> void:
	if not is_node_ready():
		return
	if bottom_panel == null or carousel_scroll == null or title_label == null:
		return

	var vp := get_viewport_rect().size
	var compact := vp.y <= 920.0
	var bottom_h := clampi(int(vp.y * 0.30), 196, 270)

	bottom_panel.offset_left = 12
	bottom_panel.offset_right = -12
	bottom_panel.offset_top = -float(bottom_h)
	bottom_panel.offset_bottom = -14
	carousel_scroll.custom_minimum_size.y = bottom_h - 76

	title_label.offset_top = 24 if compact else 34
	title_label.add_theme_font_size_override("font_size", 22 if compact else 26)


func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_adapt_layout()
