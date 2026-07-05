extends Control
class_name GameHud

## In-game HUD: top bar, XP bar, target panel, bonus row with icons.

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

signal menu_pressed
signal sound_pressed
signal bonus_pressed(type: String)

@onready var level_label: Label = $TopBar/LevelBox/LevelLabel
@onready var score_label: Label = $TopBar/ScoreLabel
@onready var menu_button: Button = $TopBar/MenuButton
@onready var settings_button: Button = $TopBar/SettingsButton
@onready var sound_button: Button = $TopBar/SoundButton
@onready var xp_bar: ProgressBar = $XpRow/XpBar
@onready var xp_label: Label = $XpRow/XpLabel
@onready var target_label: Label = $TargetPanel/TargetLabel
@onready var shuffle_button: Button = $BonusBar/ShuffleButton
@onready var destroy_button: Button = $BonusBar/DestroyButton
@onready var explosion_button: Button = $BonusBar/ExplosionButton
@onready var message_label: Label = $MessageLabel


func _ready() -> void:
	menu_button.pressed.connect(func(): menu_pressed.emit())
	sound_button.pressed.connect(func(): sound_pressed.emit())
	settings_button.pressed.connect(func(): menu_pressed.emit())
	shuffle_button.pressed.connect(func(): bonus_pressed.emit("shuffle"))
	destroy_button.pressed.connect(func(): bonus_pressed.emit("destroy"))
	explosion_button.pressed.connect(func(): bonus_pressed.emit("explosion"))
	_apply_styles()
	_load_icons()


func _apply_styles() -> void:
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = ThemeTokensLib.COLOR_PANEL
	panel_style.set_corner_radius_all(ThemeTokensLib.RADIUS_HUD)
	panel_style.set_border_width_all(1)
	panel_style.border_color = ThemeTokensLib.COLOR_PANEL_BORDER
	$TargetPanel.add_theme_stylebox_override("panel", panel_style)


func _load_icons() -> void:
	_set_button_icon(shuffle_button, "res://assets/ui/icons/reset.svg")
	_set_button_icon(destroy_button, "res://assets/ui/icons/lock.svg")
	_set_button_icon(explosion_button, "res://assets/ui/icons/bonus.svg")
	_set_button_icon(menu_button, "res://assets/ui/icons/home.svg")
	_set_button_icon(settings_button, "res://assets/ui/icons/settings.svg")
	_set_button_icon(sound_button, "res://assets/ui/icons/sound.svg")


func _set_button_icon(button: Button, path: String) -> void:
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	if tex != null:
		button.icon = tex
		button.expand_icon = true


func refresh(state: GameState, i18n_t: Callable) -> void:
	level_label.text = str(i18n_t.call("level_label", [state.current_level + 1]))
	score_label.text = str(i18n_t.call("xp_label", [state.format_value(state.xp)]))
	target_label.text = "%s: %s" % [str(i18n_t.call("goal_label")), state.format_value(state.get_target())]
	xp_label.text = str(i18n_t.call("xp_label", [state.format_value(state.xp)]))

	var target_xp := maxi(100, (state.current_level + 1) * 50)
	xp_bar.max_value = target_xp
	xp_bar.value = mini(state.xp, target_xp)

	shuffle_button.text = "%s (%d)" % [i18n_t.call("bonus_shuffle"), state.get_bonus_count("shuffle")]
	destroy_button.text = "%s (%d)" % [i18n_t.call("bonus_destroy"), state.get_bonus_count("destroy")]
	explosion_button.text = "%s (%d)" % [i18n_t.call("bonus_explosion"), state.get_bonus_count("explosion")]

	_style_bonus_button(shuffle_button, "shuffle", state.get_bonus_count("shuffle"), state.active_bonus)
	_style_bonus_button(destroy_button, "destroy", state.get_bonus_count("destroy"), state.active_bonus)
	_style_bonus_button(explosion_button, "explosion", state.get_bonus_count("explosion"), state.active_bonus)


func _style_bonus_button(button: Button, kind: String, count: int, active_bonus: String) -> void:
	button.disabled = count <= 0
	var is_active := active_bonus == kind
	if button is NeonButton:
		(button as NeonButton).variant = "primary" if is_active else "secondary"
	if is_active:
		button.modulate = Color(1.2, 1.15, 1.35)
	elif count > 0:
		button.modulate = Color(1.08, 1.08, 1.15)
	else:
		button.modulate = Color(0.55, 0.55, 0.6)


func set_message(text: String) -> void:
	message_label.text = text


func set_sound_icon(enabled: bool) -> void:
	sound_button.text = "" if sound_button.icon != null else ("🔊" if enabled else "🔇")
	if sound_button.icon == null:
		sound_button.text = "🔊" if enabled else "🔇"
