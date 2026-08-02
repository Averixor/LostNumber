extends SceneTree

## Verifies the data-driven visual skin resource, manager API, logo XOR rules,
## and dark-only UI affordances (no dead theme toggles).

const VisualThemeManagerScript := preload("res://scripts/managers/VisualThemeManager.gd")
const GothicVisualsLib := preload("res://scripts/ui/GothicVisuals.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const VISUAL_SKIN_PATH := "res://themes/skins/gothic_crystal.tres"
const GOTHIC_MENU_BG := "res://assets/ui/skins/gothic_crystal/game-backdrop.png"

var failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	print("Lost Number visual skin tests...")
	_test_resource()
	_test_manager_api()
	_test_logo_background_helpers()
	await _test_app_shell_single_logo()
	await _test_dark_only_theme_controls_hidden()

	await _cleanup_test_runtime()

	if failed > 0:
		push_error("visual skin tests failed: %s" % failed)
		quit(1)
		return

	print("visual skin tests passed")
	quit(0)


func _cleanup_test_runtime() -> void:
	var audio := root.get_node_or_null("AudioManager")
	if audio != null and audio.has_method("stop_music"):
		audio.call("stop_music")
		var player: AudioStreamPlayer = audio.get("_music_player")
		if player != null:
			_assert_true(not player.playing, "music player stopped after stop_music")
			_assert_true(player.stream == null, "music stream cleared after stop_music")
	for _i in 8:
		await process_frame


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
	_assert_true(skin.tile_frame_for_value(8192) != null, "legendary tile frame is assigned")
	_assert_true(skin.tile_style_for_value(2) != null, "tile style is generated from frame")
	_assert_true(skin.palette(true).has("primary"), "visual skin palette exposes primary color")
	_assert_true(skin.overlay_color(true).a > 0.0, "visual skin overlay is visible")
	_assert_true(skin.has_chrome_styles(), "gothic_crystal fills panel/modal/hud/button styles")
	_assert_true(skin.style_for(&"panel") != null, "panel StyleBox is non-null")
	_assert_true(skin.style_for(&"modal") != null, "modal StyleBox is non-null")
	_assert_true(skin.style_for(&"hud") != null, "hud StyleBox is non-null")
	_assert_true(skin.style_for(&"button_normal") != null, "button_normal StyleBox is non-null")
	_assert_true(skin.style_for(&"button_hover") != null, "button_hover StyleBox is non-null")
	_assert_true(skin.style_for(&"button_pressed") != null, "button_pressed StyleBox is non-null")
	_assert_true(skin.style_for(&"button_disabled") != null, "button_disabled StyleBox is non-null")
	var wheel := skin.get_wheel_colors()
	_assert_true(wheel.size() >= 4, "gothic wheel palette has sector colors")
	_assert_true(skin.wheel_sector_colors.size() >= 4, "gothic_crystal declares explicit wheel colors")
	# Explicit gothic sectors must not match neon pink/cyan acid decorative accents.
	for c in wheel:
		var sector := Color(c)
		_assert_true(
			not _is_near_neon_decorative(sector),
			"gothic wheel sector avoids neon pink/cyan/acid green"
		)


func _test_manager_api() -> void:
	var manager := VisualThemeManagerScript.new()
	var skin := manager.get_visual_skin()
	_assert_true(skin != null, "manager resolves default visual skin")
	_assert_true(manager.get_visual_skin_id() == &"gothic_crystal", "manager default id matches")
	_assert_true(
		manager.get_visual_background_path(&"menu") == GOTHIC_MENU_BG,
		"manager resolves exact-case menu background path"
	)
	_assert_true(manager.normalize_release_theme_id("dawn") == "dusk", "dawn normalizes to dusk")
	_assert_true(manager.normalize_release_theme_id("twilight") == "dusk", "twilight normalizes to dusk")
	_assert_true(manager.normalize_release_theme_id("dusk") == "dusk", "dusk stays dusk")
	_assert_true(manager.UI_CYCLE_THEMES == ["dusk"], "release UI cycle is dusk-only")
	_assert_true(manager.get_tile_rarity(16) == &"uncommon", "manager resolves uncommon rarity at 16+")
	_assert_true(manager.get_tile_rarity(8192) == &"legendary", "manager resolves legendary rarity")
	_assert_true(manager.get_tile_style_for_value(2) != null, "manager resolves tile style")
	var face_2: Color = manager.get_tile_face_color(2)
	var face_4: Color = manager.get_tile_face_color(4)
	var face_16: Color = manager.get_tile_face_color(16)
	_assert_true(face_2 != face_4 and face_4 != face_16, "manager resolves distinct per-value tile faces")
	_assert_true(face_2.get_luminance() > 0.35, "tile 2 face stays bright (not muted stone)")
	_assert_true(
		GothicVisualsLib.TILE_FRAME_PATH.ends_with("stone_frame.webp"),
		"tile frame uses border-only asset with transparent center"
	)
	_assert_true(
		ResourceLoader.exists(GothicVisualsLib.TILE_FRAME_ART_PATH),
		"full-frame tile art asset exists on disk"
	)
	_assert_true(manager.get_palette(true).has("primary"), "manager resolves visual palette")
	_assert_true(manager.get_palette().has("rim"), "default get_palette prefers active VisualSkin")
	_assert_true(manager.get_visual_style(&"panel") != null, "manager resolves panel style from skin")
	_assert_true(manager.get_visual_style(&"modal") != null, "manager resolves modal style from skin")
	_assert_true(manager.get_visual_style(&"hud") != null, "manager resolves hud style from skin")
	_assert_true(manager.get_visual_style(&"button_normal") != null, "manager resolves button_normal")
	var manager_wheel: Array = manager.get_wheel_colors()
	_assert_true(manager_wheel.size() >= 4, "manager get_wheel_colors uses gothic skin palette")
	var skin_wheel := skin.get_wheel_colors() if skin != null else []
	_assert_true(
		skin != null and manager_wheel.size() == skin_wheel.size(),
		"manager wheel colors match VisualSkin.get_wheel_colors"
	)
	_assert_true(manager.uses_visual_skin(), "manager reports gothic visual skin active")
	var chrome := GothicVisualsLib.resolve_palette(manager)
	_assert_true(
		_color_distance(chrome.get("primary", Color.WHITE), Color("#8F55D6")) > 0.35,
		"gothic chrome primary is not violet crystal"
	)
	_assert_true(
		_color_distance(chrome.get("primary", Color.WHITE), GothicVisualsLib.GOLD) < 0.20,
		"gothic chrome primary maps to gold"
	)
	var cta := GothicVisualsLib.cta_button(chrome, "normal") as StyleBoxFlat
	_assert_true(cta != null, "cta_button returns StyleBoxFlat")
	if cta != null:
		_assert_true(
			_color_distance(Color(cta.bg_color.r, cta.bg_color.g, cta.bg_color.b), Color("#8F55D6")) > 0.35,
			"cta fill is not purple"
		)
		_assert_true(
			_color_distance(Color(cta.shadow_color.r, cta.shadow_color.g, cta.shadow_color.b), Color("#8F55D6")) > 0.35,
			"cta shadow is not purple bloom"
		)
	var booster := GothicVisualsLib.booster_button(chrome, true, true) as StyleBoxFlat
	if booster != null:
		_assert_true(
			_color_distance(Color(booster.bg_color.r, booster.bg_color.g, booster.bg_color.b), Color("#8F55D6")) > 0.35,
			"active booster fill is not purple"
		)
	_assert_true(
		ResourceLoader.exists("res://assets/ui/icons/gothic/wheel.png"),
		"gothic fortune wheel dock icon exists"
	)
	manager.set_visual_skin_id(manager.PROCEDURAL_VISUAL_SKIN_ID)
	_assert_true(not manager.uses_visual_skin(), "procedural_neon disables VisualSkin")
	_assert_true(manager.get_visual_style(&"panel") == null, "procedural_neon has no skin StyleBoxes")
	manager.set_visual_skin_id(manager.DEFAULT_VISUAL_SKIN_ID)
	_assert_true(not manager.set_visual_skin(&"missing_skin"), "manager rejects unknown visual skin")
	manager.free()


func _test_logo_background_helpers() -> void:
	_assert_true(
		not LnUiLib.background_has_embedded_logo(LnUiLib.BG_MAIN_MENU),
		"common menu-bg has no embedded logo"
	)
	_assert_true(
		LnUiLib.background_has_embedded_logo(GOTHIC_MENU_BG),
		"gothic game-backdrop embeds LOST NUMBER logo"
	)
	var theme := root.get_node_or_null("ThemeManager")
	if theme != null:
		theme.set("visual_skin_id", "gothic_crystal")
		theme.set("theme_id", "dusk")
	var displayed := LnUiLib.current_background_path("main_menu")
	_assert_true(not displayed.is_empty(), "current_background_path resolves main_menu")
	_assert_true(
		not LnUiLib.background_has_embedded_logo(displayed),
		"App-shell menu path is not the gothic baked-logo backdrop"
	)
	_assert_true(
		displayed != GOTHIC_MENU_BG,
		"main_menu displayed BG must not prefer VisualSkin menu asset"
	)


func _test_app_shell_single_logo() -> void:
	var packed := load("res://scenes/App.tscn") as PackedScene
	_assert_true(packed != null, "App.tscn loads")
	if packed == null:
		return
	var app := packed.instantiate() as Control
	root.add_child(app)
	for _frame in 24:
		await process_frame
	var router := root.get_node_or_null("ScreenRouter")
	_assert_true(router != null, "ScreenRouter autoload present")
	var menu: Node = null
	if router != null and router.has_method("get_current_screen"):
		menu = router.call("get_current_screen")
	_assert_true(menu != null, "App shell mounts main_menu")
	if menu == null:
		app.queue_free()
		await process_frame
		return
	var logo := menu.get_node_or_null("Layout/RootVBox/Hero/LogoImage") as CanvasItem
	_assert_true(logo != null, "main_menu has LogoImage")
	var path := LnUiLib.current_background_path("main_menu")
	var embedded := LnUiLib.background_has_embedded_logo(path)
	var logo_visible := logo != null and logo.visible
	_assert_true(
		logo_visible != embedded,
		"App-shell menu has exactly one logo (overlay XOR baked-in)"
	)
	_assert_true(logo_visible, "fresh App-shell menu shows LogoImage overlay")
	var top_exit := menu.get_node_or_null("Layout/RootVBox/TopBar/ExitButton") as CanvasItem
	_assert_true(
		top_exit == null or not top_exit.visible,
		"top-right Exit is hidden (dock owns exit)"
	)
	var dock_exit := menu.get_node_or_null("Layout/RootVBox/DockRows/DockRowSecondary/DockExit") as CanvasItem
	_assert_true(dock_exit != null and dock_exit.visible, "dock Exit pedestal is present")
	var dock_wheel := menu.get_node_or_null("Layout/RootVBox/DockRows/DockRow/DockWheel") as Button
	_assert_true(dock_wheel != null, "dock Wheel pedestal is present")
	if dock_wheel != null:
		var icon_rect := dock_wheel.get_node_or_null("VBox/Icon") as TextureRect
		_assert_true(icon_rect != null and icon_rect.texture != null, "dock Wheel has an icon texture")
		if icon_rect != null and icon_rect.texture != null:
			var icon_path := str(icon_rect.texture.resource_path)
			_assert_true(
				icon_path.find("wheel-x2") < 0,
				"dock Wheel does not use purple crystal wheel-x2 badge"
			)
			_assert_true(
				icon_path.find("icons/gothic/wheel") >= 0 or icon_path.find("wheel.png") >= 0,
				"dock Wheel uses gothic fortune wheel icon"
			)
	if router != null and router.has_method("unregister"):
		router.call("unregister")
	app.queue_free()
	await process_frame
	await process_frame


func _test_dark_only_theme_controls_hidden() -> void:
	var hud_packed := load("res://scenes/components/GameHud.tscn") as PackedScene
	_assert_true(hud_packed != null, "GameHud.tscn loads")
	if hud_packed != null:
		var hud := hud_packed.instantiate() as Control
		root.add_child(hud)
		for _frame in 8:
			await process_frame
		var theme_btn := hud.get_node_or_null("TopBar/BarRow/RightCluster/ThemeButton") as CanvasItem
		_assert_true(theme_btn != null, "GameHud has ThemeButton node")
		_assert_true(
			theme_btn == null or not theme_btn.visible,
			"GameHud ThemeButton hidden for dark-only release"
		)
		hud.queue_free()
		await process_frame

	var settings_packed := load("res://scenes/Settings.tscn") as PackedScene
	_assert_true(settings_packed != null, "Settings.tscn loads")
	if settings_packed != null:
		var settings := settings_packed.instantiate() as Control
		root.add_child(settings)
		for _frame in 8:
			await process_frame
		var theme_btn := settings.get_node_or_null("Scroll/VBox/ThemeButton") as CanvasItem
		_assert_true(
			theme_btn == null or not theme_btn.visible,
			"Settings ThemeButton hidden for dark-only release"
		)
		settings.queue_free()
		await process_frame

	var skin_packed := load("res://scenes/SkinPreview.tscn") as PackedScene
	_assert_true(skin_packed != null, "SkinPreview.tscn loads")
	if skin_packed != null:
		var skin := skin_packed.instantiate() as Control
		root.add_child(skin)
		for _frame in 8:
			await process_frame
		var mode_btn := skin.get_node_or_null("BottomPanel/VBox/ButtonRow/CustomButton") as CanvasItem
		_assert_true(
			mode_btn == null or not mode_btn.visible,
			"SkinPreview dark/light toggle hidden for dark-only release"
		)
		_assert_true(
			bool(skin.get("_dark_mode")) == true,
			"SkinPreview forces _dark_mode = true"
		)
		skin.queue_free()
		await process_frame


func _color_distance(a: Color, b: Color) -> float:
	var dr := a.r - b.r
	var dg := a.g - b.g
	var db := a.b - b.b
	return sqrt(dr * dr + dg * dg + db * db)


func _is_near_neon_decorative(c: Color) -> bool:
	return (
		_color_distance(c, Color("#ff1b9e")) < 0.35
		or _color_distance(c, Color("#00f0ff")) < 0.35
		or _color_distance(c, Color("#00ff6b")) < 0.35
	)


func _assert_true(value: bool, message: String) -> void:
	if not value:
		failed += 1
		push_error("FAIL: " + message)
	else:
		print("OK: " + message)
