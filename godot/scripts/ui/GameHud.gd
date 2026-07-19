extends Control
class_name GameHud

## In-game HUD: top bar, goal/XP labels, bonus row, bottom chain strip.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const RulesLib := preload("res://scripts/core/Rules.gd")

const BONUS_WHEEL_ICONS := {
	"explosion": "wheel-explosion.png",
	"shuffle": "wheel-shuffle.png",
	"destroy": "wheel-break.png",
}
const BONUS_ICON_SIZE := 22
signal menu_pressed
signal sound_pressed
signal save_pressed
signal theme_pressed
signal bonus_pressed(type: String)

@onready var level_label: Label = $TopBar/BarRow/LevelLabel
@onready var save_indicator: Label = $TopBar/SaveToast
@onready var menu_button: Button = $TopBar/BarRow/MenuButton
@onready var save_button: Button = $TopBar/BarRow/RightCluster/SaveButton
@onready var theme_button: Button = $TopBar/BarRow/RightCluster/ThemeButton
@onready var sound_button: Button = $TopBar/BarRow/RightCluster/SoundButton
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
var _last_state: GameState = null

func _ready() -> void:
	bottom_strip.visible = false
	message_label.visible = false
	_center_level_label()
	_ensure_progress_bars()
	menu_button.pressed.connect(func(): menu_pressed.emit())
	sound_button.pressed.connect(func(): sound_pressed.emit())
	save_button.pressed.connect(func(): save_pressed.emit())
	# Dark-only release: hide brightness cycle (cycle_theme is a dusk no-op).
	if theme_button != null:
		theme_button.visible = false
		theme_button.disabled = true
		theme_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shuffle_button.pressed.connect(func(): bonus_pressed.emit("shuffle"))
	destroy_button.pressed.connect(func(): bonus_pressed.emit("destroy"))
	explosion_button.pressed.connect(func(): bonus_pressed.emit("explosion"))
	_apply_styles()
	_load_icons()
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_signal("theme_changed"):
		theme.theme_changed.connect(_apply_styles)


func _center_level_label() -> void:
	# The left and right button clusters have different widths. Keep the level
	# title on the TopBar overlay so it is centered on the viewport, not the HBox.
	var top_bar := $TopBar as Control
	if level_label.get_parent() != top_bar:
		level_label.reparent(top_bar)
	level_label.set_anchors_preset(Control.PRESET_CENTER)
	level_label.offset_left = -72.0
	level_label.offset_top = -24.0
	level_label.offset_right = 72.0
	level_label.offset_bottom = 24.0
	level_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	level_label.z_index = 2


func _theme_color(method: String, fallback: Color) -> Color:
	var theme := get_node_or_null("/root/ThemeManager")
	if theme != null and theme.has_method(method):
		return theme.call(method, true)
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
	track.custom_minimum_size = Vector2(0, 6)
	track.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(track)
	return track


func _make_bar_fill(track: ColorRect, fill_color: Color) -> ColorRect:
	var fill := ColorRect.new()
	fill.name = "ProgressFill"
	fill.color = fill_color
	fill.custom_minimum_size = Vector2(0, 6)
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
		track.custom_minimum_size.y = 6
	if fill != null:
		fill.color = fill.color if ratio > 0.001 else Color(fill.color, 0.0)


func _apply_styles() -> void:
	var hud_font := 13
	chain_sum_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_CHAIN_BUBBLE)
	message_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	message_label.add_theme_color_override("font_color", ThemeTokensLib.COLOR_MUTED)

	for label in [goal_label, xp_label]:
		label.add_theme_font_size_override("font_size", hud_font)
		label.add_theme_color_override("font_color", _theme_color("get_text_color", ThemeTokensLib.COLOR_TEXT))
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", Color(0.04, 0.03, 0.05, 0.72))

	chain_sum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	level_label.add_theme_font_size_override("font_size", 15)
	level_label.add_theme_color_override("font_color", _theme_color("get_secondary_color", Color("#c29a63")))
	level_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var panel_style := LnUiLib.hud_panel(true)
	$GoalRow/GoalPanel.add_theme_stylebox_override("panel", panel_style.duplicate(true))
	$XpRow/XpPanel.add_theme_stylebox_override("panel", panel_style.duplicate(true))
	bottom_strip.add_theme_stylebox_override("panel", panel_style.duplicate(true))
	if _goal_track != null:
		_goal_track.color = Color(_theme_color("get_primary_color", ThemeTokensLib.COLOR_PRIMARY), 0.13)
	if _goal_fill != null:
		_goal_fill.color = _theme_color("get_secondary_color", Color("#c29a63"))
	if _xp_track != null:
		_xp_track.color = Color(_theme_color("get_primary_color", ThemeTokensLib.COLOR_PRIMARY), 0.13)
	if _xp_fill != null:
		_xp_fill.color = _theme_color("get_primary_color", ThemeTokensLib.COLOR_PRIMARY)

	_style_icon_buttons()
	_style_badges()
	_load_icons()
	if _last_state != null:
		_style_all_badges(_last_state)
		_style_bonus_button(shuffle_button, "shuffle", _last_state.get_bonus_count("shuffle"), _last_state.active_bonus)
		_style_bonus_button(destroy_button, "destroy", _last_state.get_bonus_count("destroy"), _last_state.active_bonus)
		_style_bonus_button(explosion_button, "explosion", _last_state.get_bonus_count("explosion"), _last_state.active_bonus)


