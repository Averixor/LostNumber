extends Node

## Autoload: dawn/dusk/twilight theme state + visual skins (web background.js parity).
## Colors come from ThemeTokens; background art from assets/ui/backgrounds/{dark,light,twilight}/.

signal theme_changed

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

const THEMES := ["dawn", "dusk", "twilight"]
## User-facing theme toggle (twilight hidden until art ships).
const UI_CYCLE_THEMES := ["dawn", "dusk"]
const BACKGROUND_COUNT := 6

const SKINS := [
	{"id": "skin-1", "name_key": "visual_skin_1", "title_frame": "none", "quick_row": "circles", "primary_btn": "pill"},
	{"id": "skin-2", "name_key": "visual_skin_2", "title_frame": "diamond", "quick_row": "circles", "primary_btn": "pill"},
	{"id": "skin-3", "name_key": "visual_skin_3", "title_frame": "arc", "quick_row": "boxed", "primary_btn": "pill"},
	{"id": "skin-4", "name_key": "visual_skin_4", "title_frame": "none", "quick_row": "circles", "primary_btn": "skew"},
	{"id": "skin-5", "name_key": "visual_skin_5", "title_frame": "arc", "quick_row": "boxed", "primary_btn": "pill"},
	{"id": "skin-6", "name_key": "visual_skin_6", "title_frame": "none", "quick_row": "boxed", "primary_btn": "pill"},
]

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

const TWILIGHT_BACKGROUNDS := [
	"res://assets/ui/backgrounds/twilight/menu-bg-1.png",
	"res://assets/ui/backgrounds/twilight/menu-bg-2.png",
	"res://assets/ui/backgrounds/twilight/menu-bg-3.png",
	"res://assets/ui/backgrounds/twilight/menu-bg-4.png",
	"res://assets/ui/backgrounds/twilight/menu-bg-5.png",
	"res://assets/ui/backgrounds/twilight/menu-bg-6.png",
]

var theme_id: String = "dusk"
var background_index: int = 0
var skin_auto: bool = true


func is_dark() -> bool:
	return theme_id != "dawn"


func theme_bucket(theme: String = theme_id) -> String:
	match str(theme):
		"dawn":
			return "light"
		"twilight":
			return "twilight"
		_:
			return "dark"


func get_skin(index: int = -1) -> Dictionary:
	var idx := background_index if index < 0 else _normalize_index(index)
	return SKINS[idx]


func get_skin_count() -> int:
	return SKINS.size()


func get_daily_index() -> int:
	var now := Time.get_datetime_dict_from_system(true)
	var day_number: int = int(now.year) * 372 + int(now.month) * 31 + int(now.day)
	return day_number % BACKGROUND_COUNT


func get_preview_valid_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_PREVIEW_VALID
	return ThemeTokensLib.DAWN_COLOR_PREVIEW_VALID


func get_preview_invalid_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_PREVIEW_INVALID
	return ThemeTokensLib.DAWN_COLOR_PREVIEW_INVALID


func get_palette() -> Dictionary:
	return ThemeTokensLib.get_skin_palette(_normalize_index(background_index), is_dark())


func get_primary_color() -> Color:
	return get_palette().get("primary", get_accent_color())


func get_secondary_color() -> Color:
	return get_palette().get("secondary", get_accent_color())


func get_danger_color() -> Color:
	return get_palette().get("danger", get_preview_invalid_color())


func get_success_color() -> Color:
	return get_palette().get("success", get_preview_valid_color())


func get_chain_valid_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_VALID
	return ThemeTokensLib.DAWN_COLOR_CHAIN_VALID


func get_chain_invalid_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_INVALID
	return ThemeTokensLib.DAWN_COLOR_CHAIN_INVALID


func get_chain_continue_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_CONTINUE
	return ThemeTokensLib.DAWN_COLOR_CHAIN_CONTINUE


func get_glow_intensity() -> float:
	return float(get_palette().get("glow", 1.0))


func get_wheel_colors() -> Array:
	return ThemeTokensLib.wheel_colors_for_palette(get_palette())


func get_title_gradient() -> Array:
	var p := get_palette()
	return [p.get("title_top"), p.get("title_mid"), p.get("title_end")]


func get_background_color() -> Color:
	return get_palette().get("bg", ThemeTokensLib.COLOR_BG if is_dark() else ThemeTokensLib.DAWN_COLOR_BG)


func get_panel_color() -> Color:
	return get_palette().get("panel", ThemeTokensLib.COLOR_PANEL if is_dark() else ThemeTokensLib.DAWN_COLOR_PANEL)


func get_accent_color() -> Color:
	return get_palette().get("accent", ThemeTokensLib.COLOR_ACCENT if is_dark() else ThemeTokensLib.DAWN_COLOR_ACCENT)


func get_text_color() -> Color:
	if is_dark():
		return ThemeTokensLib.COLOR_TEXT
	return ThemeTokensLib.DAWN_COLOR_TEXT


