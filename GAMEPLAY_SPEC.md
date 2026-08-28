# Cozy Cat Blocks — locked MVP specification

## Display and art grid

- Godot 4 / GDScript; portrait Android and iOS target.
- Fixed 360×640 logical canvas with integer/pixel-nearest scaling.
- 10×20 board, 16×16 cells, 160×320 interior.
- Cat runtime frames normalized to 100×120 transparent PNGs.
- UI touch targets are 84×48 logical pixels; future standalone icons should be 32×32.

## Rules and feel

- Seven standard tetromino geometries using modern 7-bag randomization: every bag contains exactly one I/J/L/O/S/T/Z, is shuffled with Fisher-Yates, and is fully dealt before the next bag is created.
- One next-piece preview, no hold, no combos or back-to-back bonuses.
- Clockwise rotation only. Rotations test horizontal kicks at 0, −1, +1, −2, +2 cells.
- Ghost piece enabled. Held soft drop advances one row every 75 ms and scores 1 point per cell; it uses an independent timer so gravity backlog cannot cause a sudden drop. Hard drop scores 2 per cell.
- Hard drop remains logically instantaneous and adds three piece-shaped afterimages plus a 150 ms squash → slight overshoot → settle. The impact uses a brief two-pixel expanding contact line and twelve deterministic 1–2 px fragments; no particle node or texture asset is used.
- A grounded piece locks after 350 ms. Successful movement or rotation resets the lock timer; hard drop still locks immediately.
- Line clear defaults to 350 ms and uses a six-stage transparent 2D-HD gold animation extracted from `assets/source/line clear.png`. It is rendered once as a compact 192×32 row-level overlay while a synchronized center-out mask removes the blocks; it is never repeated inside individual cells. Rows are revalidated as completely occupied before removal.
- A temporary title/game-over slider tunes the line-clear duration from 80–400 ms in 10 ms increments. The selected duration drives both gameplay pause and visual progress and remains active for subsequent games in the current session.
- Scoring: 1/2/3/4 lines = 40/100/300/1200 × (level + 1).
- Level increases every 10 total lines and currently caps at level 9.
- The portrait `titlev2.png` artwork fills the title screen without overlays. Keyboard, controller, click, or touch opens a separate room-background 0–9 level grid. The grid supports click/touch, Left/Right or A/D, and direct number keys 0–9, with a clear selected state.
- Gravity matches the original Game Boy normal level 0–9 table at 60 Hz: 53, 49, 45, 41, 37, 33, 28, 22, 17, and 11 frames per row. This ranges from about 0.88 seconds per row at level 0 to 0.18 seconds at level 9.
- The original Game Boy A-Type continued beyond level 9 and reached its maximum speed at level 20. Those extreme post-9 speeds are intentionally not enabled in this nine-level MVP.
- Horizontal repeat: 160 ms delayed auto-shift, then 55 ms repeat.

## Controls

- Keyboard/controller: arrows or A/D move; Down/S soft drops; X/Up rotates; Space/A-button hard drops; P/Escape pauses.
- Start/restart accepts any key, controller button, left mouse click, or touch. During play, tap/click rotates, horizontal swipe moves, downward swipe soft-drops several cells, and upward swipe hard-drops. The four explicit bottom zones work with touch or mouse and provide left/rotate/right/drop.

## Asset policy

The eight supplied images are preserved in `assets/source/`. The portrait room is used as a dimmed backdrop and the cat sheet is cropped into normalized transparent frames. The generated tetromino and UI sheets remain reference art because their elements are not on exact production grids; the MVP uses deterministic 16×16 rendered tiles and UI panels until final sprites are cleaned.

## Milestones represented here

1. Playable falling-block loop: complete.
2. Gravity, scoring, keyboard/controller, touch, ghost, line clear, pause, game over: complete.
3. Block art: all seven colors plus ghost and clear-effect crops are normalized and integrated at 16×16. The yellow O tile is deterministically hue-derived from the orange crop so it shares identical geometry and shading.
4. Board/UI: supplied board frame, title artwork, and standalone Next/Score/Level/Lines panels are integrated in a reversible first-pass layout.
5. Cat + FX + audio: idle and four-line reaction, art-driven line clear, synthesized feedback, and authored looping title/gameplay music are integrated.
6. Android export: project configured; export preset/signing pending on a Godot-equipped machine.
7. iOS export: project configured; export preset/signing/Xcode step pending on macOS.
