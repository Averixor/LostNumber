extends RefCounted
class_name DebugLog

const SESSION_ID := "98f8ff"
const LOG_PATH := "user://debug-98f8ff.log"


static func write(
	hypothesis_id: String,
	location: String,
	message: String,
	data: Dictionary = {},
	run_id: String = "pre-fix"
) -> void:
	if not OS.is_debug_build():
		return

	var entry := {
		"sessionId": SESSION_ID,
		"runId": run_id,
		"hypothesisId": hypothesis_id,
		"location": location,
		"message": message,
		"data": data,
		"timestamp": Time.get_ticks_msec(),
	}
	var line := JSON.stringify(entry)
	print("LN_DEBUG ", line)

	var file: FileAccess = null
	if FileAccess.file_exists(LOG_PATH):
		file = FileAccess.open(LOG_PATH, FileAccess.READ_WRITE)
		if file != null:
			file.seek_end()
	if file == null:
		file = FileAccess.open(LOG_PATH, FileAccess.WRITE)
	if file != null:
		file.store_line(line)
		file.close()
