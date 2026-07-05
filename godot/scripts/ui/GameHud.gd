extends Control
class_name GameHud

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const LnUiLib := preload("res://scripts/ui/LnUi.gd")

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
	LnUiLib.apply_panel($TargetPanel)
	LnUiLib.apply_progress_bar(xp_bar, ThemeTokensLib.COLOR_PRIMARY)
	for b in [menu_button, settings_button, sound_button]:
		LnUiLib.apply_icon_button(b)
	for b in [shuffle_button, destroy_button, explosion_button]:
		LnUiLib.apply_button(b, false)
	for l in [level_label, score_label, xp_label, target_label, message_label]:
		LnUiLib.apply_body(l, 15)

func _load_icons() -> void:
	LnUiLib.set_icon(shuffle_button, "res://assets/ui/icons/reset.svg")
	LnUiLib.set_icon(destroy_button, "res://assets/ui/icons/logic.svg")
	LnUiLib.set_icon(explosion_button, "res://assets/ui/icons/bonus.svg")
	LnUiLib.set_icon(menu_button, "res://assets/ui/icons/home.svg")
	LnUiLib.set_icon(settings_button, "res://assets/ui/icons/settings.svg")
	LnUiLib.set_icon(sound_button, "res://assets/ui/icons/sound.svg")

func refresh(state: GameState, i18n_t: Callable) -> void:
	level_label.text = "Рівень %d" % (state.current_level + 1)
	score_label.text = "Очки: %s" % state.format_value(state.xp)
	var target := state.get_target()
	target_label.text = "Ціль: %s/%s" % [state.format_value(target), state.format_value(target * 2)]
	xp_label.text = "XP %s" % state.format_value(state.xp)
	var target_xp := maxi(100, (state.current_level + 1) * 50)
	xp_bar.max_value = target_xp
	xp_bar.value = mini(state.xp, target_xp)
	shuffle_button.text = "Мікс  %d" % state.get_bonus_count("shuffle")
	destroy_button.text = "Розбити  %d" % state.get_bonus_count("destroy")
	explosion_button.text = "3×3  %d" % state.get_bonus_count("explosion")
	_style_bonus_button(shuffle_button, "shuffle", state.get_bonus_count("shuffle"), state.active_bonus)
	_style_bonus_button(destroy_button, "destroy", state.get_bonus_count("destroy"), state.active_bonus)
	_style_bonus_button(explosion_button, "explosion", state.get_bonus_count("explosion"), state.active_bonus)

func _style_bonus_button(button: Button, kind: String, count: int, active_bonus: String) -> void:
	button.disabled = count <= 0
	var is_active := active_bonus == kind
	button.modulate = Color(1.12, 1.04, 1.16) if is_active else (Color(1, 1, 1, 1) if count > 0 else Color(0.55, 0.55, 0.62, 1))
	if button is NeonButton:
		(button as NeonButton).variant = "primary" if is_active else "secondary"

func set_message(text: String) -> void:
	message_label.text = text

func set_sound_icon(enabled: bool) -> void:
	sound_button.text = "" if sound_button.icon != null else ("🔊" if enabled else "🔇")
