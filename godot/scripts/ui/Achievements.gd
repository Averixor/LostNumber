extends Control

const AchievementCardScene := preload("res://scenes/components/AchievementCard.tscn")
const NeonButtonScene := preload("res://scenes/components/NeonButton.tscn")

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var list: VBoxContainer = $Scroll/List
@onready var back_button: NeonButton = $BackButton
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


func _navigate_back() -> void:
	var router := _autoload("ScreenRouter")
	if router == null:
		get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
		return
	var handled: bool = await router.go_back()
	if not handled:
		router.call("replace", "main_menu")


func _ready() -> void:
	LnUiLib.set_background(self, LnUiLib.screen_bg("achievements"))
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("achievements_title")
	back_button.text = _i18n("menu_back")
	LnUiLib.apply_title(title_label, 26)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button_icon(back_button, "back.png")
	back_button.pressed.connect(_on_back)
	_render()
	_animate_entrance()


func _animate_entrance() -> void:
	var items: Array = [title_label]
	for child in list.get_children():
		items.append(child)
	items.append(back_button)
	await LnUiLib.animate_entrance(items)


func _render() -> void:
	for child in list.get_children():
		child.queue_free()

	var progress := _load_progress()
	var locked_text := _i18n("achievement_locked")

	for key in progress.achievements.keys():
		var item: Dictionary = progress.achievements[key]
		var card = AchievementCardScene.instantiate()
		list.add_child(card)
		if card != null and card.has_method("setup"):
			var title := _achievement_name(key)
			var unlocked := bool(item.get("unlocked", false))
			card.call(
				"setup",
				unlocked,
				title,
				int(item.get("progress", 0)),
				int(item.get("max", 1)),
				"✓",
				locked_text
			)

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
