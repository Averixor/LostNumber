extends SceneTree

## Deterministic visual-review capture for the portrait game slice.

const CAPTURE_SIZE := Vector2i(420, 920)


func _init() -> void:
	call_deferred("_capture")


func _capture() -> void:
	if OS.get_environment("LOSTNUMBER_CAPTURE_ISOLATED") != "1":
		push_error("Visual capture refused: run through scripts/run-godot-isolated.sh")
		quit(2)
		return
	var expected_user_root := OS.get_environment("LOSTNUMBER_ISOLATED_USER_ROOT").simplify_path()
	var actual_user_root := ProjectSettings.globalize_path("user://").simplify_path()
	if expected_user_root.is_empty() or not actual_user_root.begins_with(expected_user_root + "/"):
		push_error("Visual capture refused: user:// '%s' is not inside isolated root '%s'" % [actual_user_root, expected_user_root])
		quit(2)
		return

	root.size = CAPTURE_SIZE
	var args := OS.get_cmdline_user_args()
	if args.is_empty() or str(args[0]).is_empty():
		push_error("Visual capture requires an explicit output PNG path")
		quit(2)
		return
	var mode := args[1] if args.size() > 1 else "game"
	var locale := str(args[2]) if args.size() > 2 else "uk"
	if locale not in ["uk", "ru", "en"]:
		push_error("Unsupported visual-capture locale: %s" % locale)
		quit(2)
		return
	var settings := root.get_node_or_null("SettingsManager")
	if settings != null:
		settings.set("language", locale)
		# Captures do not need playback; suppressing music keeps the test process
		# free of decoder resources while the HUD still reads sound as enabled.
		settings.set("music_enabled", false)
		if mode == "low_effects":
			settings.set("bg_effects_enabled", false)
	var theme := root.get_node_or_null("ThemeManager")
	if theme != null:
		# Preview the target slice without mutating persisted theme settings.
		theme.set("visual_skin_id", "gothic_crystal")
		theme.set("theme_id", "dusk")
	var save := root.get_node_or_null("SaveManager")
	if save != null and save.has_method("enable_test_root"):
		var capture_save_dir := ProjectSettings.globalize_path("user://capture-save")
		DirAccess.make_dir_recursive_absolute(capture_save_dir)
		save.call("enable_test_root", capture_save_dir)
	var scene_path := "res://scenes/Game.tscn"
	match mode:
		"skin":
			scene_path = "res://scenes/SkinPreview.tscn"
		"menu":
			scene_path = "res://scenes/MainMenu.tscn"
		"settings":
			scene_path = "res://scenes/Settings.tscn"
		"background":
			scene_path = "res://scenes/BackgroundPreview.tscn"
	var packed := load(scene_path) as PackedScene
	if packed == null:
		push_error("Scene could not be loaded for visual capture: %s" % scene_path)
		quit(1)
		return

	var game := packed.instantiate()
	if mode in ["game", "chain", "long_chain", "low_effects", "states", "pause", "complete"]:
		game.set_meta("visual_capture_no_persistence", true)
	root.add_child(game)
	for _frame in 12:
		await process_frame
	if mode in ["game", "chain", "long_chain", "low_effects", "states", "pause", "complete"]:
		_apply_game_fixture(game)
		await process_frame

	if mode in ["chain", "low_effects"]:
		var state = game.get("state")
		var board = game.get_node_or_null("VBox/BoardView")
		if state != null and board != null:
			board.set("_dragging", true)
			var chain_cells := [Vector2i(0, 0), Vector2i(0, 1), Vector2i(0, 2), Vector2i(1, 3)]
			state.call("begin_chain", chain_cells[0])
			for index in range(1, chain_cells.size()):
				if not bool(state.call("extend_chain", chain_cells[index])):
					push_error("Deterministic chain fixture is invalid at step %s" % index)
					quit(1)
					return
			board.call("_update_chain_visual")
			var can_finish := bool(state.call("can_finish_current_chain"))
			board.call("update_preview_bubble", can_finish, board.call("get_cell_center_local", chain_cells.back()))
			await process_frame
	elif mode == "pause":
		game.call("_show_pause")
		await process_frame
	elif mode == "complete":
		var complete_overlay := game.get_node_or_null("LevelCompleteOverlay") as CanvasItem
		if complete_overlay == null:
			push_error("Game capture has no level-complete overlay")
			quit(1)
			return
		complete_overlay.visible = true
		await process_frame
	elif mode == "long_chain":
		var state = game.get("state")
		var board = game.get_node_or_null("VBox/BoardView")
		if state != null and board != null:
			var grid: Array = state.get("board").get("grid")
			for x in 5:
				for y in 8:
					grid[x][y] = 2
			board.call("bind_state", state)
			board.set("_dragging", true)
			var chain_cells: Array[Vector2i] = []
			for y in 8:
				if y % 2 == 0:
					for x in 5:
						chain_cells.append(Vector2i(x, y))
				else:
					for x in range(4, -1, -1):
						chain_cells.append(Vector2i(x, y))
			state.call("begin_chain", chain_cells[0])
			for index in range(1, chain_cells.size()):
				if not bool(state.call("extend_chain", chain_cells[index])):
					push_error("Long-chain fixture is invalid at step %s" % index)
					quit(1)
					return
			board.call("_update_chain_visual")
			board.call("update_preview_bubble", false, board.call("get_cell_center_local", chain_cells.back()))
			await process_frame
	elif mode == "states":
		var board = game.get_node_or_null("VBox/BoardView")
		var columns: Array = board.get("_tiles") if board != null else []
		if columns.size() != 5:
			push_error("Tile-state capture has no 5x8 board")
			quit(1)
			return
		(columns[0][0] as TileView).set_chain_selected(true, "valid")
		(columns[1][0] as TileView).set_chain_selected(true, "continue")
		(columns[2][0] as TileView).set_chain_selected(true, "invalid")
		(columns[3][0] as TileView).set_target_highlight(true)
		(columns[4][0] as TileView).set_bonus_mode(true)
		(columns[0][1] as TileView).set_carry(true)
		(columns[1][1] as TileView).set_frozen(true)
		(columns[2][1] as TileView).set_pressed_visual(true)
		await process_frame
	await RenderingServer.frame_post_draw

	var output := str(args[0])
	var image := root.get_texture().get_image()
	var error := image.save_png(output)
	if error != OK:
		push_error("Visual capture could not be saved: %s" % error)
		quit(1)
		return
	print("Visual capture saved: %s (%s, %s)" % [output, mode, locale])
	game.queue_free()
	await process_frame
	if save != null and save.has_method("disable_test_root"):
		save.call("disable_test_root")
	quit(0)


func _apply_game_fixture(game: Node) -> void:
	var state = game.get("state")
	var board = game.get_node_or_null("VBox/BoardView")
	if state == null or board == null:
		return
	state.set("current_level", 2)
	state.set("xp", 128)
	state.set("max_reached_number", 128)
	state.set("bonus_inventory", {"explosion": 1, "shuffle": 2, "destroy": 2})
	var rows := [
		[2, 4, 2, 2, 128],
		[2, 2, 4, 128, 2],
		[4, 2, 2, 8, 2],
		[2, 8, 2, 2, 2],
		[2, 4, 4, 4, 8],
		[2, 2, 2, 2, 2],
		[16, 32, 64, 128, 2],
		[8, 4, 2, 4, 4],
	]
	var grid: Array = state.get("board").get("grid")
	for y in rows.size():
		for x in rows[y].size():
			grid[x][y] = int(rows[y][x])
	board.call("bind_state", state)
	game.call("_refresh_hud")
