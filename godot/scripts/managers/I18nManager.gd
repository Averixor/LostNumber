extends Node

## i18n from res://assets/i18n/{uk,ru,en}.json with fallback uk → ru → en.
## Empty string values are valid translations.

const LANG_FILES := {
	"uk": "res://assets/i18n/uk.json",
	"ru": "res://assets/i18n/ru.json",
	"en": "res://assets/i18n/en.json",
}

const FALLBACK_ORDER := ["uk", "ru", "en"]

## Godot UI keys → JSON keys from js/system/i18n/i18n.js
const KEY_ALIASES := {
	"app_title": "game_logo",
	"boot_loading": "loading",
	"menu_play": "btn_play",
	"menu_continue": "btn_continue",
	"menu_new_game": "btn_new_game",
	"menu_settings": "btn_settings",
	"menu_achievements": "btn_achievements",
	"menu_daily": "btn_daily_quests",
	"menu_daily_short": "menu_daily_short",
	"menu_wheel": "bonus_wheel_title",
	"menu_back": "btn_back",
	"hud_menu": "btn_home",
	"settings_sound": "settings_sound_label",
	"settings_music": "settings_music_label",
	"settings_theme": "settings_theme_label",
	"settings_bg_effects": "settings_bg_effects_label",
	"lang_uk": "settings_language_ua",
	"lang_ru": "settings_language_ru",
	"lang_en": "settings_language_en",
	"level_label": "level_label",
	"goal_label": "goal_label",
	"xp_label": "xp_label",
	"level_complete": "level_completed_title",
	"next_level": "btn_next_level",
	"bonus_shuffle": "bonus_shuffle_title",
	"bonus_destroy": "bonus_destroy_title",
	"bonus_explosion": "bonus_explosion_title",
	"no_bonus": "no_bonus",
	"choose_cell_bonus": "choose_cell_bonus",
	"shuffle_done": "shuffle_done",
	"destroy_done": "destroy_done",
	"explosion_done": "explosion_done",
	"daily_title": "daily_quests_title",
	"daily_complete_level": "daily_complete_level",
	"daily_chain_5": "daily_chain_5",
	"daily_xp_100": "daily_xp_100",
	"daily_use_bonus": "daily_use_bonus",
	"daily_spin_wheel": "daily_spin_wheel",
	"daily_completed": "daily_completed",
	"daily_progress": "daily_progress",
	"daily_received": "daily_received",
	"wheel_title": "wheel_title",
	"wheel_spin": "btn_spin_wheel",
	"achievements_title": "achievements_title",
	"achievement_locked": "achievement_locked",
	"achievement_unlocked": "achievement_unlocked",
	"leaderboard_opt_in": "leaderboard_opt_in",
	"version_label": "version_label",
	"main_subtitle": "main_subtitle",
	"settings_import_legacy": "settings_import_legacy",
	"settings_import_legacy_success": "settings_import_legacy_success",
	"settings_import_legacy_failed": "settings_import_legacy_failed",
	"settings_import_legacy_none": "settings_import_legacy_none",
	"btn_stats": "btn_stats",
	"btn_about": "btn_about",
	"dock_premium": "dock_premium",
	"dock_tournaments": "dock_tournaments",
	"dock_achievements": "dock_achievements",
	"dock_daily": "dock_daily",
	"dock_bonuses": "dock_bonuses",
	"feature_stub_ok": "feature_stub_ok",
	"feature_premium_title": "feature_premium_title",
	"feature_premium_intro": "feature_premium_intro",
	"feature_premium_bullet_ad": "feature_premium_bullet_ad",
	"feature_premium_bullet_themes": "feature_premium_bullet_themes",
	"feature_premium_bullet_tournaments": "feature_premium_bullet_tournaments",
	"feature_premium_note": "feature_premium_note",
	"feature_tournaments_title": "feature_tournaments_title",
	"feature_tournaments_intro": "feature_tournaments_intro",
	"feature_tournaments_bullet_weekly": "feature_tournaments_bullet_weekly",
	"feature_tournaments_note": "feature_tournaments_note",
	"feature_bonuses_title": "feature_bonuses_title",
	"feature_bonuses_text": "feature_bonuses_text",
	"feature_1": "feature_1",
	"feature_2": "feature_2",
	"feature_3": "feature_3",
	"feature_4": "feature_4",
	"game_logo": "game_logo",
	"settings_visual_skin_label": "settings_visual_skin_label",
	"settings_visual_skin_auto": "settings_visual_skin_auto",
	"settings_skin_selected": "settings_skin_selected",
	"skin_selected_badge": "skin_selected_badge",
	"settings_pick_background": "settings_pick_background",
	"settings_theme_twilight": "settings_theme_twilight",
	"skin_apply": "skin_apply",
	"skin_cancel": "skin_cancel",
	"skin_custom_bg": "skin_custom_bg",
	"skin_picker_folders_label": "skin_picker_folders_label",
	"skin_picker_folder_pictures": "skin_picker_folder_pictures",
	"skin_picker_folder_downloads": "skin_picker_folder_downloads",
	"skin_picker_folder_documents": "skin_picker_folder_documents",
	"skin_picker_open": "skin_picker_open",
	"skin_picker_empty": "skin_picker_empty",
	"skin_picker_no_folders": "skin_picker_no_folders",
	"skin_picker_permission_denied": "skin_picker_permission_denied",
	"skin_bg_load_failed": "skin_bg_load_failed",
	"skin_bg_format_unsupported": "skin_bg_format_unsupported",
	"skin_reset_default": "skin_reset_default",
	"visual_skin_1": "visual_skin_1",
	"visual_skin_2": "visual_skin_2",
	"visual_skin_3": "visual_skin_3",
	"visual_skin_4": "visual_skin_4",
	"visual_skin_5": "visual_skin_5",
	"visual_skin_6": "visual_skin_6",
	"goal_full": "goal_full",
	"btn_exit": "btn_exit",
	"pause_title": "pause_title",
	"btn_resume": "btn_resume",
	"save_indicator": "save_indicator",
	"chain_status_valid": "chain_status_valid",
	"chain_status_invalid": "chain_status_invalid",
	"chain_status_continue": "chain_status_continue",
	"score_label": "score_label",
	"chain_sum_hud": "chain_sum_hud",
	"chain_can_merge": "chain_can_merge",
	"wheel_xp_25": "wheel_xp_25",
	"wheel_xp_50": "wheel_xp_50",
	"wheel_xp_75": "wheel_xp_75",
	"wheel_xp_100": "wheel_xp_100",
	"wheel_win_prefix": "wheel_win_prefix",
}

