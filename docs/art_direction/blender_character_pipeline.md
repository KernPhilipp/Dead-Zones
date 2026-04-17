# Blender Character Pipeline

## Schon jetzt vorhanden
- Spielbare First-Person-Ansicht des Spielers in `scenes/player.tscn`
- Mehrere Zombie-Variantenszenen in `scenes/zombies/`
- Full-body-Referenz fuer den Main Character in `scenes/characters/survivor_reference.tscn`

## Workflow fuer echte Modelle
1. Die Proportionen zuerst in Blender an den Godot-Platzhaltern orientieren.
2. Zuerst nur Body-Meshes ersetzen, danach Kleidung/Props.
3. Erst wenn die Silhouette passt, UVs und Texturen ausbauen.
4. Animationen spaeter an denselben Rollen ausrichten:
   `Idle`, `Walk`, `Attack`, `Hit`, optional `Death`.

## Zombie-Richtungen
- `Walker`: klassischer Lost-Place-Infizierter, ausgewogen und lesbar.
- `Brute`: schwer, massig, demoliert, eher Ex-Arbeiter oder Sicherheitskraft.
- `Sprinter`: drahtig, hungrig, aggressiv nach vorne gekippt.
- `Skully`: halb skelettiert, markant fuer spaetere Spezialgegner.

## Spieler-Richtung
- Dunkle scavenger-artige Kleidung.
- Praktischer Rucksack, improvisiertes Equipment, keine saubere Elite-Soldat-Optik.
- Gut geeignet fuer Lost Places, Survival und spaeteres Loot-Upgrade-Feeling.
