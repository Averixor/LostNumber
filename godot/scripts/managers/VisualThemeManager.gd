extends "res://scripts/managers/ThemeManager.gd"
class_name VisualThemeManager

## Compatibility facade for callers introduced by the first data-driven skin slice.
## ThemeManager.gd is now the single source of truth for theme and skin state.

signal visual_skin_changed(skin_id: StringName)


func get_visual_skin_id() -> StringName:
	return StringName(visual_skin_id)


func get_visual_skin_path(id: StringName = &"") -> String:
	var requested := visual_skin_id if id.is_empty() else str(id)
	return str(VISUAL_SKIN_PATHS.get(requested, ""))


func get_visual_background_path(screen_kind: StringName = &"menu") -> String:
	return get_visual_skin_background_path(visual_skin_id, str(screen_kind), is_dark())


func set_visual_skin(id: StringName) -> bool:
	var requested := str(id)
	if not has_visual_skin_id(requested):
		return false
	set_visual_skin_id(requested)
	return true


func set_visual_skin_id(id: String) -> void:
	var previous := visual_skin_id
	super.set_visual_skin_id(id)
	if previous != visual_skin_id:
		visual_skin_changed.emit(StringName(visual_skin_id))
