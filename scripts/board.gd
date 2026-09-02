class_name GameBoard
extends RefCounted

var cells: Array = []

func _init() -> void:
	clear()

func clear() -> void:
	cells.clear()
	for y in GameConfig.BOARD_SIZE.y:
		var row: Array[String] = []
		for x in GameConfig.BOARD_SIZE.x:
			row.append("")
		cells.append(row)

func fits(piece: Polyomino, at_position: Vector2i, at_rotation: int) -> bool:
	for cell: Vector2i in piece.cells(at_position, at_rotation):
		if cell.x < 0 or cell.x >= GameConfig.BOARD_SIZE.x or cell.y >= GameConfig.BOARD_SIZE.y:
			return false
		if cell.y >= 0 and cells[cell.y][cell.x] != "":
			return false
	return true

func place(piece: Polyomino) -> void:
	for cell: Vector2i in piece.cells():
		if cell.y >= 0:
			cells[cell.y][cell.x] = piece.kind

func full_rows() -> Array[int]:
	var rows: Array[int] = []
	for y in GameConfig.BOARD_SIZE.y:
		if is_row_full(y):
			rows.append(y)
	return rows

func is_row_full(y: int) -> bool:
	if y < 0 or y >= cells.size():
		return false
	for x in GameConfig.BOARD_SIZE.x:
		if cells[y][x] == "":
			return false
	return true

func remove_rows(rows: Array[int]) -> void:
	# Compact once, after deciding which original rows survive. Inserting a new
	# top row between removals shifts every remaining index and corrupts multi-
	# line clears (especially the five-line signature clear).
	var rows_to_remove := {}
	for y in rows:
		if y >= 0 and y < GameConfig.BOARD_SIZE.y:
			rows_to_remove[y] = true
	var survivors: Array = []
	for y in GameConfig.BOARD_SIZE.y:
		if not rows_to_remove.has(y):
			survivors.append(cells[y])
	while survivors.size() < GameConfig.BOARD_SIZE.y:
		var empty: Array[String] = []
		for x in GameConfig.BOARD_SIZE.x:
			empty.append("")
		survivors.push_front(empty)
	cells = survivors

func push_up(new_bottom_row: Array[String]) -> bool:
	# The caller can end the run when an occupied ceiling row would be pushed
	# outside the playfield. The board is left untouched in that case.
	for value: String in cells[0]:
		if value != "":
			return false
	if new_bottom_row.size() != GameConfig.BOARD_SIZE.x:
		return false
	cells.pop_front()
	cells.append(new_bottom_row.duplicate())
	return true

func remap_cells_after_row_removal(tracked_cells: Array, removed_rows: Array[int]) -> Array:
	# Return the new coordinates of tracked cells that survived a row clear.
	# Row compaction moves a cell down once for each cleared row below it.
	var result: Array = []
	for cell: Vector2i in tracked_cells:
		if removed_rows.has(cell.y):
			continue
		var shifted_y := cell.y
		for row: int in removed_rows:
			if row > cell.y:
				shifted_y += 1
		result.append(Vector2i(cell.x, shifted_y))
	return result

func settle_tracked_cells(tracked_cells: Array, kind: String) -> Array:
	# Flowing mode gives the surviving cells from the just-placed piece their
	# own gravity. Remove them first, then settle bottom-to-top so they cannot
	# pass through each other and can create a legitimate cascade line.
	var movable: Array = []
	for cell: Vector2i in tracked_cells:
		if cell.y >= 0 and cell.y < GameConfig.BOARD_SIZE.y \
				and cell.x >= 0 and cell.x < GameConfig.BOARD_SIZE.x:
			cells[cell.y][cell.x] = ""
			movable.append(cell)
	movable.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y > b.y
	)
	var settled: Array = []
	for cell: Vector2i in movable:
		var landing_y := cell.y
		while landing_y + 1 < GameConfig.BOARD_SIZE.y and cells[landing_y + 1][cell.x] == "":
			landing_y += 1
		var landing := Vector2i(cell.x, landing_y)
		cells[landing.y][landing.x] = kind
		settled.append(landing)
	return settled

func settle_all_cells() -> int:
	# Flowing mode treats every occupied tile as an independent cell. Compact
	# each column to the floor while preserving the cells' vertical order, so a
	# later clear can never leave older pieces floating above a new cavity.
	var moved := 0
	for x in GameConfig.BOARD_SIZE.x:
		var column: Array[String] = []
		for y in range(GameConfig.BOARD_SIZE.y - 1, -1, -1):
			var kind: String = cells[y][x]
			if kind != "":
				column.append(kind)
				if y != GameConfig.BOARD_SIZE.y - column.size():
					moved += 1
			cells[y][x] = ""
		for index in column.size():
			cells[GameConfig.BOARD_SIZE.y - 1 - index][x] = column[index]
	return moved

func has_valid_dimensions() -> bool:
	if cells.size() != GameConfig.BOARD_SIZE.y:
		return false
	for row in cells:
		if row.size() != GameConfig.BOARD_SIZE.x:
			return false
	return true
