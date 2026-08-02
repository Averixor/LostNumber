extends "res://scripts/ui/WheelCanvas.gd"
class_name ReadableWheelCanvas

## Text-first wheel presentation used by Wheel.tscn.
## Base WheelCanvas already draws localized label_key captions (no sector icons);
## this subclass keeps the #47 scene identity and clearer XP/multiplier fallbacks.


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
			return _compact_wheel_label(sector)


func _i18n(key: String) -> String:
	var i18n := get_node_or_null("/root/I18nManager")
	if i18n != null and i18n.has_method("t"):
		return str(i18n.call("t", key))
	return key


func _draw_sector_label(
	pos: Vector2,
	text: String,
	angle: float,
	highlighted: bool,
	font_size_override: int = -1
) -> void:
	# Slightly tighter sizes for long UK/RU words on 420×920.
	var font_size := font_size_override
	if font_size <= 0:
		font_size = 13
		if text.length() > 8:
			font_size = 11
		if text.length() > 12:
			font_size = 9
	super._draw_sector_label(pos, text, angle, highlighted, font_size)


func set_sector_icon_slot(_sector_type: String, _texture: Texture2D) -> void:
	## Compatibility no-op: the readable wheel deliberately has no sector art.
	queue_redraw()
