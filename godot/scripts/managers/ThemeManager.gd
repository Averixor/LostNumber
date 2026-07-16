extends Node

## Autoload: brightness mode, background variant, and independent VisualSkin.
## Legacy background/palette profiles remain available as the procedural fallback.

signal theme_changed

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const VisualSkinLib := preload("res://scripts/ui/VisualSkin.gd")

const THEMES := ["dawn", "dusk", "twilight"]
## User-facing theme toggle (twilight hidden until art ships).
const UI_CYCLE_THEMES := ["dawn", "dusk"]
const BACKGROUND_COUNT := 6

const DEFAULT_VISUAL_SKIN_ID := "gothic_crystal"
const PROCEDURAL_VISUAL_SKIN_ID := "procedural_neon"
const LEGACY_SETTINGS_PATH := "user://lost_number_settings.json"
const EXISTING_USER_STATE_PATHS := [
	LEGACY_SETTINGS_PATH,
	"user://lost_number_save.json",
	"user://lost_number_save.bak.json",
	"user://legacy_capacitor_save.json",
	"user://imported_save.json",
]
const VISUAL_SKIN_ORDER := [DEFAULT_VISUAL_SKIN_ID, PROCEDURAL_VISUAL_SKIN_ID]
const VISUAL_SKIN_PATHS := {
	DEFAULT_VISUAL_SKIN_ID: "res://themes/skins/gothic_crystal.tres",
}

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
var visual_skin_id: String = DEFAULT_VISUAL_SKIN_ID

var _visual_skin_cache: Dictionary = {}


func is_dark() -> bool:
	return theme_id != "dawn"


func get_visual_skin(id: String = "") -> VisualSkin:
	var requested := visual_skin_id if id.is_empty() else id
	if requested == PROCEDURAL_VISUAL_SKIN_ID:
		return null
	if _visual_skin_cache.has(requested):
		return _visual_skin_cache[requested] as VisualSkin
	var path := str(VISUAL_SKIN_PATHS.get(requested, ""))
	if path.is_empty() or not ResourceLoader.exists(path):
		return null
	var loaded := load(path)
	if loaded is VisualSkin and (loaded as VisualSkin).is_valid_skin():
		_visual_skin_cache[requested] = loaded
		return loaded as VisualSkin
	return null


func get_visual_skin_ids() -> PackedStringArray:
	return PackedStringArray(VISUAL_SKIN_ORDER)


func has_visual_skin_id(id: String) -> bool:
	return id == PROCEDURAL_VISUAL_SKIN_ID or get_visual_skin(id) != null


func get_visual_skin_metadata(id: String = "") -> Dictionary:
	var requested := visual_skin_id if id.is_empty() else id
	if requested == PROCEDURAL_VISUAL_SKIN_ID:
		return {
			"id": PROCEDURAL_VISUAL_SKIN_ID,
			"name_key": "visual_skin_procedural_name",
			"description_key": "visual_skin_procedural_description",
		}
	var skin := get_visual_skin(requested)
	if skin == null:
		return {}
	return {
		"id": str(skin.skin_id),
		"name_key": str(skin.name_key),
		"description_key": str(skin.description_key),
	}


func set_visual_skin_id(id: String) -> void:
	if not has_visual_skin_id(id):
		return
	var changed := visual_skin_id != id
	visual_skin_id = id
	if not changed:
		return
	_save()
	theme_changed.emit()


func visual_skin_supports_light_mode(id: String = "") -> bool:
	var requested := visual_skin_id if id.is_empty() else id
	if requested == PROCEDURAL_VISUAL_SKIN_ID:
		return true
	var skin := get_visual_skin(requested)
	return skin == null or bool(skin.supports_light_mode)


func _visual_skin_dark_mode(id: String = "") -> bool:
	# Brightness is a meta-screen preference and must remain independent from
	# the gameplay art kit. A dark-only kit renders its own game components in
	# dark mode without rewriting the global dawn/dusk setting.
	return is_dark() or not visual_skin_supports_light_mode(id)


func get_visual_style(kind: StringName, id: String = "") -> StyleBox:
	var skin := get_visual_skin(id)
	if skin == null:
		return null
	var style := skin.style_for(kind)
	if style == null:
		return null
	return style.duplicate(true) as StyleBox


func get_tile_style_for_value(value: int, frozen: bool = false, id: String = "") -> StyleBox:
	var skin := get_visual_skin(id)
	if skin == null:
		return null
	var style := skin.tile_style_for_value(value, frozen)
	if style == null:
		return null
	return style.duplicate(true) as StyleBox


