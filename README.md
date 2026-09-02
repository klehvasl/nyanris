# Nyanris Mix

An experimental branch of Nyanris built around a fixed mixture of 2–5 cell pieces on a 12×22 board. The released four-block game remains preserved on `master`; this branch has a separate app name, package ID, and local save directory.

The published Web version remains the original game until this branch is ready for separate deployment.

## Run

1. Open `project.godot` in Godot 4.7.2 or newer.
2. Run the main scene (F6) or project (F5).
3. Use arrows/A/D, Down/S, X/Up, Space, and P/Escape. Press R to retry and M to toggle music. Tap the playfield to rotate, swipe sideways to move, and swipe down to drop. The in-game Pause button opens Resume, Retry, and Level Select actions.

Press Start on the title screen to open the touch-friendly starting-level grid. Left/Right moves across levels, Up/Down moves between rows, and Enter/Space confirms. Named top-ten scores are saved locally and can be viewed from level selection or the game-over screen.

In debug builds, press 7 to preview Stargazer or 8 to preview Lantern from a menu. Preview endings return to that menu and never submit their temporary score. Godot reserves F7/F8 while running from the editor.

## Export

- Android: use the separate `Android Debug` export preset for device testing.
- Web PWA: run `tools/export_web_pwa.ps1`, then `tools/serve_web_pwa.ps1` for local testing.
- The generated `export/` and `web/` directories are intentionally excluded from Git. Distributable Android builds belong in GitHub Releases, while the PWA is deployed separately to Vercel.

## Version checkpoints

The first Git commit, `8158cc8`, is the playable pre-visual-integration checkpoint. The current board frame, panels, and title layout are modular, so individual art assets can be replaced without reverting gameplay code.

The exact design decisions and remaining production milestones are documented in `GAMEPLAY_SPEC.md`.

Platform-specific release prerequisites are documented in `EXPORTING.md`.

Post-release ideas, including the V2 Cat Garden, are tracked in `ROADMAP.md`.
