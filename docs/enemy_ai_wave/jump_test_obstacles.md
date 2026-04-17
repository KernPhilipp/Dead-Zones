# Jump-Test-Hindernisse (Vorlage)

Diese Testelemente sind eine funktionale Vorbereitung fuer spaetere Zombie-Sprung-/Traversaltests.

Wichtig:
- kein finales Leveldesign
- keine finale Sprung-KI
- nur testbare Platzhalter mit klaren Hoehen-/Breitenunterschieden

## 1. Szenen

- Prefab: `res://scenes/wave/jump_test_obstacle.tscn`
- Testarea: `res://scenes/wave/zombie_jump_test_area.tscn`
- Boxen-Set: `res://scenes/wave/jump_test_box_variants.tscn`

Die Testarea ist absichtlich isoliert und greift keine finalen Fremd-Maps an.

## 2. Obstacle-Typen in der Testarea

Reihenfolge von leicht nach schwer:

1. `A_very_low_box` (very_low)
2. `B_low_box` (low)
3. `C_wide_barricade` (low, breit)
4. `D_medium_block` (medium)
5. `E_borderline_block` (borderline)
6. `F_irregular_base` + `F_irregular_top` (unregelmaessige Stapelform)

Damit sind vorhanden:
- niedrige Box
- breiteres Hindernis/Barrikade
- mittelhohes Hindernis
- grenzwertiger Fall
- unregelmaessige Form

## 2.1 Zusaetzliche Box-Varianten

Im separaten Boxen-Set sind weitere Formen vorhanden:
- tiny crate
- narrow tall
- wide flat
- long low
- medium cube
- borderline tall
- step base + step top

Damit lassen sich auch reine Box-Formtests (Breite/Hoehe/Stacking) reproduzierbar pruefen.

## 3. Kennzeichnung fuer spaetere Jump-Logik

`JumpTestObstacle` setzt pro Instanz:

- Gruppen:
  - `jump_test_obstacle`
  - `jumpable_candidate`
  - `jump_type_<obstacle_type>`
  - `jump_height_<very_low|low|medium|borderline>`

- Metadaten:
  - `jump_test_id`
  - `obstacle_type`
  - `obstacle_height_class`
  - `traversal_hint`
  - `jump_test_enabled`
  - `obstacle_dimensions`

Das erlaubt spaeter:
- schnelle Filterung ueber Gruppen
- genaue Validierung ueber Metadaten/Dimensionen

## 4. Modularer Anschluss fuer spaetere KI

Geplante andockbare Schritte:

1. Zombie erkennt `jumpable_candidate` in Laufbahn
2. Liest `obstacle_height_class` + `obstacle_dimensions`
3. Prueft Art-/Rang-/State-Regeln (z. B. wer springen darf)
4. Entscheidet: springen, umgehen, abbrechen

Aktuell wird nur die Testgrundlage bereitgestellt, keine finale Traversal-Implementierung.

Aktuelle Basisanbindung:
- `scripts/zombie.gd` nutzt optional eine einfache Vorwaerts-Probe auf `jumpable_candidate`
- bei Treffer kann die neue `request_jump()`-Basisfunktion direkt ausgeloest werden
- steuerbar ueber `auto_jump_on_obstacle_probe`

## 5. Debug-Nutzen

Jedes Hindernis hat ein kleines Label:
- `jump_test_id`
- Hoehenklasse
- ungefaehre Hoehe in Metern

So lassen sich spaetere Sprungtests reproduzierbar und lesbar durchfuehren.
