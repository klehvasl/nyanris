extends SceneTree

var failures := 0

func _initialize() -> void:
	test_piece_geometry()
	test_board_collision()
	test_multi_line_removal()
	test_five_line_removal_compacts_once()
	test_non_adjacent_row_compaction()
	test_incomplete_rows_never_clear()
	test_all_complete_rows_resolve_together()
	test_flow_floor_push()
	test_flow_cells_settle_on_every_lock()
	test_flow_piece_residue_cascade()
	test_gravity_and_scoring()
	test_mixed_bag()
	test_high_score_ranking()
	if failures == 0:
		print("PASS: Nyanris Mix gameplay tests")
		quit(0)
	else:
		push_error("FAIL: %d gameplay tests failed" % failures)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func test_piece_geometry() -> void:
	var expected_sizes := {"D2": 2, "I3": 3, "L3": 3, "I4": 4, "J4": 4, "L4": 4, "O4": 4, "S4": 4, "T4": 4, "Z4": 4, "I5": 5, "T5": 5, "U5": 5, "P5": 5, "W5": 5}
	var expected_rotations := {"D2": 2, "I3": 2, "L3": 4, "I4": 2, "J4": 4, "L4": 4, "O4": 1, "S4": 2, "T4": 4, "Z4": 2, "I5": 2, "T5": 4, "U5": 4, "P5": 4, "W5": 4}
	for kind: String in GameConfig.PIECE_KINDS:
		check(Polyomino.rotation_count(kind) == expected_rotations[kind], "%s must have %d distinct rotations" % [kind, expected_rotations[kind]])
		for rotation in Polyomino.rotation_count(kind):
			var piece := Polyomino.new(kind)
			check(piece.cells(Vector2i.ZERO, rotation).size() == expected_sizes[kind], "%s rotation %d must have %d cells" % [kind, rotation, expected_sizes[kind]])

func test_board_collision() -> void:
	var board := GameBoard.new()
	var piece := Polyomino.new("O4")
	check(board.fits(piece, piece.position, 0), "O piece should fit at spawn")
	check(not board.fits(piece, Vector2i(-2, 0), 0), "O piece should collide with left wall")
	check(not board.fits(piece, Vector2i(3, GameConfig.BOARD_SIZE.y - 1), 0), "O piece should collide with floor")
	board.place(piece)
	check(not board.fits(piece, piece.position, 0), "Placed piece should occupy its cells")

func test_multi_line_removal() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom - 1][x] = "I4"
		board.cells[bottom][x] = "O4"
	check(board.full_rows() == [bottom - 1, bottom], "Two bottom rows should be detected")
	board.remove_rows([bottom - 1, bottom])
	check(board.cells.size() == GameConfig.BOARD_SIZE.y, "Board height must remain constant")
	check(board.cells[0].has(""), "New top row must be empty")
	check(board.cells[1].has(""), "Second new top row must be empty")
	check(board.full_rows().is_empty(), "Both cleared rows must actually be gone")
	check(board.has_valid_dimensions(), "Board must retain configured dimensions after a double clear")

func test_five_line_removal_compacts_once() -> void:
	var board := GameBoard.new()
	var first_clear := GameConfig.BOARD_SIZE.y - 5
	# A marker immediately above five completed bottom rows must fall exactly five
	# cells and become the new bottom row after the signature clear resolves.
	board.cells[first_clear - 1][3] = "T4"
	for y in range(first_clear, GameConfig.BOARD_SIZE.y):
		for x in GameConfig.BOARD_SIZE.x:
			board.cells[y][x] = "I5"
	var rows := board.full_rows()
	check(rows == Array(range(first_clear, GameConfig.BOARD_SIZE.y)), "A five-line clear must detect all intended adjacent rows")
	board.remove_rows(rows)
	check(board.full_rows().is_empty(), "No completed row may survive a five-line clear")
	check(board.cells[-1][3] == "T4", "Blocks above a five-line clear must fall exactly five rows")
	check(board.has_valid_dimensions(), "Board must retain configured dimensions after a five-line clear")

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
				board.cells[bottom][x] = "T4"
		check(not board.is_row_full(bottom), "A row missing column %d must remain incomplete" % missing_x)
		check(board.full_rows().is_empty(), "An incomplete row must never be returned for clearing")
	var board := GameBoard.new()
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom][x] = "I4"
	board.cells[bottom - 1][0] = "O4"
	board.remove_rows(board.full_rows())
	check(board.cells[bottom][0] == "O4", "Blocks above a cleared row must fall without being removed")

func test_all_complete_rows_resolve_together() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	# Even if a complete row predates the latest placement, it must be found on
	# the next lock rather than remaining as a solid, playable row.
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[bottom][x] = "I4"
	var block := Polyomino.new("O4")
	block.position = Vector2i(3, 2)
	board.place(block)
	check(board.full_rows() == [bottom], "Every complete row must be detected regardless of where the latest piece landed")
	board.remove_rows(board.full_rows())
	check(not board.is_row_full(bottom), "A complete bottom row must be removed before play continues")

