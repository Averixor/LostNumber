extends Node

## Offline-first leaderboard stub. Replace HTTP calls when Play Games / backend is ready.

signal submit_completed(board_id: String, ok: bool)
signal leaderboard_loaded(board_id: String, entries: Array)

const BOARDS := {
	"best_level": "Highest level",
	"total_xp": "Total XP",
	"longest_chain": "Longest chain",
}


func submit_score(board_id: String, payload: Dictionary) -> bool:
	if not BOARDS.has(board_id):
		push_warning("LeaderboardService: unknown board %s" % board_id)
		return false

	var entry := payload.duplicate(true)
	entry["board"] = board_id
	entry["submitted_at"] = Time.get_unix_time_from_system()

	if not _is_online():
		return false

	# Future: HTTPRequest to Play Games / Firebase / Supabase.
	push_warning("LeaderboardService: online submit not wired yet (%s)" % board_id)
	submit_completed.emit(board_id, false)
	return false


func flush_pending(pending: Array) -> Array:
	var remaining: Array = []
	for item in pending:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var board_id := str(item.get("board", ""))
		if submit_score(board_id, item):
			continue
		remaining.append(item)
	return remaining


func fetch_top(board_id: String, _limit: int = 10) -> Array:
	if not BOARDS.has(board_id):
		return []
	# Future: fetch remote leaderboard.
	var entries: Array = []
	leaderboard_loaded.emit(board_id, entries)
	return entries


func queue_best_scores(progress) -> void:
	if progress == null or not progress.has_method("build_leaderboard_payload"):
		return
	if not bool(progress.leaderboard.get("opt_in", false)):
		return

	var payload: Dictionary = progress.build_leaderboard_payload()
	for board_id in payload.keys():
		var score_dict: Dictionary = payload[board_id]
		if submit_score(board_id, score_dict):
			continue
		progress.queue_leaderboard_submit(board_id, score_dict)


func _is_online() -> bool:
	# Godot has no universal connectivity API; keep offline until backend exists.
	return false
