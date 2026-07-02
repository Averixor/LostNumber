extends Node

## Dawn/dusk theme tokens. Background art can be wired later from assets/images/.

var theme_id: String = "dusk"
var background_index: int = 0

const THEMES := ["dawn", "dusk"]


func get_background_color() -> Color:
	if theme_id == "dawn":
		return Color(0.94, 0.91, 0.86, 1.0)
	return Color(0.11, 0.06, 0.16, 1.0)


func get_panel_color() -> Color:
	if theme_id == "dusk":
		return Color(0.18, 0.12, 0.24, 0.92)
	return Color(1.0, 1.0, 1.0, 0.88)


func get_accent_color() -> Color:
	if theme_id == "dusk":
		return Color(1.0, 0.42, 0.62, 1.0)
	return Color(0.85, 0.35, 0.55, 1.0)


func cycle_theme() -> void:
	var idx := THEMES.find(theme_id)
	theme_id = THEMES[(idx + 1) % THEMES.size()]
	background_index = (background_index + 1) % 6
	_save()


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
