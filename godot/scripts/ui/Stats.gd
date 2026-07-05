extends Control

@onready var list: VBoxContainer = $Scroll/List
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Title
@onready var background: ColorRect = $Background


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


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

	title_label.text = _i18n("btn_stats")
	back_button.text = _i18n("menu_back")
	back_button.pressed.connect(_on_back)
	_render()


func _render() -> void:
	for child in list.get_children():
		child.queue_free()

	var progress := _load_progress()
	var stats: Dictionary = progress.stats
	var rows := [
		["stat_games_played", int(stats.get("games_played", 0))],
		["stat_levels_completed", int(stats.get("levels_completed", 0))],
		["stat_highest_level", int(stats.get("highest_level", 0))],
		["stat_total_xp", int(stats.get("total_xp", 0))],
		["stat_longest_chain", int(stats.get("longest_chain", 0))],
		["stat_wheel_spins", int(stats.get("wheel_spins", 0))],
	]
	for row in rows:
		var label := Label.new()
		var key: String = str(row[0])
		var val: int = int(row[1])
		label.text = "%s: %d" % [_i18n(key) if _has_i18n(key) else key, val]
		list.add_child(label)


func _has_i18n(key: String) -> bool:
	var t := _i18n(key)
	return t != key


func _load_progress() -> PlayerProgress:
	var progress := PlayerProgress.new()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var state = save.call("load_game")
		if state != null:
			return state.progress
	return progress


func _on_back() -> void:
	var audio := _autoload("AudioManager")
	if audio != null:
		audio.call("play_sfx", "button_click")
	_navigate_back()
