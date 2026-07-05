extends Control

## App shell: owns the persistent BackgroundLayer, the screen mount point and
## overlay layers. Registers ScreenRouter and handles the Android back button.

const MODAL_SCALE_TIME := 0.18

@onready var screen_root: Control = $ScreenRoot
@onready var toast_layer: Control = $OverlayRoot/ToastLayer
@onready var modal_layer: Control = $OverlayRoot/ModalLayer
@onready var transition: Control = $OverlayRoot/TransitionLayer/ScreenTransition


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	get_tree().set_auto_accept_quit(true)
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("register"):
		router.call("register", screen_root, transition)
		router.call("replace", "main_menu")


func _exit_tree() -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("unregister"):
		router.call("unregister")


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_GO_BACK_REQUEST:
		_handle_android_back()


func _handle_android_back() -> void:
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().quit()
		return
	var handled: bool = await router.go_back()
	if not handled:
		get_tree().quit()


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
