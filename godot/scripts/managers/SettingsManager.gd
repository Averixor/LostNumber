extends Node

## Autoload: sound/music/language toggles for MVP.


var sound_enabled: bool = true
var music_enabled: bool = true
var sfx_volume: float = 0.5
var music_volume: float = 0.3
var music_track: String = "ambient"
var language: String = "uk"
var bg_effects_enabled: bool = true

const SETTINGS_PATH := "user://lost_number_settings.json"


func _ready() -> void:
	load_settings()


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		return
	sound_enabled = bool(data.get("sound_enabled", true))
	music_enabled = bool(data.get("music_enabled", true))
	sfx_volume = _normalize_volume(data.get("sfx_volume", 0.5), 0.5)
	music_volume = _normalize_volume(data.get("music_volume", 0.3), 0.3)
	music_track = str(data.get("music_track", "ambient"))
	language = str(data.get("language", "uk"))
	bg_effects_enabled = bool(data.get("bg_effects_enabled", true))


func save_settings() -> void:
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"music_track": music_track,
		"language": language,
		"bg_effects_enabled": bg_effects_enabled,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))


func _normalize_volume(value: Variant, fallback: float) -> float:
	var number := float(value)
	if not is_finite(number):
		return fallback
	if number > 1.0:
		number /= 100.0
	return clampf(number, 0.0, 1.0)
