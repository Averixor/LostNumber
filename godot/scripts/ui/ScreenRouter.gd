extends Node

## Autoload: screen navigation with back-stack and fade transitions.
## App.tscn registers its ScreenRoot/TransitionLayer via register().
## Screens never call get_tree().change_scene_to_file directly — they use
## push()/replace()/go_back(). When the App shell is not mounted (a scene is
## run standalone via F6), navigation falls back to change_scene_to_file.

signal screen_changed(screen_id: String)
signal transition_finished

const SCREENS := {
	"main_menu": "res://scenes/MainMenu.tscn",
	"game": "res://scenes/Game.tscn",
	"settings": "res://scenes/Settings.tscn",
	"achievements": "res://scenes/Achievements.tscn",
	"daily": "res://scenes/DailyQuests.tscn",
	"wheel": "res://scenes/Wheel.tscn",
	"stats": "res://scenes/Stats.tscn",
	"about": "res://scenes/About.tscn",
	"skin_preview": "res://scenes/SkinPreview.tscn",
	"background_preview": "res://scenes/BackgroundPreview.tscn",
}

const FADE_DURATION := 0.18

var current_screen_id: String = ""
var use_slide_transition: bool = true

var _screen_root: Control = null
var _transition: Node = null
var _back_stack: Array[String] = []
var _busy := false
var _pending_action := ""


func register(screen_root: Control, transition: Node) -> void:
	_screen_root = screen_root
	_transition = transition
	_back_stack.clear()
	current_screen_id = ""
	_pending_action = ""
	_busy = false


func unregister() -> void:
	_screen_root = null
	_transition = null
	_back_stack.clear()
	current_screen_id = ""
	_pending_action = ""
	_busy = false


func is_registered() -> bool:
	return _screen_root != null and is_instance_valid(_screen_root)


func get_current_screen() -> Node:
	if not is_registered() or _screen_root.get_child_count() == 0:
		return null
	return _screen_root.get_child(0)


## Navigation requests made while a transition is in flight are queued
## (single-slot, last writer wins). Awaiters wait until the full chain —
## current swap plus any queued action — finishes.
func push(screen_id: String) -> void:
	if not SCREENS.has(screen_id):
		return
	if _busy:
		_pending_action = "push:" + screen_id
		await wait_until_idle()
		return
	if not is_registered():
		_fallback_change(screen_id)
		return
	if not current_screen_id.is_empty():
		_back_stack.append(current_screen_id)
	await _swap(screen_id)


func replace(screen_id: String) -> void:
	if not SCREENS.has(screen_id):
		return
	if _busy:
		_pending_action = "replace:" + screen_id
		await wait_until_idle()
		return
	if not is_registered():
		_fallback_change(screen_id)
		return
	await _swap(screen_id)


func reload_current() -> void:
	if current_screen_id.is_empty() or not is_registered():
		return
	if _busy:
		_pending_action = "reload"
		await wait_until_idle()
		return
	await _swap(current_screen_id)


## Pops the back-stack. Returns false when there is nothing to go back to
## (caller decides what to do, e.g. quit on Android back from main menu).
func can_go_back() -> bool:
	return not _back_stack.is_empty()


func go_back() -> bool:
	if _busy:
		# Queue only if the stack can actually satisfy the back later.
		# Otherwise report false now so the Android back handler can quit.
		if _back_stack.is_empty():
			return false
		_pending_action = "back"
		await wait_until_idle()
		return true
	if not is_registered() or _back_stack.is_empty():
		return false
	var screen_id: String = _back_stack.pop_back()
	await _swap(screen_id)
	return true


func wait_until_idle() -> void:
	while _busy:
		await transition_finished


func _swap(screen_id: String) -> void:
	_busy = true
	await _run_transition(screen_id)
	## Обробити чергу, поки ще «в навігації», щоб await wait_until_idle
	## не прокидався між swap і flush.
	while not _pending_action.is_empty():
		var action := _pending_action
		_pending_action = ""
		await _apply_queued_action(action)
	_busy = false
	transition_finished.emit()


func _apply_queued_action(action: String) -> void:
	if action == "back":
		if _back_stack.is_empty():
			if current_screen_id != "main_menu" and not current_screen_id.is_empty():
				await _run_transition("main_menu")
			return
		var screen_id: String = _back_stack.pop_back()
		await _run_transition(screen_id)
		return
	if action == "reload":
		if not current_screen_id.is_empty():
			await _run_transition(current_screen_id)
		return
	if action.begins_with("push:"):
		var push_id := action.substr(5)
		if not SCREENS.has(push_id):
			return
		if not current_screen_id.is_empty():
			_back_stack.append(current_screen_id)
		await _run_transition(push_id)
		return
	if action.begins_with("replace:"):
		var replace_id := action.substr(8)
		if not SCREENS.has(replace_id):
			return
		await _run_transition(replace_id)


func _run_transition(screen_id: String) -> void:
	var slide := use_slide_transition and _effects_enabled()
	if _transition != null and _transition.has_method("cover"):
		await _transition.call("cover", FADE_DURATION, slide)

	for child in _screen_root.get_children():
		child.queue_free()

	var packed: PackedScene = load(SCREENS[screen_id])
	if packed != null:
		var screen: Node = packed.instantiate()
		_screen_root.add_child(screen)
	current_screen_id = screen_id
	screen_changed.emit(screen_id)

	if _transition != null and _transition.has_method("uncover"):
		await _transition.call("uncover", FADE_DURATION, slide)


func _effects_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return true
	return bool(settings.get("bg_effects_enabled"))


func _fallback_change(screen_id: String) -> void:
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(SCREENS[screen_id])
