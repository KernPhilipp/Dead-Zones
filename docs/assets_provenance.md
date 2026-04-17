# Asset Provenance

This project's current UI/world polish pass uses in-repo Godot geometry and materials for runtime-safe upgrades.
The following external CC0 sources are the approved asset pool for the next editor-side import pass.

## Approved Sources

### Quaternius
- Zombie Apocalypse Kit
  - Source page: https://quaternius.com/packs/zombieapocalypsekit.html
  - License: CC0
  - Download folder exposed by source page: https://drive.google.com/drive/folders/1mWP6sCHun7OUMHQeDNZLrXTteXlzWg_t?usp=sharing
  - Intended use: third-person player mesh, zombie apocalypse props, additional environmental set dressing

- Buildings Pack
  - Source page: https://quaternius.com/packs/buildings.html
  - License: CC0
  - Download folder exposed by source page: https://drive.google.com/drive/folders/1uWCsV9QfnAu8u_QbwkYwOfuU3McME7CA?usp=sharing
  - Intended use: environment/building replacements and prop refinement

### Kenney
- Support / license FAQ: https://kenney.nl/support
- 3D assets index: https://kenney.nl/knowledge-base/game-assets-3d
- License expectation for selected packs: CC0-compatible/free use per official site guidance
- Intended use: modular props, pickups, UI-adjacent world props

### Poly Haven
- License: https://polyhaven.com/license
- Intended use: CC0 textures/material references for environment polish

## Current State In Repo
- Player third-person visibility is currently implemented with procedural in-engine geometry in `scenes/player.tscn`.
- Buy stations, upgrade stations, pickups, fences, barricades, and the central house were refined in-scene with Godot meshes/materials so the project stays runnable without waiting for editor imports.
- External asset import is intentionally deferred until it can be validated inside the Godot editor available to the team.
