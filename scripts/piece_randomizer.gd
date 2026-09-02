class_name PieceRandomizer
extends RefCounted

var rng := RandomNumberGenerator.new()
var bag: Array[String] = []

func _init(seed_value := -1) -> void:
	if seed_value >= 0:
		rng.seed = seed_value
	else:
		rng.randomize()

func reset() -> void:
	bag.clear()

func next_piece() -> String:
	if bag.is_empty():
		refill()
	return bag.pop_back()

func take_piece(piece_kind: String) -> String:
	# Used by authored openings without breaking the fixed bag: remove the chosen
	# piece from its normal shuffled position, then continue through the remainder.
	if bag.is_empty():
		refill()
	var index := bag.find(piece_kind)
	return bag.pop_at(index) if index >= 0 else next_piece()

func refill() -> void:
	bag.clear()
	for kind: String in GameConfig.PIECE_KINDS:
		bag.append(kind)
	# Fisher-Yates shuffle so each fixed fifteen-piece bag is uniformly shuffled.
	for i in range(bag.size() - 1, 0, -1):
		var j := rng.randi_range(0, i)
		var swap := bag[i]
		bag[i] = bag[j]
		bag[j] = swap
