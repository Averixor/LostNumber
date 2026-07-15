extends SceneTree

## Graphical 40-cell chain benchmark. Run only through run-godot-isolated.sh.

const CAPTURE_SIZE := Vector2i(420, 920)
const CYCLES_PER_MODE := 4
const FRAME_P95_LIMIT_MS := 34.0
const MEMORY_GROWTH_LIMIT_BYTES := 8 * 1024 * 1024

var _failed := 0


func _init() -> void:
	call_deferred("_run")


func _run() -> void:
	if not _isolated_user_data_is_safe():
		push_error("Long-chain benchmark refused: user:// is not isolated")
		quit(2)
		return
	root.size = CAPTURE_SIZE
	# The benchmark drives GameState directly. Ignore host mouse/touch events so
	# they cannot start a real Board drag, merge the fixture, and corrupt later
	# samples when the graphical window happens to receive focus.
	root.gui_disable_input = true
	await process_frame

	var settings := root.get_node_or_null("SettingsManager")
	if settings != null:
		settings.set("music_enabled", false)
		settings.set("sound_enabled", false)
	var theme := root.get_node_or_null("ThemeManager")
	if theme != null:
		theme.set("visual_skin_id", "gothic_crystal")
		theme.set("theme_id", "dusk")

	var save := root.get_node_or_null("SaveManager")
	if save != null and save.has_method("enable_test_root"):
		var test_root := ProjectSettings.globalize_path("user://perf-save")
		DirAccess.make_dir_recursive_absolute(test_root)
		save.call("enable_test_root", test_root)

	var game := (load("res://scenes/Game.tscn") as PackedScene).instantiate()
	game.set_meta("visual_capture_no_persistence", true)
	root.add_child(game)
	for _frame in 20:
		await process_frame
		await RenderingServer.frame_post_draw

	var fixture := _prepare_fixture(game)
	if fixture.is_empty():
		quit(1)
		return

	var reports: Array[Dictionary] = []
	for effects_enabled in [true, false]:
		if settings != null:
			settings.set("bg_effects_enabled", effects_enabled)
		if theme != null and theme.has_method("notify_visual_settings_changed"):
			theme.call("notify_visual_settings_changed")
		await process_frame
		await RenderingServer.frame_post_draw
		reports.append(await _benchmark_mode(fixture, effects_enabled))

	var result := {
		"status": "passed" if _failed == 0 else "failed",
		"viewport": [CAPTURE_SIZE.x, CAPTURE_SIZE.y],
		"chain_cells": 40,
		"cycles_per_mode": CYCLES_PER_MODE,
		"limits": {
			"frame_p95_ms": FRAME_P95_LIMIT_MS,
			"memory_growth_bytes": MEMORY_GROWTH_LIMIT_BYTES,
		},
		"modes": reports,
	}
	var output := _output_path()
	DirAccess.make_dir_recursive_absolute(output.get_base_dir())
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Could not write long-chain benchmark: %s" % output)
		_failed += 1
	else:
		file.store_string(JSON.stringify(result, "\t"))
		file.close()
	print("LN_PERF %s" % JSON.stringify(result))
	print("Long-chain benchmark report: %s" % output)

	root.remove_child(game)
	game.free()
	await process_frame
	if save != null and save.has_method("disable_test_root"):
		save.call("disable_test_root")
	quit(0 if _failed == 0 else 1)


func _prepare_fixture(game: Node) -> Dictionary:
	var state = game.get("state")
	var board = game.get_node_or_null("VBox/BoardView")
	if state == null or board == null:
		push_error("Long-chain benchmark could not bind Game fixture")
		_failed += 1
		return {}
	var grid: Array = state.get("board").get("grid")
	for x in 5:
		for y in 8:
			grid[x][y] = 2
	board.call("bind_state", state)
	var path: Array[Vector2i] = []
	for y in 8:
		if y % 2 == 0:
			for x in 5:
				path.append(Vector2i(x, y))
		else:
			for x in range(4, -1, -1):
				path.append(Vector2i(x, y))
	return {"state": state, "board": board, "path": path}


