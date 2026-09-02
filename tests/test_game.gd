extends SceneTree

var failures := 0

func _initialize() -> void:
	test_piece_geometry()
	test_board_collision()
	test_multi_line_removal()
	test_six_line_removal_compacts_once()
	test_non_adjacent_row_compaction()
	test_incomplete_rows_never_clear()
	test_all_complete_rows_resolve_together()
	test_gravity_and_scoring()
	test_twelve_bag()
	test_high_score_ranking()
	if failures == 0:
		print("PASS: Nyanris Six gameplay tests")
		quit(0)
	else:
		push_error("FAIL: %d gameplay tests failed" % failures)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func test_piece_geometry() -> void:
	for kind: String in GameConfig.PIECE_KINDS:
		for rotation in Hexomino.rotation_count(kind):
			var piece := Hexomino.new(kind)
			check(piece.cells(Vector2i.ZERO, rotation).size() == 6, "%s rotation %d must have six cells" % [kind, rotation])

func test_board_collision() -> void:
	var board := GameBoard.new()
	var piece := Hexomino.new("BLOCK")
	check(board.fits(piece, piece.position, 0), "BLOCK piece should fit at spawn")
	check(not board.fits(piece, Vector2i(-2, 0), 0), "BLOCK piece should collide with left wall")
	check(not board.fits(piece, Vector2i(3, GameConfig.BOARD_SIZE.y - 1), 0), "BLOCK piece should collide with floor")
	board.place(piece)
	check(not board.fits(piece, piece.position, 0), "Placed piece should occupy its cells")

func test_multi_line_removal() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom - 1][x] = "BAR"
		board.cells[bottom][x] = "BLOCK"
	check(board.full_rows() == [bottom - 1, bottom], "Two bottom rows should be detected")
	board.remove_rows([bottom - 1, bottom])
	check(board.cells.size() == GameConfig.BOARD_SIZE.y, "Board height must remain constant")
	check(board.cells[0].has(""), "New top row must be empty")
	check(board.cells[1].has(""), "Second new top row must be empty")
	check(board.full_rows().is_empty(), "Both cleared rows must actually be gone")
	check(board.has_valid_dimensions(), "Board must retain configured dimensions after a double clear")

func test_six_line_removal_compacts_once() -> void:
	var board := GameBoard.new()
	var first_clear := GameConfig.BOARD_SIZE.y - 6
	# A marker immediately above six completed bottom rows must fall exactly six
	# cells and become the new bottom row after the signature clear resolves.
	board.cells[first_clear - 1][3] = "T"
	for y in range(first_clear, GameConfig.BOARD_SIZE.y):
		for x in GameConfig.BOARD_SIZE.x:
			board.cells[y][x] = "BAR"
	var rows := board.full_rows()
	check(rows == Array(range(first_clear, GameConfig.BOARD_SIZE.y)), "A six-line clear must detect all intended adjacent rows")
	board.remove_rows(rows)
	check(board.full_rows().is_empty(), "No completed row may survive a six-line clear")
	check(board.cells[-1][3] == "T", "Blocks above a six-line clear must fall exactly six rows")
	check(board.has_valid_dimensions(), "Board must retain configured dimensions after a six-line clear")

func test_non_adjacent_row_compaction() -> void:
	var board := GameBoard.new()
	var height := GameConfig.BOARD_SIZE.y
	board.cells[height - 5][1] = "J"
	board.cells[height - 3][2] = "L"
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[height - 4][x] = "S"
		board.cells[height - 2][x] = "Z"
	board.remove_rows(board.full_rows())
	check(board.cells[height - 3][1] == "J", "A block above two separated clears must fall two rows")
	check(board.cells[height - 2][2] == "L", "A block between separated clears must fall only through the row below it")
	check(board.full_rows().is_empty(), "Separated completed rows must both be removed")
	check(board.has_valid_dimensions(), "Board dimensions must survive separated clears")

