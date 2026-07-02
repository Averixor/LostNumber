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


func _achievement_name(key: String) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("achievement_name"):
		return str(i18n.call("achievement_name", key))
	return key


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")

	title_label.text = _i18n("achievements_title")
	back_button.text = _i18n("menu_back")
	back_button.pressed.connect(_on_back)
	_render()


func _render() -> void:
	for child in list.get_children():
		child.queue_free()

	var progress := _load_progress()
	for key in progress.achievements.keys():
		var item: Dictionary = progress.achievements[key]
		var row := HBoxContainer.new()
		var status := Label.new()
		status.text = _i18n("achievement_unlocked") if bool(item.get("unlocked", false)) else _i18n("achievement_locked")
		var name := Label.new()
		name.text = _achievement_name(key)
		var prog := Label.new()
		prog.text = "%d / %d" % [int(item.get("progress", 0)), int(item.get("max", 1))]
		row.add_child(status)
		row.add_child(name)
		row.add_child(prog)
		list.add_child(row)


func _load_progress() -> PlayerProgress:
	var progress := PlayerProgress.new()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var state = save.call("load_game")
		if state != null:
			return state.progress
	return progress


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
