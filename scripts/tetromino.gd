class_name Tetromino
extends RefCounted

const SHAPES := {
	"I": [[Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(3,1)], [Vector2i(2,0),Vector2i(2,1),Vector2i(2,2),Vector2i(2,3)]],
	"O": [[Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(2,1)]],
	"T": [[Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)], [Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)], [Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)], [Vector2i(1,0),Vector2i(0,1),Vector2i(1,1),Vector2i(1,2)]],
	"J": [[Vector2i(0,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)], [Vector2i(1,0),Vector2i(2,0),Vector2i(1,1),Vector2i(1,2)], [Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)], [Vector2i(1,0),Vector2i(1,1),Vector2i(0,2),Vector2i(1,2)]],
	"L": [[Vector2i(2,0),Vector2i(0,1),Vector2i(1,1),Vector2i(2,1)], [Vector2i(1,0),Vector2i(1,1),Vector2i(1,2),Vector2i(2,2)], [Vector2i(0,1),Vector2i(1,1),Vector2i(2,1),Vector2i(0,2)], [Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(1,2)]],
	"S": [[Vector2i(1,0),Vector2i(2,0),Vector2i(0,1),Vector2i(1,1)], [Vector2i(1,0),Vector2i(1,1),Vector2i(2,1),Vector2i(2,2)]],
	"Z": [[Vector2i(0,0),Vector2i(1,0),Vector2i(1,1),Vector2i(2,1)], [Vector2i(2,0),Vector2i(1,1),Vector2i(2,1),Vector2i(1,2)]]
}

var kind: String
var position := Vector2i(3, 0)
var rotation := 0

func _init(piece_kind: String) -> void:
	kind = piece_kind

func cells(at_position: Vector2i = position, at_rotation: int = rotation) -> Array:
	var result: Array = []
	var states: Array = SHAPES[kind]
	for cell: Vector2i in states[posmod(at_rotation, states.size())]:
		result.append(at_position + cell)
	return result

