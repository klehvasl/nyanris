class_name GameConfig
extends RefCounted

const LOGICAL_SIZE := Vector2i(360, 640)
const BOARD_SIZE := Vector2i(10, 20)
const CELL_SIZE := 16
const BOARD_ORIGIN := Vector2i(28, 142)
const PIECE_KINDS := ["I", "J", "L", "O", "S", "T", "Z"]
const LINE_CLEAR_SECONDS := 0.35
const LOCK_DELAY_SECONDS := 0.35
const MAX_LEVEL := 9
const DAS_SECONDS := 0.16
const ARR_SECONDS := 0.055
const SOFT_DROP_SECONDS := 0.075
const HARD_DROP_TRAIL_SECONDS := 0.08
const HARD_DROP_IMPACT_SECONDS := 0.15

# Original Game Boy Tetris normal level 0-9 timings, expressed as frames per row.
# The hardware runs at about 59.73 Hz; 60 Hz is used here for stable cross-platform timing.
const GRAVITY_FRAMES := [53, 49, 45, 41, 37, 33, 28, 22, 17, 11]
const LINE_POINTS := [0, 40, 100, 300, 1200]

const COLORS := {
	"I": Color("42c7cc"), "O": Color("f1bd3b"), "T": Color("9b5aa5"),
	"S": Color("72a947"), "Z": Color("db4d45"), "J": Color("447bb7"),
	"L": Color("df7a32")
}

static func gravity_seconds(level: int) -> float:
	return GRAVITY_FRAMES[clampi(level, 0, MAX_LEVEL)] / 60.0
