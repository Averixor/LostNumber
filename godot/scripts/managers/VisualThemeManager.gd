extends "res://scripts/managers/ThemeManager.gd"
class_name VisualThemeManager

## Extends the existing color/background theme manager with data-driven art skins.
## Visual skin persistence is intentionally separate from the legacy theme JSON so
## existing installs and save data remain backward compatible.

signal visual_skin_changed(skin_id: StringName)

const DEFAULT_VISUAL_SKIN_ID: StringName = &"gothic_crystal"
const VISUAL_SKIN_PATHS := {
	&"gothic_crystal": "res://themes/skins/gothic_crystal.tres",
}

var visual_skin_id: StringName = DEFAULT_VISUAL_SKIN_ID
var _visual_skin: VisualSkin


func _ready() -> void:
	super._ready()
	_load_visual_skin_settings()
	_load_visual_skin_resource()


func get_visual_skin() -> VisualSkin:
	if _visual_skin == null:
		_load_visual_skin_resource()
	return _visual_skin


func get_visual_skin_id() -> StringName:
	return visual_skin_id


func get_visual_skin_path(id: StringName = visual_skin_id) -> String:
	return str(VISUAL_SKIN_PATHS.get(id, ""))


func get_visual_background_path(screen_kind: StringName = &"menu") -> String:
	var skin := get_visual_skin()
	if skin == null:
		return ""
	var texture := skin.background_for(screen_kind)
	if texture == null:
		return ""
	return texture.resource_path


func set_visual_skin(id: StringName) -> bool:
	var path := get_visual_skin_path(id)
	if path.is_empty() or not ResourceLoader.exists(path):
		return false
	var loaded := load(path) as VisualSkin
	if loaded == null or not loaded.is_valid() or loaded.skin_id != id:
		return false

	var changed := visual_skin_id != id or _visual_skin != loaded
	visual_skin_id = id
	_visual_skin = loaded
	_save_visual_skin_settings()
	if changed:
		visual_skin_changed.emit(visual_skin_id)
		theme_changed.emit()
	return true


func _load_visual_skin_resource() -> void:
	var path := get_visual_skin_path(visual_skin_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		visual_skin_id = DEFAULT_VISUAL_SKIN_ID
		path = get_visual_skin_path(visual_skin_id)
	if path.is_empty() or not ResourceLoader.exists(path):
		_visual_skin = null
		return
	var loaded := load(path) as VisualSkin
	if loaded == null or not loaded.is_valid():
		_visual_skin = null
		return
	visual_skin_id = loaded.skin_id
	_visual_skin = loaded


func _load_visual_skin_settings() -> void:
	if not FileAccess.file_exists(_visual_skin_settings_path()):
		return
	var data = JSON.parse_string(FileAccess.get_file_as_string(_visual_skin_settings_path()))
	if typeof(data) != TYPE_DICTIONARY:
		return
	var candidate := StringName(str(data.get("visual_skin_id", DEFAULT_VISUAL_SKIN_ID)))
	if VISUAL_SKIN_PATHS.has(candidate):
		visual_skin_id = candidate


func _save_visual_skin_settings() -> void:
	var file := FileAccess.open(_visual_skin_settings_path(), FileAccess.WRITE)
	if file != null:
		file.store_string(JSON.stringify({"visual_skin_id": str(visual_skin_id)}))


func _visual_skin_settings_path() -> String:
	return "user://lost_number_visual_skin.json"