const STATIC_FALLBACKS := {
	"achievement_locked": {
		"uk": "Заблоковано",
		"ru": "Заблокировано",
		"en": "Locked",
	},
	"leaderboard_opt_in": {
		"uk": "Надсилати рекорди в таблицю лідерів (скоро)",
		"ru": "Отправлять рекорды в таблицу лидеров (скоро)",
		"en": "Submit scores to leaderboard (coming soon)",
	},
	"version_label": {
		"uk": "v%s",
		"ru": "v%s",
		"en": "v%s",
	},
	"settings_import_legacy": {
		"uk": "Імпортувати старе збереження",
		"ru": "Импортировать старое сохранение",
		"en": "Import legacy save",
	},
	"settings_import_legacy_success": {
		"uk": "Збереження імпортовано",
		"ru": "Сохранение импортировано",
		"en": "Save imported successfully",
	},
	"settings_import_legacy_failed": {
		"uk": "Не вдалося імпортувати збереження",
		"ru": "Не удалось импортировать сохранение",
		"en": "Could not import save",
	},
	"settings_import_legacy_none": {
		"uk": "Файл збереження не знайдено",
		"ru": "Файл сохранения не найден",
		"en": "No legacy save file found",
	},
	"pause_title": {
		"uk": "Пауза",
		"ru": "Пауза",
		"en": "Paused",
	},
	"btn_resume": {
		"uk": "Продовжити",
		"ru": "Продолжить",
		"en": "Resume",
	},
	"save_indicator": {
		"uk": "Збережено",
		"ru": "Сохранено",
		"en": "Saved",
	},
	"chain_status_valid": {
		"uk": "Валідно!",
		"ru": "Валидно!",
		"en": "Valid!",
	},
	"chain_sum_hud": {
		"uk": "Сума ланцюжка: {sum}",
		"ru": "Сумма цепочки: {sum}",
		"en": "Chain sum: {sum}",
	},
	"chain_can_merge": {
		"uk": "Можна об'єднати!",
		"ru": "Можно объединить!",
		"en": "Can merge!",
	},
	"chain_status_invalid": {
		"uk": "Не можна",
		"ru": "Нельзя",
		"en": "Invalid",
	},
	"chain_status_continue": {
		"uk": "Продовжуй",
		"ru": "Продолжай",
		"en": "Continue",
	},
	"score_label": {
		"uk": "Очки: {xp}",
		"ru": "Очки: {xp}",
		"en": "Score: {xp}",
	},
	"wheel_xp_25": {
		"uk": "+25 XP",
		"ru": "+25 XP",
		"en": "+25 XP",
	},
	"wheel_xp_50": {
		"uk": "+50 XP",
		"ru": "+50 XP",
		"en": "+50 XP",
	},
	"wheel_xp_75": {
		"uk": "+75 XP",
		"ru": "+75 XP",
		"en": "+75 XP",
	},
	"wheel_xp_100": {
		"uk": "+100 XP",
		"ru": "+100 XP",
		"en": "+100 XP",
	},
	"wheel_win_prefix": {
		"uk": "Виграш:",
		"ru": "Выигрыш:",
		"en": "Prize:",
	},
	"exit_confirm_title": {
		"uk": "Вийти з гри?",
		"ru": "Выйти из игры?",
		"en": "Exit the game?",
	},
	"exit_confirm_text": {
		"uk": "Ви впевнені, що хочете вийти?",
		"ru": "Вы уверены, что хотите выйти?",
		"en": "Are you sure you want to exit?",
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

var _strings: Dictionary = {}


func _ready() -> void:
	_load_all()


func _load_all() -> void:
	_strings.clear()
	for lang in FALLBACK_ORDER:
		var path: String = LANG_FILES[lang]
		if not ResourceLoader.exists(path):
			push_warning("I18nManager: missing %s" % path)
			_strings[lang] = {}
			continue
		var file := FileAccess.open(path, FileAccess.READ)
		if file == null:
			_strings[lang] = {}
			continue
		var parsed = JSON.parse_string(file.get_as_text())
		_strings[lang] = parsed if typeof(parsed) == TYPE_DICTIONARY else {}


func t(key: String, args: Array = []) -> String:
	var resolved := _resolve_key(key)
	var text := _lookup(resolved)
	if args.is_empty():
		return text
	return _format(text, args)


func achievement_name(key: String) -> String:
	var lang := _current_lang()
	var bucket: Dictionary = ACHIEVEMENT_NAMES.get(lang, ACHIEVEMENT_NAMES["uk"])
	if bucket.has(key):
		return str(bucket[key])
	for fb in FALLBACK_ORDER:
		var b: Dictionary = ACHIEVEMENT_NAMES.get(fb, {})
		if b.has(key):
			return str(b[key])
	return key


func _resolve_key(key: String) -> String:
	return str(KEY_ALIASES.get(key, key))


func _lookup(key: String) -> String:
	var lang := _current_lang()
	var order: Array[String] = []
	order.append(lang)
	for fb in FALLBACK_ORDER:
		if fb != lang:
			order.append(fb)

	for l in order:
		var bucket: Dictionary = _strings.get(l, {})
		if bucket.has(key):
			return str(bucket[key])

	if STATIC_FALLBACKS.has(key):
		var fb_map: Dictionary = STATIC_FALLBACKS[key]
		if fb_map.has(lang):
			return str(fb_map[lang])
		for l in FALLBACK_ORDER:
			if fb_map.has(l):
				return str(fb_map[l])

	return key


func _format(text: String, args: Array) -> String:
	# Godot printf-style (%d, %s)
	if "%" in text:
		return text % args
	# JS-style {placeholders} — match names present in the string, not positional index.
	var names := [
		"level", "xp", "target", "cost", "turns", "used", "total", "value", "multiplier", "sum",
	]
	var placeholders: Array[String] = []
	for name in names:
		var token := "{%s}" % name
		if token in text:
			placeholders.append(name)
	if placeholders.is_empty():
		return text
	var out := text
	for i in mini(args.size(), placeholders.size()):
		out = out.replace("{%s}" % placeholders[i], str(args[i]))
	return out


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _current_lang() -> String:
	if not is_inside_tree():
		return "uk"
	var settings := _autoload("SettingsManager")
	if settings != null:
		var language := str(settings.get("language"))
		if LANG_FILES.has(language):
			return language
	return "uk"
