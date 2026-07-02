extends Control

@onready var list: VBoxContainer = $Scroll/List
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Title
@onready var background: ColorRect = $Background

var _state: GameState


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _ready() -> void:
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = theme.call("get_background_color")

	title_label.text = _i18n("daily_title")
	back_button.text = _i18n("menu_back")
	back_button.pressed.connect(_on_back)
	_state = _load_state()
	_render()


func _render() -> void:
	for child in list.get_children():
		child.queue_free()

	var daily := DailyQuestManager.new(_state)
	daily.ensure_loaded()
	for quest in daily.get_quests():
		var row := HBoxContainer.new()
		var done := daily.is_done(str(quest.get("id", "")))
		var status := Label.new()
		status.text = "✓" if done else "○"
		var text := Label.new()
		text.text = _i18n(str(quest.get("text_key", "")))
		row.add_child(status)
		row.add_child(text)
		list.add_child(row)


func _load_state() -> GameState:
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var loaded = save.call("load_game")
		if loaded != null:
			return loaded
	var state := GameState.new()
	state.start_new_game()
	return state


func _on_back() -> void:
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
