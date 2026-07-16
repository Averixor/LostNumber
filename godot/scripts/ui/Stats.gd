extends Control

const LnUiLib := preload("res://scripts/ui/LnUi.gd")

const STAT_ICONS := {
	"stat_games_played": "statistics.png",
	"stat_levels_completed": "achievements.png",
	"stat_highest_level": "tile-crown.png",
	"stat_total_xp": "premium.png",
	"stat_longest_chain": "bonus.png",
	"stat_wheel_spins": "tournaments.png",
}

@onready var list: VBoxContainer = $Scroll/List
@onready var back_button: Button = $BackButton
@onready var title_label: Label = $Title
@onready var background: ColorRect = $Background


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
	LnUiLib.set_background(self, LnUiLib.screen_bg("stats"))
	var theme := _autoload("ThemeManager")
	if background != null and theme != null and theme.has_method("get_background_color"):
		background.color = Color(theme.call("get_background_color"), 0.6)

	title_label.text = _i18n("btn_stats")
	back_button.text = _i18n("menu_back")
	LnUiLib.apply_title(title_label, 26)
	LnUiLib.apply_button(back_button)
	LnUiLib.apply_button_icon(back_button, "back.png")
	back_button.pressed.connect(_on_back)
	_render()
	_animate_entrance()


func _animate_entrance() -> void:
	var items: Array = [title_label]
	for child in list.get_children():
		items.append(child)
	items.append(back_button)
	await LnUiLib.animate_entrance(items)


func _render() -> void:
	for child in list.get_children():
		child.queue_free()

	var progress := _load_progress()
	var stats: Dictionary = progress.stats
	var rows := [
		["stat_games_played", int(stats.get("games_played", 0))],
		["stat_levels_completed", int(stats.get("levels_completed", 0))],
		["stat_highest_level", int(stats.get("highest_level", 0))],
		["stat_total_xp", int(stats.get("total_xp", 0))],
		["stat_longest_chain", int(stats.get("longest_chain", 0))],
		["stat_wheel_spins", int(stats.get("wheel_spins", 0))],
	]
	for row in rows:
		var panel := PanelContainer.new()
		panel.add_theme_stylebox_override("panel", LnUiLib.hud_panel())
		var hbox := HBoxContainer.new()
		hbox.add_theme_constant_override("separation", 10)
		var key: String = str(row[0])
		var val: int = int(row[1])
		var icon_name: String = STAT_ICONS.get(key, "statistics.png")
		var icon_path := LnUiLib.icon_path(icon_name)
		if ResourceLoader.exists(icon_path):
			var icon := TextureRect.new()
			icon.custom_minimum_size = Vector2(28, 28)
			icon.texture = load(icon_path)
			icon.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			hbox.add_child(icon)
		var name_label := Label.new()
		name_label.text = _i18n(key) if _has_i18n(key) else key
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_label.add_theme_color_override("font_color", LnUiLib.TEXT_MUTED)
		var val_label := Label.new()
		val_label.text = str(val)
		val_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		val_label.add_theme_color_override("font_color", LnUiLib.TEXT)
		hbox.add_child(name_label)
		hbox.add_child(val_label)
		panel.add_child(hbox)
		list.add_child(panel)


func _has_i18n(key: String) -> bool:
	var t := _i18n(key)
	return t != key


func _load_progress() -> PlayerProgress:
	var progress := PlayerProgress.new()
	var save := _autoload("SaveManager")
	if save != null and save.has_method("has_save") and bool(save.call("has_save")):
		var state = save.call("load_game")
		if state != null:
			return state.progress
	return progress


func _on_back() -> void:
	var audio := _autoload("AudioManager")
	if audio != null:
		audio.call("play_sfx", "button_click")
	_navigate_back()