func get_tile_rarity(value: int) -> StringName:
	return VisualSkinLib.rarity_for_value(value)


func get_tile_face_color(value: int) -> Color:
	var skin := get_visual_skin()
	if skin != null:
		return skin.tile_face_color_for_value(value)
	if ThemeTokensLib.TILE_COLORS.has(value):
		return ThemeTokensLib.TILE_COLORS[value]
	if ThemeTokensLib.TILE_GRADIENTS.has(value):
		var pair: Array = ThemeTokensLib.TILE_GRADIENTS[value]
		return pair[0].lerp(pair[1], 0.5)
	return ThemeTokensLib.COLOR_CELL


func effects_enabled() -> bool:
	var settings := get_node_or_null("/root/SettingsManager")
	return settings == null or bool(settings.get("bg_effects_enabled"))


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


func get_preview_valid_color(use_visual_skin: bool = false) -> Color:
	var skin := get_visual_skin() if use_visual_skin else null
	if skin != null:
		return skin.success_color
	if is_dark():
		return ThemeTokensLib.COLOR_PREVIEW_VALID
	return ThemeTokensLib.DAWN_COLOR_PREVIEW_VALID


func get_preview_invalid_color(use_visual_skin: bool = false) -> Color:
	var skin := get_visual_skin() if use_visual_skin else null
	if skin != null:
		return skin.danger_color
	if is_dark():
		return ThemeTokensLib.COLOR_PREVIEW_INVALID
	return ThemeTokensLib.DAWN_COLOR_PREVIEW_INVALID


func get_palette(use_visual_skin: bool = false) -> Dictionary:
	var skin := get_visual_skin() if use_visual_skin else null
	if skin != null:
		return skin.palette(_visual_skin_dark_mode())
	return ThemeTokensLib.get_skin_palette(_normalize_index(background_index), is_dark())


func get_primary_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("primary", get_accent_color(use_visual_skin))


func get_secondary_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("secondary", get_accent_color(use_visual_skin))


func get_danger_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("danger", get_preview_invalid_color(use_visual_skin))


func get_success_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("success", get_preview_valid_color(use_visual_skin))


func get_chain_valid_color() -> Color:
	var skin := get_visual_skin()
	if skin != null:
		return skin.chain_valid_color
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_VALID
	return ThemeTokensLib.DAWN_COLOR_CHAIN_VALID


func get_chain_invalid_color() -> Color:
	var skin := get_visual_skin()
	if skin != null:
		return skin.chain_invalid_color
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_INVALID
	return ThemeTokensLib.DAWN_COLOR_CHAIN_INVALID


func get_chain_continue_color() -> Color:
	var skin := get_visual_skin()
	if skin != null:
		return skin.chain_continue_color
	if is_dark():
		return ThemeTokensLib.COLOR_CHAIN_CONTINUE
	return ThemeTokensLib.DAWN_COLOR_CHAIN_CONTINUE


func get_chain_core_color() -> Color:
	var skin := get_visual_skin()
	return skin.chain_core_color if skin != null else Color(0.96, 0.98, 1.0, 0.95)


func get_particle_color(use_visual_skin: bool = false) -> Color:
	var skin := get_visual_skin() if use_visual_skin else null
	return skin.particle_color if skin != null else ThemeTokensLib.ICON_PINK


func get_overlay_color(alpha: float = -1.0, use_visual_skin: bool = false) -> Color:
	var skin := get_visual_skin() if use_visual_skin else null
	var color := skin.overlay_color(_visual_skin_dark_mode()) if skin != null else (
		Color(0.03, 0.01, 0.07, 0.40) if is_dark() else Color(Color("#ffe8f8"), 0.35)
	)
	if alpha >= 0.0:
		color.a = alpha
	return color


func get_glow_intensity(use_visual_skin: bool = false) -> float:
	return float(get_palette(use_visual_skin).get("glow", 1.0))


func get_wheel_colors() -> Array:
	return ThemeTokensLib.wheel_colors_for_palette(get_palette())


func get_title_gradient() -> Array:
	var p := get_palette()
	return [p.get("title_top"), p.get("title_mid"), p.get("title_end")]


func get_background_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("bg", ThemeTokensLib.COLOR_BG if is_dark() else ThemeTokensLib.DAWN_COLOR_BG)


func get_panel_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("panel", ThemeTokensLib.COLOR_PANEL if is_dark() else ThemeTokensLib.DAWN_COLOR_PANEL)


func get_accent_color(use_visual_skin: bool = false) -> Color:
	return get_palette(use_visual_skin).get("accent", ThemeTokensLib.COLOR_ACCENT if is_dark() else ThemeTokensLib.DAWN_COLOR_ACCENT)


