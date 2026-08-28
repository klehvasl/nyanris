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

func fits(piece: Tetromino, at_position: Vector2i, at_rotation: int) -> bool:
	for cell: Vector2i in piece.cells(at_position, at_rotation):
		if cell.x < 0 or cell.x >= GameConfig.BOARD_SIZE.x or cell.y >= GameConfig.BOARD_SIZE.y:
			return false
		if cell.y >= 0 and cells[cell.y][cell.x] != "":
			return false
	return true

func place(piece: Tetromino) -> void:
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
	rows.sort()
	rows.reverse()
	for y in rows:
		cells.remove_at(y)
		var empty: Array[String] = []
		for x in GameConfig.BOARD_SIZE.x:
			empty.append("")
		cells.push_front(empty)
