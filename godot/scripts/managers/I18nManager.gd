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
	var out := text
	# Godot printf-style (%d, %s)
	if "%" in out:
		return out % args
	# JS-style {placeholders}
	var names := ["level", "xp", "target", "cost", "turns", "used", "total", "value"]
	for i in args.size():
		var placeholder := "{%s}" % names[mini(i, names.size() - 1)]
		if placeholder in out:
			out = out.replace(placeholder, str(args[i]))
		elif "{cost}" in out and i == 0:
			out = out.replace("{cost}", str(args[i]))
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
