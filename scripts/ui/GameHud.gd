extends Control
class_name GameHud

## In-game HUD: top bar, goal/XP labels, bonus row, bottom chain strip.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const RulesLib := preload("res://scripts/core/Rules.gd")

signal menu_pressed
signal sound_pressed
signal save_pressed
signal theme_pressed
signal bonus_pressed(type: String)

@onready var level_label: Label = $TopBar/LevelLabel
@onready var save_indicator: Label = $TopBar/SaveIndicator
@onready var menu_button: Button = $TopBar/MenuButton
@onready var save_button: Button = $TopBar/SaveButton
@onready var theme_button: Button = $TopBar/ThemeButton
@onready var sound_button: Button = $TopBar/SoundButton
@onready var goal_label: Label = $GoalRow/GoalPanel/GoalHBox/GoalLabel
@onready var xp_label: Label = $XpRow/XpPanel/XpHBox/XpLabel
@onready var bottom_strip: PanelContainer = $BottomStrip
@onready var chain_sum_label: Label = $BottomStrip/BottomHBox/ChainSumLabel
@onready var message_label: Label = $BottomStrip/BottomHBox/MessageLabel
@onready var shuffle_button: Button = $BonusBar/ShuffleButton
@onready var destroy_button: Button = $BonusBar/DestroyButton
@onready var explosion_button: Button = $BonusBar/ExplosionButton
@onready var explosion_badge: Label = $BonusBar/ExplosionButton/ExplosionBadge
@onready var shuffle_badge: Label = $BonusBar/ShuffleButton/ShuffleBadge
@onready var destroy_badge: Label = $BonusBar/DestroyButton/DestroyBadge

var _goal_track: ColorRect
var _goal_fill: ColorRect
var _xp_track: ColorRect
var _xp_fill: ColorRect
var _save_flash_tween: Tween = null
var _i18n_t: Callable

func _ready() -> void:
	bottom_strip.visible = false
	message_label.visible = false
	_ensure_progress_bars()
	menu_button.pressed.connect(func(): menu_pressed.emit())
	sound_button.pressed.connect(func(): sound_pressed.emit())
	save_button.pressed.connect(func(): save_pressed.emit())
	theme_button.pressed.connect(func(): theme_pressed.emit())
	shuffle_button.pressed.connect(func(): bonus_pressed.emit("shuffle"))
	destroy_button.pressed.connect(func(): bonus_pressed.emit("destroy"))
	explosion_button.pressed.connect(func(): bonus_pressed.emit("explosion"))
	_layout_bonus_badges()
	_apply_styles()
	_load_icons()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_styles)


func _theme_color(method: String, fallback: Color) -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method(method):
		return theme.call(method)
	return fallback


func _ensure_progress_bars() -> void:
	if _goal_track != null:
		return

	_goal_track = _make_bar_track($GoalRow/GoalPanel/GoalHBox)
	_goal_fill = _make_bar_fill(_goal_track, LnUiLib.GOAL.lerp(LnUiLib.CYAN, 0.35))
	$GoalRow/GoalPanel/GoalHBox.move_child(_goal_track, 0)

	_xp_track = _make_bar_track($XpRow/XpPanel/XpHBox)
	_xp_fill = _make_bar_fill(_xp_track, ThemeTokensLib.COLOR_PRIMARY.lerp(ThemeTokensLib.COLOR_SECONDARY, 0.35))
	$XpRow/XpPanel/XpHBox.move_child(_xp_track, 0)


func _make_bar_track(parent: Control) -> ColorRect:
	var track := ColorRect.new()
	track.name = "ProgressTrack"
	track.color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.10)
	track.custom_minimum_size = Vector2(0, 8)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	return track


