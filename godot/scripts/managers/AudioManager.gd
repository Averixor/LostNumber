extends Node

## Autoload: SFX pool + looping music. Semantic play_sfx events map to asset files.

const SFX_EVENTS := {
	"connect": "res://assets/audio/sfx/connect.mp3",
	"chainComplete": "res://assets/audio/sfx/chain-complete.mp3",
	"chain_complete": "res://assets/audio/sfx/chain-complete.mp3",
	"button": "res://assets/audio/sfx/button.mp3",
	"button_click": "res://assets/audio/sfx/button.mp3",
	"bonus": "res://assets/audio/sfx/bonus.mp3",
	"xp": "res://assets/audio/sfx/xp.mp3",
	"error": "res://assets/audio/sfx/error.mp3",
	"invalid": "res://assets/audio/sfx/error.mp3",
	"questComplete": "res://assets/audio/sfx/quest-complete.mp3",
	"quest_complete": "res://assets/audio/sfx/quest-complete.mp3",
	"quest-complete": "res://assets/audio/sfx/quest-complete.mp3",
	"victory": "res://assets/audio/sfx/victory.mp3",
	"level_complete": "res://assets/audio/sfx/victory.mp3",
	"tile_select": "res://assets/audio/sfx/connect.mp3",
	"chain_connect": "res://assets/audio/sfx/connect.mp3",
	"merge": "res://assets/audio/sfx/chain-complete.mp3",
	"wheel_spin": "res://assets/audio/sfx/bonus.mp3",
	"wheel_reward": "res://assets/audio/sfx/xp.mp3",
	"achievement_unlock": "res://assets/audio/sfx/victory.mp3",
	"level_up": "res://assets/audio/sfx/xp.mp3",
}

const MUSIC_PATHS := {
	"ambient": "res://assets/audio/music/ambient.mp3",
	"crystal_flow": "res://assets/audio/music/Crystal Flow.mp3",
	"digital_horizon": "res://assets/audio/music/Digital Horizon.mp3",
	"neon_drift": "res://assets/audio/music/Neon Drift.mp3",
	"stellar_logic": "res://assets/audio/music/Stellar Logic.mp3",
}

const WEB_TRACK_ALIASES := {
	"crystalFlow": "crystal_flow",
	"digitalHorizon": "digital_horizon",
	"neonDrift": "neon_drift",
	"stellarLogic": "stellar_logic",
}

const SFX_POOL_SIZE := 6

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_track: String = ""
var _streams: Dictionary = {}
var _sfx_last_play_ms: Dictionary = {}
var _app_in_background := false
var _was_music_playing_before_background := false

const SFX_COOLDOWN_MS := {
	"chain_connect": 90,
	"connect": 90,
	"button_click": 40,
	"button": 40,
	"invalid": 120,
	"error": 120,
	"merge": 120,
	"chain_complete": 120,
	"chainComplete": 120,
	"level_up": 250,
	"level_complete": 250,
	"victory": 250,
}


func _autoload(name: String) -> Node:
	return get_node_or_null("/root/" + name)


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.bus = "Master"
	add_child(_music_player)

	for i in SFX_POOL_SIZE:
		var player := AudioStreamPlayer.new()
		player.bus = "Master"
		add_child(player)
		_sfx_players.append(player)

	_preload_streams()


func _notification(what: int) -> void:
	match what:
		NOTIFICATION_APPLICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT:
			handle_app_background()
		NOTIFICATION_APPLICATION_RESUMED, NOTIFICATION_APPLICATION_FOCUS_IN:
			handle_app_foreground()


func _preload_streams() -> void:
	for key in SFX_EVENTS:
		_streams[key] = _load_stream(SFX_EVENTS[key])
	for key in MUSIC_PATHS:
		_streams["music:" + key] = _load_stream(MUSIC_PATHS[key])


func _load_stream(path: String) -> AudioStream:
	if not ResourceLoader.exists(path):
		push_warning("AudioManager: missing %s" % path)
		return null
	var stream: AudioStream = load(path)
	if stream is AudioStreamMP3:
		stream.loop = path.begins_with("res://assets/audio/music/")
	return stream


func _resolve_sfx_path(name: String) -> String:
	if SFX_EVENTS.has(name):
		return SFX_EVENTS[name]
	return ""


