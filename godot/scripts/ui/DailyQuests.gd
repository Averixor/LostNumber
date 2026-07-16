extends Control

const DailyQuestCardScene := preload("res://scenes/components/DailyQuestCard.tscn")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

@onready var scroll: ScrollContainer = $Scroll
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
	LnUiLib.apply_screen_background(self, "daily", 0.66)
	if background != null:
		background.color = Color(0, 0, 0, 0)
	
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("daily_quests_title")
	back_button.text = _i18n("menu_back")
	LnUiLib.apply_title(title_label, 26)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button_icon(back_button, "back.png")
	back_button.pressed.connect(_on_back)
	_state = _load_state()
	_render()
	_adapt_layout()
	call_deferred("_adapt_layout")
	_animate_entrance()


func _is_compact_layout() -> bool:
	return get_viewport_rect().size.y <= 920.0


func _adapt_layout() -> void:
	if not is_node_ready():
		return
	if title_label == null or scroll == null or list == null or back_button == null:
		return

	var compact := _is_compact_layout()
	var title_bottom := 52.0 if compact else 56.0
	var back_top := -56.0
	var back_bottom := -12.0 if compact else -16.0

	var __ln_safe_offset_1 = title_label

	if __ln_safe_offset_1 != null:

		__ln_safe_offset_1.offset_top = 12.0 if compact else 16.0
	var __ln_safe_offset_2 = title_label
	if __ln_safe_offset_2 != null:
		__ln_safe_offset_2.offset_bottom = title_bottom

	var __ln_safe_offset_3 = scroll

	if __ln_safe_offset_3 != null:

		__ln_safe_offset_3.offset_left = 16.0
	var __ln_safe_offset_4 = scroll
	if __ln_safe_offset_4 != null:
		__ln_safe_offset_4.offset_right = -16.0
	var __ln_safe_offset_5 = scroll
	if __ln_safe_offset_5 != null:
		__ln_safe_offset_5.offset_top = title_bottom + 8.0
	var __ln_safe_offset_6 = scroll
	if __ln_safe_offset_6 != null:
		__ln_safe_offset_6.offset_bottom = back_top - 8.0
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO

	var __ln_safe_offset_7 = back_button

	if __ln_safe_offset_7 != null:

		__ln_safe_offset_7.offset_top = back_top
	var __ln_safe_offset_8 = back_button
	if __ln_safe_offset_8 != null:
		__ln_safe_offset_8.offset_bottom = back_bottom

	list.add_theme_constant_override("separation", 4 if compact else 6)
	for child in list.get_children():
		if child != null and child.has_method("apply_layout"):
			child.call("apply_layout", compact)

func _notification(what: int) -> void:
	if what == NOTIFICATION_RESIZED and is_node_ready():
		_adapt_layout()

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
	var progress_prefix := _i18n("daily_progress")

	for quest in daily.get_quests():
		var card: DailyQuestCard = DailyQuestCardScene.instantiate()
		list.add_child(card)
		var qid := str(quest.get("id", ""))
		var done := daily.is_done(qid)
		var text_key := str(quest.get("text_key", quest.get("textKey", "")))
		var quest_text := _i18n(text_key) if not text_key.is_empty() else ""
		if quest_text.is_empty() or quest_text == text_key:
			quest_text = _fallback_quest_text(qid)
		
		var prog: Dictionary = daily.get_progress(qid)
		var progress_text := "%s %d/%d" % [progress_prefix, int(prog.get("current", 0)), int(prog.get("max", 1))]
		var reward_text := daily.get_reward_label(qid)
		card.setup(done, quest_text, progress_text, reward_text, _i18n("daily_received") if done else "")


func _fallback_quest_text(id: String) -> String:
	match id:
		"completeLevel":
			return "Пройти 1 рівень"
		"chain5":
			return "Зібрати ланцюжок з 5 чисел"
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
