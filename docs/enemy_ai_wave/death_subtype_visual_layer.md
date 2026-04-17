# DeathSubtype Visual Layer (Placeholder)

Dieses Dokument beschreibt den separaten Visual-Layer fuer Todesarten.

Ziel:
- Todesart nur dezent andeuten
- pro Todesart farblich unterscheidbar
- aktuelle Umsetzung ueber Partikel
- spaeter ohne KI-Refactor auf Modell/Overlay umstellbar

## 1. Trennung der Layer

Die Darstellung bleibt in separaten Ebenen:
- Species-Visual: Silhouette/Proportion
- Rank-Visual: Groesse/Praesenz
- Mort-Visual: Dunkelheit (0..10)
- DeathSubtype-Visual: farbcodierter Zusatzhinweis

Wichtig:
- keine Vermischung mit Gameplay-Logik
- DeathSubtype-Farbe dient nur Lesbarkeit/Atmosphaere

## 2. Runtime-Komponenten

### Datenquelle
- `scripts/zombie_death_visuals.gd`
- zentrale Tabelle: `SUBTYPE_VISUAL_DATA`
- pro Subtype mindestens:
  - `visual_mode`
  - `display_color`
  - `secondary_color`
  - `intensity`
  - `spawn_anchor`

### Controller
- `scripts/zombie_death_visual_controller.gd`
- generische Runtime-Schnittstelle:
  - `spawn_visual_instance(zombie, visual_profile, anchor_nodes)`
  - `clear_instance(instance_data)`

Unterstuetzte Modi:
- `particle` (jetzt aktiv)
- `attachment_model` (vorbereitet)
- `mesh_overlay` (vorbereitet)
- `none`

### Zombie-Anbindung
- `scripts/zombie.gd`
- bei `_apply_profile_data()`:
  - Profil aufloesen
  - Visual-Instance spawnen
  - Meta-Infos setzen (`death_visual_mode`, `death_visual_color_hex`, `death_visual_intensity`, ...)
- bei `_exit_tree()`:
  - Visual-Instance sauber freigeben

## 3. Darstellung jetzt (particle)

Aktuell wird pro Zombie eine kleine GPUParticles3D-Instanz erzeugt:
- geringe bis mittlere Partikelmenge
- kurze Lebensdauer
- subtile Farbgradienten
- Attach ueber klaren Anker (Standard `torso`)

Designregel:
- Effekt bleibt dezent
- Species/Rank/Mort-Lesbarkeit bleibt erhalten

## 4. Austauschbarkeit spaeter

Umstellung auf Modell/Overlay:
1. `visual_mode` im Visualprofil anpassen (`attachment_model` / `mesh_overlay`)
2. Controller-Zweig fuellen (statt Partikel Modell-Instanz/Overlay setzen)
3. bestehende Zombie-KI und DeathSubtype-Gameplay bleiben unveraendert

Damit bleibt der Layer merge-sicher und austauschbar.

## 5. Handbuch-Anbindung

Todesarten-Eintraege zeigen jetzt auch Visualdaten:
- Visual-Modus
- Primaerfarbe (Hex + Farbfeld)
- Sekundaerfarbe
- Intensitaet
- Anchor
- Placeholder-Status

Technik:
- Datenaufbereitung in `scripts/zombie_handbook_data.gd`
- Ausgabe in `scripts/handbook_book.gd`

## 6. Scope-Hinweis

Nicht Teil dieses Schritts:
- finale VFX-Inszenierung
- finale Shader-/Materialpipeline
- aufwendige Modell-Anbauteile

Aktueller Stand ist bewusst eine technische Vorschau.
