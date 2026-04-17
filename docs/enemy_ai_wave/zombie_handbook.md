# Zombie-Kompendium - Datenmodell und Handbuch

Dieses Dokument beschreibt den aktuellen Stand der Zombie-Datenstrukturen und der Ingame-Handbuchlogik im Eneas-Bereich.

## 1. Handbuch-UI (aktueller Aufbau)

Aktive Kapitel-Reiter im Spiel:
- `Uebersicht`
- `Zombie-Arten`
- `Todesarten`
- `Grundlagen`

Wichtig:
- Es gibt **keinen separaten `Todesklassen`-Reiter** mehr.
- Todesklassen bleiben als Datenebene erhalten und werden im Reiter `Todesarten` als Gruppen verwendet.

Navigation:
- Linke Seite ist ein ausklappbarer `Tree`.
- Im Reiter `Uebersicht` sind die Unterpunkte als Schnellnavigation klickbar.
- Klick auf Unterpunkte kann direkt in andere Kapitel springen (z. B. von `Uebersicht` zu `Todesarten-Uebersicht`).

## 2. Schichtenmodell eines Zombie-Profils

Jede Zombie-Instanz wird aus separaten Layern zusammengesetzt:
- `Species` (Art)
- `GameplayClass`
- `Mort-Grad` (0..10)
- `Rank` (Alpha..Epsilon)
- `DeathClass`
- `DeathSubtype`
- `VisualVariant` (`male`/`female`, nur visuell)
- `HandbookCategory` (nur Anzeige im Handbuch)

Wichtig:
- `GameplayClass` und `DeathClass` sind strikt getrennt.
- `HandbookCategory` ist nur Sortierung im Handbuch, kein Gameplay-Modifier.

## 3. Arten und Handbuch-Kategorien

Arten-Reihenfolge:
1. Walker
2. Tumbler
3. Brute
4. Twink
5. Buffed
6. Crawler
7. Granny
8. Hidder
9. Sprinter
10. Skinner
11. Bomb
12. Feeder
13. Cry Baby
14. Panico
15. Skully

Handbuch-Kategorien (Anzeige):
- Gewoehnlich
- Heavy
- Fast
- Ambush
- Special

## 3.1 Species-Visual-Layer (Placeholder)

Der visuelle Arten-Layer ist separat und austauschbar umgesetzt:
- zentrale Definition: `scripts/zombie_species_visuals.gd`
- Runtime-Anwendung: `scripts/zombie.gd` bei `_apply_profile_data()`

Pro Art werden datengetrieben gesetzt:
- Silhouette/Proportion (`part_scale`, `part_offset`, `part_rotation_deg`)
- Haltung (`model_root_offset`, `model_root_rotation_deg`)
- einfache Platzhalterfarbe (`palette`)
- Treffer-/Koerperprofil (`hitbox_scale`, `hitbox_offset`, `body_collision`)

Referenzbasis:
- `assets/handbook/species/*` (SVG-Artenkarten)

Designziel:
- Arten auf den ersten Blick unterscheidbar
- keine finalen Art-Assets
- spaeterer Austausch durch Character-/Art-Owner ohne KI-Refactor

## 4. DeathClass und DeathSubtype

`DeathClass`-Gruppen:
- Krankheit
- Uebernatuerlich
- Gewalt
- Chemisch
- Natur
- Unfall
- Verwesung
- Strahlung

`DeathSubtype` ist die konkrete Unterform (z. B. `infiziert`, `verbrannt`, `atomverseucht`) inkl.:
- Seltenheit (`Gewoehnlich`, `Ungewoehnlich`, `Selten`, `Episch`, `Legendaer`)
- Effektprofil
- Implementierungsstatus
- RacheBonus-Flag

## 4.1 DeathSubtype-Visual-Layer (dezent, austauschbar)

Die Todesart wird zusaetzlich ueber einen separaten Visual-Layer angedeutet:
- `scripts/zombie_death_visuals.gd` (Datenbank pro Subtype)
- `scripts/zombie_death_visual_controller.gd` (Runtime-Instanzierung)
- `scripts/zombie.gd` (Anbindung beim Profil-Apply)

Aktiv jetzt:
- `visual_mode = particle` (dezent, farbcodiert pro Todesart)

Vorbereitet fuer spaeter:
- `visual_mode = attachment_model`
- `visual_mode = mesh_overlay`

Wichtig:
- Species-/Rank-/Mort-Lesbarkeit bleibt erhalten
- DeathSubtype-Visuals sind von DeathSubtype-Gameplay getrennt
- aktuelle Partikel sind technische Vorschau, nicht finales VFX

## 5. Mort-Grad (0..10)

Semantik:
- `0` = frisch
- `10` = stark verwest
- `6` = neutraler Schwerpunkt

### 5.1 Spawn-Wahrscheinlichkeit

Rohgewicht:
- `raw_weight(g) = 0.5 ^ abs(g - 6)`

Normalisierung:
- `P(g) = raw_weight(g) / Sum(raw_weight(min..max))`

Bei Bereich `0..10`:
- g0  = 0.534759 %
- g1  = 1.069519 %
- g2  = 2.139037 %
- g3  = 4.278075 %
- g4  = 8.556150 %
- g5  = 17.112299 %
- g6  = 34.224599 %
- g7  = 17.112299 %
- g8  = 8.556150 %
- g9  = 4.278075 %
- g10 = 2.139037 %