func _normalize_volume(value: Variant, fallback: float) -> float:
	var settings := _autoload("SettingsManager")
	if settings != null and settings.has_method("_normalize_volume"):
		return float(settings.call("_normalize_volume", value, fallback))
	var number := float(value)
	if not is_finite(number):
		return fallback
	if number > 1.0:
		number /= 100.0
	return clampf(number, 0.0, 1.0)


func _sound_enabled() -> bool:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return true
	return bool(settings.get("sound_enabled"))


func _music_enabled() -> bool:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return true
	return bool(settings.get("music_enabled"))


func _sfx_volume_multiplier(name: String) -> float:
	var base := 0.55
	if name in ["victory", "level_complete"]:
		base = 0.7
	elif name in ["button_click", "button"]:
		base = 0.45

	var settings := _autoload("SettingsManager")
	var volume := 0.5
	if settings != null:
		volume = _normalize_volume(settings.get("sfx_volume"), 0.5)
	return clampf(base * volume, 0.0, 1.0)


func _music_volume() -> float:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return 0.3
	return _normalize_volume(settings.get("music_volume"), 0.3)


func _normalize_music_track(track: String) -> String:
	var key := str(track)
	if MUSIC_PATHS.has(key):
		return key
	if WEB_TRACK_ALIASES.has(key):
		return WEB_TRACK_ALIASES[key]
	return "ambient"


func get_music_track() -> String:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return "ambient"
	return _normalize_music_track(str(settings.get("music_track")))


func play_sfx(name: String) -> void:
	if not _sound_enabled():
		return

	var now_ms := Time.get_ticks_msec()
	var cooldown := int(SFX_COOLDOWN_MS.get(name, 0))
	if cooldown > 0:
		var last_ms := int(_sfx_last_play_ms.get(name, 0))
		if now_ms - last_ms < cooldown:
			return
		_sfx_last_play_ms[name] = now_ms

	var stream: AudioStream = _streams.get(name)
	if stream == null:
		var path := _resolve_sfx_path(name)
		if path.is_empty():
			return
		stream = _load_stream(path)
		_streams[name] = stream
	if stream == null:
		return

	var volume := _sfx_volume_multiplier(name)
	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.volume_db = linear_to_db(volume)
			player.play()
			return

	_sfx_players[0].stream = stream
	_sfx_players[0].volume_db = linear_to_db(volume)
	_sfx_players[0].play()


func play_music(track: String = "ambient", force_restart: bool = false) -> void:
	if not _music_enabled():
		return

	var normalized := _normalize_music_track(track)
	var cache_key := "music:" + normalized
	var stream: AudioStream = _streams.get(cache_key)
	if stream == null:
		stream = _load_stream(MUSIC_PATHS.get(normalized, MUSIC_PATHS.ambient))
		_streams[cache_key] = stream
	if stream == null:
		return

	if not force_restart and _current_music_track == normalized and _music_player.playing:
		_music_player.volume_db = linear_to_db(_music_volume())
		return

	_current_music_track = normalized
	_music_player.stream = stream
	_music_player.volume_db = linear_to_db(_music_volume())
	_music_player.play()


func play_settings_music(force_restart: bool = false) -> void:
	play_music(get_music_track(), force_restart)


func stop_music() -> void:
	_music_player.stop()
	_music_player.stream = null
	_current_music_track = ""


func apply_audio_settings() -> void:
	if _music_enabled():
		play_settings_music(true)
	else:
		stop_music()


func handle_app_background() -> void:
	if _app_in_background:
		return
	_app_in_background = true
	_was_music_playing_before_background = _music_enabled() and _music_player.playing
	if _was_music_playing_before_background:
		_music_player.stream_paused = true


func handle_app_foreground() -> void:
	if not _app_in_background:
		return
	_app_in_background = false
	if _was_music_playing_before_background and _music_enabled():
		_music_player.stream_paused = false
		if not _music_player.playing:
			play_settings_music(false)
	_was_music_playing_before_background = false


func is_audio_enabled() -> bool:
	return _sound_enabled() and _music_enabled()


func toggle_all_audio() -> void:
	var settings := _autoload("SettingsManager")
	if settings == null:
		return
	var next := not is_audio_enabled()
	settings.set("sound_enabled", next)
	settings.set("music_enabled", next)
	if settings.has_method("save_settings"):
		settings.call("save_settings")
	apply_audio_settings()