func test_flow_floor_push() -> void:
	var board := GameBoard.new()
	board.cells[1][3] = "T4"
	var incoming: Array[String] = []
	for x in GameConfig.BOARD_SIZE.x:
		incoming.append("I3" if x % 4 != 0 else "")
	check(board.push_up(incoming), "A flow row should rise while the ceiling is open")
	check(board.cells[0][3] == "T4", "Existing flow cells must move exactly one row upward")
	check(board.cells[-1] == incoming, "The incoming pattern must become the new bottom row")
	board.cells[0][0] = "O4"
	check(not board.push_up(incoming), "Flowing must report game over before an occupied ceiling is discarded")

func test_flow_piece_residue_cascade() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	for x in GameConfig.BOARD_SIZE.x:
		if x != 5:
			board.cells[bottom][x] = "O4"
		board.cells[bottom - 1][x] = "J4"
	board.cells[bottom - 2][5] = "I3"
	board.cells[bottom - 1][5] = "I3"
	var tracked: Array = [Vector2i(5, bottom - 2), Vector2i(5, bottom - 1)]
	var cleared: Array[int] = [bottom - 1]
	board.remove_rows(cleared)
	tracked = board.remap_cells_after_row_removal(tracked, cleared)
	tracked = board.settle_tracked_cells(tracked, "I3")
	check(tracked == [Vector2i(5, bottom)], "The surviving cell of a cleared piece must fall into the lowest opening")
	check(board.full_rows() == [bottom], "A falling piece remnant must be able to complete a cascade line")

func test_flow_cells_settle_on_every_lock() -> void:
	var board := GameBoard.new()
	var bottom := GameConfig.BOARD_SIZE.y - 1
	for x in GameConfig.BOARD_SIZE.x:
		if x not in [3, 4]:
			board.cells[bottom][x] = "O4"
	var tracked: Array = [Vector2i(3, bottom - 3), Vector2i(3, bottom - 2), Vector2i(4, bottom - 2)]
	for cell: Vector2i in tracked:
		board.cells[cell.y][cell.x] = "L3"
	var settled := board.settle_tracked_cells(tracked, "L3")
	check(settled.has(Vector2i(3, bottom)), "A placed cell must fall into an unsupported target before any clear")
	check(settled.has(Vector2i(4, bottom)), "Each column of a placed piece must settle independently")
	check(board.full_rows() == [bottom], "Placement gravity must be able to create the first clear")

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
	check(GameConfig.LINE_POINTS[5] == 2000, "Five-line base score should be 2000")
	check(is_equal_approx(GameConfig.flow_rise_seconds(0), 5.0), "Flowing level 0 should travel one row every five seconds")
	check(is_equal_approx(GameConfig.flow_rise_seconds(9), 2.84), "Flowing rise pressure should scale with starting level")
	check(GameConfig.FLOW_STARTING_ROWS == 1, "Flowing should begin with one easy target row")
	check(GameConfig.FLOW_INITIAL_MASKS[0] == "XXXXX..XXXXX", "Flowing must open with one centered domino-sized clearing target")
	for mask: String in GameConfig.FLOW_INITIAL_MASKS + GameConfig.FLOW_RISING_MASKS:
		check(mask.length() == GameConfig.BOARD_SIZE.x, "Every flow pattern must span the board width")
		check(mask.contains("."), "Every flow row must retain at least one playable opening")
	var expected_gap_starts := [3, 1, 3, 5, 7, 9, 7, 5]
	for pattern_index in GameConfig.FLOW_RISING_MASKS.size():
		var mask: String = GameConfig.FLOW_RISING_MASKS[pattern_index]
		check(mask.find("..") == expected_gap_starts[pattern_index], "Flow gaps must trace the authored left-to-right zigzag")
		check(mask.count("X") == GameConfig.BOARD_SIZE.x - 2, "Every rising row should have one domino-sized target")
	check(GameConfig.LINE_SHARDS_PER_BLOCK == 8, "Each cleared block must break into eight visual shards")

func test_mixed_bag() -> void:
	var randomizer := PieceRandomizer.new(12345)
	for bag_number in 2:
		var seen := {}
		var occupied_cells := 0
		for draw in GameConfig.PIECE_KINDS.size():
			var kind := randomizer.next_piece()
			seen[kind] = true
			occupied_cells += Polyomino.BASE_SHAPES[kind].size()
		check(seen.size() == GameConfig.PIECE_KINDS.size(), "Bag %d must contain all fifteen unique pieces" % bag_number)
		check(occupied_cells == 61, "Bag %d must contain exactly 61 occupied cells" % bag_number)
		for kind: String in GameConfig.PIECE_KINDS:
			check(seen.has(kind), "Bag %d is missing %s" % [bag_number, kind])
	var authored_randomizer := PieceRandomizer.new(12345)
	check(authored_randomizer.take_piece("D2") == "D2", "Flowing must be able to author a domino opener")
	var authored_seen := {"D2": true}
	for draw in GameConfig.PIECE_KINDS.size() - 1:
		authored_seen[authored_randomizer.next_piece()] = true
	check(authored_seen.size() == GameConfig.PIECE_KINDS.size(), "An authored opener must still consume exactly one normal bag piece")

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
