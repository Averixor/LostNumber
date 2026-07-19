extends SceneTree

## i18n JSON loading, fallback chain, and placeholder formatting.

const I18nManagerScript := preload("res://scripts/managers/I18nManager.gd")
const WheelCanvasScript := preload("res://scripts/ui/WheelCanvas.gd")

class LanguageSettings:
	extends Node
	var language := "uk"

var failed := 0
var _i18n: Node
var _settings: Node
var _owns_settings := false
var _previous_language := "uk"


func _init() -> void:
	print("Lost Number i18n tests...")
	_settings = root.get_node_or_null("SettingsManager")
	if _settings == null:
		_settings = LanguageSettings.new()
		_settings.name = "SettingsManager"
		root.add_child(_settings)
		_owns_settings = true
	else:
		_previous_language = str(_settings.get("language"))
	_i18n = I18nManagerScript.new()
	root.add_child(_i18n)
	_i18n._load_all()
	await process_frame

	_test_json_loaded()
	_test_fallback_chain()
	_test_empty_string_valid()
	_test_key_aliases()
	_test_achievement_names()
	_test_title_placeholder()
	_test_language_key_parity()
	_test_visual_skin_languages()
	_test_wheel_fallback_labels()

	if failed > 0:
		push_error("i18n tests failed: %s" % failed)
		_cleanup()
		quit(1)
		return

	print("i18n tests passed")
	_cleanup()
	quit(0)


func _test_json_loaded() -> void:
	for lang in ["uk", "ru", "en"]:
		var path := "res://assets/i18n/%s.json" % lang
		_assert_true(ResourceLoader.exists(path), "json exists: %s" % lang)


func _test_fallback_chain() -> void:
	var text := str(_i18n.call("t", "btn_play"))
	_assert_true(not text.is_empty() and text != "btn_play", "uk btn_play resolves")


func _test_empty_string_valid() -> void:
	# Inject empty value into lookup path — empty is valid, not missing.
	var bucket: Dictionary = _i18n._strings.get("uk", {})
	bucket["__test_empty__"] = ""
	_i18n._strings["uk"] = bucket
	var text := str(_i18n.call("t", "__test_empty__"))
	_assert_eq(text, "", "empty string is valid translation")
	# Keep later locale-parity checks focused on the real JSON dictionaries.
	bucket.erase("__test_empty__")
	_i18n._strings["uk"] = bucket


func _test_key_aliases() -> void:
	var menu := str(_i18n.call("t", "menu_play"))
	_assert_true(menu.length() > 0, "menu_play alias resolves")


func _test_achievement_names() -> void:
	var name := str(_i18n.call("achievement_name", "first_game"))
	_assert_true(name.length() > 0, "achievement_name first_game")


func _test_title_placeholder() -> void:
	var formatted := str(_i18n.call("t", "achievement_unlocked", ["Перша гра"]))
	_assert_true("{title}" not in formatted, "achievement_unlocked substitutes {title}")
	_assert_true("Перша гра" in formatted, "achievement_unlocked includes title value")


func _test_visual_skin_languages() -> void:
	var keys := [
		"settings_visual_skin_label",
		"settings_visual_skin_pick",
		"settings_pick_background",
		"settings_background_label",
		"settings_background_auto",
		"background_preview_title",
		"background_variant",
		"skin_preview_title",
		"skin_preview_mode_dark",
		"skin_preview_mode_light",
		"skin_preview_dark_only",
		"skin_preview_button",
		"skin_apply",
		"skin_cancel",
		"skin_custom_bg",
		"skin_reset_default",
		"skin_selected_badge",
		"visual_skin_gothic_crystal_name",
		"visual_skin_gothic_crystal_description",
		"visual_skin_procedural_name",
		"visual_skin_procedural_description",
	]
	for lang in ["uk", "ru", "en"]:
		_settings.set("language", lang)
		var bucket: Dictionary = _i18n._strings.get(lang, {})
		for key in keys:
			_assert_true(bucket.has(key) and not str(bucket[key]).is_empty(), "%s visual key exists: %s" % [lang, key])
			_assert_eq(str(_i18n.call("t", key)), str(bucket.get(key, "")), "%s visual key resolves: %s" % [lang, key])


func _test_wheel_fallback_labels() -> void:
	var wheel := WheelCanvasScript.new()
	# Disk labels: short tokens / icon-only. Full names remain in result modal i18n.
	for value in [25, 50, 75, 100]:
		var compact := str(wheel.call("_compact_wheel_label", "", {"effect": "xp", "value": value}))
		_assert_eq(compact, "+%d" % value, "xp disk token: +%d" % value)
	_assert_eq(
		str(wheel.call("_compact_wheel_label", "", {"effect": "multiplier", "value": 5})),
		"2× XP",
		"multiplier disk token"
	)
	for value in ["destroy", "shuffle", "explosion"]:
		var compact := str(wheel.call("_compact_wheel_label", "ignored", {"effect": "bonus", "value": value}))
		_assert_eq(compact, "", "bonus disk is icon-only: %s" % value)
		# Result-modal strings must stay present in every locale.
		var key := "wheel_sector_%s" % value
		for lang in ["uk", "ru", "en"]:
			_settings.set("language", lang)
			var translated := str(_i18n.call("t", key))
			_assert_true(
				translated != key and not translated.is_empty(),
				"%s result string kept: %s" % [lang, value]
			)
	wheel.free()


func _test_language_key_parity() -> void:
	var baseline: Dictionary = _i18n._strings.get("uk", {})
	for lang in ["ru", "en"]:
		var bucket: Dictionary = _i18n._strings.get(lang, {})
		_assert_true(bucket.size() == baseline.size(), "%s key count matches Ukrainian" % lang)
		for key in baseline:
			_assert_true(bucket.has(key), "%s contains key: %s" % [lang, key])


func _cleanup() -> void:
	if _i18n != null:
		root.remove_child(_i18n)
		_i18n.free()
		_i18n = null
	if _settings != null:
		if _owns_settings:
			root.remove_child(_settings)
			_settings.free()
		else:
			_settings.set("language", _previous_language)
	_settings = null


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(a: String, b: String, message: String) -> void:
	_assert_true(a == b, "%s (got '%s' expected '%s')" % [message, a, b])