### 5.2 Stat-Modifikatoren

Speed:
- `g < 6`: `1.0 + (6-g) * 0.02`
- `g > 6`: `1.0 - (g-6) * 0.03`
- Clamp: `0.82 .. 1.12`

Damage:
- `g < 6`: `1.0 + (6-g) * 0.015`
- `g > 6`: `1.0 - (g-6) * 0.05`
- Clamp: `0.80 .. 1.09`

Attack-Cooldown:
- `g < 6`: `1.0 - (6-g) * 0.015`
- `g > 6`: `1.0 + (g-6) * 0.025`
- Clamp: `0.90 .. 1.25`

### 5.3 Visuelle Mort-Darstellung

Mort-Grad wirkt jetzt auch als separater Visual-Layer:
- niedriger Mort-Grad: heller
- hoher Mort-Grad: dunkler

Technische Dunkelheitskurve (Vorlage):
- Mort 0: 0.00
- Mort 1: 0.04
- Mort 2: 0.08
- Mort 3: 0.12
- Mort 4: 0.17
- Mort 5: 0.22
- Mort 6: 0.28
- Mort 7: 0.36
- Mort 8: 0.45
- Mort 9: 0.55
- Mort 10: 0.65

Implementierung:
- `scripts/zombie_mort_visuals.gd` liefert Mort-Visual-Profil und Dunkelheitswerte
- `scripts/zombie.gd` legt den Mort-Layer ueber die Species-Palette

Wichtig:
- Species-/Rank-Lesbarkeit bleibt erhalten
- Mort-Layer ist austauschbar fuer spaetere Art-Polish-Pipelines

## 6. Rang-Hierarchie

Hierarchie:
- Alpha (`rank_power=4`)
- Beta (`rank_power=3`)
- Gamma (`rank_power=2`)
- Delta (`rank_power=1`)
- Epsilon (`rank_power=0`)

Aktive Rang-Modifier:

| Rank | Size | HP | Damage | Speed | Threat | Spawn-Intervall | Speed-Cap |
|---|---:|---:|---:|---:|---:|---:|---:|
| Alpha | x1.55 | x2.20 | x1.85 | x0.75 | x2.50 | x1.80 | 2.60 |
| Beta | x1.30 | x1.65 | x1.45 | x0.88 | x1.70 | x1.35 | 2.95 |
| Gamma | x1.15 | x1.30 | x1.20 | x0.94 | x1.30 | x1.15 | 3.25 |
| Delta | x1.00 | x1.00 | x1.00 | x1.00 | x1.00 | x1.00 | 3.55 |
| Epsilon | x0.90 | x0.75 | x0.80 | x1.08 | x0.80 | x0.90 | 4.35 |

## 7. Endwert-Berechnung im Profil

Die finalen Kampfwerte entstehen multiplikativ:
- Speed: `base_speed * class * rank * mort`, danach `min(rank_speed_cap)` und globales Clamp
- Health: `base_health * class * rank * mort`
- Damage: `base_damage * class * rank * mort`
- Attack-CD: `base_attack_cooldown * class * rank * mort`

Gender:
- `allow_female_variants` steuert nur die visuelle Auswahl.
- Kein Gameplay-Unterschied zwischen male/female.

## 8. Bildlogik im Handbuch

Arten- und Todesarten-Eintraege:
- Versuchen zuerst das spezifische Bild aus den Daten.
- Bei fehlendem/ungueltigem Pfad wird automatisch Platzhalter geladen:
  - `res://assets/handbook/placeholder_missing.svg`

Seiten ohne Bildbedarf (z. B. viele Grundlagen/Meta-Seiten):
- bekommen bewusst kein erzwungenes Platzhalterbild.

## 9. Verknuepfte Doku

- Wellenruntime: [wave_runtime.md](./wave_runtime.md)
- Todesarten-Status: [death_effects_status.md](./death_effects_status.md)
- DeathSubtype-Visual-Layer: [death_subtype_visual_layer.md](./death_subtype_visual_layer.md)
- Jump-Test-Hindernisse: [jump_test_obstacles.md](./jump_test_obstacles.md)

## 10. Sprungtest-Hindernisse (Vorlage)

Im Grundlagen-Kapitel gibt es eine eigene Handbuchseite `Sprungtest-Hindernisse`.

Zweck:
- Vorbereitung fuer spaetere Zombie-Sprungtests
- klar abgestufte Hindernisse von `very_low` bis `borderline`
- keine finale Traversal-Logik in diesem Schritt

Technik:
- Prefab: `res://scenes/wave/jump_test_obstacle.tscn`
- Testbereich: `res://scenes/wave/zombie_jump_test_area.tscn`
- Gruppen/Metadaten fuer spaetere KI-Anbindung sind bereits gesetzt

## 11. Zombie-Sprungbasis

Die einfache Sprungfunktion ist jetzt direkt in der Zombie-Logik vorhanden.

Wesentliche Punkte:
- klarer Air-State (`is_grounded`, `is_jumping`, `is_falling`)
- Sprung nur vom Boden, kein Doppelsprung
- Luftphase mit separater Jump-/Fall-Gravity-Skalierung
- Landung mit kurzer Recovery
- waehrend Airborne keine normalen Nahkampfangriffe
- optionale leichte Vorwaerts-Probe auf `jumpable_candidate`

Technische Details:
- `scripts/zombie.gd`
- siehe: [zombie_jump_basics.md](./zombie_jump_basics.md)
