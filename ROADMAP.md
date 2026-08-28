# Cozy Cat Blocks roadmap

## V1 — release scope

- [x] Complete and polish the core falling-block game.
- [x] Finalize gameplay timing, keyboard/controller controls, touch controls, retry, and pause.
- [x] Integrate block, cat, line-clear, title, board-frame, and status-panel art.
- [x] Add authored looping title/gameplay music with a persistent mute preference.
- [ ] Fine-tune frame/panel alignment after device playtesting and final asset review.
- [ ] Add final sound effects and production volume controls.
  - Normal landing: briefly and subtly flash the cells of the piece when it locks.
  - Hard-drop landing: use a brighter piece flash alongside the pixel-comet and impact effects.
  - Give normal downward movement/landing and hard drop clearly different sounds; keep the normal cue restrained and the hard-drop cue punchier.
- [ ] Expand and finalize the gameplay music rotation.
  - Evaluate the supplied **Kantele Drop Loop** as an additional gameplay track.
  - Add a few complementary cozy arrangements so longer sessions do not rely on one loop.
  - Normalize track loudness, choose loop points, and verify redistribution rights before release.
- [ ] Produce signed Android and iOS exports (requires Android signing setup and macOS/Xcode for iOS).

## V2 — post-release

### Cat Garden

- Add a persistent cat garden outside the main playfield.
- Each level reached adds another cat to the garden.
- Give arriving cats varied poses, idle behaviors, and small interactions.
- Let the garden become progressively busier as the player advances.
- At high levels, fill the garden with playful overlapping activity: intentional **cat chaos—or cat bliss**.
- Keep garden activity visually separate from the board so it never harms gameplay readability.
- Decide later whether garden population resets per run, persists as progression, or supports both modes.