func _make_bar_fill(track: ColorRect, fill_color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.name = "ProgressFill"
	fill.color = fill_color
	fill.custom_minimum_size = Vector2(0, 8)
	fill.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(fill)
	fill.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	fill.offset_right = track.size.x
	return fill


func _set_bar_fill(fill: ColorRect, track: ColorRect, ratio: float) -> void:
	var clamped := clampf(ratio, 0.0, 1.0)
	fill.anchor_left = 0.0
	fill.anchor_top = 0.0
	fill.anchor_bottom = 1.0
	fill.anchor_right = clamped
	fill.offset_left = 0.0
	fill.offset_top = 0.0
	fill.offset_bottom = 0.0
	fill.offset_right = 0.0
	if track != null:
		track.custom_minimum_size.y = 8
	if fill != null:
		fill.color = fill.color if ratio > 0.001 else Color(fill.color, 0.0)


func _apply_styles() -> void:
	var hud_font := ThemeTokensLib.FONT_SIZE_HUD
	chain_sum_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_CHAIN_BUBBLE)
	message_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	message_label.add_theme_color_override("font_color", ThemeTokensLib.COLOR_MUTED)

	for label in [goal_label, xp_label]:
		label.add_theme_font_size_override("font_size", hud_font)
		label.add_theme_color_override("font_color", _theme_color("get_text_color", ThemeTokensLib.COLOR_TEXT))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	chain_sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", hud_font)
	level_label.add_theme_color_override("font_color", _theme_color("get_text_color", ThemeTokensLib.COLOR_TEXT))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER

	$TopBar.custom_minimum_size.y = ThemeTokensLib.TOUCH_TARGET_MIN

	var panel_style := LnUiLib.hud_panel()
	$GoalRow/GoalPanel.add_theme_stylebox_override("panel", panel_style)
	$XpRow/XpPanel.add_theme_stylebox_override("panel", panel_style)
	bottom_strip.add_theme_stylebox_override("panel", panel_style)

	_style_icon_buttons()
	_style_badges()


func _layout_bonus_badges() -> void:
	for badge in [explosion_badge, shuffle_badge, destroy_badge]:
		badge.set_anchors_preset(Control.PRESET_TOP_LEFT)
		badge.offset_left = -6.0
		badge.offset_top = -6.0
		badge.offset_right = 14.0
		badge.offset_bottom = 14.0
		badge.custom_minimum_size = Vector2(20, 20)
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		badge.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _style_badge(badge: Label, count: int) -> void:
	badge.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_XS)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = ThemeTokensLib.COLOR_ACCENT_ORANGE if count > 0 else Color(ThemeTokensLib.COLOR_PREVIEW_INVALID, 0.65)
	badge_style.set_corner_radius_all(10)
	badge_style.set_content_margin_all(0)
	badge.add_theme_stylebox_override("normal", badge_style)


func _panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _theme_color("get_panel_color", ThemeTokensLib.COLOR_PANEL)
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_HUD)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(6)
	return style


func _style_icon_buttons() -> void:
	var size := float(ThemeTokensLib.TOUCH_TARGET_MIN)
	var icon_pad := (size - 24.0) * 0.5
	for btn in [menu_button, save_button, sound_button, theme_button]:
		btn.custom_minimum_size = Vector2(size, size)
		btn.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.add_theme_constant_override("icon_max_width", 24)
		btn.add_theme_constant_override("icon_max_height", 24)
		var normal := LnUiLib.make_icon_button()
		normal.content_margin_left = icon_pad
		normal.content_margin_right = icon_pad
		normal.content_margin_top = icon_pad
		normal.content_margin_bottom = icon_pad
		btn.add_theme_stylebox_override("normal", normal)
		var hover := normal.duplicate()
		hover.bg_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.16)
		hover.border_color = ThemeTokensLib.COLOR_SECONDARY
		btn.add_theme_stylebox_override("hover", hover)
		btn.add_theme_stylebox_override("pressed", normal.duplicate())


func _style_badges() -> void:
	pass


func _style_all_badges(state: GameState) -> void:
	_style_badge(explosion_badge, state.get_bonus_count("explosion"))
	_style_badge(shuffle_badge, state.get_bonus_count("shuffle"))
	_style_badge(destroy_badge, state.get_bonus_count("destroy"))


