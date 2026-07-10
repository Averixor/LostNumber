extends Control

## Full-screen transition: fade + optional horizontal slide (phases 13–14).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")

@onready var fade_rect: ColorRect = $Fade
@onready var slide_panel: Control = $SlidePanel

var _tween: Tween = null
var _slide_offset: float = 0.0


func _ready() -> void:
	fade_rect.color = ThemeTokensLib.COLOR_BG
	fade_rect.modulate.a = 0.0
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slide_panel.modulate.a = 0.0
	slide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)


func cover(duration: float, slide: bool = true) -> void:
	fade_rect.mouse_filter = Control.MOUSE_FILTER_STOP
	slide_panel.mouse_filter = Control.MOUSE_FILTER_STOP if slide else Control.MOUSE_FILTER_IGNORE
	if slide:
		await _animate_cover_slide(duration)
	else:
		await _fade_to(1.0, duration)


func uncover(duration: float, slide: bool = true) -> void:
	if slide:
		await _animate_uncover_slide(duration)
	else:
		await _fade_to(0.0, duration)
	fade_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	slide_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE


func _fade_to(alpha: float, duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(fade_rect, "modulate:a", alpha, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	await _tween.finished


func _animate_cover_slide(duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_slide_offset = size.x * 0.08
	slide_panel.position.x = _slide_offset
	slide_panel.modulate.a = 0.0
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(fade_rect, "modulate:a", 0.85, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN)
	_tween.tween_property(slide_panel, "modulate:a", 1.0, duration * 0.6)
	_tween.tween_property(slide_panel, "position:x", 0.0, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	await _tween.finished


func _animate_uncover_slide(duration: float) -> void:
	if _tween != null and _tween.is_valid():
		_tween.kill()
	_tween = create_tween().set_parallel(true)
	_tween.tween_property(fade_rect, "modulate:a", 0.0, duration) \
		.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
	_tween.tween_property(slide_panel, "position:x", -size.x * 0.06, duration) \
		.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_property(slide_panel, "modulate:a", 0.0, duration)
	await _tween.finished
	slide_panel.position.x = 0.0
