class_name Polyomino
extends RefCounted

# Fixed 15-piece bag: one domino, two triominoes, seven tetrominoes, and five
# pentominoes. The bag always contains exactly 61 occupied cells.
const BASE_SHAPES := {
	"D2": [Vector2i(0,0), Vector2i(1,0)],
	"I3": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0)],
	"L3": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1)],
	"I4": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0)],
	"J4": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	"L4": [Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	"O4": [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1)],
	"S4": [Vector2i(1,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1)],
	"T4": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1)],
	"Z4": [Vector2i(0,0), Vector2i(1,0), Vector2i(1,1), Vector2i(2,1)],
	"I5": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(3,0), Vector2i(4,0)],
	"T5": [Vector2i(0,0), Vector2i(1,0), Vector2i(2,0), Vector2i(1,1), Vector2i(1,2)],
	"U5": [Vector2i(0,0), Vector2i(2,0), Vector2i(0,1), Vector2i(1,1), Vector2i(2,1)],
	"P5": [Vector2i(0,0), Vector2i(1,0), Vector2i(0,1), Vector2i(1,1), Vector2i(0,2)],
	"W5": [Vector2i(0,0), Vector2i(0,1), Vector2i(1,1), Vector2i(1,2), Vector2i(2,2)]
}

static var _rotation_cache: Dictionary = {}

var kind: String
var position := Vector2i.ZERO
var rotation := 0

func _init(piece_kind: String) -> void:
	kind = piece_kind
	var first_state: Array = rotation_states(kind)[0]
	var max_x := 0
	for cell: Vector2i in first_state:
		max_x = maxi(max_x, cell.x)
	position = Vector2i(floori((GameConfig.BOARD_SIZE.x - (max_x + 1)) * 0.5), 0)

func cells(at_position: Vector2i = position, at_rotation: int = rotation) -> Array:
	var result: Array = []
	var states := rotation_states(kind)
	for cell: Vector2i in states[posmod(at_rotation, states.size())]:
		result.append(at_position + cell)
	return result

static func rotation_count(piece_kind: String) -> int:
	return rotation_states(piece_kind).size()

static func rotation_states(piece_kind: String) -> Array:
	if _rotation_cache.has(piece_kind):
		return _rotation_cache[piece_kind]
	var states: Array = []
	var signatures := {}
	var current: Array = BASE_SHAPES[piece_kind].duplicate()
	for _turn in 4:
		var normalized := normalize_cells(current)
		var signature := cells_signature(normalized)
		if not signatures.has(signature):
			signatures[signature] = true
			states.append(normalized)
		current = rotate_clockwise(normalized)
	_rotation_cache[piece_kind] = states
	return states

static func normalize_cells(source: Array) -> Array:
	var min_x := 999
	var min_y := 999
	for cell: Vector2i in source:
		min_x = mini(min_x, cell.x)
		min_y = mini(min_y, cell.y)
	var normalized: Array = []
	for cell: Vector2i in source:
		normalized.append(cell - Vector2i(min_x, min_y))
	normalized.sort_custom(func(a: Vector2i, b: Vector2i) -> bool:
		return a.y < b.y or (a.y == b.y and a.x < b.x)
	)
	return normalized

static func rotate_clockwise(source: Array) -> Array:
	var rotated: Array = []
	for cell: Vector2i in source:
		rotated.append(Vector2i(-cell.y, cell.x))
	return rotated

static func cells_signature(source: Array) -> String:
	var parts: PackedStringArray = []
	for cell: Vector2i in source:
		parts.append("%d,%d" % [cell.x, cell.y])
	return ";".join(parts)