func get_text_color(use_visual_skin: bool = false) -> Color:
	var skin := get_visual_skin() if use_visual_skin else null
	if skin != null:
		return skin.text_color(_visual_skin_dark_mode())
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


func get_background_texture_path(screen: String = "") -> String:
	var settings := get_node_or_null("/root/SettingsManager")
	# Background selection is independent from the component skin. Preserve any
	# explicit custom or built-in choice before using the skin's default art.
	if settings != null and settings.has_method("get_selected_background_path"):
		var selected := str(settings.call("get_selected_background_path", theme_bucket()))
		if selected.begins_with("user://") and FileAccess.file_exists(selected):
			return selected
		if ResourceLoader.exists(selected):
			return selected
	# The first vertical slice is intentionally game-only. Meta screens keep
	# their existing background variant until their own art pass is approved.
	var skin := get_visual_skin() if screen == "game" else null
	if skin != null:
		var texture := skin.background_for(screen)
		if texture != null and not texture.resource_path.is_empty():
			return texture.resource_path
	if settings != null and settings.has_method("current_background_for_theme"):
		return str(settings.call("current_background_for_theme", theme_id))
	var pool: Array = _builtin_pool(theme_bucket())
	var idx := _normalize_index(background_index)
	return str(pool[idx])


func get_visual_skin_background_path(id: String, screen: String = "", dark_mode: bool = is_dark()) -> String:
	if id == PROCEDURAL_VISUAL_SKIN_ID:
		return get_background_texture_path_for(background_index, dark_mode)
	var skin := get_visual_skin(id)
	if skin == null:
		return ""
	var texture := skin.background_for(screen)
	return texture.resource_path if texture != null else ""


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
	var idx := 0 if path.is_empty() else path_to_index(path, bucket)
	if idx >= 0:
		background_index = idx
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null and settings.has_method("apply_background_for_active_theme"):
		settings.call("apply_background_for_active_theme", path)
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
	# Theme files written before VisualSkin existed must keep their old look.
	visual_skin_id = _resolve_saved_visual_skin_id(data)
	_sync_settings_theme()
	if skin_auto:
		background_index = get_daily_index()
		# SettingsManager resolves selected paths first, so refresh today's path
		# on every launch instead of leaving yesterday's auto choice frozen.
		# Sync active_theme first so dawn choices land in the light bucket.
		_sync_background_to_settings()


func _ready() -> void:
	load_settings()


func _save() -> void:
	var file := FileAccess.open(_path(), FileAccess.WRITE)
	if file:
		file.store_string(JSON.stringify({
			"theme_id": theme_id,
			"background_index": background_index,
			"skin_auto": skin_auto,
			"visual_skin_id": visual_skin_id,
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
	# Persist the decision immediately so a later Settings save cannot change a
	# clean install into a legacy install on the next launch.
	visual_skin_id = _default_visual_skin_for_install()
	var settings := get_node_or_null("/root/SettingsManager")
	if settings != null:
		theme_id = str(settings.get("active_theme"))
		if theme_id not in THEMES:
			theme_id = "dusk"
	_save()


func _default_visual_skin_for_install() -> String:
	for path in EXISTING_USER_STATE_PATHS:
		if FileAccess.file_exists(str(path)):
			return PROCEDURAL_VISUAL_SKIN_ID
	return DEFAULT_VISUAL_SKIN_ID


func _resolve_saved_visual_skin_id(data: Dictionary) -> String:
	var requested := str(data.get("visual_skin_id", PROCEDURAL_VISUAL_SKIN_ID))
	return requested if has_visual_skin_id(requested) else PROCEDURAL_VISUAL_SKIN_ID


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



func set_theme_mode(dark_mode: bool) -> void:
	theme_id = "dusk" if dark_mode else "dawn"
	_sync_settings_theme()
	_save()
	theme_changed.emit()


func set_skin_profile(index: int, dark_mode: bool) -> void:
	theme_id = "dusk" if dark_mode else "dawn"
	skin_auto = false
	background_index = _normalize_index(index)
	_sync_settings_theme()
	_sync_background_to_settings()
	_save()
	theme_changed.emit()


func get_skin_profile_id() -> String:
	if visual_skin_id != PROCEDURAL_VISUAL_SKIN_ID:
		return "%s_%s" % [visual_skin_id, "dark" if _visual_skin_dark_mode() else theme_bucket()]
	return "%s_%d" % [theme_bucket(), background_index + 1]


func _path() -> String:
	return "user://lost_number_theme.json"
