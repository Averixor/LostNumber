extends Node

## Autoload: SFX pool + looping music. Semantic play_sfx events map to asset files.

const SFX_EVENTS := {
	"button_click": "res://assets/audio/sfx/button.mp3",
	"tile_select": "res://assets/audio/sfx/connect.mp3",
	"chain_connect": "res://assets/audio/sfx/connect.mp3",
	"chain_complete": "res://assets/audio/sfx/chain-complete.mp3",
	"merge": "res://assets/audio/sfx/chain-complete.mp3",
	"invalid": "res://assets/audio/sfx/error.mp3",
	"wheel_spin": "res://assets/audio/sfx/bonus.mp3",
	"wheel_reward": "res://assets/audio/sfx/xp.mp3",
	"achievement_unlock": "res://assets/audio/sfx/victory.mp3",
	"quest_complete": "res://assets/audio/sfx/quest-complete.mp3",
	"level_up": "res://assets/audio/sfx/xp.mp3",
	"victory": "res://assets/audio/sfx/victory.mp3",
	# Legacy aliases (smoke / older call sites)
	"connect": "res://assets/audio/sfx/connect.mp3",
	"error": "res://assets/audio/sfx/error.mp3",
	"button": "res://assets/audio/sfx/button.mp3",
	"bonus": "res://assets/audio/sfx/bonus.mp3",
	"xp": "res://assets/audio/sfx/xp.mp3",
	"quest-complete": "res://assets/audio/sfx/quest-complete.mp3",
	"level_complete": "res://assets/audio/sfx/victory.mp3",
}

const MUSIC_PATHS := {
	"ambient": "res://assets/audio/music/ambient.mp3",
	"crystal_flow": "res://assets/audio/music/Crystal Flow.mp3",
	"digital_horizon": "res://assets/audio/music/Digital Horizon.mp3",
	"neon_drift": "res://assets/audio/music/Neon Drift.mp3",
	"stellar_logic": "res://assets/audio/music/Stellar Logic.mp3",
}

const SFX_POOL_SIZE := 6

var _sfx_players: Array[AudioStreamPlayer] = []
var _music_player: AudioStreamPlayer
var _current_music_track: String = ""
var _streams: Dictionary = {}
var _sfx_last_play_ms: Dictionary = {}

const SFX_COOLDOWN_MS := {
	"chain_connect": 90,
	"connect": 90,
	"button_click": 40,
	"button": 40,
	"invalid": 120,
	"error": 120,
	"merge": 120,
	"chain_complete": 120,
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

	for player in _sfx_players:
		if not player.playing:
			player.stream = stream
			player.play()
			return

	_sfx_players[0].stream = stream
	_sfx_players[0].play()


func play_music(track: String = "ambient") -> void:
	if not _music_enabled():
		return

	var cache_key := "music:" + track
	var stream: AudioStream = _streams.get(cache_key)
	if stream == null:
		stream = _load_stream(MUSIC_PATHS.get(track, MUSIC_PATHS.ambient))
		_streams[cache_key] = stream
	if stream == null:
		return

	if _current_music_track == track and _music_player.playing:
		return

	_current_music_track = track
	_music_player.stream = stream
	_music_player.play()


func stop_music() -> void:
	_music_player.stop()
	_current_music_track = ""


func apply_audio_settings() -> void:
	if _music_enabled():
		play_music(_current_music_track if _current_music_track else "ambient")
	else:
		stop_music()


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
