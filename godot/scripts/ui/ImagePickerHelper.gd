extends RefCounted

## Native gallery / file picker on Android and desktop; FileDialog fallback in editor/Linux dev.
## Android: use the system picker only — do NOT declare/request broad READ_MEDIA_IMAGES.

const LnUiLib := preload("res://scripts/ui/LnUi.gd")


static func pick_image(host: Control, i18n: Callable) -> String:
	if OS.get_name() == "Android":
		# Photo Picker / SAF via DisplayServer — no broad storage permission.
		return await _pick_with_display_server(host, i18n, true)

	if DisplayServer.has_feature(DisplayServer.FEATURE_NATIVE_DIALOG_FILE):
		return await _pick_with_display_server(host, i18n, false)

	return await _pick_with_file_dialog(host, i18n)


static func _scene_tree() -> SceneTree:
	return Engine.get_main_loop() as SceneTree


static func _await_picker_done(state: Dictionary) -> void:
	## Do not await via host.get_tree() — the Settings/BackgroundPreview host
	## can be freed while the native dialog is still open.
	var tree := _scene_tree()
	while not bool(state["done"]):
		if tree == null or not is_instance_valid(tree):
			state["done"] = true
			return
		await tree.process_frame


static func _desktop_image_filters() -> PackedStringArray:
	return PackedStringArray([
		"*.png,*.jpg,*.jpeg,*.webp;Images;image/png,image/jpeg,image/webp",
	])


static func _android_image_filters() -> PackedStringArray:
	return PackedStringArray([
		"image/*",
		"*.png,*.jpg,*.jpeg,*.webp;Images;image/png,image/jpeg,image/webp",
	])


static func _pick_with_display_server(_host: Control, i18n: Callable, on_android: bool) -> String:
	var state := {"selected": "", "done": false}
	var title := str(i18n.call("skin_custom_bg"))
	var root_dir := ""
	if on_android:
		root_dir = OS.get_system_dir(OS.SYSTEM_DIR_PICTURES)
	var filters := _android_image_filters() if on_android else _desktop_image_filters()

	DisplayServer.file_dialog_show(
		title,
		root_dir,
		"",
		false,
		DisplayServer.FILE_DIALOG_MODE_OPEN_FILE,
		filters,
		func(status: bool, paths: PackedStringArray, _filter_idx: int) -> void:
			if status and not paths.is_empty():
				state["selected"] = paths[0]
			state["done"] = true
	)
	await _await_picker_done(state)
	return str(state["selected"])


static func _pick_with_file_dialog(host: Control, i18n: Callable) -> String:
	if not is_instance_valid(host):
		return ""
	var dialog := FileDialog.new()
	dialog.file_mode = FileDialog.FILE_MODE_OPEN_FILE
	dialog.access = FileDialog.ACCESS_FILESYSTEM
	dialog.title = str(i18n.call("skin_custom_bg"))
	dialog.filters = _desktop_image_filters()
	host.add_child(dialog)
	dialog.popup_centered_ratio(0.8)
	var state := {"selected": "", "done": false}
	dialog.file_selected.connect(func(path: String) -> void:
		state["selected"] = path
		state["done"] = true
	)
	dialog.canceled.connect(func() -> void:
		state["done"] = true
	)
	await _await_picker_done(state)
	if is_instance_valid(dialog):
		dialog.queue_free()
	return str(state["selected"])
