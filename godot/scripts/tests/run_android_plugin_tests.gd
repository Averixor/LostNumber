extends SceneTree

## Parse export dependencies with Godot itself: malformed comments can hide remote keys.

func _init() -> void:
	var config := ConfigFile.new()
	if config.load("res://android/plugins/LostNumberFirebase.gdap") != OK:
		push_error("Cannot load LostNumberFirebase.gdap")
		quit(1)
		return
	var dependencies: PackedStringArray = config.get_value("dependencies", "remote", PackedStringArray())
	for coordinate_prefix in [
		"com.google.firebase:firebase-auth:",
		"androidx.credentials:credentials:",
		"androidx.credentials:credentials-play-services-auth:",
		"com.google.android.libraries.identity.googleid:googleid:",
	]:
		var found := false
		for dependency in dependencies:
			if dependency.begins_with(coordinate_prefix) and dependency.length() > coordinate_prefix.length():
				found = true
		if not found:
			push_error("Missing Android runtime dependency: " + coordinate_prefix)
			quit(1)
			return
	print("Android plugin dependency tests passed")
	quit(0)
