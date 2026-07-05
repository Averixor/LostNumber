extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

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
	LnUiLib.set_background(self, "res://assets/ui/backgrounds/dark/menu-bg-4.png", 0.66)
	if background != null:
		background.color = Color(0, 0, 0, 0)
	LnUiLib.apply_title(title_label, 34)
	LnUiLib.apply_body(cost_label, 16)
	LnUiLib.apply_button(spin_button)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button(result_close, false)
	title_label.text = "Колесо фортуни"
	back_button.text = "Назад"
	result_close.text = "Закрити"
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
	LnUiLib.fade_in($VBox)

func _refresh_ui() -> void:
	var cost := _wheel.get_cost()
	var can := _wheel.can_spin()
	spin_button.text = "Обернути %d XP" % cost if can.ok else "Недостатньо XP"
	spin_button.disabled = not can.ok or wheel_canvas.is_spinning()
	cost_label.text = "Спроб сьогодні: %d/%d" % [_state.wheel_spins_today, WheelManager.MAX_DAILY_SPINS]

func _on_spin() -> void:
	_play_sfx("button_click")
	var prep := _wheel.prepare_spin()
	if not prep.ok:
		_show_result("Недостатньо XP")
		_refresh_ui()
		return
	_play_sfx("wheel_spin")
	spin_button.disabled = true
	await wheel_canvas.animate_to_sector(int(prep.index), WheelManager.SPIN_DURATION_SEC)

func _on_spin_animation_done(sector: Dictionary, _index: int) -> void:
	_wheel.finish_spin(sector)
	_daily.on_wheel_spun()
	_play_sfx("wheel_reward")
	_show_result("Виграш: %s" % str(sector.get("label", "")))
	var save := _autoload("SaveManager")
	if save != null and save.has_method("save_game"):
		save.call("save_game", _state)
	_refresh_ui()

func _style_result_modal() -> void:
	if result_dim != null:
		result_dim.color = Color(0, 0, 0, 0.58)
	LnUiLib.apply_panel(result_card, true)
	LnUiLib.apply_body(result_label, 20)

func _show_result(text: String) -> void:
	result_label.text = text
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
