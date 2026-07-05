extends Node

## Autoload: sound/music/language toggles for MVP.

signal tile_font_scale_changed(scale: float)

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const TILE_FONT_SCALES := [0.8, 1.0, 1.2, 1.4]

var sound_enabled: bool = true
var music_enabled: bool = true
var sfx_volume: float = 0.5
var music_volume: float = 0.3
var music_track: String = "ambient"
var language: String = "uk"
var bg_effects_enabled: bool = true
var tile_font_scale: float = 1.0

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
	tile_font_scale = normalize_tile_font_scale(data.get("tile_font_scale", 1.0))


func save_settings() -> void:
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"music_track": music_track,
		"language": language,
		"bg_effects_enabled": bg_effects_enabled,
		"tile_font_scale": tile_font_scale,
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


func normalize_tile_font_scale(value: Variant) -> float:
	var number := float(value)
	if not is_finite(number):
		return 1.0
	return clampf(number, TILE_FONT_SCALES[0], TILE_FONT_SCALES[TILE_FONT_SCALES.size() - 1])


func set_tile_font_scale(scale: float) -> void:
	var normalized := normalize_tile_font_scale(scale)
	if is_equal_approx(tile_font_scale, normalized):
		return
	tile_font_scale = normalized
	tile_font_scale_changed.emit(tile_font_scale)


func get_tile_font_size(cell_size: Vector2 = Vector2.ZERO, digit_count: int = 1) -> int:
	if cell_size.x > 0.0 and cell_size.y > 0.0:
		return ThemeTokensLib.tile_font_size_for_cell(cell_size, digit_count, tile_font_scale)
	return maxi(8, int(round(ThemeTokensLib.FONT_SIZE_TILE * tile_font_scale)))


func tile_font_scale_to_index(scale: float = tile_font_scale) -> int:
	var normalized := normalize_tile_font_scale(scale)
	var best_idx := 1
	var best_delta := absf(normalized - TILE_FONT_SCALES[1])
	for i in TILE_FONT_SCALES.size():
		var delta := absf(normalized - TILE_FONT_SCALES[i])
		if delta < best_delta:
			best_delta = delta
			best_idx = i
	return best_idx


func tile_font_scale_from_index(index: int) -> float:
	return TILE_FONT_SCALES[clampi(index, 0, TILE_FONT_SCALES.size() - 1)]
