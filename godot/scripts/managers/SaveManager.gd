extends Node

## Autoload: versioned JSON saves with SHA-256 checksum + rolling backup (user://).
## Legacy flat saves (version: 2) still load without envelope.

const SAVE_FILE := "lost_number_save.json"
const BACKUP_FILE := "lost_number_save.bak.json"
const ENVELOPE_VERSION := 1

const GameStateScript := preload("res://scripts/core/GameState.gd")

var _test_root: String = ""


func _save_path(file_name: String = SAVE_FILE) -> String:
	if _test_root.is_empty():
		return "user://%s" % file_name
	return "%s/%s" % [_test_root.trim_suffix("/"), file_name]


func enable_test_root(absolute_dir: String) -> void:
	_test_root = absolute_dir


func disable_test_root() -> void:
	_test_root = ""


func has_save() -> bool:
	## True when primary or backup can be restored (same candidates as load_game).
	## File presence alone is not enough — corrupt-only must not show Continue.
	return _is_valid_save_path(_save_path(SAVE_FILE)) or _is_valid_save_path(_save_path(BACKUP_FILE))


func _is_valid_save_path(path: String) -> bool:
	var payload := _quiet_load(path)
	if payload.is_empty():
		return false
	return not _extract_and_verify_payload(payload, path).is_empty()


func save_game(state) -> bool:
	if state == null:
		push_warning("SaveManager.save_game: state is null")
		return false

	if not state.has_method("to_save_dict"):
		push_error("SaveManager.save_game: state has no to_save_dict()")
		return false

	var data: Variant = state.to_save_dict()
	if typeof(data) != TYPE_DICTIONARY:
		push_error("SaveManager.save_game: payload is not Dictionary")
		return false

	var envelope := _build_envelope(data)
	var json_text := JSON.stringify(envelope, "\t")
	var primary := _save_path(SAVE_FILE)
	var backup := _save_path(BACKUP_FILE)

	if FileAccess.file_exists(primary):
		_copy_file(primary, backup)

	return _write_text_file(primary, json_text)


func load_game(state = null):
	var primary := _save_path(SAVE_FILE)
	var backup := _save_path(BACKUP_FILE)

	if not FileAccess.file_exists(primary) and not FileAccess.file_exists(backup):
		return null

	var loaded = _try_load_path(primary, state)
	if loaded != null:
		return loaded

	push_warning("SaveManager: primary save invalid, trying backup")
	loaded = _try_load_path(backup, state)
	if loaded != null:
		# Self-heal: promote recovered backup to primary.
		_copy_file(backup, primary)
		return loaded

	push_warning("SaveManager: primary and backup saves are invalid")
	return null


func delete_save() -> bool:
	var ok := true
	for file_name in [SAVE_FILE, BACKUP_FILE]:
		var path := _save_path(file_name)
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(ProjectSettings.globalize_path(path))
			if err != OK:
				push_error("SaveManager.delete_save failed for %s" % path)
				ok = false
	return ok


func _try_load_path(path: String, state):
	var payload := _quiet_load(path)
	if payload.is_empty():
		return null

	var data: Dictionary = _extract_and_verify_payload(payload, path)
	if data.is_empty():
		return null

	var target_state = state if state != null else GameStateScript.new()

	if target_state.has_method("load_from_save_dict"):
		if not target_state.load_from_save_dict(data):
			return null
	elif target_state.has_method("from_save_dict"):
		target_state.from_save_dict(data)
	elif target_state.has_method("load_from_dict"):
		target_state.load_from_dict(data)
	elif target_state.has_method("apply_save_dict"):
		target_state.apply_save_dict(data)
	else:
		push_error("SaveManager.load_game: GameState has no load method")
		return null

	return target_state


func _build_envelope(data: Dictionary) -> Dictionary:
	var data_json := JSON.stringify(data, "\t")
	return {
		"envelope_version": ENVELOPE_VERSION,
		"saved_at": Time.get_datetime_string_from_system(true),
		"checksum": _checksum_text(data_json),
		"data_json": data_json,
	}


func _extract_and_verify_payload(payload: Dictionary, path: String) -> Dictionary:
	# New envelope format (canonical data_json + checksum).
	if payload.has("envelope_version") and payload.has("data_json"):
		var data_json := str(payload.get("data_json", ""))
		if data_json.is_empty():
			push_error("SaveManager: empty data_json (%s)" % path)
			return {}

		var expected := str(payload.get("checksum", ""))
		var actual := _checksum_text(data_json)
		if expected.is_empty() or expected != actual:
			push_warning("SaveManager: checksum mismatch (%s)" % path)
			return {}

		var data = JSON.parse_string(data_json)
		if typeof(data) != TYPE_DICTIONARY:
			push_error("SaveManager: data_json is not Dictionary (%s)" % path)
			return {}
		return data

	# Envelope with embedded data object (older ideal builds).
	if payload.has("envelope_version") and payload.has("data"):
		var data_obj: Variant = payload.get("data")
		if typeof(data_obj) != TYPE_DICTIONARY:
			push_error("SaveManager: envelope data is not Dictionary (%s)" % path)
			return {}
		var data_json := JSON.stringify(data_obj, "\t")
		var expected := str(payload.get("checksum", ""))
		if not expected.is_empty() and expected != _checksum_text(data_json):
			push_error("SaveManager: checksum mismatch (%s)" % path)
			return {}
		return data_obj

	# Legacy flat save (Capacitor-era schema version inside data).
	if payload.has("version") and payload.has("grid"):
		return payload

	push_error("SaveManager: unknown save schema (%s)" % path)
	return {}


func _quiet_load(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var text := _read_text_file(path)
	if text.is_empty():
		return {}
	var payload = _parse_json_dict(text)
	return payload if payload != null else {}


func _parse_json_dict(text: String):
	var parser := JSON.new()
	if parser.parse(text) != OK:
		return null
	if typeof(parser.data) != TYPE_DICTIONARY:
		return null
	return parser.data


func _checksum_text(text: String) -> String:
	var ctx := HashingContext.new()
	ctx.start(HashingContext.HASH_SHA256)
	ctx.update(text.to_utf8_buffer())
	return ctx.finish().hex_encode()


func _write_text_file(path: String, text: String) -> bool:
	var file := FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		push_error("SaveManager: cannot write %s" % path)
		return false
	file.store_string(text)
	file.close()
	return true


func _read_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _copy_file(from_path: String, to_path: String) -> void:
	var source := FileAccess.open(from_path, FileAccess.READ)
	if source == null:
		return
	var content := source.get_as_text()
	source.close()
	_write_text_file(to_path, content)
