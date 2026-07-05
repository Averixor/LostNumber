extends Control

const DailyQuestCardScene := preload("res://scenes/components/DailyQuestCard.tscn")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var list: VBoxContainer = $Scroll/ListMargin/List
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
	
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("daily_quests_title")
	back_button.text = _i18n("menu_back")
	LnUiLib.apply_title(title_label, 26)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button_icon(back_button, "back.svg")
	back_button.pressed.connect(_on_back)
	_state = _load_state()
	_render()
	_animate_entrance()


func _animate_entrance() -> void:
	var items: Array = [title_label]
	for child in list.get_children():
		items.append(child)
	items.append(back_button)
	await LnUiLib.animate_entrance(items)


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
	var progress_prefix := "Прогрес:"
	var done_label := "Отримано"

	for quest in daily.get_quests():
		var card: DailyQuestCard = DailyQuestCardScene.instantiate()
		var qid := str(quest.get("id", ""))
		var done := daily.is_done(qid)
		var text_key := str(quest.get("text_key", ""))
		var quest_text := _i18n(text_key) if not text_key.is_empty() else ""
		if quest_text.is_empty() or quest_text == text_key:
			quest_text = _fallback_quest_text(qid)
		
		var prog: Dictionary = daily.get_progress(qid)
		var progress_text := "%s %d/%d" % [progress_prefix, int(prog.get("current", 0)), int(prog.get("max", 1))]
		var reward_text := daily.get_reward_label(qid)
		var reward_text_display := reward_text if not done else done_label
		
		card.setup(done, quest_text, progress_text, reward_text, "Отримано" if done else "")
		list.add_child(card)


func _fallback_quest_text(id: String) -> String:
	match id:
		"completeLevel":
			return "Пройти 1 рівень"
		"chain5":
			return "З'єднай 10 плиток"
		"xp100":
			return "Набери 100 XP"
		"useBonus":
			return "Використай бонус"
		"spinWheel":
			return "Прокрути колесо фортуни"
		_:
			return "Щоденне завдання"


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