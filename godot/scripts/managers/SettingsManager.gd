extends Node

## Autoload: sound/music/language toggles + per-theme background selections.

signal tile_font_scale_changed(scale: float)
signal settings_saved
signal background_selection_changed(bucket: String)

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const TILE_FONT_SCALES := [0.85, 1.0, 1.1, 1.2]

const SETTINGS_PATH := "user://lost_number_settings.json"
const CUSTOM_BG_DIR := "user://custom_backgrounds/"

const THEME_BUCKETS := ["dark", "light", "twilight"]

const SUPPORTED_BG_EXTENSIONS := ["png", "jpg", "jpeg", "webp"]

var sound_enabled: bool = true
var music_enabled: bool = true
var sfx_volume: float = 0.5
var music_volume: float = 0.3
var music_track: String = "ambient"
var language: String = "uk"
var bg_effects_enabled: bool = true
var tile_font_scale: float = 1.0

## Mirrors ThemeManager.theme_id ("dawn" | "dusk" | "twilight").
var active_theme: String = "dusk"

## Selected background path per visual bucket (empty = default built-in index 0).
var selected_background_dark: String = ""
var selected_background_light: String = ""
var selected_background_twilight: String = ""

## Custom background paths copied to user://custom_backgrounds/, keyed by bucket.
var custom_backgrounds: Dictionary = {
	"dark": [],
	"light": [],
	"twilight": [],
}


func _ready() -> void:
	_ensure_custom_dir()
	load_settings()


func _ensure_custom_dir() -> void:
	if not DirAccess.dir_exists_absolute(CUSTOM_BG_DIR):
		DirAccess.make_dir_recursive_absolute(CUSTOM_BG_DIR)


func theme_bucket_for(theme_id: String = active_theme) -> String:
	match str(theme_id):
		"dawn":
			return "light"
		"twilight":
			return "twilight"
		_:
			return "dark"


func _bucket_selected_key(bucket: String) -> String:
	match bucket:
		"light":
			return "selected_background_light"
		"twilight":
			return "selected_background_twilight"
		_:
			return "selected_background_dark"


func get_selected_background_path(bucket: String) -> String:
	match bucket:
		"light":
			return selected_background_light
		"twilight":
			return selected_background_twilight
		_:
			return selected_background_dark


func set_selected_background_path(bucket: String, path: String) -> void:
	var normalized := str(path)
	match bucket:
		"light":
			selected_background_light = normalized
		"twilight":
			selected_background_twilight = normalized
		_:
			selected_background_dark = normalized
	background_selection_changed.emit(bucket)


func current_background_for_theme(theme_id: String = active_theme) -> String:
	var bucket := theme_bucket_for(theme_id)
	var selected := get_selected_background_path(bucket)
	if not selected.is_empty():
		if selected.begins_with("user://"):
			if FileAccess.file_exists(selected):
				return selected
		elif ResourceLoader.exists(selected):
			return selected
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("get_default_background_path"):
		return str(theme_mgr.call("get_default_background_path", bucket))
	return "res://assets/ui/backgrounds/dark/menu-bg-1.png"


func get_carousel_backgrounds(theme_id: String = active_theme) -> Array[String]:
	var bucket := theme_bucket_for(theme_id)
	var result: Array[String] = []
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("discover_builtin_backgrounds"):
		for path in theme_mgr.call("discover_builtin_backgrounds", bucket):
			result.append(str(path))
	var customs: Array = custom_backgrounds.get(bucket, [])
	for entry in customs:
		var path := str(entry)
		if path.is_empty() or path in result:
			continue
		if path.begins_with("user://") and FileAccess.file_exists(path):
			result.append(path)
		elif ResourceLoader.exists(path):
			result.append(path)
	return result


func add_custom_background(bucket: String, source_path: String) -> String:
	if not source_path.begins_with("content://"):
		var ext := source_path.get_extension().to_lower()
		if ext not in SUPPORTED_BG_EXTENSIONS:
			return ""
	_ensure_custom_dir()
	var now := Time.get_datetime_dict_from_system(true)
	var safe_name := "custom_bg_%04d%02d%02d_%02d%02d%02d.png" % [
		int(now.year), int(now.month), int(now.day),
		int(now.hour), int(now.minute), int(now.second),
	]
	var dest := CUSTOM_BG_DIR + safe_name
	if not _import_image_to_png(source_path, dest):
		return ""
	if not custom_backgrounds.has(bucket):
		custom_backgrounds[bucket] = []
	var list: Array = custom_backgrounds[bucket]
	if dest not in list:
		list.append(dest)
	custom_backgrounds[bucket] = list
	return dest


