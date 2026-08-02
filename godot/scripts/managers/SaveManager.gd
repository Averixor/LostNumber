extends Node

## Autoload: versioned JSON saves with SHA-256 checksum + rolling backup (user://).
## Legacy flat saves (version: 2) still load without envelope.

const SAVE_FILE := "lost_number_save.json"
const BACKUP_FILE := "lost_number_save.bak.json"
const TEMP_FILE := "lost_number_save.tmp.json"
const BACKUP_TEMP_FILE := "lost_number_save.bak.tmp.json"
const ENVELOPE_VERSION := 1

const GameStateScript := preload("res://scripts/core/GameState.gd")

var _test_root: String = ""
var _test_failure_point: String = ""


func _save_path(file_name: String = SAVE_FILE) -> String:
	if _test_root.is_empty():
		return "user://%s" % file_name
	return "%s/%s" % [_test_root.trim_suffix("/"), file_name]


func enable_test_root(absolute_dir: String) -> void:
	_test_root = absolute_dir


func disable_test_root() -> void:
	_test_root = ""
	_test_failure_point = ""


func set_test_failure_point(point: String) -> void:
	if _test_root.is_empty():
		push_error("SaveManager: failure injection requires an enabled test root")
		return
	_test_failure_point = point


func clear_test_failure_point() -> void:
	_test_failure_point = ""


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
	var temp := _save_path(TEMP_FILE)
	var backup_temp := _save_path(BACKUP_TEMP_FILE)

	_cleanup_staging_files([temp, backup_temp])
	if _test_failure_point == "temp_write":
		push_error("SaveManager.save_game: injected temp write failure")
		return false
	if not _write_text_file(temp, json_text):
		_cleanup_staging_files([temp, backup_temp])
		return false

	_apply_test_temp_corruption(temp)
	if not _is_valid_save_path(temp):
		push_error("SaveManager.save_game: temporary save failed JSON/checksum verification")
		_cleanup_staging_files([temp, backup_temp])
		return false

	var primary_exists := FileAccess.file_exists(primary)
	var primary_valid := primary_exists and _is_valid_save_path(primary)
	if primary_valid:
		if _test_failure_point == "backup_copy":
			push_error("SaveManager.save_game: injected backup copy failure")
			_cleanup_staging_files([temp, backup_temp])
			return false
		if not _copy_file(primary, backup_temp):
			push_error("SaveManager.save_game: old primary could not be staged as backup")
			_cleanup_staging_files([temp, backup_temp])
			return false
		if not _promote_file(backup_temp, backup, "backup_promotion"):
			push_error("SaveManager.save_game: staged backup could not replace backup")
			_cleanup_staging_files([temp, backup_temp])
			return false
	elif primary_exists:
		if _is_valid_save_path(backup):
			push_warning("SaveManager.save_game: primary is invalid; preserving valid backup")
		else:
			push_warning(
				"SaveManager.save_game: no valid existing recovery save; promoting verified temp only"
			)

	if not _promote_file(temp, primary, "primary_promotion"):
		push_error("SaveManager.save_game: verified temp could not replace primary")
		_restore_primary_if_needed(primary, backup)
		_cleanup_staging_files([temp, backup_temp])
		return false

	return true


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
		# Self-heal through a verified staging file; backup remains untouched on failure.
		if not _restore_backup_to_primary(backup, primary):
			push_warning("SaveManager: loaded backup but could not self-heal primary")
		return loaded

	push_warning("SaveManager: primary and backup saves are invalid")
	return null


func delete_save() -> bool:
	var ok := true
	for file_name in [SAVE_FILE, BACKUP_FILE, TEMP_FILE, BACKUP_TEMP_FILE]:
		var path := _save_path(file_name)
		if FileAccess.file_exists(path):
			var err := DirAccess.remove_absolute(_absolute_path(path))
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
	file.flush()
	var write_error := file.get_error()
	file.close()
	if write_error != OK:
		push_error("SaveManager: write failed for %s (err %s)" % [path, write_error])
		return false
	return true


func _read_text_file(path: String) -> String:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return ""
	var text := file.get_as_text()
	file.close()
	return text


func _copy_file(from_path: String, to_path: String) -> bool:
	if not FileAccess.file_exists(from_path):
		push_error("SaveManager: cannot read %s for copy" % from_path)
		return false
	var err := DirAccess.copy_absolute(_absolute_path(from_path), _absolute_path(to_path))
	if err != OK:
		push_error("SaveManager: cannot copy %s to %s (err %s)" % [from_path, to_path, err])
		return false
	if _read_text_file(to_path) != _read_text_file(from_path):
		push_error("SaveManager: copied bytes do not match source (%s -> %s)" % [from_path, to_path])
		return false
	return true


func _promote_file(from_path: String, to_path: String, failure_point: String) -> bool:
	if _test_failure_point == failure_point:
		push_error("SaveManager: injected %s failure" % failure_point)
		return false
	var err := DirAccess.rename_absolute(_absolute_path(from_path), _absolute_path(to_path))
	if err != OK:
		push_error("SaveManager: cannot promote %s to %s (err %s)" % [from_path, to_path, err])
		return false
	return true


func _restore_primary_if_needed(primary: String, backup: String) -> void:
	# A failed atomic rename should leave primary untouched. If a platform violates
	# that contract, the just-verified backup still contains the old primary.
	if FileAccess.file_exists(primary) or not FileAccess.file_exists(backup):
		return
	if not _copy_file(backup, primary):
		push_error("SaveManager: primary promotion failed and backup restore also failed")


func _restore_backup_to_primary(backup: String, primary: String) -> bool:
	var temp := _save_path(TEMP_FILE)
	_cleanup_staging_files([temp])
	if not _copy_file(backup, temp):
		push_error("SaveManager: could not stage backup for primary recovery")
		_cleanup_staging_files([temp])
		return false
	if not _is_valid_save_path(temp):
		push_error("SaveManager: staged backup failed verification during primary recovery")
		_cleanup_staging_files([temp])
		return false
	if not _promote_file(temp, primary, "recovery_promotion"):
		push_error("SaveManager: verified backup stage could not replace primary")
		_cleanup_staging_files([temp])
		return false
	return true


func _cleanup_staging_files(paths: Array) -> void:
	for path_value in paths:
		var path := str(path_value)
		if not FileAccess.file_exists(path):
			continue
		var err := DirAccess.remove_absolute(_absolute_path(path))
		if err != OK:
			push_warning("SaveManager: could not clean staging file %s (err %s)" % [path, err])


func _apply_test_temp_corruption(temp: String) -> void:
	if _test_root.is_empty():
		return
	if _test_failure_point == "temp_partial":
		_write_text_file(temp, "{\"envelope_version\":1,")
	elif _test_failure_point == "temp_checksum":
		var payload := _quiet_load(temp)
		if not payload.is_empty():
			payload["checksum"] = "injected-invalid-checksum"
			_write_text_file(temp, JSON.stringify(payload, "\t"))


func _absolute_path(path: String) -> String:
	return ProjectSettings.globalize_path(path)
