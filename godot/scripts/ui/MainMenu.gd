extends Control

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")
const MenuDockScene := preload("res://scenes/components/MenuDockButton.tscn")

@onready var logo_rect: TextureRect = $Layout/RootVBox/Hero/Logo
@onready var title_label: Label = $Layout/RootVBox/Hero/Title
@onready var tagline_label: Label = $Layout/RootVBox/Hero/Tagline
@onready var play_button: NeonButton = $Layout/RootVBox/Actions/Buttons/PlayButton
@onready var continue_button: NeonButton = $Layout/RootVBox/Actions/Buttons/ContinueButton
@onready var wheel_button: NeonButton = $Layout/RootVBox/Actions/Buttons/WheelButton
@onready var quick_settings: Button = $Layout/RootVBox/Actions/QuickRow/SettingsChip
@onready var quick_stats: Button = $Layout/RootVBox/Actions/QuickRow/StatsChip
@onready var quick_about: Button = $Layout/RootVBox/Actions/QuickRow/AboutChip
@onready var dock_panel: PanelContainer = $Layout/RootVBox/DockPanel
@onready var dock_row: HBoxContainer = $Layout/RootVBox/DockPanel/DockRow
@onready var version_label: Label = $Layout/RootVBox/VersionLabel
@onready var feature_dim: ColorRect = $FeatureDim
@onready var feature_stub: Control = $FeatureStub


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _navigate(screen_id: String) -> void:
	var router := _autoload("ScreenRouter")
	if router != null and router.has_method("push"):
		router.call("push", screen_id)


func _ready() -> void:
	LnUiLib.set_background(self, "res://assets/ui/backgrounds/dark/menu-bg-1.png", 0.60)
	_setup_brand()
	_setup_buttons()
	_build_dock()
	LnUiLib.apply_panel(dock_panel)
	_refresh_save_state()
	play_button.pressed.connect(_on_play)
	continue_button.pressed.connect(_on_continue)
	wheel_button.pressed.connect(_on_wheel)
	quick_settings.pressed.connect(_on_settings)
	quick_stats.pressed.connect(_on_stats)
	quick_about.pressed.connect(_on_about)
	feature_dim.visible = false
	feature_stub.visible = false
	feature_stub.connect("closed", func(): feature_dim.visible = false)
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_music"):
		audio.call("play_music", "ambient")
	_animate_entrance()


func _setup_brand() -> void:
	title_label.text = "LOST\nNUMBER"
	LnUiLib.apply_title(title_label, 52)
	tagline_label.text = "З'єднуй числа. Ставай сильнішим."
	tagline_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_TEXT, 0.90))
	var logo_path := "res://assets/ui/logo/lost-number-logo.png"
	if ResourceLoader.exists(logo_path):
		logo_rect.texture = load(logo_path)
		logo_rect.visible = true
		title_label.visible = false
	else:
		logo_rect.visible = false
		title_label.visible = true
	version_label.text = "v%s" % str(ProjectSettings.get_setting("application/config/version", ""))
	version_label.add_theme_color_override("font_color", Color(ThemeTokensLib.COLOR_MUTED, 0.82))


func _setup_buttons() -> void:
	play_button.text = "Нова гра"
	continue_button.text = "Продовжити"
	wheel_button.text = "Колесо фортуни"
	for btn in [play_button, continue_button, wheel_button]:
		LnUiLib.apply_button(btn, true)
	LnUiLib.set_icon(play_button, "res://assets/ui/icons/new-game.svg")
	LnUiLib.set_icon(continue_button, "res://assets/ui/icons/continue.svg")
	LnUiLib.set_icon(wheel_button, "res://assets/ui/icons/wheel.svg")
	quick_settings.call("setup", "Налаштування", "res://assets/ui/icons/settings.svg")
	quick_stats.call("setup", "Статистика", "res://assets/ui/icons/statistics.svg")
	quick_about.call("setup", "Про гру", "res://assets/ui/icons/about.svg")


func _refresh_save_state() -> void:
	var save := _autoload("SaveManager")
	var has_save: bool = save != null and save.has_method("has_save") and bool(save.call("has_save"))
	continue_button.visible = true
	continue_button.disabled = not has_save
	play_button.text = "Нова гра" if has_save else "Грати"


func _build_dock() -> void:
	for child in dock_row.get_children():
		child.queue_free()
	var items := [
		["Щоденні", "res://assets/ui/icons/daily-tasks.svg", _on_dock_daily],
		["Досягнення", "res://assets/ui/icons/achievements.svg", _on_dock_achievements],
		["Бонуси", "res://assets/ui/icons/bonus.svg", _on_dock_bonuses],
	]
	for item in items:
		var btn: Button = MenuDockScene.instantiate()
		btn.call("setup", str(item[0]), str(item[1]))
		btn.pressed.connect(item[2])
		dock_row.add_child(btn)


func _animate_entrance() -> void:
	var items: Array[Control] = []
	if logo_rect.visible:
		items.append(logo_rect)
	if title_label.visible:
		items.append(title_label)
	items.append(tagline_label)
	items.append(play_button)
	items.append(continue_button)
	items.append(wheel_button)
	items.append(quick_settings)
	items.append(quick_stats)
	items.append(quick_about)
	items.append(version_label)
	for item in items:
		item.modulate.a = 0.0
	await get_tree().process_frame
	if not is_inside_tree():
		return
	for i in items.size():
		var item := items[i]
		var y := item.position.y
		item.position.y = y + 14.0
		var tween := create_tween().set_parallel(true)
		var delay := 0.035 * i
		tween.tween_property(item, "modulate:a", 1.0, 0.24).set_delay(delay)
		tween.tween_property(item, "position:y", y, 0.24).set_delay(delay)


func _play_button_sfx() -> void:
	var audio := _autoload("AudioManager")
	if audio != null and audio.has_method("play_sfx"):
		audio.call("play_sfx", "button_click")


func _show_stub(title: String, body: String) -> void:
	feature_dim.visible = true
	feature_stub.call("show_stub", title, body, "Добре")


func _on_play() -> void:
	_play_button_sfx()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("delete_save"):
		save.call("delete_save")
	_navigate("game")


func _on_continue() -> void:
	_play_button_sfx()
	_navigate("game")


func _on_wheel() -> void:
	_play_button_sfx()
	_navigate("wheel")


func _on_settings() -> void:
	_play_button_sfx()
	_navigate("settings")


func _on_stats() -> void:
	_play_button_sfx()
	_navigate("stats")


func _on_about() -> void:
	_play_button_sfx()
	_navigate("about")


func _on_dock_achievements() -> void:
	_play_button_sfx()
	_navigate("achievements")


func _on_dock_daily() -> void:
	_play_button_sfx()
	_navigate("daily")


func _on_dock_bonuses() -> void:
	_play_button_sfx()
	_show_stub("Бонуси", "Додаткові можливості будуть відкриватися поступово.")
