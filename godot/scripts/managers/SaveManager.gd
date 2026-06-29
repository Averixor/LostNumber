extends Node

const SAVE_PATH := "user://lost_number_save.json"
const GameStateScript := preload("res://scripts/core/GameState.gd")


func has_save() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func save_game(state) -> bool:
	if state == null:
		push_warning("SaveManager.save_game: state is null")
		return false

	if not state.has_method("to_save_dict"):
		push_error("SaveManager.save_game: state has no to_save_dict()")
		return false

	var payload = state.to_save_dict()

	if typeof(payload) != TYPE_DICTIONARY:
		push_error("SaveManager.save_game: payload is not Dictionary")
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)

	if file == null:
		push_error("SaveManager.save_game: cannot open save file")
		return false

	file.store_string(JSON.stringify(payload, "\t"))
	file.close()

	return true


func load_game():
	if not has_save():
		return null

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)

	if file == null:
		push_error("SaveManager.load_game: cannot open save file")
		return null

	var text := file.get_as_text()
	file.close()

	var payload = JSON.parse_string(text)

	if typeof(payload) != TYPE_DICTIONARY:
		push_error("SaveManager.load_game: save JSON is not Dictionary")
		return null

	var state = GameStateScript.new()

	if state.has_method("from_save_dict"):
		state.from_save_dict(payload)
	elif state.has_method("load_from_dict"):
		state.load_from_dict(payload)
	elif state.has_method("apply_save_dict"):
		state.apply_save_dict(payload)
	else:
		push_error("SaveManager.load_game: GameState has no load method")
		return null

	return state


func delete_save() -> bool:
	if not has_save():
		return true

	var absolute_path := ProjectSettings.globalize_path(SAVE_PATH)
	var err := DirAccess.remove_absolute(absolute_path)

	if err != OK:
		push_error("SaveManager.delete_save failed")
		return false

	return true
