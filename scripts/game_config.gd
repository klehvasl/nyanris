class_name GameConfig
extends RefCounted

const LOGICAL_SIZE := Vector2i(360, 640)
const BOARD_SIZE := Vector2i(14, 24)
const CELL_SIZE := 20
const BOARD_ORIGIN := Vector2i(40, 112)
const PIECE_KINDS := ["I", "J", "L", "O", "S", "T", "Z"]
const LINE_CLEAR_SECONDS := 0.35
const LOCK_DELAY_SECONDS := 0.35
const MAX_LEVEL := 9
const DAS_SECONDS := 0.16
const ARR_SECONDS := 0.055
const SOFT_DROP_SECONDS := 0.075
const HARD_DROP_TRAIL_SECONDS := 0.20
const HARD_DROP_IMPACT_SECONDS := 0.28

# Original Game Boy Tetris normal level 0-9 timings, expressed as frames per row.
# The hardware runs at about 59.73 Hz; 60 Hz is used here for stable cross-platform timing.
const GRAVITY_FRAMES := [53, 49, 45, 41, 37, 33, 28, 22, 17, 11]
const LINE_POINTS := [0, 40, 100, 300, 700, 1500, 3000]

const COLORS := {
	# The seven familiar families keep the established wood stains rather than
	# using the official bright tetromino palette.
	"I": Color("76543b"), "O": Color("7b7a43"), "T": Color("b6a077"),
	"S": Color("76505a"), "Z": Color("62564d"), "J": Color("a56f2f"),
	"L": Color("783f31")
}

# The original carved tiles already provide exactly these seven material families.
const TILE_SOURCE_KIND := {
	"I": "I", "J": "J", "L": "L", "O": "O", "S": "S", "T": "T", "Z": "Z"
}

static func gravity_seconds(level: int) -> float:
	return GRAVITY_FRAMES[clampi(level, 0, MAX_LEVEL)] / 60.0
