extends "res://scripts/ui/WheelCanvas.gd"
class_name ReadableWheelCanvas

## Text-first wheel presentation. The previous stone pictograms were ambiguous
## at phone scale; every sector now shows its localized reward name instead.


func _load_sector_icons() -> void:
	## Intentionally do not load res://assets/ui/icons/wheel/*.
	_sector_textures.clear()
	_sector_icon_slots.clear()


func _sector_label(sector: Dictionary) -> String:
	var key := str(sector.get("label_key", ""))
	if not key.is_empty():
		var translated := _i18n(key)
		if not translated.is_empty() and translated != key:
			return translated

	match str(sector.get("effect", "")):
		"xp":
			return "+%d XP" % int(sector.get("value", 0))
		"multiplier":
			return "×%d XP" % int(sector.get("multiplier", 2))
		_:
			return str(sector.get("label", sector.get("value", "")))


func _i18n(key: String) -> String:
	var i18n := get_node_or_null("/root/I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _draw_sector_content(
	icon_pos: Vector2,
	label_pos: Vector2,
	_sector: Dictionary,
	label: String,
	angle: float,
	highlighted: bool,
	_icon_size: float
) -> void:
	if label.is_empty():
		return
	# Place text in the middle of the former icon/caption bands. This provides
	# enough arc width for UK/RU words while keeping the hub and rim clear.
	var text_pos := icon_pos.lerp(label_pos, 0.56)
	var font_size := 13
	if label.length() > 8:
		font_size = 11
	if label.length() > 12:
		font_size = 9
	_draw_sector_label(text_pos, label, angle, highlighted, font_size)


func set_sector_icon_slot(_sector_type: String, _texture: Texture2D) -> void:
	## Compatibility no-op: the readable wheel deliberately has no sector art.
	queue_redraw()