func _benchmark_mode(fixture: Dictionary, effects_enabled: bool) -> Dictionary:
	var state = fixture.state
	var board = fixture.board
	var path: Array[Vector2i] = fixture.path
	var update_samples: Array[float] = []
	var frame_samples: Array[float] = []
	var cycle_memory: Array[int] = []

	for _cycle in CYCLES_PER_MODE:
		state.call("clear_chain")
		board.call("reset_all_highlights")
		# Build the chain directly through GameState. Marking the board as an
		# active pointer drag makes a graphical benchmark depend on window focus:
		# NOTIFICATION_WM_WINDOW_FOCUS_OUT intentionally cancels real gameplay
		# drags, which can otherwise clear this fixture between sampled frames.
		board.set("_dragging", false)
		await process_frame
		await RenderingServer.frame_post_draw
		for index in path.size():
			var cell: Vector2i = path[index]
			if index == 0:
				state.call("begin_chain", cell)
			elif not bool(state.call("extend_chain", cell)):
				push_error("Long-chain benchmark fixture rejected cell %s" % index)
				_failed += 1
				break
			board.set("_pending_drag_local", board.call("get_cell_center_local", cell))
			var update_start := Time.get_ticks_usec()
			board.call("_update_chain_visual")
			board.call(
				"update_preview_bubble",
				bool(state.call("can_finish_current_chain")),
				board.call("get_cell_center_local", cell)
			)
			var update_ms := float(Time.get_ticks_usec() - update_start) / 1000.0
			var frame_start := Time.get_ticks_usec()
			await process_frame
			await RenderingServer.frame_post_draw
			var frame_ms := float(Time.get_ticks_usec() - frame_start) / 1000.0
			update_samples.append(update_ms)
			frame_samples.append(frame_ms)
		cycle_memory.append(int(Performance.get_monitor(Performance.MEMORY_STATIC)))

	board.set("_dragging", false)
	board.call("reset_all_highlights")
	var frame_p95 := _percentile(frame_samples, 0.95)
	var update_p95 := _percentile(update_samples, 0.95)
	var memory_growth := 0
	if cycle_memory.size() >= 2:
		memory_growth = cycle_memory.back() - cycle_memory.front()
	if frame_p95 > FRAME_P95_LIMIT_MS:
		push_error("Long-chain frame p95 %.2fms exceeds %.2fms" % [frame_p95, FRAME_P95_LIMIT_MS])
		_failed += 1
	if memory_growth > MEMORY_GROWTH_LIMIT_BYTES:
		push_error("Long-chain memory growth %s exceeds %s" % [memory_growth, MEMORY_GROWTH_LIMIT_BYTES])
		_failed += 1
	return {
		"effects": "full" if effects_enabled else "low",
		"samples": frame_samples.size(),
		"frame_p50_ms": _percentile(frame_samples, 0.50),
		"frame_p95_ms": frame_p95,
		"frame_max_ms": _max_value(frame_samples),
		"update_p95_ms": update_p95,
		"memory_by_cycle_bytes": cycle_memory,
		"memory_growth_bytes": memory_growth,
		"reported_fps": Performance.get_monitor(Performance.TIME_FPS),
	}


func _percentile(values: Array[float], ratio: float) -> float:
	if values.is_empty():
		return 0.0
	var sorted := values.duplicate()
	sorted.sort()
	var index := int(ceil(float(sorted.size() - 1) * clampf(ratio, 0.0, 1.0)))
	return float(sorted[index])


func _max_value(values: Array[float]) -> float:
	var maximum := 0.0
	for value in values:
		maximum = maxf(maximum, value)
	return maximum


func _isolated_user_data_is_safe() -> bool:
	var expected := OS.get_environment("LOSTNUMBER_ISOLATED_USER_ROOT").simplify_path()
	var actual := ProjectSettings.globalize_path("user://").simplify_path()
	return (
		OS.get_environment("LOSTNUMBER_CAPTURE_ISOLATED") == "1"
		and not expected.is_empty()
		and actual.begins_with(expected + "/")
	)


func _output_path() -> String:
	var args := OS.get_cmdline_user_args()
	if not args.is_empty() and not str(args[0]).is_empty():
		return str(args[0])
	return ProjectSettings.globalize_path("res://../build/qa/godot-long-chain-perf.json")
