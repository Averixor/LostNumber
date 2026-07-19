extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var wheel_canvas: WheelCanvas = $Layout/VBox/WheelCanvas
@onready var spin_button: NeonButton = $Layout/VBox/SpinButton
@onready var cost_label: Label = $Layout/VBox/CostLabel
@onready var back_button: NeonButton = $Layout/VBox/BackButton
@onready var title_label: Label = $Layout/VBox/Title
@onready var result_panel: PanelContainer = $ResultModal
@onready var result_dim: ColorRect = $ResultModal/Dim
@onready var result_card: PanelContainer = $ResultModal/Center/ResultCard
@onready var result_label: Label = $ResultModal/Center/ResultCard/VBox/ResultLabel
@onready var result_close: NeonButton = $ResultModal/Center/ResultCard/VBox/CloseButton
@onready var background: ColorRect = $Background

var _state: GameState
var _wheel: WheelManager
var _daily: DailyQuestManager
var _invalid_session := false

func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)

func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key

func _play_sfx(name: String) -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", name)

func _navigate_back() -> void:
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")

func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("wheel"))
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("wheel_title")
	LnUiLib.apply_title(title_label, ThemeTokensLib.FONT_SIZE_TITLE)
	back_button.text = _i18n("menu_back")
	result_close.text = _i18n("btn_close")
	result_panel.visible = false
	_style_result_modal()
	spin_button.pressed.connect(_on_spin)
	back_button.pressed.connect(_on_back)
	result_close.pressed.connect(_hide_result)
	wheel_canvas.spin_finished.connect(_on_spin_animation_done)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button_icon(back_button, "back.png")
	LnUiLib.apply_button_icon(result_close, "back.png")

	_state = _load_state()
	if _state == null:
		_invalid_session = true
		_disable_invalid_session()
		if not bool(get_meta("suppress_invalid_session_navigation", false)):
			call_deferred("_leave_invalid_session")
		return
	_wheel = WheelManager.new(_state)
	_daily = DailyQuestManager.new(_state)
	_daily.ensure_loaded()
	_refresh_ui()
	_animate_entrance()


func _animate_entrance() -> void:
	await LnUiLib.animate_entrance([title_label, wheel_canvas, spin_button, cost_label, back_button])


func _refresh_ui() -> void:
	if _invalid_session or _state == null or _wheel == null:
		_disable_invalid_session()
		return
	cost_label.add_theme_color_override("font_color", LnUiLib.TEXT_MUTED)
	cost_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_SMALL)
	var cost := _wheel.get_cost()
	var check := _wheel.can_spin()
	spin_button.disabled = not check.ok or wheel_canvas.is_spinning()
	if not check.ok:
		spin_button.text = _wheel_error_text(str(check.get("reason", "")))
	else:
		spin_button.text = _i18n("btn_spin_wheel", [cost])
	LnUiLib.apply_wheel_button_icon(spin_button, "wheel-xp-25.png", 32)
	LnUiLib.apply_button(spin_button, spin_button.disabled)
	_style_action_buttons()
	cost_label.text = _i18n("wheel_daily_limit", [_state.wheel_spins_today, WheelManager.MAX_DAILY_SPINS])


func _style_action_buttons() -> void:
	pass


func _on_spin() -> void:
	_play_sfx("button_click")
	if _invalid_session or _wheel == null:
		_show_message(_i18n("wheel_no_save"))
		return
	var prep := _wheel.prepare_spin()
	if not prep.ok:
		_show_message(_wheel_error_text(str(prep.get("reason", ""))))
		_refresh_ui()
		return
	_play_sfx("wheel_spin")
	spin_button.disabled = true
	spin_button.text = _i18n("wheel_spinning")
	LnUiLib.apply_button(spin_button, true)
	_style_action_buttons()
	await wheel_canvas.animate_to_sector(int(prep.index), WheelManager.SPIN_DURATION_SEC)

