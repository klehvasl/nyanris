class_name GameConfig
extends RefCounted

const LOGICAL_SIZE := Vector2i(360, 640)
const BOARD_SIZE := Vector2i(12, 22)
const CELL_SIZE := 22
const BOARD_ORIGIN := Vector2i(48, 112)
const PIECE_KINDS := ["D2", "I3", "L3", "I4", "J4", "L4", "O4", "S4", "T4", "Z4", "I5", "T5", "U5", "P5", "W5"]
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
const LINE_POINTS := [0, 40, 100, 300, 800, 2000]

const COLORS := {
	"D2": Color("7b7a43"), "I3": Color("76543b"), "L3": Color("783f31"),
	"I4": Color("76543b"), "J4": Color("a56f2f"), "L4": Color("783f31"),
	"O4": Color("7b7a43"), "S4": Color("76505a"), "T4": Color("b6a077"),
	"Z4": Color("62564d"), "I5": Color("76543b"), "T5": Color("b6a077"),
	"U5": Color("7b7a43"), "P5": Color("a56f2f"), "W5": Color("76505a")
}

# Reuse the existing seven carved wood materials across related shape families.
const TILE_SOURCE_KIND := {
	"D2": "O", "I3": "I", "L3": "L", "I4": "I", "J4": "J", "L4": "L",
	"O4": "O", "S4": "S", "T4": "T", "Z4": "Z", "I5": "I", "T5": "T",
	"U5": "O", "P5": "J", "W5": "S"
}

static func gravity_seconds(level: int) -> float:
	return GRAVITY_FRAMES[clampi(level, 0, MAX_LEVEL)] / 60.0
