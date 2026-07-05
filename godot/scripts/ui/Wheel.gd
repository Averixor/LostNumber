extends Control

const WheelCanvasScript := preload("res://scripts/ui/WheelCanvas.gd")
const NeonButtonScene := preload("res://scenes/components/NeonButton.tscn")

@onready var wheel_canvas: WheelCanvas = $VBox/WheelCanvas
@onready var spin_button: NeonButton = $VBox/SpinButton
@onready var cost_label: Label = $VBox/CostLabel
@onready var back_button: NeonButton = $VBox/BackButton
@onready var title_label: Label = $VBox/Title
@onready var result_panel: PanelContainer = $ResultModal
@onready var result_dim: ColorRect = $ResultModal/Dim
@onready var result_card: PanelContainer = $ResultModal/Center/ResultCard
@onready var result_label: Label = $ResultModal/Center/ResultCard/VBox/ResultLabel
@onready var result_close: NeonButton = $ResultModal/Center/ResultCard/VBox/CloseButton
@onready var background: ColorRect = $Background

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

var _state: GameState
var _wheel: WheelManager
var _daily: DailyQuestManager


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
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("wheel_title")
	back_button.text = _i18n("menu_back")
	result_close.text = _i18n("btn_close")
	result_panel.visible = false
	_style_result_modal()

	spin_button.pressed.connect(_on_spin)
	back_button.pressed.connect(_on_back)
	result_close.pressed.connect(_hide_result)
	wheel_canvas.spin_finished.connect(_on_spin_animation_done)

	_state = _load_state()
	_wheel = WheelManager.new(_state)
	_daily = DailyQuestManager.new(_state)
	_daily.ensure_loaded()
	_refresh_ui()


func _refresh_ui() -> void:
	var cost := _wheel.get_cost()
	spin_button.text = _i18n("btn_spin_wheel", [cost])
	spin_button.disabled = not _wheel.can_spin().ok or wheel_canvas.is_spinning()
	var remaining := WheelManager.MAX_DAILY_SPINS - _state.wheel_spins_today
	cost_label.text = "%s: %d/%d" % [_i18n("wheel_title"), _state.wheel_spins_today, WheelManager.MAX_DAILY_SPINS]


func _on_spin() -> void:
	_play_sfx("button_click")
	var prep := _wheel.prepare_spin()
	if not prep.ok:
		var reason := str(prep.get("reason", ""))
		if reason == "not_enough_xp":
			_show_result(_i18n("dice_not_enough"))
		elif reason == "limit":
			_show_result(_i18n("wheel_limit_reached"))
		_refresh_ui()
		return

	_play_sfx("wheel_spin")
	spin_button.disabled = true
	var idx := int(prep.index)
	await wheel_canvas.animate_to_sector(idx, WheelManager.SPIN_DURATION_SEC)


func _on_spin_animation_done(sector: Dictionary, _index: int) -> void:
	_wheel.finish_spin(sector)
	_daily.on_wheel_spun()
	_play_sfx("wheel_reward")

	var msg_key := str(sector.get("message_key", ""))
	var text := _i18n(msg_key) if not msg_key.is_empty() else str(sector.get("label", ""))
	_show_result(text)

	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", _state)
	_refresh_ui()


func _style_result_modal() -> void:
	if result_dim != null:
		result_dim.color = Color(0, 0, 0, 0.55)
	if result_card == null:
		return
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokensLib.COLOR_PANEL
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_PANEL)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(16)
	result_card.add_theme_stylebox_override("panel", style)


func _show_result(text: String) -> void:
	result_label.text = text
	result_panel.visible = true
	if result_card == null:
		return
	result_card.scale = Vector2(0.92, 0.92)
	result_card.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(result_card, "scale", Vector2.ONE, 0.16) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(result_card, "modulate:a", 1.0, 0.16) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _hide_result() -> void:
	_play_sfx("button_click")
	result_panel.visible = false


func _load_state() -> GameState:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var loaded = save.call("load_game")
		if loaded != null:
			return loaded
	var state := GameState.new()
	state.start_new_game()
	state.xp = 100
	return state


func _on_back() -> void:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", _state)
	_play_sfx("button_click")
	_navigate_back()
