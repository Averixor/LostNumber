extends SceneTree

## Verifies the data-driven visual skin resource and manager API.

const VisualThemeManagerScript := preload("res://scripts/managers/VisualThemeManager.gd")
const VISUAL_SKIN_PATH := "res://themes/skins/gothic_crystal.tres"

var failed := 0


func _init() -> void:
	print("Lost Number visual skin tests...")
	_test_resource()
	_test_manager_api()

	if failed > 0:
		push_error("visual skin tests failed: %s" % failed)
		quit(1)
		return

	print("visual skin tests passed")
	quit(0)


func _test_resource() -> void:
	_assert_true(ResourceLoader.exists(VISUAL_SKIN_PATH), "Gothic Crystal resource exists")
	var skin := load(VISUAL_SKIN_PATH) as VisualSkin
	_assert_true(skin != null, "Gothic Crystal resource loads")
	if skin == null:
		return
	_assert_true(skin.is_valid(), "Gothic Crystal resource is valid")
	_assert_true(skin.is_valid_skin(), "Gothic Crystal manager validation API is valid")
	_assert_true(skin.skin_id == &"gothic_crystal", "Gothic Crystal id matches")
	_assert_true(skin.background_for(&"menu") != null, "menu background is assigned")
	_assert_true(skin.background_for(&"game") != null, "game background is assigned")
	_assert_true(skin.tile_frame_for_value(2) != null, "common tile frame is assigned")
	_assert_true(skin.tile_frame_for_value(4096) != null, "legendary tile frame is assigned")
	_assert_true(skin.tile_style_for_value(2) != null, "tile style is generated from frame")
	_assert_true(skin.palette(true).has("primary"), "visual skin palette exposes primary color")
	_assert_true(skin.overlay_color(true).a > 0.0, "visual skin overlay is visible")


func _test_manager_api() -> void:
	var manager := VisualThemeManagerScript.new()
	var skin := manager.get_visual_skin()
	_assert_true(skin != null, "manager resolves default visual skin")
	_assert_true(manager.get_visual_skin_id() == &"gothic_crystal", "manager default id matches")
	_assert_true(
		manager.get_visual_background_path(&"menu") == "res://assets/ui/skins/gothic_crystal/game-backdrop.png",
		"manager resolves exact-case menu background path"
	)
	_assert_true(manager.get_tile_rarity(4096) == &"legendary", "manager resolves legendary rarity")
	_assert_true(manager.get_tile_style_for_value(2) != null, "manager resolves tile style")
	_assert_true(manager.get_palette(true).has("primary"), "manager resolves visual palette")
	_assert_true(not manager.set_visual_skin(&"missing_skin"), "manager rejects unknown visual skin")
	manager.free()


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)