func _load_icons() -> void:
	_set_button_icon(menu_button, LnUiLib.icon_path("home.svg"), false)
	_set_button_icon(save_button, LnUiLib.icon_path("save.svg"), false)
	_set_button_icon(theme_button, LnUiLib.icon_path("theme.svg"), false)
	_set_button_icon(sound_button, LnUiLib.icon_path("sound.svg"), false)
	_configure_bonus_button(explosion_button, LnUiLib.icon_path("bonus.svg"))
	_configure_bonus_button(shuffle_button, LnUiLib.icon_path("reset.svg"))
	_configure_bonus_button(destroy_button, LnUiLib.icon_path("path.svg"))


func _configure_bonus_button(button: Button, path: String) -> void:
	button.icon = null
	if ResourceLoader.exists(path):
		var tex: Texture2D = load(path)
		if tex != null:
			button.icon = tex
	button.custom_minimum_size.y = 56.0
	button.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	button.clip_text = true
	button.expand_icon = true
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", 22)
	button.add_theme_constant_override("icon_max_height", 22)
	button.add_theme_constant_override("h_separation", 0)
	button.add_theme_constant_override("v_separation", 2)


func _set_button_icon(button: Button, path: String, clear_text: bool = true) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true
		if clear_text:
			button.text = ""


func refresh(state: GameState, i18n_t: Callable) -> void:
	_i18n_t = i18n_t
	level_label.text = str(i18n_t.call("level_label", [state.current_level + 1]))

	var target: int = state.get_target()
	var board_max: int = _board_max_value(state)
	goal_label.text = "%s %s/%s" % [
		str(i18n_t.call("goal_full")),
		state.format_value(board_max),
		state.format_value(target),
	]
	if _goal_fill != null and _goal_track != null:
		var goal_ratio := float(board_max) / float(maxi(1, target))
		_set_bar_fill(_goal_fill, _goal_track, goal_ratio)

	xp_label.text = str(i18n_t.call("xp_label", [state.format_value(state.xp)]))
	if _xp_fill != null and _xp_track != null:
		_set_bar_fill(_xp_fill, _xp_track, 1.0)

	shuffle_button.text = str(i18n_t.call("bonus_shuffle"))
	destroy_button.text = str(i18n_t.call("bonus_destroy"))
	explosion_button.text = str(i18n_t.call("bonus_explosion"))
	explosion_badge.text = str(state.get_bonus_count("explosion"))
	shuffle_badge.text = str(state.get_bonus_count("shuffle"))
	destroy_badge.text = str(state.get_bonus_count("destroy"))
	_style_all_badges(state)

	_style_bonus_button(shuffle_button, "shuffle", state.get_bonus_count("shuffle"), state.active_bonus)
	_style_bonus_button(destroy_button, "destroy", state.get_bonus_count("destroy"), state.active_bonus)
	_style_bonus_button(explosion_button, "explosion", state.get_bonus_count("explosion"), state.active_bonus)
	_clear_bonus_button_focus(state.active_bonus)

	save_indicator.text = ""


func update_chain_sum(state: GameState, can_finish: bool, dragging: bool = false) -> void:
	if dragging or state == null or state.selected_path.is_empty():
		_set_chain_sum_idle()
		return

	var numbers := PackedInt32Array()
	for p in state.selected_path:
		numbers.append(state.board.grid[p.x][p.y])
	var total := RulesLib.chain_sum(numbers)
	var is_ok := can_finish and state.selected_path.size() >= 2

	bottom_strip.visible = true
	bottom_strip.add_theme_stylebox_override("panel", LnUiLib.chain_sum_panel(is_ok))
	chain_sum_label.text = state.format_value(total)
	chain_sum_label.add_theme_color_override("font_color", ThemeTokensLib.COLOR_TEXT)
	chain_sum_label.add_theme_constant_override("outline_size", 2)
	chain_sum_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.55))

	if _i18n_t.is_valid():
		if is_ok:
			message_label.text = str(_i18n_t.call("chain_can_merge"))
		else:
			message_label.text = str(_i18n_t.call("chain_sum_hud"))
	else:
		message_label.text = ""
	message_label.visible = not message_label.text.is_empty()


