extends Node

## Autoload: audio hooks — wire OGG/MP3 imports in Phase 5.


func play_sfx(_name: String) -> void:
	if not SettingsManager.sound_enabled:
		return
	# TODO: AudioStreamPlayer pool when assets are imported from ../public/audio/sfx/


func play_music(_track: String = "ambient") -> void:
	if not SettingsManager.music_enabled:
		return
	# TODO: WebAudio-style buffer cache not needed; use AudioStreamPlayer + loop


func stop_music() -> void:
	pass