func _style_badge(badge: Label, count: int) -> void:
	badge.add_theme_font_size_override("font_size", 9)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = Color("#8a683e") if count > 0 else Color("#5c4450")
	badge_style.border_color = Color("#d3ad70") if count > 0 else Color("#80626b")
	badge_style.set_border_width_all(1)
	badge_style.set_corner_radius_all(8)
	badge_style.set_content_margin_all(1)
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
	for btn in [menu_button, save_button, sound_button]:
		btn.custom_minimum_size = Vector2.ONE * ThemeTokensLib.TOUCH_TARGET_MIN
		btn.focus_mode = Control.FOCUS_NONE
		btn.text = ""
		btn.expand_icon = true
		btn.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		btn.alignment = HORIZONTAL_ALIGNMENT_CENTER
		btn.add_theme_constant_override("icon_max_width", 22)
		btn.add_theme_constant_override("icon_max_height", 22)
		btn.add_theme_color_override("icon_normal_color", Color.WHITE)
		btn.add_theme_color_override("icon_hover_color", Color(1.08, 1.08, 1.08, 1.0))
		btn.add_theme_color_override("icon_pressed_color", Color(0.82, 0.82, 0.82, 1.0))
		btn.add_theme_color_override("icon_disabled_color", Color(1, 1, 1, 0.42))
		var normal := LnUiLib.make_icon_button(true)
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", LnUiLib.button_hover(true))
		btn.add_theme_stylebox_override("pressed", LnUiLib.button_pressed(true))
		btn.add_theme_stylebox_override("disabled", LnUiLib.button_disabled(true))
		btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	if theme_button != null:
		theme_button.visible = false
		theme_button.disabled = true
		theme_button.mouse_filter = Control.MOUSE_FILTER_IGNORE
		theme_button.icon = null
		theme_button.text = ""


func _style_badges() -> void:
	pass


func _style_all_badges(state: GameState) -> void:
	_style_badge(explosion_badge, state.get_bonus_count("explosion"))
	_style_badge(shuffle_badge, state.get_bonus_count("shuffle"))
	_style_badge(destroy_badge, state.get_bonus_count("destroy"))


func _load_icons() -> void:
	LnUiLib.apply_button_icon(menu_button, "pause.png")
	LnUiLib.apply_button_icon(save_button, "save.png")
	LnUiLib.apply_button_icon(sound_button, "sound.png")
	for kind in BONUS_WHEEL_ICONS:
		var btn := _bonus_button_for_type(kind)
		if btn != null:
			_apply_bonus_wheel_icon(btn, kind)


func _configure_bonus_button(button: Button, kind: String) -> void:
	_apply_bonus_wheel_icon(button, kind)


func _apply_bonus_wheel_icon(button: Button, kind: String) -> void:
	var file_name: String = BONUS_WHEEL_ICONS.get(kind, "")
	if file_name.is_empty():
		button.icon = null
		button.expand_icon = false
		return
	var tex := LnUiLib.load_wheel_icon(file_name)
	if tex == null:
		button.icon = null
		button.expand_icon = false
		return
	button.icon = tex
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
	button.alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.add_theme_constant_override("icon_max_width", BONUS_ICON_SIZE)
	button.add_theme_constant_override("icon_max_height", BONUS_ICON_SIZE)


func refresh(state: GameState, i18n_t: Callable) -> void:
	_last_state = state
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
	save_indicator.modulate.a = 0.0


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

	var normal := LnUiLib.make_booster_button(is_active, available, true)
	normal.content_margin_left = 5
	normal.content_margin_right = 6
	normal.content_margin_top = 4
	normal.content_margin_bottom = 4
	var hover := LnUiLib.button_hover(true)
	var pressed := LnUiLib.button_pressed(true)
	var disabled := LnUiLib.button_disabled(true)
	for style in [hover, pressed, disabled]:
		style.content_margin_left = 5
		style.content_margin_right = 6
		style.content_margin_top = 4
		style.content_margin_bottom = 4
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_stylebox_override("focus", normal.duplicate() if is_active else StyleBoxEmpty.new())
	button.add_theme_font_size_override("font_size", 11)
	button.add_theme_color_override("font_color", Color("#f4e7d3") if is_active or available else LnUiLib.TEXT_DISABLED)
	button.add_theme_color_override("font_disabled_color", LnUiLib.TEXT_DISABLED)
	button.modulate = Color.WHITE

	_apply_bonus_wheel_icon(button, kind)


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
	# Overlay toast — does not participate in TopBarHBox layout.
	save_indicator.text = text
	save_indicator.modulate.a = 1.0
	save_indicator.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	save_indicator.add_theme_color_override("font_color", ThemeTokensLib.COLOR_TEXT)
	save_indicator.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.75))
	save_indicator.add_theme_constant_override("outline_size", 3)
	if _save_flash_tween != null and _save_flash_tween.is_valid():
		_save_flash_tween.kill()
	_save_flash_tween = create_tween()
	_save_flash_tween.tween_interval(1.2)
	_save_flash_tween.tween_property(save_indicator, "modulate:a", 0.0, 0.35)
	_save_flash_tween.tween_callback(func(): save_indicator.text = "")
