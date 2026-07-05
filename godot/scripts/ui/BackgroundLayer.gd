extends Control

## App-wide background: theme art from assets/ui/backgrounds/{dark,light}/,
## a dim overlay for readability (web .main-menu overlay parity), soft neon
## glow and slow floating particles. Heavy effects respect
## SettingsManager.bg_effects_enabled (low effects mode for weak devices).

const ThemeTokensLib := preload("res://scripts/ui/ThemeTokens.gd")
const AutoloadAccessLib := preload("res://scripts/managers/AutoloadAccess.gd")

const PARTICLE_AMOUNT_FULL := 14
const PARTICLE_AMOUNT_LOW := 5

@onready var base_color: ColorRect = $BaseColor
@onready var art: TextureRect = $Art
@onready var dim_overlay: ColorRect = $DimOverlay
@onready var glow: TextureRect = $Glow
@onready var effects_root: Control = $Effects

var _particles: CPUParticles2D = null


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var theme_mgr := AutoloadAccessLib.get_autoload("ThemeManager")
	if theme_mgr != null and theme_mgr.has_signal("theme_changed"):
		theme_mgr.theme_changed.connect(refresh)
	resized.connect(_on_resized)
	refresh()


func refresh() -> void:
	var theme_mgr := AutoloadAccessLib.get_autoload("ThemeManager")
	var dark := true
	if theme_mgr != null and theme_mgr.has_method("is_dark"):
		dark = bool(theme_mgr.call("is_dark"))

	base_color.color = ThemeTokensLib.COLOR_BG if dark else ThemeTokensLib.DAWN_COLOR_BG
	if theme_mgr != null and theme_mgr.has_method("get_palette"):
		var palette: Dictionary = theme_mgr.call("get_palette")
		base_color.color = palette.get("bg", base_color.color)

	art.texture = null
	if theme_mgr != null and theme_mgr.has_method("get_background_texture_path"):
		var path := str(theme_mgr.call("get_background_texture_path"))
		if ResourceLoader.exists(path):
			art.texture = load(path)

	# Web parity: dusk uses a dark overlay over the art, dawn a light veil.
	dim_overlay.color = Color(0.03, 0.01, 0.07, 0.4) if dark else Color(Color("#ffe8f8"), 0.35)

	_setup_glow(dark, theme_mgr)
	_setup_effects()


func _effects_enabled() -> bool:
	var enabled = AutoloadAccessLib.get_property("SettingsManager", "bg_effects_enabled", true)
	return bool(enabled)


func _setup_glow(dark: bool, theme_mgr: Node) -> void:
	if glow.texture == null:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
		gradient.offsets = PackedFloat32Array([0.0, 1.0])
		var tex := GradientTexture2D.new()
		tex.gradient = gradient
		tex.fill = GradientTexture2D.FILL_RADIAL
		tex.fill_from = Vector2(0.5, 0.5)
		tex.fill_to = Vector2(0.5, 0.0)
		tex.width = 256
		tex.height = 256
		glow.texture = tex
	var tint := ThemeTokensLib.MENU_TITLE_GLOW if dark else ThemeTokensLib.DAWN_COLOR_ACCENT
	if theme_mgr != null and theme_mgr.has_method("get_palette"):
		var palette: Dictionary = theme_mgr.call("get_palette")
		tint = palette.get("accent", tint)
	var alpha := 0.16 * float(theme_mgr.call("get_glow_intensity") if theme_mgr != null and theme_mgr.has_method("get_glow_intensity") else 1.0) if _effects_enabled() else 0.08
	glow.modulate = Color(tint.r, tint.g, tint.b, alpha)


func _setup_effects() -> void:
	if not _effects_enabled():
		if _particles != null:
			_particles.queue_free()
			_particles = null
		return
	if _particles != null:
		return

	# Slow floating neon dots (web .float-color parity), built only when enabled.
	_particles = CPUParticles2D.new()
	_particles.amount = PARTICLE_AMOUNT_FULL if _effects_enabled() else PARTICLE_AMOUNT_LOW
	_particles.lifetime = 12.0
	_particles.preprocess = 6.0
	_particles.explosiveness = 0.0
	_particles.direction = Vector2(0, -1)
	_particles.spread = 25.0
	_particles.gravity = Vector2.ZERO
	_particles.initial_velocity_min = 6.0
	_particles.initial_velocity_max = 16.0
	_particles.scale_amount_min = 1.5
	_particles.scale_amount_max = 4.0
	_particles.color = Color(ThemeTokensLib.ICON_PINK, 0.18)
	_on_resized()
	effects_root.add_child(_particles)


func _on_resized() -> void:
	if _particles == null:
		return
	_particles.position = size / 2.0
	_particles.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	_particles.emission_rect_extents = size / 2.0
