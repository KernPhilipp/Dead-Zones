# Todesarten-Effekte - Implementierungsstatus

Dieses Dokument beschreibt den aktuellen Runtime-Stand der DeathSubtype-Effekte.

Statuswerte:
- `active_now` = voll aktiv im aktuellen Runtime-Loop
- `simplified_now` = reduzierte, aber spielbare Version aktiv
- `planned_later` = als Hook vorgesehen (kein kompletter Ausbau im aktuellen Scope)

Hinweis:
- Alle DeathSubtypes sind im Handbuch sichtbar.
- Ein separater `Todesklassen`-Reiter wurde entfernt; Klassen erscheinen als Gruppen im Reiter `Todesarten`.

## 1. Voll aktiv (`active_now`)

- verflucht
- militaerisch
- vergiftet
- infiziert
- krebsinfiziert
- zerstueckelt
- atomverseucht
- verbrannt
- erfroren
- elektrisiert
- verblutet
- pilzinfiziert
- chemisch verseucht
- saeureveraetzt
- seuchenverseucht
- verwest
- frisch verstorben
- gefoltert
- Blitzschlag-Opfer
- Tierangriff-Opfer
- radioaktiv mutiert
- erstochen
- erschossen
- erschlagen

## 2. Reduziert aktiv (`simplified_now`)

- alkoholisiert
- geistlich
- stark verletzt
- ertrunken
- erhaengt
- parassitiert
- mumifiziert
- daemonisch besessen
- hingerichtet

## 3. Hooks fuer spaetere Ausbaustufen

Diese Bereiche sind bewusst reduziert oder als Hook vorbereitet:
- gezielte Kopftreffer-/Limb-Praezisionslogik
- ortsgebundene Triggerlogik (z. B. heilige Orte)
- komplexe Sicht-/Screen-Effekte fuer den Spieler
- echte Parasiten-Minions als separates Spawn-Subsystem
- erweiterte Daemonenstufen/Faehigkeitsbaeume
- spezielle Weakspot-Layouts pro Todesart

## 4. Aktive Effektfamilien in der Runtime

- Bewegungsmodifikatoren (Wobble, Stumble, Jitter)
- Aggro-/Chase-Modifikatoren
- Attack-Cooldown-Variationen
- Aura-Effekte
- Kontakt-DOT und Touch-Zusatzschaden
- On-Death-Bursts
- Schmerz-/Stagger-Resistenz
- lokale Ally-Interaktion
- kontrollierter Mutationspool (`radioaktiv mutiert`)
- generischer RacheBonus

## 5. RacheBonus

Wenn `revenge_bonus=true`:
- stirbt ein verbuendeter Zombie in Reichweite, kann der betreffende Zombie zeitlich begrenzte Buffs erhalten
- typische Buffachsen: Speed, Damage, Attack-Cooldown

## 6. Bildstatus im Handbuch

Todesarten-Eintraege laden zuerst ihr spezifisches Bild.
Falls ein Bild fehlt oder fehlschlaegt, greift der Platzhalter:
- `res://assets/handbook/placeholder_missing.svg`