func discover_builtin_backgrounds(bucket: String) -> Array[String]:
	var pool := _builtin_pool_raw(bucket)
	var result: Array[String] = []
	for path in pool:
		if ResourceLoader.exists(path):
			result.append(path)
	return result


func get_default_background_path(bucket: String) -> String:
	var pool := discover_builtin_backgrounds(bucket)
	if pool.is_empty():
		return DARK_BACKGROUNDS[0]
	return pool[0]


func get_background_texture_path() -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("current_background_for_theme"):
		return str(settings.call("current_background_for_theme", theme_id))
	var pool: Array = _builtin_pool(theme_bucket())
	var idx := _normalize_index(background_index)
	return str(pool[idx])


func get_background_texture_path_for(index: int, dark_mode: bool = is_dark()) -> String:
	var bucket := "light" if not dark_mode else "dark"
	var pool := discover_builtin_backgrounds(bucket)
	if pool.is_empty():
		return DARK_BACKGROUNDS[_normalize_index(index)]
	var idx := _normalize_index(index)
	idx = mini(idx, pool.size() - 1)
	return str(pool[idx])


func path_to_index(path: String, bucket: String = theme_bucket()) -> int:
	var pool := discover_builtin_backgrounds(bucket)
	var idx := pool.find(path)
	if idx >= 0:
		return idx
	return -1


func cycle_theme() -> void:
	var idx := UI_CYCLE_THEMES.find(theme_id)
	if idx < 0:
		theme_id = UI_CYCLE_THEMES[0]
	else:
		theme_id = UI_CYCLE_THEMES[(idx + 1) % UI_CYCLE_THEMES.size()]
	if skin_auto:
		background_index = get_daily_index()
	_sync_settings_theme()
	_save()
	theme_changed.emit()


func notify_visual_settings_changed() -> void:
	theme_changed.emit()


func cycle_background() -> void:
	skin_auto = false
	background_index = (background_index + 1) % BACKGROUND_COUNT
	_sync_background_to_settings()
	_save()
	theme_changed.emit()


func set_skin_index(index: int) -> void:
	skin_auto = false
	background_index = _normalize_index(index)
	_sync_background_to_settings()
	_save()
	theme_changed.emit()


func set_skin_auto(enabled: bool) -> void:
	skin_auto = enabled
	if enabled:
		background_index = get_daily_index()
	_sync_background_to_settings()
	_save()
	theme_changed.emit()


func apply_background_path(path: String) -> void:
	skin_auto = false
	var bucket := theme_bucket()
	var idx := path_to_index(path, bucket)
	if idx >= 0:
		background_index = idx
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("apply_background_for_active_theme"):
		settings.call("apply_background_for_active_theme", path)
	else:
		_save()
	theme_changed.emit()


func load_settings() -> void:
	if not FileAccess.file_exists(_path()):
		_migrate_from_settings_manager()
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(_path()))
	if typeof(data) != TYPE_DICTIONARY:
		_migrate_from_settings_manager()
		return
	theme_id = str(data.get("theme_id", "dusk"))
	if theme_id not in THEMES:
		theme_id = "dusk" if theme_id != "dawn" else "dawn"
	background_index = int(data.get("background_index", 0))
	skin_auto = bool(data.get("skin_auto", true))
	if skin_auto:
		background_index = get_daily_index()
	_sync_settings_theme()


func _ready() -> void:
	load_settings()


func _save() -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"theme_id": theme_id,
			"background_index": background_index,
			"skin_auto": skin_auto,
		}))


func _sync_settings_theme() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	settings.set("active_theme", theme_id)
	if settings.has_method("save_settings"):
		settings.call("save_settings")


func _sync_background_to_settings() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	var path := get_background_texture_path_for(background_index, theme_bucket() != "light")
	if settings.has_method("apply_background_for_active_theme"):
		settings.call("apply_background_for_active_theme", path)


func _migrate_from_settings_manager() -> void:
	var settings := get_node_or_null("/root/SettingsManager")
	if settings == null:
		return
	theme_id = str(settings.get("active_theme"))
	if theme_id not in THEMES:
		theme_id = "dusk"


func _builtin_pool_raw(bucket: String) -> Array:
	match bucket:
		"light":
			return LIGHT_BACKGROUNDS
		"twilight":
			for path in TWILIGHT_BACKGROUNDS:
				if ResourceLoader.exists(path):
					return TWILIGHT_BACKGROUNDS
			return DARK_BACKGROUNDS
		_:
			return DARK_BACKGROUNDS


func _builtin_pool(bucket: String) -> Array:
	return _builtin_pool_raw(bucket)


func _normalize_index(index: int) -> int:
	if BACKGROUND_COUNT <= 0:
		return 0
	return ((index % BACKGROUND_COUNT) + BACKGROUND_COUNT) % BACKGROUND_COUNT


func _path() -> String:
	return "user://lost_number_theme.json"
