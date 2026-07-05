extends Control
class_name GameHud

## In-game HUD: top bar, XP/goal/score bars, bonus row, bottom chain strip.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const WheelManagerScript := preload("res://scripts/meta/WheelManager.gd")

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
@onready var goal_bar: ProgressBar = $GoalRow/GoalPanel/GoalHBox/GoalBar
@onready var goal_label: Label = $GoalRow/GoalPanel/GoalHBox/GoalLabel
@onready var xp_bar: ProgressBar = $XpRow/XpPanel/XpHBox/XpBar
@onready var xp_label: Label = $XpRow/XpPanel/XpHBox/XpLabel
@onready var score_label: Label = $ScoreRow/ScoreLabel
@onready var bottom_strip: PanelContainer = $BottomStrip
@onready var chain_sum_label: Label = $BottomStrip/BottomHBox/ChainSumLabel
@onready var message_label: Label = $BottomStrip/BottomHBox/MessageLabel
@onready var shuffle_button: Button = $BonusBar/ShuffleButton
@onready var destroy_button: Button = $BonusBar/DestroyButton
@onready var explosion_button: Button = $BonusBar/ExplosionButton
@onready var explosion_badge: Label = $BonusBar/ExplosionButton/ExplosionBadge
@onready var shuffle_badge: Label = $BonusBar/ShuffleButton/ShuffleBadge
@onready var destroy_badge: Label = $BonusBar/DestroyButton/DestroyBadge

var _save_flash_tween: Tween = null
var _i18n_t: Callable


func _ready() -> void:
	bottom_strip.visible = false
	message_label.visible = false
	menu_button.pressed.connect(func(): menu_pressed.emit())
	sound_button.pressed.connect(func(): sound_pressed.emit())
	save_button.pressed.connect(func(): save_pressed.emit())
	theme_button.pressed.connect(func(): theme_pressed.emit())
	shuffle_button.pressed.connect(func(): bonus_pressed.emit("shuffle"))
	destroy_button.pressed.connect(func(): bonus_pressed.emit("destroy"))
	explosion_button.pressed.connect(func(): bonus_pressed.emit("explosion"))
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


func _apply_styles() -> void:
	for label in [level_label, goal_label, xp_label, score_label, chain_sum_label, message_label]:
		label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
		label.add_theme_color_override("font_color", _theme_color("get_text_color", ThemeTokensLib.COLOR_TEXT))

	var panel_style := LnUiLib.hud_panel()
	$GoalRow/GoalPanel.add_theme_stylebox_override("panel", panel_style)
	$XpRow/XpPanel.add_theme_stylebox_override("panel", panel_style)
	bottom_strip.add_theme_stylebox_override("panel", panel_style)

	var goal_fill := _bar_fill_style(LnUiLib.GOAL)
	var xp_fill := _bar_fill_style(LnUiLib.XP)
	var bar_bg := _bar_bg_style()
	goal_bar.add_theme_stylebox_override("fill", goal_fill)
	goal_bar.add_theme_stylebox_override("background", bar_bg)
	xp_bar.add_theme_stylebox_override("fill", xp_fill)
	xp_bar.add_theme_stylebox_override("background", bar_bg)

	_style_icon_buttons()
	_style_badges()


func _style_badge(badge: Label, count: int) -> void:
	badge.add_theme_font_size_override("font_size", 10)
	badge.add_theme_color_override("font_color", Color.WHITE)
	var badge_style := StyleBoxFlat.new()
	badge_style.bg_color = LnUiLib.ACCENT if count > 0 else Color(LnUiLib.ACCENT_2, 0.55)
	badge_style.set_corner_radius_all(8)
	badge_style.set_content_margin_all(2)
	badge.add_theme_stylebox_override("normal", badge_style)


func _panel_stylebox() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = _theme_color("get_panel_color", ThemeTokensLib.COLOR_PANEL)
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_HUD)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(6)
	return style


func _bar_bg_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(ThemeTokensLib.COLOR_CELL, 0.55)
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_SMALL)
	return style


func _bar_fill_style(color: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_SMALL)
	return style


func _style_icon_buttons() -> void:
	for btn in [menu_button, save_button, sound_button, theme_button]:
		var normal := StyleBoxFlat.new()
		normal.bg_color = Color(ThemeTokensLib.COLOR_BTN_BG, 0.85)
		normal.set_corner_radius_all(18)
		normal.set_border_width_all(1)
		normal.border_color = ThemeTokensLib.COLOR_BTN_BORDER
		btn.add_theme_stylebox_override("normal", normal)
		btn.add_theme_stylebox_override("hover", normal.duplicate())
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
	button.expand_icon = true
	button.icon_alignment = HORIZONTAL_ALIGNMENT_CENTER
	button.vertical_icon_alignment = VERTICAL_ALIGNMENT_TOP
	button.add_theme_constant_override("icon_max_width", 22)
	button.add_theme_constant_override("icon_max_height", 22)


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
	goal_bar.max_value = maxf(float(target), 1.0)
	goal_bar.value = mini(float(board_max), goal_bar.max_value)

	var wheel := WheelManagerScript.new(state)
	var wheel_cost: int = maxi(wheel.get_cost(), 1)
	xp_label.text = "XP %s/%s" % [state.format_value(state.xp), state.format_value(wheel_cost)]
	xp_bar.max_value = float(wheel_cost)
	xp_bar.value = clampf(float(state.xp), 0.0, xp_bar.max_value)

	score_label.text = str(i18n_t.call("score_label", [state.format_value(state.xp)]))

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

	save_indicator.text = ""


func update_chain_sum(state: GameState, can_finish: bool, dragging: bool = false) -> void:
	if dragging or state == null or state.selected_path.is_empty():
		bottom_strip.visible = false
		message_label.visible = false
		message_label.text = ""
		return

	bottom_strip.visible = false
	message_label.visible = false
	message_label.text = ""


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

	var normal := LnUiLib.glass_box(14, 2,
		LnUiLib.PANEL if available or is_active else Color(0.10, 0.07, 0.13, 0.58),
		LnUiLib.BORDER_ACTIVE if is_active else (LnUiLib.BORDER_ACTIVE if available else LnUiLib.BORDER))
	normal.content_margin_left = 8
	normal.content_margin_right = 8
	normal.content_margin_top = 6
	normal.content_margin_bottom = 6
	var hover := normal.duplicate()
	hover.bg_color = LnUiLib.PANEL_HOVER if available else normal.bg_color
	var pressed := normal.duplicate()
	pressed.bg_color = LnUiLib.PANEL_PRESSED if available else normal.bg_color
	var disabled := normal.duplicate()
	disabled.bg_color = Color(0.10, 0.07, 0.13, 0.58)
	disabled.border_color = Color(0.35, 0.23, 0.39, 0.38)
	button.add_theme_stylebox_override("normal", normal)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", pressed)
	button.add_theme_stylebox_override("disabled", disabled)
	button.add_theme_color_override("font_color", LnUiLib.TEXT if available else LnUiLib.TEXT_DISABLED)
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
