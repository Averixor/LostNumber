extends Node

## Lightweight i18n for Godot UI (UA / RU / EN). Uses SettingsManager.language.

const STRINGS := {
	"uk": {
		"app_title": "Lost Number",
		"menu_continue": "Продовжити",
		"menu_new_game": "Нова гра",
		"menu_settings": "Налаштування",
		"menu_achievements": "Досягнення",
		"menu_daily": "Щоденні завдання",
		"menu_wheel": "Колесо",
		"menu_back": "Назад",
		"hud_menu": "Меню",
		"settings_title": "Налаштування",
		"settings_sound": "Звук",
		"settings_music": "Музика",
		"settings_language": "Мова",
		"lang_uk": "Українська",
		"lang_ru": "Русский",
		"lang_en": "English",
		"level_label": "Рівень %d",
		"target_label": "Ціль: %s",
		"xp_label": "XP: %s",
		"level_complete": "Рівень пройдено!",
		"next_level": "Наступний рівень",
		"bonus_shuffle": "Перемішати",
		"bonus_destroy": "Знищити",
		"bonus_explosion": "Вибух",
		"no_bonus": "Немає бонусів",
		"choose_cell_bonus": "Оберіть клітинку",
		"shuffle_done": "Поле перемішано",
		"destroy_done": "Клітинку знищено",
		"explosion_done": "Група клітинок очищена",
		"daily_title": "Щоденні завдання",
		"daily_complete_level": "Пройти рівень",
		"daily_chain_5": "Ланцюг з 5 клітинок",
		"daily_xp_100": "Заробити 100 XP за день",
		"daily_use_bonus": "Використати бонус",
		"daily_spin_wheel": "Крутити колесо",
		"daily_completed": "Завдання виконано!",
		"wheel_title": "Колесо фортуни",
		"wheel_spin": "Крутити",
		"achievements_title": "Досягнення",
		"achievement_locked": "Заблоковано",
		"achievement_unlocked": "Отримано",
		"leaderboard_opt_in": "Надсилати рекорди в таблицю лідерів (скоро)",
	},
	"ru": {
		"app_title": "Lost Number",
		"menu_continue": "Продолжить",
		"menu_new_game": "Новая игра",
		"menu_settings": "Настройки",
		"menu_achievements": "Достижения",
		"menu_daily": "Ежедневные задания",
		"menu_wheel": "Колесо",
		"menu_back": "Назад",
		"hud_menu": "Меню",
		"settings_title": "Настройки",
		"settings_sound": "Звук",
		"settings_music": "Музыка",
		"settings_language": "Язык",
		"lang_uk": "Українська",
		"lang_ru": "Русский",
		"lang_en": "English",
		"level_label": "Уровень %d",
		"target_label": "Цель: %s",
		"xp_label": "XP: %s",
		"level_complete": "Уровень пройден!",
		"next_level": "Следующий уровень",
		"bonus_shuffle": "Перемешать",
		"bonus_destroy": "Уничтожить",
		"bonus_explosion": "Взрыв",
		"no_bonus": "Нет бонусов",
		"choose_cell_bonus": "Выберите клетку",
		"shuffle_done": "Поле перемешано",
		"destroy_done": "Клетка уничтожена",
		"explosion_done": "Группа клеток очищена",
		"daily_title": "Ежедневные задания",
		"daily_complete_level": "Пройти уровень",
		"daily_chain_5": "Цепь из 5 клеток",
		"daily_xp_100": "Заработать 100 XP за день",
		"daily_use_bonus": "Использовать бонус",
		"daily_spin_wheel": "Крутить колесо",
		"daily_completed": "Задание выполнено!",
		"wheel_title": "Колесо фортуны",
		"wheel_spin": "Крутить",
		"achievements_title": "Достижения",
		"achievement_locked": "Заблокировано",
		"achievement_unlocked": "Получено",
		"leaderboard_opt_in": "Отправлять рекорды в таблицу лидеров (скоро)",
	},
	"en": {
		"app_title": "Lost Number",
		"menu_continue": "Continue",
		"menu_new_game": "New Game",
		"menu_settings": "Settings",
		"menu_achievements": "Achievements",
		"menu_daily": "Daily Tasks",
		"menu_wheel": "Wheel",
		"menu_back": "Back",
		"hud_menu": "Menu",
		"settings_title": "Settings",
		"settings_sound": "Sound",
		"settings_music": "Music",
		"settings_language": "Language",
		"lang_uk": "Українська",
		"lang_ru": "Русский",
		"lang_en": "English",
		"level_label": "Level %d",
		"target_label": "Target: %s",
		"xp_label": "XP: %s",
		"level_complete": "Level complete!",
		"next_level": "Next level",
		"bonus_shuffle": "Shuffle",
		"bonus_destroy": "Destroy",
		"bonus_explosion": "Blast",
		"no_bonus": "No bonuses left",
		"choose_cell_bonus": "Pick a cell",
		"shuffle_done": "Grid shuffled",
		"destroy_done": "Cell destroyed",
		"explosion_done": "Area cleared",
		"daily_title": "Daily Tasks",
		"daily_complete_level": "Complete a level",
		"daily_chain_5": "Chain of 5 cells",
		"daily_xp_100": "Earn 100 XP today",
		"daily_use_bonus": "Use a bonus",
		"daily_spin_wheel": "Spin the wheel",
		"daily_completed": "Task completed!",
		"wheel_title": "Wheel of Fortune",
		"wheel_spin": "Spin",
		"achievements_title": "Achievements",
		"achievement_locked": "Locked",
		"achievement_unlocked": "Unlocked",
		"leaderboard_opt_in": "Submit scores to leaderboard (coming soon)",
	},
}

const ACHIEVEMENT_NAMES := {
	"uk": {
		"first_game": "Перша гра",
		"level_10": "10 рівнів",
		"level_25": "25 рівнів",
		"xp_1000": "1000 XP",
		"xp_5000": "5000 XP",
		"chain_5": "Ланцюг ×5",
		"chain_10": "Ланцюг ×10",
	},
	"ru": {
		"first_game": "Первая игра",
		"level_10": "10 уровней",
		"level_25": "25 уровней",
		"xp_1000": "1000 XP",
		"xp_5000": "5000 XP",
		"chain_5": "Цепь ×5",
		"chain_10": "Цепь ×10",
	},
	"en": {
		"first_game": "First game",
		"level_10": "Level 10",
		"level_25": "Level 25",
		"xp_1000": "1000 XP",
		"xp_5000": "5000 XP",
		"chain_5": "Chain ×5",
		"chain_10": "Chain ×10",
	},
}


func t(key: String, args: Array = []) -> String:
	var lang := _current_lang()
	var bucket: Dictionary = STRINGS.get(lang, STRINGS["uk"])
	var text := str(bucket.get(key, STRINGS["uk"].get(key, key)))
	if args.is_empty():
		return text
	return text % args


func achievement_name(key: String) -> String:
	var lang := _current_lang()
	var bucket: Dictionary = ACHIEVEMENT_NAMES.get(lang, ACHIEVEMENT_NAMES["uk"])
	return str(bucket.get(key, key))


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _current_lang() -> String:
	var settings := _autoload("SettingsManager")
	if settings != null:
		var language := str(settings.get("language"))
		if STRINGS.has(language):
			return language
	return "uk"
