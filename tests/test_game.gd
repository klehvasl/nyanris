extends SceneTree

var failures := 0

func _initialize() -> void:
	test_piece_geometry()
	test_board_collision()
	test_multi_line_removal()
	test_incomplete_rows_never_clear()
	test_gravity_and_scoring()
	test_seven_bag()
	if failures == 0:
		print("PASS: Cozy Cat Blocks gameplay tests")
		quit(0)
	else:
		push_error("FAIL: %d gameplay tests failed" % failures)
		quit(1)

func check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func test_piece_geometry() -> void:
	for kind in Tetromino.SHAPES:
		for rotation in Tetromino.SHAPES[kind].size():
			var piece := Tetromino.new(kind)
			check(piece.cells(Vector2i.ZERO, rotation).size() == 4, "%s rotation %d must have four cells" % [kind, rotation])

func test_board_collision() -> void:
	var board := GameBoard.new()
	var piece := Tetromino.new("O")
	check(board.fits(piece, Vector2i(3, 0), 0), "O piece should fit at spawn")
	check(not board.fits(piece, Vector2i(-2, 0), 0), "O piece should collide with left wall")
	check(not board.fits(piece, Vector2i(3, 19), 0), "O piece should collide with floor")
	board.place(piece)
	check(not board.fits(piece, piece.position, 0), "Placed piece should occupy its cells")

func test_multi_line_removal() -> void:
	var board := GameBoard.new()
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[18][x] = "I"
		board.cells[19][x] = "O"
	check(board.full_rows() == [18, 19], "Two bottom rows should be detected")
	board.remove_rows([18, 19])
	check(board.cells.size() == 20, "Board height must remain 20")
	check(board.cells[0].has(""), "New top row must be empty")
	check(board.cells[1].has(""), "Second new top row must be empty")

func test_incomplete_rows_never_clear() -> void:
	for missing_x in GameConfig.BOARD_SIZE.x:
		var board := GameBoard.new()
		for x in GameConfig.BOARD_SIZE.x:
			if x != missing_x:
				board.cells[19][x] = "T"
		check(not board.is_row_full(19), "A row missing column %d must remain incomplete" % missing_x)
		check(board.full_rows().is_empty(), "An incomplete row must never be returned for clearing")
	var board := GameBoard.new()
	for x in GameConfig.BOARD_SIZE.x:
		board.cells[19][x] = "I"
	board.cells[18][0] = "O"
	board.remove_rows(board.full_rows())
	check(board.cells[19][0] == "O", "Blocks above a cleared row must fall without being removed")

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
	check(GameConfig.LINE_POINTS[4] == 1200, "Four-line base score should be 1200")

func test_seven_bag() -> void:
	var randomizer := PieceRandomizer.new(12345)
	for bag_number in 2:
		var seen := {}
		for draw in 7:
			seen[randomizer.next_piece()] = true
		check(seen.size() == 7, "Bag %d must contain all seven unique pieces" % bag_number)
		for kind: String in GameConfig.PIECE_KINDS:
			check(seen.has(kind), "Bag %d is missing %s" % [bag_number, kind])
