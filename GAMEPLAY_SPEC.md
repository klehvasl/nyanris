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
- Scoring: 1/2/3/4 lines = 40/100/300/1200 × (level + 1).
- Level increases every 10 total lines and currently caps at level 9.
- The portrait `titlev2.png` artwork fills the title screen without overlays. Keyboard, controller, click, or touch opens a separate room-background 0–9 level grid. The grid supports click/touch, Left/Right or A/D, and direct number keys 0–9, with a clear selected state.
- Gravity matches the original Game Boy normal level 0–9 table at 60 Hz: 53, 49, 45, 41, 37, 33, 28, 22, 17, and 11 frames per row. This ranges from about 0.88 seconds per row at level 0 to 0.18 seconds at level 9.
- The original Game Boy A-Type continued beyond level 9 and reached its maximum speed at level 20. Those extreme post-9 speeds are intentionally not enabled in this nine-level MVP.
- Horizontal repeat: 160 ms delayed auto-shift, then 55 ms repeat.
- During gameplay, ordinary line clears add one basic cat per earned line at stable random positions strictly outside the wooden boundary on the right side of the board. A four-line Tetris adds one glowing golden cat instead of four ordinary cats and makes the entire crowd jump. Overlap is intentional, positions reroll on retry, and there is no collision behavior.
- Every top-out enters the Stargazer ending before result handling. The supplied rooftop fills the screen, the cleaned and ground-aligned six-pose cat sheet animates at lower center, and a brighter procedural shooting star leaves behind a permanently twinkling new star. The two-line result title reads `YOUR ENDING IS` / `STARGAZER`; the supplied plaque presents the final score, and `Kantele Drop Loop` plays for the duration of the scene. The ending remains open indefinitely until confirm/tap after an 850 ms accidental-input guard; the music then stops before the flow continues to name entry for a qualifying score or the retry/level-select game-over menu.
- Scores of 10,000 or more receive `LANTERN` on the same rooftop. A code-rendered amber grade warms the original background without replacing it, while consistently readable art-driven lanterns emerge only from the horizon behind the cathedral, then rise, drift, tilt, flicker, and recycle indefinitely at one-third of the initial prototype speed. F7/F8 provide non-scoring Stargazer/Lantern previews in debug builds. Stargazer remains the ending below 10,000; higher ending tiers will replace Lantern's open-ended upper range when their assets are added.

## Controls

- Keyboard/controller: arrows or A/D move; Down/S soft drops; X/Up rotates; Space/A-button hard drops; P/Escape pauses.
- Start accepts Enter, Space, X, a controller button, left mouse click, or touch. Android hardware volume keys are ignored. During play, tap/click rotates, horizontal swipe moves, and a downward swipe soft- or hard-drops based on distance and speed.

## Asset policy

The eight supplied images are preserved in `assets/source/`. The portrait room is used as a dimmed backdrop and the cat sheet is cropped into normalized transparent frames. The generated tetromino and UI sheets remain reference art because their elements are not on exact production grids; the MVP uses deterministic 16×16 rendered tiles and UI panels until final sprites are cleaned.

## Milestones represented here

1. Playable falling-block loop: complete.
2. Gravity, scoring, keyboard/controller, touch, ghost, line clear, pause, game over: complete.
3. Block art: all seven colors plus ghost and clear-effect crops are normalized and integrated at 16×16. The yellow O tile is deterministically hue-derived from the orange crop so it shares identical geometry and shading.
4. Board/UI: supplied board frame, title artwork, and standalone Next/Score/Level/Lines panels are integrated in a reversible first-pass layout.
5. Cat + FX + audio: idle and four-line reaction, art-driven line clear, synthesized feedback, and authored looping title/gameplay music are integrated.
6. Ending + scores: Stargazer sequence, final-score plaque, local named top-ten board, retry, and level-select return are integrated.
7. Android export: project configured; export preset/signing pending on a Godot-equipped machine.
8. iOS export: project configured; export preset/signing/Xcode step pending on macOS.
