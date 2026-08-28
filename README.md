# Cozy Cat Blocks

A portrait, mobile-first falling-block MVP for Godot 4. The game uses original cozy-cat artwork supplied with the project and intentionally conservative late-1980s handheld-style rules.

## Run

1. Open `project.godot` in Godot 4.2 or newer.
2. Run the main scene (F6) or project (F5).
3. Use arrows/A/D, Down/S, X/Up, Space, and P/Escape. Press R to retry and M to toggle music. Touch or click the controls drawn at the bottom; clicking the playfield rotates.

Press Start on the title screen to open the room-background, touch-friendly starting-level grid. F1 reveals the temporary line-clear timing tuner while choosing a level.

## Version checkpoints

The first Git commit, `8158cc8`, is the playable pre-visual-integration checkpoint. The current board frame, panels, and title layout are modular, so individual art assets can be replaced without reverting gameplay code.

The exact design decisions and remaining production milestones are documented in `GAMEPLAY_SPEC.md`.

Platform-specific release prerequisites are documented in `EXPORTING.md`.

Post-release ideas, including the V2 Cat Garden, are tracked in `ROADMAP.md`.
