extends Control

## Main menu (web parity: primary actions, quick-row chips, bottom dock).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const MenuDockScene := preload("res://scenes/components/MenuDockButton.tscn")
const MenuQuickChipScene := preload("res://scenes/components/MenuQuickChip.tscn")

@onready var title_label: Label = $Layout/RootVBox/Hero/Title
@onready var tagline_label: Label = $Layout/RootVBox/Hero/Tagline
@onready var play_button: NeonButton = $Layout/RootVBox/Actions/Buttons/PlayButton
@onready var continue_button: NeonButton = $Layout/RootVBox/Actions/Buttons/ContinueButton
@onready var quick_settings: Button = $Layout/RootVBox/Actions/QuickRow/SettingsChip
@onready var quick_stats: Button = $Layout/RootVBox/Actions/QuickRow/StatsChip
@onready var quick_about: Button = $Layout/RootVBox/Actions/QuickRow/AboutChip
@onready var dock_panel: PanelContainer = $Layout/RootVBox/DockPanel
@onready var dock_row: HBoxContainer = $Layout/RootVBox/DockPanel/DockRow
@onready var version_label: Label = $Layout/RootVBox/VersionLabel
@onready var feature_dim: ColorRect = $FeatureDim
@onready var feature_stub: Control = $FeatureStub

var _tagline_taps := 0
var _tagline_tap_time := 0


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _i18n(key: String, args: Array = []) -> String:
	var i18n := _autoload("I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key, args))
	return key


func _navigate(screen_id: String) -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		router.call("push", screen_id)


func _ready() -> void:
	title_label.text = _i18n("app_title").to_upper().replace(" ", "\n")
	_apply_title_gradient_height()
	tagline_label.text = _i18n("main_subtitle")
	tagline_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_TEXT, 0.9))
	tagline_label.gui_input.connect(_on_tagline_input)

	play_button.text = _i18n("menu_play")
	continue_button.text = _i18n("menu_continue")
	version_label.text = _i18n("version_label", [str(ProjectSettings.get_setting("application/config/version", ""))])
	version_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_MUTED, 0.8))

	_set_button_icon(play_button, "res://assets/ui/icons/new-game.svg")
	_set_button_icon(continue_button, "res://assets/ui/icons/continue.svg")

	quick_settings.call("setup", _i18n("menu_settings"), "res://assets/ui/icons/settings.svg")
	quick_stats.call("setup", _i18n("btn_stats"), "res://assets/ui/icons/statistics.svg")
	quick_about.call("setup", _i18n("btn_about"), "res://assets/ui/icons/about.svg")

	_build_dock()
	_style_dock_panel()

	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))
	continue_button.visible = has_save
	play_button.text = _i18n("menu_new_game") if has_save else _i18n("menu_play")

	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	quick_settings.pressed.connect(_on_settings)
	quick_stats.pressed.connect(_on_stats)
	quick_about.pressed.connect(_on_about)
	feature_stub.connect("closed", func(): feature_dim.visible = false)

	feature_dim.visible = false
	feature_stub.visible = false

	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "ambient")

	_animate_entrance()


func _build_dock() -> void:
	for child in dock_row.get_children():
		child.queue_free()

	var items := [
		["dock_premium", "res://assets/ui/icons/premium.svg", _on_dock_premium],
		["dock_tournaments", "res://assets/ui/icons/tournaments.svg", _on_dock_tournaments],
		["dock_achievements", "res://assets/ui/icons/achievements.svg", _on_dock_achievements],
		["dock_daily", "res://assets/ui/icons/daily-tasks.svg", _on_dock_daily],
		["dock_bonuses", "res://assets/ui/icons/bonus.svg", _on_dock_bonuses],
	]
	for item in items:
		var btn: Button = MenuDockScene.instantiate()
		btn.call("setup", _i18n(str(item[0])), str(item[1]))
		btn.pressed.connect(item[2])
		dock_row.add_child(btn)


