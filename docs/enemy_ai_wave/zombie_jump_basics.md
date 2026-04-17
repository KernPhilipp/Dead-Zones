# Zombie-Sprungbasis (einfach, unabhaengig)

Dieses Dokument beschreibt die aktuelle Basis-Sprungfunktion fuer Zombies.

Ziel:
- robuste Grundmechanik
- keine Abhaengigkeit von komplexer Traversal-/Nav-Architektur
- spaeter erweiterbar fuer Hindernis- und Arten-spezifische Regeln

## 1. Kernfunktionen

In `scripts/zombie.gd`:
- `request_jump(reason)`
- `can_jump()`
- `_start_jump(reason)`
- `_apply_gravity(delta)`
- `_update_air_state(delta)`
- `_handle_landing()`
- `request_jump_for_obstacle()` (Hook fuer spaetere Hindernislogik)

## 2. Jump-/Air-State

Verwendete Laufzeitflags:
- `is_grounded`
- `is_jumping`
- `is_falling`
- `jump_cooldown_remaining`
- `landing_recovery_remaining`

Regeln:
- Sprung nur bei Bodenkontakt
- kein Doppelsprung in der Luft
- kurze Recovery nach Landung

## 3. Konfigurierbare Parameter

Exportwerte pro Zombie:
- `jump_force`
- `jump_gravity_scale`
- `fall_gravity_scale`
- `air_control_multiplier`
- `jump_cooldown_seconds`
- `landing_recovery_seconds`
- `jump_requires_legs`
- `auto_jump_on_obstacle_probe`
- `jump_obstacle_probe_distance`
- `jump_obstacle_probe_height`

Debug:
- `debug_jump_once`
- `debug_auto_jump_enabled`
- `debug_auto_jump_interval`

## 4. Kampfverhalten waehrend Sprung

Bewusst einfach:
- solange `airborne`: kein normaler Nahkampf-Trigger
- Attack-Transition wird in Luftphase blockiert

## 5. Tod/Reset

Bei `die()` / `_die_with_explosion()`:
- Jump-Flags werden sofort zurueckgesetzt
- keine weitere Jump-Reaktivierung im Dead-State

## 6. Aktueller Hindernisbezug

Es gibt eine leichte, optionale Vorab-Erkennung:
- Vorwaerts-Probe erkennt `jumpable_candidate`
- bei Treffer kann direkt `request_jump()` ausgeloest werden

Wichtig:
- das ist bewusst eine minimale Basis
- keine finale Traversal-KI
- keine komplexe NavMesh-Sprungplanung

## 7. Andockpunkte fuer spaeter

Spaetere Erweiterungen koennen ohne Refactor andocken:
- Arten-/Rang-/Mort-abh. Jump-Multiplikator
- Beine/Verletzung beeinflusst Jump-Qualitaet
- intelligentere Hindernisklassifikation
- Sprungentscheidung in Wave-/KI-Strategielayer