func _set_chain_sum_idle() -> void:
	bottom_strip.visible = false
	message_label.visible = false
	message_label.text = ""
	chain_sum_label.text = ""


func _board_max_value(state: GameState) -> int:
	var max_val := 0
	for x in state.board.grid_w:
		for y in state.board.grid_h:
			max_val = maxi(max_val, int(state.board.grid[x][y]))
	return max_val


func _style_bonus_button(button: Button, kind: String, count: int, active_bonus: String) -> void:
	var is_active := active_bonus == kind
	var available := count > 0
	button.disabled = not available and not is_active

	var bg: Color
	var border: Color
	if is_active:
		bg = Color(ThemeTokensLib.COLOR_PRIMARY, 0.22)
		border = ThemeTokensLib.COLOR_SECONDARY
	elif available:
		bg = Color(ThemeTokensLib.COLOR_BTN_BG)
		border = ThemeTokensLib.COLOR_BTN_BORDER
	else:
		bg = Color(ThemeTokensLib.COLOR_BG_TERTIARY, 0.45)
		border = Color(ThemeTokensLib.COLOR_PANEL_BORDER, 0.35)

	var normal := LnUiLib.glass_box(14, 2, bg, border)
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	if is_active:
		normal.shadow_color = Color(ThemeTokensLib.COLOR_PRIMARY, 0.45)
		normal.shadow_size = 12
	var hover := normal.duplicate()
	if is_active:
		hover.bg_color = normal.bg_color.lightened(0.08)
	elif available:
		hover.bg_color = LnUiLib.PANEL_HOVER
		hover.border_color = LnUiLib.BORDER_ACTIVE
	var pressed := normal.duplicate()
	if is_active:
		pressed.bg_color = normal.bg_color.darkened(0.08)
	elif available:
		pressed.bg_color = LnUiLib.PANEL_PRESSED
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.10, 0.07, 0.13, 0.58)
	disabled.border_color = Color(0.35, 0.23, 0.39, 0.38)
	disabled.shadow_size = 0
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", normal.duplicate() if is_active else StyleBoxEmpty.new())
	button.add_theme_color_override("font_color", Color.WHITE if is_active else (LnUiLib.TEXT if available else LnUiLib.TEXT_DISABLED))
	button.add_theme_color_override("font_disabled_color", LnUiLib.TEXT_DISABLED)
	button.modulate = Color.WHITE

	if not available:
		_set_button_icon(button, LnUiLib.icon_path("lock.svg"), false)
	elif kind == "shuffle":
		_set_button_icon(button, LnUiLib.icon_path("reset.svg"), false)
	elif kind == "destroy":
		_set_button_icon(button, LnUiLib.icon_path("path.svg"), false)
	elif kind == "explosion":
		_set_button_icon(button, LnUiLib.icon_path("bonus.svg"), false)


func _clear_bonus_button_focus(active_bonus: String) -> void:
	for btn in [shuffle_button, destroy_button, explosion_button]:
		if btn.has_focus() and (active_bonus.is_empty() or btn != _bonus_button_for_type(active_bonus)):
			btn.release_focus()


func _bonus_button_for_type(type: String) -> Button:
	match type:
		"shuffle":
			return shuffle_button
		"destroy":
			return destroy_button
		"explosion":
			return explosion_button
		_:
			return null


func set_message(text: String) -> void:
	message_label.text = text

func set_sound_icon(enabled: bool) -> void:
	if sound_button.icon != null:
		return
	sound_button.text = "🔊" if enabled else "🔇"


func flash_save_indicator(text: String) -> void:
	save_indicator.text = text
	save_indicator.visible = true
	save_indicator.modulate.a = 1.0
	if _save_flash_tween != null and _save_flash_tween.is_valid():
		_save_flash_tween.kill()
	_save_flash_tween = create_tween()
	_save_flash_tween.tween_interval(1.2)
	_save_flash_tween.tween_property(save_indicator, "modulate:a", 0.0, 0.35)
	_save_flash_tween.tween_callback(func(): save_indicator.visible = false)