func _on_spin_animation_done(sector: Dictionary, _index: int) -> void:
	if _invalid_session or _state == null or _wheel == null or _daily == null:
		return
	_wheel.finish_spin(sector)
	_daily.on_wheel_spun()
	_play_sfx("wheel_reward")
	_show_result(_sector_label(sector))
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		var saved := bool(save.call("save_game", _state))
		if not saved:
			push_warning("Wheel: failed to save wheel result")
	_refresh_ui()

func _style_result_modal() -> void:
	if result_dim != null:
		result_dim.color = LnUiLib.DIM_DARK
	if result_card == null:
		return
	var style := LnUiLib.glass_box(ThemeTokensLib.RADIUS_PANEL, 2, LnUiLib.PANEL, LnUiLib.BORDER_ACTIVE)
	style.shadow_color = Color(LnUiLib.ACCENT_2, 0.42)
	style.shadow_size = 18
	style.set_content_margin_all(20)
	result_card.add_theme_stylebox_override("panel", style)
	result_label.add_theme_color_override("font_color", LnUiLib.TEXT)
	result_label.add_theme_font_size_override("font_size", ThemeTokensLib.FONT_SIZE_BODY)
	LnUiLib.apply_button(result_close)


func _show_result(text: String) -> void:
	var prize := text.strip_edges()
	var bonus_prefix := _i18n("wheel_result_bonus_prefix")
	if bonus_prefix != "wheel_result_bonus_prefix" and prize.begins_with(bonus_prefix):
		prize = prize.substr(bonus_prefix.length()).strip_edges()
	var win_prefix := _i18n("wheel_win_prefix")
	if win_prefix == "wheel_win_prefix":
		win_prefix = ""
	result_label.text = ("%s %s" % [win_prefix, prize]).strip_edges() if not prize.is_empty() else text
	result_label.add_theme_color_override("font_color", LnUiLib.ACCENT if not prize.is_empty() else LnUiLib.TEXT)
	result_panel.visible = true
	result_card.scale = Vector2(0.92, 0.92)
	result_card.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(result_card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_card, "modulate:a", 1.0, 0.16)

func _show_message(text: String) -> void:
	result_label.text = text
	result_label.add_theme_color_override("font_color", LnUiLib.TEXT)
	result_panel.visible = true
	result_card.scale = Vector2(0.92, 0.92)
	result_card.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(result_card, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_card, "modulate:a", 1.0, 0.16)

func _hide_result() -> void:
	_play_sfx("button_click")
	result_panel.visible = false

func _load_state() -> GameState:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var loaded = save.call("load_game")
		if loaded != null:
			return loaded
	return null

func _disable_invalid_session() -> void:
	if spin_button != null:
		spin_button.disabled = true
		spin_button.text = _i18n("wheel_no_save")
		LnUiLib.apply_button(spin_button, true)
		_style_action_buttons()
	if cost_label != null:
		cost_label.text = _i18n("wheel_no_save_hint")

func _leave_invalid_session() -> void:
	if not is_inside_tree():
		return
	_navigate_back()

func _wheel_error_text(reason: String) -> String:
	match reason:
		"spinning":
			return _i18n("wheel_error_spinning")
		"limit":
			return _i18n("wheel_error_limit")
		"not_enough_xp":
			return _i18n("wheel_error_not_enough_xp")
		_:
			return _i18n("wheel_error_generic")

func _sector_label(sector: Dictionary) -> String:
	var key := str(sector.get("label_key", ""))
	if not key.is_empty():
		var translated := _i18n(key)
		if translated != key:
			return translated
	return str(sector.get("label", ""))

func _on_back() -> void:
	var save := _autoload("SaveManager")
	if _state != null and save != null and save.has_method("save_game"):
		var saved := bool(save.call("save_game", _state))
		if not saved:
			push_warning("Wheel: failed to save before leaving")
	_play_sfx("button_click")
	_navigate_back()
