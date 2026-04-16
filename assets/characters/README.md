# Character Asset Structure

Diese Ordner sind die saubere Austauschstelle zwischen Godot und spaeteren Blender-Modellen.

## Ziel
- Primitive in den Szenen dienen aktuell als spielbare Platzhalter.
- Echte Modelle sollen dieselben Rollen und Anker uebernehmen, damit Code und Hitboxen nicht neu gebaut werden muessen.

## Struktur
- `assets/characters/player/`
  Erwartete Dateien spaeter: `player_viewmodel.glb`, `player_survivor_fullbody.glb`
- `assets/characters/zombies/`
  Erwartete Dateien spaeter: `zombie_walker.glb`, `zombie_brute.glb`, `zombie_sprinter.glb`, `zombie_skully.glb`

## Ersetzungsregel
1. Modell in Blender auf Basis der vorhandenen Silhouette bauen.
2. Nach Godot als `.glb` exportieren.
3. In den Szenen nur die Mesh-Knoten ersetzen, nicht die Gameplay-Wurzelknoten.
4. Hitboxen, `DamageArea`, `RayCast3D`-Trefferlogik und Variantenszenen bleiben dabei stabil.
