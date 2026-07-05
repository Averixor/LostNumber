extends Control

const DailyQuestCardScene := preload("res://scenes/components/DailyQuestCard.tscn")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var list: VBoxContainer = $Scroll/List
@onready var back_button: NeonButton = $BackButton
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
	LnUiLib.apply_title(title_label, 32)
	LnUiLib.apply_button(back_button, false)
	title_label.text = "Щоденні завдання"
	back_button.text = "Назад"
	back_button.pressed.connect(_on_back)
	_state = _load_state()
	_render()
	LnUiLib.fade_in($Scroll)

func _quest_text(quest: Dictionary, idx: int) -> String:
	var key := str(quest.get("text_key", ""))
	var text := _i18n(key) if not key.is_empty() else ""
	if text == key or text.is_empty():
		var fallback := ["З'єднай 10 плиток", "Збери плитку 128", "Використай бонус", "Набери 100 очок", "Заверши одну гру"]
		text = fallback[idx % fallback.size()]
	return text

func _render() -> void:
	for child in list.get_children():
		child.queue_free()
	var daily := DailyQuestManager.new(_state)
	daily.ensure_loaded()
	var done_label := "Отримано"
	var quests := daily.get_quests()
	if quests.is_empty():
		quests = [{}, {}, {}, {}, {}]
	for i in quests.size():
		var quest: Dictionary = quests[i]
		var card: DailyQuestCard = DailyQuestCardScene.instantiate()
		var done := daily.is_done(str(quest.get("id", "")))
		card.setup(done, _quest_text(quest, i), done_label if done else "+25 XP")
		list.add_child(card)

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
	var audio := _autoload("AudioManager")
	if audio != null:
		audio.call("play_sfx", "button_click")
	_navigate_back()
