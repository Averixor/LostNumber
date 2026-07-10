extends Control

## App shell: owns the persistent BackgroundLayer, the screen mount point and
## overlay layers. Registers ScreenRouter and handles the Android back button.

const MODAL_SCALE_TIME := 0.18
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var screen_root: Control = $ScreenRoot
@onready var toast_layer: Control = $OverlayRoot/ToastLayer
@onready var modal_layer: Control = $OverlayRoot/ModalLayer
@onready var transition: Control = $OverlayRoot/TransitionLayer/ScreenTransition

var _exit_dialog: ConfirmationDialog = null
var _back_busy := false


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	get_tree().set_auto_accept_quit(false)
	_apply_fullscreen()
	var theme_mgr := _autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(_on_theme_changed)
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("register"):
		router.call("register", screen_root, transition)
		router.call("replace", "main_menu")


func _apply_fullscreen() -> void:
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)


func _on_theme_changed() -> void:
	_refresh_current_screen_background()


func _refresh_current_screen_background() -> void:
	var router := _autoload("ScreenRouter")
	if router == null or not router.has_method("is_registered") or not bool(router.call("is_registered")):
		return
	var screen_id: String = str(router.get("current_screen_id"))
	if screen_id.is_empty() or screen_id == "skin_preview":
		return
	var screen: Node = router.get_current_screen()
	if screen == null or not (screen is Control):
		return
	LnUiLib.set_background(screen as Control, LnUiLib.screen_bg(screen_id))
	if screen.has_method("_apply_theme"):
		screen.call("_apply_theme")
	elif screen.has_method("_apply_background"):
		screen.call("_apply_background")


func _exit_tree() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("unregister"):
		router.call("unregister")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		call_deferred("_handle_android_back_async")


func _handle_android_back_async() -> void:
	if _back_busy:
		return
	_back_busy = true
	await _handle_android_back()
	_back_busy = false


func _handle_android_back() -> void:
	if _exit_dialog != null and is_instance_valid(_exit_dialog) and _exit_dialog.visible:
		_exit_dialog.hide()
		get_viewport().set_input_as_handled()
		return

	var router := _autoload("ScreenRouter")
	if router == null:
		_show_exit_confirm()
		get_viewport().set_input_as_handled()
		return

	var screen_id: String = str(router.get("current_screen_id"))

	if screen_id == "main_menu":
		_show_exit_confirm()
		get_viewport().set_input_as_handled()
		return

	if screen_id == "game":
		var screen: Node = router.get_current_screen()
		if screen != null and screen.has_method("handle_back"):
			screen.call("handle_back")
		get_viewport().set_input_as_handled()
		return

	var handled: bool = await router.go_back()
	if not handled:
		await router.replace("main_menu")
	get_viewport().set_input_as_handled()


func _show_exit_confirm() -> void:
	if _exit_dialog != null and is_instance_valid(_exit_dialog):
		_exit_dialog.popup_centered()
		return

	_exit_dialog = ConfirmationDialog.new()
	_exit_dialog.title = _i18n("exit_confirm_title")
	_exit_dialog.dialog_text = _i18n("exit_confirm_text")
	_exit_dialog.ok_button_text = _i18n("btn_exit")
	_exit_dialog.cancel_button_text = _i18n("menu_back")
	_exit_dialog.confirmed.connect(func(): get_tree().quit())
	add_child(_exit_dialog)
	_exit_dialog.popup_centered()


## Presents a modal control in ModalLayer with a scale-in (web parity: overlays).
func show_modal(modal: Control) -> void:
	modal_layer.add_child(modal)
	modal.pivot_offset = modal.size / 2.0
	modal.scale = Vector2.ONE * 0.9
	modal.modulate.a = 0.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal, "scale", Vector2.ONE, MODAL_SCALE_TIME) \
		.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tween.tween_property(modal, "modulate:a", 1.0, MODAL_SCALE_TIME)


func hide_modal(modal: Control) -> void:
	if modal == null or not is_instance_valid(modal):
		return
	var tween := create_tween().set_parallel(true)
	tween.tween_property(modal, "scale", Vector2.ONE * 0.92, MODAL_SCALE_TIME * 0.7)
	tween.tween_property(modal, "modulate:a", 0.0, MODAL_SCALE_TIME * 0.7)
	tween.chain().tween_callback(modal.queue_free)
