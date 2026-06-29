extends Node

## Autoload: user:// save for MVP (Godot-native, not JS localStorage format).

const SAVE_PATH := "user://lost_number_save.json"


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(state: GameState) -> bool:
	var payload := state.to_save_dict()
	var json := JSON.stringify(payload, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % SAVE_PATH)
		return false
	file.store_string(json)
	return true


func load_game(state: GameState) -> bool:
	if not has_save():
		return false
	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		return false
	var text := file.get_as_text()
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveManager: invalid save JSON")
		return false
	return state.load_from_save_dict(parsed)


func delete_save() -> void:
	if has_save():
		DirAccess.remove_absolute(SAVE_PATH)
