extends Node
## Google Sign-In (Firebase Auth) — offline-first; no Cloud Save in this stage.

signal auth_state_changed(state: String, user: Dictionary)
signal auth_error(message: String)

const PLUGIN_NAME := "LostNumberFirebase"
const SESSION_PATH := "user://auth_session.json"

const STATE_LOGGED_OUT := "logged_out"
const STATE_SIGNING_IN := "signing_in"
const STATE_LOGGED_IN := "logged_in"
const STATE_ERROR := "error"

var state: String = STATE_LOGGED_OUT
var user: Dictionary = {}
var last_error: String = ""

var _plugin = null


func _ready() -> void:
	_bind_plugin()
	_refresh_from_plugin_or_cache()


func is_android() -> bool:
	return OS.get_name() == "Android"


## Godot 4.7 JNISingleton exposes Java methods via has_java_method(), not has_method().
func _plugin_has(method_name: String) -> bool:
	if _plugin == null:
		return false
	if _plugin.has_method("has_java_method"):
		return bool(_plugin.call("has_java_method", method_name))
	return _plugin.has_method(method_name)


func _plugin_call(method_name: String, args: Array = []):
	if not _plugin_has(method_name):
		return null
	match args.size():
		0:
			return _plugin.call(method_name)
		1:
			return _plugin.call(method_name, args[0])
		2:
			return _plugin.call(method_name, args[0], args[1])
		_:
			return _plugin.callv(method_name, args)


func is_available() -> bool:
	if not is_android():
		return false
	_bind_plugin()
	if _plugin == null:
		return false
	if _plugin_has("isAvailable"):
		return bool(_plugin_call("isAvailable"))
	return false


func is_signed_in() -> bool:
	return state == STATE_LOGGED_IN and str(user.get("uid", "")) != ""


func get_display_label() -> String:
	if not is_signed_in():
		return ""
	var name := str(user.get("displayName", "")).strip_edges()
	if not name.is_empty():
		return name
	var email := str(user.get("email", "")).strip_edges()
	if not email.is_empty():
		return email
	return str(user.get("uid", ""))


func sign_in_google() -> void:
	if not is_android():
		_set_error("android_only")
		return
	_bind_plugin()
	if _plugin == null:
		_set_error("plugin_missing")
		return
	if not _plugin_has("signInGoogle"):
		_set_error("sign_in_unavailable")
		return
	if _plugin_has("isAvailable") and not bool(_plugin_call("isAvailable")):
		var err := ""
		if _plugin_has("getLastError"):
			err = str(_plugin_call("getLastError"))
		_set_error(err if not err.is_empty() else "firebase_not_configured")
		return
	state = STATE_SIGNING_IN
	last_error = ""
	auth_state_changed.emit(state, user.duplicate(true))
	_plugin_call("signInGoogle")


func sign_out() -> void:
	if not is_android():
		_clear_session()
		state = STATE_LOGGED_OUT
		user = {}
		last_error = ""
		auth_state_changed.emit(state, user.duplicate(true))
		return
	_bind_plugin()
	if _plugin != null and _plugin_has("signOut"):
		_plugin_call("signOut")
		return
	_clear_session()
	state = STATE_LOGGED_OUT
	user = {}
	auth_state_changed.emit(state, user.duplicate(true))


func _bind_plugin() -> void:
	# Retry until the Android singleton appears; do not latch a failed attempt.
	if _plugin != null or not is_android():
		return
	if not Engine.has_singleton(PLUGIN_NAME):
		push_warning("AuthManager: Android singleton %s not found" % PLUGIN_NAME)
		return
	_plugin = Engine.get_singleton(PLUGIN_NAME)
	if _plugin != null and _plugin.has_signal("auth_result"):
		var cb := Callable(self, "_on_plugin_auth_result")
		if not _plugin.is_connected("auth_result", cb):
			_plugin.connect("auth_result", cb)


func _on_plugin_auth_result(json_text: String) -> void:
	_apply_payload(_parse_json(json_text), true)


func _refresh_from_plugin_or_cache() -> void:
	if is_android() and _plugin != null and _plugin_has("getUserJson"):
		_apply_payload(_parse_json(str(_plugin_call("getUserJson"))), false)
		return
	_load_session_cache()


func _apply_payload(data: Dictionary, persist: bool) -> void:
	var status := str(data.get("status", STATE_LOGGED_OUT))
	var err := str(data.get("error", ""))
	if status == "error" or (status == STATE_ERROR):
		_set_error(err if not err.is_empty() else "auth_failed")
		return
	if status == "cancelled":
		state = STATE_LOGGED_OUT
		last_error = "cancelled"
		auth_state_changed.emit(state, user.duplicate(true))
		return
	if status == STATE_SIGNING_IN:
		state = STATE_SIGNING_IN
		last_error = ""
		auth_state_changed.emit(state, user.duplicate(true))
		return
	if status == STATE_LOGGED_IN:
		user = {
			"uid": str(data.get("uid", "")),
			"displayName": str(data.get("displayName", "")),
			"email": str(data.get("email", "")),
		}
		if str(user.get("uid", "")).is_empty():
			_set_error("missing_uid")
			return
		state = STATE_LOGGED_IN
		last_error = ""
		if persist:
			_save_session_cache()
		auth_state_changed.emit(state, user.duplicate(true))
		return
	# logged_out / default
	user = {}
	state = STATE_LOGGED_OUT
	if err == "cancelled":
		last_error = "cancelled"
	else:
		last_error = ""
	if persist:
		_clear_session()
	auth_state_changed.emit(state, user.duplicate(true))


func _set_error(message: String) -> void:
	state = STATE_ERROR
	last_error = message
	auth_error.emit(message)
	auth_state_changed.emit(state, user.duplicate(true))


func _parse_json(text: String) -> Dictionary:
	if text.is_empty():
		return {}
	var parsed = JSON.parse_string(text)
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	return parsed


func _save_session_cache() -> void:
	# Minimize PII on disk: uid + displayName only (never email/tokens).
	var payload := {
		"uid": str(user.get("uid", "")),
		"displayName": str(user.get("displayName", "")),
	}
	var file := FileAccess.open(SESSION_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(payload))


func _load_session_cache() -> void:
	if not FileAccess.file_exists(SESSION_PATH):
		return
	var file := FileAccess.open(SESSION_PATH, FileAccess.READ)
	if file == null:
		return
	var data := _parse_json(file.get_as_text())
	if str(data.get("uid", "")).is_empty():
		return
	# Cache is UI hint only; Android plugin remains source of truth when present.
	user = {
		"uid": str(data.get("uid", "")),
		"displayName": str(data.get("displayName", "")),
		"email": "",
	}
	state = STATE_LOGGED_IN


func _clear_session() -> void:
	if FileAccess.file_exists(SESSION_PATH):
		DirAccess.remove_absolute(ProjectSettings.globalize_path(SESSION_PATH))