func _style_dock_panel() -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = ThemeTokensLib.MENU_DOCK_BG
	style.set_corner_radius_all(ThemeTokensLib.RADIUS_PANEL)
	style.set_border_width_all(1)
	style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	style.set_content_margin_all(8)
	dock_panel.add_theme_stylebox_override("panel", style)


func _set_button_icon(button: Button, path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true


func _apply_title_gradient_height() -> void:
	var material := title_label.material
	if material is ShaderMaterial:
		var height: float = maxf(title_label.get_minimum_size().y, 1.0)
		(material as ShaderMaterial).set_shader_parameter("gradient_height", height)


func _animate_entrance() -> void:
	var items: Array[Control] = [title_label, tagline_label, play_button]
	if continue_button.visible:
		items.append(continue_button)
	for chip in [quick_settings, quick_stats, quick_about]:
		items.append(chip)
	for child in dock_row.get_children():
		if child is Control:
			items.append(child)
	items.append(version_label)

	for item in items:
		item.modulate.a = 0.0

	await get_tree().process_frame
	if not is_inside_tree():
		return

	for i in items.size():
		var item := items[i]
		var target_y := item.position.y
		item.position.y = target_y + 16.0
		var tween := create_tween().set_parallel(true)
		var delay := 0.05 * i
		tween.tween_property(item, "modulate:a", 1.0, 0.28) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		tween.tween_property(item, "position:y", target_y, 0.28) \
			.set_delay(delay).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)


func _on_tagline_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.double_click:
		var theme_mgr := _autoload("ThemeManager")
		if theme_mgr != null and theme_mgr.has_method("cycle_background"):
			theme_mgr.call("cycle_background")
	elif event is InputEventMouseButton and event.pressed:
		var now := Time.get_ticks_msec()
		if now - _tagline_tap_time > 400:
			_tagline_taps = 0
		_tagline_tap_time = now
		_tagline_taps += 1
		if _tagline_taps >= 2:
			_tagline_taps = 0
			var theme_mgr := _autoload("ThemeManager")
			if theme_mgr != null and theme_mgr.has_method("cycle_background"):
				theme_mgr.call("cycle_background")


func _play_button_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "button_click")


func _show_feature_stub(title_key: String, body_key: String, extra_bullets: Array = []) -> void:
	var body := _i18n(body_key)
	for bullet_key in extra_bullets:
		body += "\n• " + _i18n(str(bullet_key))
	feature_dim.visible = true
	feature_stub.call("show_stub", _i18n(title_key), body, _i18n("feature_stub_ok"))


func _on_play() -> void:
	_play_button_sfx()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("delete_save"):
		save.call("delete_save")
	_navigate("game")


func _on_continue() -> void:
	_play_button_sfx()
	_navigate("game")


func _on_settings() -> void:
	_play_button_sfx()
	_navigate("settings")


func _on_stats() -> void:
	_play_button_sfx()
	_navigate("stats")


func _on_about() -> void:
	_play_button_sfx()
	_navigate("about")


func _on_dock_premium() -> void:
	_play_button_sfx()
	_show_feature_stub("feature_premium_title", "feature_premium_intro", [
		"feature_premium_bullet_ad",
		"feature_premium_bullet_themes",
		"feature_premium_bullet_tournaments",
		"feature_premium_note",
	])


func _on_dock_tournaments() -> void:
	_play_button_sfx()
	_show_feature_stub("feature_tournaments_title", "feature_tournaments_intro", [
		"feature_tournaments_bullet_weekly",
		"feature_tournaments_note",
	])


func _on_dock_achievements() -> void:
	_play_button_sfx()
	_navigate("achievements")


func _on_dock_daily() -> void:
	_play_button_sfx()
	_navigate("daily")


func _on_dock_bonuses() -> void:
	_play_button_sfx()
	_show_feature_stub("feature_bonuses_title", "feature_bonuses_text")
