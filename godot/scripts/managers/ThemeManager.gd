extends Node

## Autoload: dawn/dusk theme state. Colors come from ThemeTokens (web CSS parity),
## background art from res://assets/ui/backgrounds/{dark,light}/.

signal theme_changed

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const THEMES := ["dawn", "dusk"]
const BACKGROUND_COUNT := 6

const DARK_BACKGROUNDS := [
	"res://assets/ui/backgrounds/dark/menu-bg-1.png",
	"res://assets/ui/backgrounds/dark/menu-bg-2.png",
	"res://assets/ui/backgrounds/dark/menu-bg-3.png",
	"res://assets/ui/backgrounds/dark/menu-bg-4.png",
	"res://assets/ui/backgrounds/dark/menu-bg-5.png",
	"res://assets/ui/backgrounds/dark/menu-bg-6.png",
]

const LIGHT_BACKGROUNDS := [
	"res://assets/ui/backgrounds/light/bg-light-01.png",
	"res://assets/ui/backgrounds/light/bg-light-02.png",
	"res://assets/ui/backgrounds/light/bg-light-03.png",
	"res://assets/ui/backgrounds/light/bg-light-04.png",
	"res://assets/ui/backgrounds/light/bg-light-05.png",
	"res://assets/ui/backgrounds/light/bg-light-06.png",
]

var theme_id: String = "dusk"
var background_index: int = 0


func is_dark() -> bool:
	return theme_id != "dawn"


func get_background_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_BG
	return ThemeTokensLib.DAWN_COLOR_BG


func get_panel_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_PANEL
	return ThemeTokensLib.DAWN_COLOR_PANEL


func get_accent_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_ACCENT
	return ThemeTokensLib.DAWN_COLOR_ACCENT


func get_text_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_TEXT
	return ThemeTokensLib.DAWN_COLOR_TEXT


func get_background_texture_path() -> String:
	var pool: Array = DARK_BACKGROUNDS if is_dark() else LIGHT_BACKGROUNDS
	var idx := background_index % pool.size()
	if idx < 0:
		idx += pool.size()
	return str(pool[idx])


func cycle_theme() -> void:
	var idx := THEMES.find(theme_id)
	theme_id = THEMES[(idx + 1) % THEMES.size()]
	_save()
	theme_changed.emit()


## Re-emits theme_changed so listeners (e.g. BackgroundLayer) rebuild effects
## after visual settings like bg_effects_enabled change.
func notify_visual_settings_changed() -> void:
	theme_changed.emit()


func cycle_background() -> void:
	background_index = (background_index + 1) % BACKGROUND_COUNT
	_save()
	theme_changed.emit()


func load_settings() -> void:
	if not FileAccess.file_exists(_path()):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(_path()))
	if typeof(data) != TYPE_DICTIONARY:
		return
	theme_id = str(data.get("theme_id", "dusk"))
	background_index = int(data.get("background_index", 0))


func _ready() -> void:
	load_settings()


func _save() -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"theme_id": theme_id,
			"background_index": background_index,
		}))


func _path() -> String:
	return "user://lost_number_theme.json"