func _import_image_to_png(source_path: String, dest_path: String) -> bool:
	var img := Image.new()
	var err: Error
	if source_path.begins_with("content://"):
		err = _load_image_from_uri(img, source_path)
	else:
		err = img.load(source_path)
	if err != OK:
		return false
	return img.save_png(dest_path) == OK


func _load_image_from_uri(img: Image, uri: String) -> Error:
	var bytes := FileAccess.get_file_as_bytes(uri)
	if bytes.is_empty():
		return ERR_FILE_NOT_FOUND
	if img.load_png_from_buffer(bytes) == OK:
		return OK
	if img.load_jpg_from_buffer(bytes) == OK:
		return OK
	if img.load_webp_from_buffer(bytes) == OK:
		return OK
	return ERR_FILE_UNRECOGNIZED


func apply_background_for_active_theme(path: String) -> void:
	var bucket := theme_bucket_for(active_theme)
	set_selected_background_path(bucket, path)
	save_settings()


func sync_active_theme_from_manager() -> void:
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr == null:
		return
	var raw := str(theme_mgr.get("theme_id"))
	if theme_mgr.has_method("normalize_release_theme_id"):
		active_theme = str(theme_mgr.call("normalize_release_theme_id", raw))
	else:
		active_theme = raw


func load_settings() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		sync_active_theme_from_manager()
		return
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if file == null:
		sync_active_theme_from_manager()
		return
	var data = JSON.parse_string(file.get_as_text())
	if typeof(data) != TYPE_DICTIONARY:
		sync_active_theme_from_manager()
		return
	sound_enabled = bool(data.get("sound_enabled", true))
	music_enabled = bool(data.get("music_enabled", true))
	sfx_volume = _normalize_volume(data.get("sfx_volume", 0.5), 0.5)
	music_volume = _normalize_volume(data.get("music_volume", 0.3), 0.3)
	music_track = str(data.get("music_track", "ambient"))
	language = str(data.get("language", "uk"))
	bg_effects_enabled = bool(data.get("bg_effects_enabled", true))
	tile_font_scale = normalize_tile_font_scale(data.get("tile_font_scale", 1.0))
	active_theme = str(data.get("active_theme", "dusk"))
	var theme_mgr := get_node_or_null("/root/ThemeManager")
	if theme_mgr != null and theme_mgr.has_method("normalize_release_theme_id"):
		active_theme = str(theme_mgr.call("normalize_release_theme_id", active_theme))
	elif active_theme != "dusk":
		active_theme = "dusk"
	selected_background_dark = str(data.get("selected_background_dark", ""))
	selected_background_light = str(data.get("selected_background_light", ""))
	selected_background_twilight = str(data.get("selected_background_twilight", ""))
	custom_backgrounds = _load_custom_backgrounds(data.get("custom_backgrounds", {}))
	sync_active_theme_from_manager()


func save_settings() -> void:
	sync_active_theme_from_manager()
	var data := {
		"sound_enabled": sound_enabled,
		"music_enabled": music_enabled,
		"sfx_volume": sfx_volume,
		"music_volume": music_volume,
		"music_track": music_track,
		"language": language,
		"bg_effects_enabled": bg_effects_enabled,
		"tile_font_scale": tile_font_scale,
		"active_theme": active_theme,
		"selected_background_dark": selected_background_dark,
		"selected_background_light": selected_background_light,
		"selected_background_twilight": selected_background_twilight,
		"custom_backgrounds": custom_backgrounds,
	}
	var file := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify(data))
	settings_saved.emit()


func _load_custom_backgrounds(raw: Variant) -> Dictionary:
	var result := {
		"dark": [],
		"light": [],
		"twilight": [],
	}
	if typeof(raw) != TYPE_DICTIONARY:
		return result
	for bucket in THEME_BUCKETS:
		var list: Array = []
		var source: Array = raw.get(bucket, [])
		if typeof(source) == TYPE_ARRAY:
			for entry in source:
				var path := str(entry)
				if path.is_empty():
					continue
				if path.begins_with("user://") and FileAccess.file_exists(path):
					list.append(path)
				elif ResourceLoader.exists(path):
					list.append(path)
		result[bucket] = list
	return result


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
