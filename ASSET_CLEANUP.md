# Asset cleanup handoff

The playable build does not need more extraction work. For the polished-art milestone, these are the useful human-assisted deliverables, in priority order.

## 1. Block tiles

The seven independent runtime tiles now exist as `tile_i.png`, `tile_o.png`, `tile_t.png`, `tile_s.png`, `tile_z.png`, `tile_j.png`, and `tile_l.png`. Future color changes can be made without recropping by using `tools/recolor_tile.ps1`.

- Exactly 16×16 pixels each.
- One block only—not a complete tetromino.
- Hard pixel edges, no glow outside the canvas, no background color.
- The visible block must occupy the same bounds in every file.
- Preserve the cyan/yellow/purple/green/red/blue/orange mapping in the reference sheet.

Optional variants: `ghost.png` and four 16×16 line-clear frames named `clear_01.png` through `clear_04.png`.

## 2. UI kit

The generated UI sheet has attractive parts but inconsistent bounds. Please provide transparent, nine-patch-friendly exports:

- `panel_small.png`: one blank score/level/lines panel, with a clean stretchable center.
- `panel_next.png`: one blank preview panel.
- `button_square.png`: a blank square button; icons should remain separate.
- `icon_pause.png`, `icon_play.png`, `icon_restart.png`, `icon_home.png`, each exactly 32×32.

Do not bake labels or numbers into the panels; the game renders dynamic text.

## 3. Board frame

Please export a transparent frame surrounding a precisely empty 160×320 opening. Outer dimensions may be larger, but record the opening's top-left offset in the file. Avoid shadows or ornament crossing into the opening.

## Already handled

- All original sheets are preserved in `assets/source/`.
- Four idle and four happy cat frames are extracted, alpha-preserved, and normalized to 100×120.
- The portrait room background is integrated at the exact 360×640 logical aspect ratio.
