# Species Visual Templates (Placeholder)

Dieses Dokument beschreibt den technischen Platzhalter-Visual-Layer fuer Zombie-Arten im Eneas2-Bereich.

Ziel:
- klare visuelle Unterscheidbarkeit pro Art
- austauschbare Vorlagen statt finaler Art-Produktion
- Anlehnung an Referenzbilder unter `assets/handbook/species/*`

Wichtig:
- Das ist **kein finaler Modellstand**.
- Die Vorlagen sind fuer spaeteren Austausch durch Art/Character-Owner vorbereitet.

## 1. Technischer Aufbau

Runtime-Quelle:
- `scripts/zombie_species_visuals.gd`

Anbindung:
- `scripts/zombie.gd` liest pro `species_id` eine `SpeciesVisualDefinition`
- Visual-Layer wird bei `_apply_profile_data()` angewendet

Pro Species werden aktuell datengetrieben gesetzt:
- `model_root_offset`
- `model_root_rotation_deg`
- `part_scale` (Kopf, Torso, Arme, Beine)
- `part_offset`
- `part_rotation_deg`
- `weapon_socket_offset`
- `held_item_scale`
- `hitbox_scale` und `hitbox_offset`
- `body_collision` (radius/height/y)
- `palette` (Platzhalterfarben)
- `silhouette_tags`
- `reference_image`

## 2. Austauschbarkeit

Die Visuals sind bewusst getrennt von der Kern-KI:
- KI-/Combat-Layer bleibt in `zombie.gd`, `zombie_definitions.gd`, `zombie_death_effects.gd`
- Form/Silhouette liegt zentral in `zombie_species_visuals.gd`

Spaeterer Austausch:
1. Species-Template in `zombie_species_visuals.gd` ersetzen oder auf echte Meshes umbiegen
2. KI-/Wave-/Death-Layer bleibt unveraendert
3. Handbuch-/Runtime-Logik muss nicht refactored werden

## 3. Umgesetzte Silhouetten

- Walker: neutraler Basistyp
- Tumbler: schiefe, instabile Koerperlinie
- Brute: deutlich breiter und kompakter Tank-Koerper
- Twink: schmal, klein, fragil
- Buffed: gross, muskuloes, breite Schultern
- Crawler: bodennah, niedrige Silhouette, Beine stark reduziert
- Granny: alt, gebueckt, fragiler Aufbau
- Hidder: gedrueckt/geduckt fuer Ambush-Lesbarkeit
- Sprinter: drahtig, langgliedrig, speed-orientiert
- Skinner: sehnig, straff, rohes Profil
- Bomb: aufgeblähtes Zentrum, volatile Lesbarkeit
- Feeder: klein, mutiert, gedrueckt
- Cry Baby: eingefallen, apathische Haltung
- Panico: asymmetrisch-chaotisch, nervoes instabil
- Skully: extrem ausgemergelt, knochige Silhouette

## 4. Hinweise zu Referenzen

Primare Referenzen:
- `assets/handbook/species/walker.svg`
- `assets/handbook/species/tumbler.svg`
- `assets/handbook/species/brute.svg`
- `assets/handbook/species/twink.svg`
- `assets/handbook/species/buffed.svg`
- `assets/handbook/species/crawler.svg`
- `assets/handbook/species/granny.svg`
- `assets/handbook/species/hidder.svg`
- `assets/handbook/species/sprinter.svg`
- `assets/handbook/species/skinner.svg`
- `assets/handbook/species/bomb.svg`
- `assets/handbook/species/feeder.svg`
- `assets/handbook/species/cry_baby.svg`
- `assets/handbook/species/panico.svg`
- `assets/handbook/species/skully.svg`

## 5. Scope-Grenze

Nicht Bestandteil dieses Schritts:
- finale Texturen/Materialien
- finale High-Poly-Modelle
- Rig-/Animations-Polish
- VFX-Polish

Fokus bleibt:
- schnell lesbare Artenunterschiede
- merge-sichere, austauschbare technische Vorlage