func test_incomplete_rows_never_clear() -> void:
	var bottom := GameConfig.BOARD_SIZE.y - 1
	for missing_x in GameConfig.BOARD_SIZE.x:
		var board := GameBoard.new()
		for x in GameConfig.BOARD_SIZE.x:
			if x != missing_x:
				board.cells[bottom][x] = "T"
		check(not board.is_row_full(bottom), "A row missing column %d must remain incomplete" % missing_x)
		check(board.full_rows().is_empty(), "An incomplete row must never be returned for clearing")
	var board := GameBoard.new()
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom][x] = "BAR"
	board.cells[bottom - 1][0] = "BLOCK"
	board.remove_rows(board.full_rows())
	check(board.cells[bottom][0] == "BLOCK", "Blocks above a cleared row must fall without being removed")

func test_all_complete_rows_resolve_together() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	# Even if a complete row predates the latest placement, it must be found on
	# the next lock rather than remaining as a solid, playable row.
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom][x] = "BAR"
	var block := Hexomino.new("BLOCK")
	block.position = Vector2i(3, 2)
	board.place(block)
	check(board.full_rows() == [bottom], "Every complete row must be detected regardless of where the latest piece landed")
	board.remove_rows(board.full_rows())
	check(not board.is_row_full(bottom), "A complete bottom row must be removed before play continues")

func test_gravity_and_scoring() -> void:
	check(is_equal_approx(GameConfig.gravity_seconds(0), 53.0 / 60.0), "Level 0 gravity should match Game Boy's 53 frames")
	check(is_equal_approx(GameConfig.gravity_seconds(5), 33.0 / 60.0), "Level 5 gravity should match Game Boy's 33 frames")
	check(is_equal_approx(GameConfig.gravity_seconds(9), 11.0 / 60.0), "Level 9 gravity should match Game Boy's 11 frames")
	check(is_equal_approx(GameConfig.gravity_seconds(20), 11.0 / 60.0), "Levels above the current cap should use level 9 speed")
	check(GameConfig.MAX_LEVEL == 9, "Normal progression should cap at displayed level 9")
	check(is_equal_approx(GameConfig.LOCK_DELAY_SECONDS, 0.35), "Lock delay should be 350 ms")
	check(is_equal_approx(GameConfig.SOFT_DROP_SECONDS, 0.075), "Soft drop should move at 75 ms per row")
	check(is_equal_approx(GameConfig.LINE_CLEAR_SECONDS, 0.35), "Line clear pause should be 350 ms")
	check(is_equal_approx(GameConfig.HARD_DROP_TRAIL_SECONDS, 0.20), "Hard-drop pixel trail should last 200 ms")
	check(is_equal_approx(GameConfig.HARD_DROP_IMPACT_SECONDS, 0.28), "Hard-drop impact should remain visible for 280 ms")
	check(GameConfig.LINE_POINTS[6] == 3000, "Six-line base score should be 3000")

func test_twelve_bag() -> void:
	var randomizer := PieceRandomizer.new(12345)
	for bag_number in 2:
		var seen := {}
		for draw in GameConfig.PIECE_KINDS.size():
			seen[randomizer.next_piece()] = true
		check(seen.size() == GameConfig.PIECE_KINDS.size(), "Bag %d must contain all twelve unique pieces" % bag_number)
		for kind: String in GameConfig.PIECE_KINDS:
			check(seen.has(kind), "Bag %d is missing %s" % [bag_number, kind])

func test_high_score_ranking() -> void:
	var entries: Array[Dictionary] = []
	for i in 12:
		entries.append({"name": "CAT%d" % i, "score": i * 100, "level": i % 10, "lines": i})
	entries = SaveSystem.sort_high_scores(entries)
	check(entries.size() == SaveSystem.MAX_HIGH_SCORES, "Leaderboard must keep exactly ten scores")
	check(int(entries[0].score) == 1100, "Leaderboard must sort the best score first")
	check(int(entries[-1].score) == 200, "Leaderboard must discard scores below tenth place")
	check(SaveSystem.qualifies_for_high_score(201, entries), "A score above tenth place must qualify")
	check(not SaveSystem.qualifies_for_high_score(200, entries), "A tied tenth-place score must not displace it")
	check(SaveSystem.sanitize_player_name("  nY@n! cat  ") == "NYN CAT", "Names must be normalized for safe display")
