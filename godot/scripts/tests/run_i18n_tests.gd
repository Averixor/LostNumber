extends SceneTree

## i18n JSON loading, fallback chain, and placeholder formatting.

const I18nManagerScript := preload("res://scripts/managers/I18nManager.gd")

var failed := 0
var _i18n: Node


func _init() -> void:
	print("Lost Number i18n tests...")
	_i18n = I18nManagerScript.new()
	_i18n._load_all()

	_test_json_loaded()
	_test_fallback_chain()
	_test_empty_string_valid()
	_test_key_aliases()
	_test_achievement_names()

	if failed > 0:
		push_error("i18n tests failed: %s" % failed)
		_cleanup()
		quit(1)

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


func _test_key_aliases() -> void:
	var menu := str(_i18n.call("t", "menu_play"))
	_assert_true(menu.length() > 0, "menu_play alias resolves")


func _test_achievement_names() -> void:
	var name := str(_i18n.call("achievement_name", "first_game"))
	_assert_true(name.length() > 0, "achievement_name first_game")


func _cleanup() -> void:
	if _i18n != null:
		_i18n.free()
		_i18n = null


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)


func _assert_eq(a: String, b: String, message: String) -> void:
	_assert_true(a == b, "%s (got '%s' expected '%s')" % [message, a, b])
