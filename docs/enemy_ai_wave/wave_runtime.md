# Wave Runtime - Rang, Budget, Ebenen, Schedule

Dieses Dokument beschreibt die aktuelle Wellen-Laufzeitlogik im Eneas-Bereich.

## 1. Export-Defaults (GameManager)

Budgets:
- `base_wave_spawn_count = 20`
- `alive_cap = 12`
- `near_zero_threshold = 0.01`

Timing:
- `base_spawn_interval_seconds = 1.2`
- `spawn_delay_step_seconds = 0.25`
- `intermission_seconds = 3.0`

Spawnposition:
- `min_spawn_distance_from_player = 10.0`
- `spawn_retry_limit = 12`

Profil-Parameter:
- `allow_female_variants = true`
- `mort_grade_min = 0`
- `mort_grade_max = 10`

Debug/Tuning:
- `show_wave_debug_overlay = true`
- `allow_runtime_curve_toggle = true`
- `use_tuned_wave_curve = false`

## 2. Runtime-Zustandsmaschine

Phasen:
1. Intermission
2. Active Wave
3. Wave Complete -> Intermission

Falls `wave_start_on_ready = true`, startet Welle 1 direkt.
Sonst startet das System mit Intermission.

## 3. Start einer neuen Welle (Plan-vorher-Prinzip)

Beim Wellenstart:
1. Spawnquellen aktualisieren (`SpawnPoints` + Gruppe `map_spawn_point`)
2. Budget berechnen
3. Hauptverteilung berechnen (default oder tuned)
4. Main-Rank-Counts samplen
5. Verdraengte Ranks ueber `near_zero_threshold` ermitteln
6. Persistente Ebenen (`layer_state`) aktualisieren
7. Extra-Spawn-Allokation aus Restbudget erzeugen
8. Vollstaendige Entry-Liste bauen
9. Zeitplan (`planned_earliest_time`) erstellen
10. Als `wave_plan` einfrieren und nur noch ausfuehren

Wichtig:
- Waehren der Welle wird nicht neu gewuerfelt, sondern nur der Plan abgearbeitet.

## 4. Budgetmodell

Das Budget kommt aus `SpawnBudgetModel`:
- `main_spawn_budget = base_wave_spawn_count`
- `max_total_spawn_budget = main_spawn_budget * 2`
- `extra_spawn_budget = max_total - main`

Mit Default `20`:
- Main = 20
- Max Total = 40
- Extra = 20

## 5. Hauptverteilung (non-linear)

Kurvenmodell in `MainWaveProgressionModel`:
- `epsilon_raw(w) = 0.002 + 1.35 * exp(-0.22*(w-1))`
- `delta_raw(w)   = 0.004 + 1.20 * sigmoid((w-12.5)/3.0)`
- `gamma_raw(w)   = 0.001 + 0.85 * sigmoid((w-17.0)/3.0)`
- `beta_raw(w)    = 0.0002 + 0.42 * sigmoid((w-26.0)/3.6)`
- `alpha_raw(w)   = 0.00002 + 0.08 * sigmoid((w-38.0)/4.8)`

Danach Normalisierung:
- `p(rank,w) = raw(rank,w) / sum(raw_all_ranks)`

Tuned-Variante:
- Zweites Preset (`curve_mode = tuned`) mit frueherem Druckanstieg.
- Umschaltbar im Lauf mit `F7` (wenn `allow_runtime_curve_toggle=true`).
- Wirkt auf naechste neu berechnete Wellen.

## 6. Verdraengte Ranks und Ebenensystem

Ein Rank gilt als verdraengt, wenn:
- `probability < near_zero_threshold`
- und Trend gegenueber Vorwelle nicht steigend ist

Layer-Update:
- Neue verdraengte Ranks gehen auf Ebene 1.
- Bestehende Ebenen ruecken nach hinten.
- `waves_in_layer` neuer Eintrag startet bei 0.

Intensitaet:
- `intensity = 1 - exp(-(waves_in_layer)/(3.0 + 0.8*layer_depth))`

Layergewicht:
- `layer_weight = min(1.0, 0.22 + 0.18*layer_depth)`

Extra-Spawns:
- Verteilung ueber normalisierte `layer_weight * intensity`
- hart gedeckelt durch `extra_spawn_budget`

## 7. Entry-Komposition

`WaveComposer` erzeugt pro Entry:
- `rank_id` (aus Main/Extra-Verteilung)
- `species_id` (random aus Species-Order)
- `class_id` (random aus Class-Daten)
- `mort_grade` (gewichtetes Mort-Rolling)
- `death_subtype_id` (random aus Subtype-Order)
- `death_class_id` (aus DeathSubtype abgeleitet)
- `visual_variant` (male/female je Setting)
- `source_layer` (`main` oder `extra_lX`)
- Plan-Statusfelder (`planned_earliest_time`, `state`, `spawn_attempts`)

## 8. Schedule-Aufbau

`SpawnScheduleBuilder`:
1. Eintraege shufflen
2. Spacing-Regeln anwenden:
   - Alpha: Mindestabstand 4 Eintraege
   - Beta/Gamma-Gruppe: Mindestabstand 2 Eintraege
3. Zeitstaffelung berechnen

Intervallformel:
- `interval = base_spawn_interval * rank_interval_factor * source_layer_factor * wave_modifier`
- `source_layer_factor = 1.05` fuer `extra_*`, sonst `1.0`
- Jitter `+-8%`

## 9. Spawn-Ausfuehrung zur Laufzeit

`SpawnExecutor` arbeitet nur due Entries ab:
- Wenn `planned_earliest_time > elapsed`: warten
- Wenn `alive_count >= alive_cap`: Entry auf `delayed`, Zeit `+spawn_delay_step_seconds`
- Bei Spawn-Erfolg: `state=spawned`, `pending_index++`
- Bei Spawn-Fehler:
  - `spawn_attempts++`
  - wenn `attempts >= spawn_retry_limit`: `state=failed`, `pending_index++`
  - sonst `state=delayed`, Zeit verschieben

## 10. Spawnpunkt-Validierung

`MapSpawnProvider` sammelt Spawnquellen aus:
- `../SpawnPoints` (Child-Nodes)
- Gruppe `map_spawn_point`

`SpawnPositionValidator`:
- sampled zufaelligen Punkt
- prueft Mindestabstand zum Player
- retry bis `spawn_retry_limit`
- bei Fehlschlag liefert `valid=false`

## 11. Wellenende

Eine Welle gilt als abgeschlossen, wenn:
- `pending_index >= entries.size()`
- kein Entry mehr `planned` oder `delayed` ist
- `alive_count <= 0`

Danach:
- `wave_active = false`
- Intermission startet (`intermission_seconds`)

## 12. Debug-Overlay

Bei `show_wave_debug_overlay=true` zeigt das Overlay live:
- Welle/Phase (`ACTIVE` oder `INTERMISSION`)
- Kurvenmodus (`default`/`tuned`)
- Plan-Counts (`total/main/extra/pending/alive`)
- Timing (`elapsed/intermission/base interval`)
- Spawnpoint-Infos (`count/min dist/retry`)
- Verteilungs-Snapshot je Rank
- Layer-Snapshot (`L1/L2/...`)

## 13. Erweiterungspunkt Spezialwellen

`SpecialWaveModifierInterface` ist aktuell no-op (`1.0` Multiplikatoren), aber vorbereitet fuer:
- Rank-Weight-Modifikation
- Spawn-Intervall-Modifikation
- Extra-Budget-Modifikation
