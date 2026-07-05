extends Node

## Autoload: screen navigation with back-stack and fade transitions.
## App.tscn registers its ScreenRoot/TransitionLayer via register().
## Screens never call get_tree().change_scene_to_file directly — they use
## push()/replace()/go_back(). When the App shell is not mounted (a scene is
## run standalone via F6), navigation falls back to change_scene_to_file.

signal screen_changed(screen_id: String)

const SCREENS := {
	"main_menu": "res://scenes/MainMenu.tscn",
	"game": "res://scenes/Game.tscn",
	"settings": "res://scenes/Settings.tscn",
	"achievements": "res://scenes/Achievements.tscn",
	"daily": "res://scenes/DailyQuests.tscn",
	"wheel": "res://scenes/Wheel.tscn",
	"stats": "res://scenes/Stats.tscn",
	"about": "res://scenes/About.tscn",
}

const FADE_DURATION := 0.18

var current_screen_id: String = ""
var use_slide_transition: bool = true

var _screen_root: Control = null
var _transition: Node = null
var _back_stack: Array[String] = []
var _busy := false


func register(screen_root: Control, transition: Node) -> void:
	_screen_root = screen_root
	_transition = transition
	_back_stack.clear()
	current_screen_id = ""


func unregister() -> void:
	_screen_root = null
	_transition = null
	_back_stack.clear()
	current_screen_id = ""


func is_registered() -> bool:
	return _screen_root != null and is_instance_valid(_screen_root)


func push(screen_id: String) -> void:
	if not SCREENS.has(screen_id) or _busy:
		return
	if not is_registered():
		_fallback_change(screen_id)
		return
	if not current_screen_id.is_empty():
		_back_stack.append(current_screen_id)
	await _swap(screen_id)


func replace(screen_id: String) -> void:
	if not SCREENS.has(screen_id) or _busy:
		return
	if not is_registered():
		_fallback_change(screen_id)
		return
	await _swap(screen_id)


func reload_current() -> void:
	if current_screen_id.is_empty() or _busy or not is_registered():
		return
	await _swap(current_screen_id)


## Pops the back-stack. Returns false when there is nothing to go back to
## (caller decides what to do, e.g. quit on Android back from main menu).
func go_back() -> bool:
	if _busy:
		return true
	if not is_registered() or _back_stack.is_empty():
		return false
	var screen_id: String = _back_stack.pop_back()
	await _swap(screen_id)
	return true


func _swap(screen_id: String) -> void:
	_busy = true
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
	_busy = false


func _effects_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return true
	return bool(settings.get("bg_effects_enabled"))


func _fallback_change(screen_id: String) -> void:
	var tree := get_tree()
	if tree != null:
		tree.change_scene_to_file(SCREENS[screen_id])
