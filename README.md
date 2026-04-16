# 🧟 Dead Zones
commit test

**Dead Zones** ist ein First-Person Zombie-Shooter im Stil klassischer COD-Zombies-Modi.  
Der Fokus liegt auf **Wellen-basiertem Survival**, **Erkundung von Lost Places** sowie einem **Loot- und Upgrade-System**.
testteset
---

## 🎮 Spielkonzept

Der Spieler kämpft in verlassenen, düsteren Umgebungen ums Überleben.  
Mit jeder Runde werden die Gegner stärker, aggressiver und zahlreicher.

### 🔁 Core Gameplay Loop
1. Neue Gegnerwelle startet  
2. Spieler bekämpft Zombies  
3. Ressourcen / Loot werden gesammelt  
4. Ausrüstung wird verbessert  
5. Nächste, schwerere Welle beginnt  

---

## ⚙️ Geplante Features

- 🧟 Zombie-KI & Gegnerwellen  
- 🔫 Waffensystem mit Upgrades  
- 🎒 Loot- & Inventarsystem  
- 🏚️ Atmosphärische Lost-Places-Maps  
- 🌦️ Dynamisches Wetter  
- 🌙 Tag-/Nachtzyklus  
- 🧍 First-Person Movement  
- 🧱 Barrikaden / Interaktionsobjekte  
- 🖥️ UI & Menüsystem  

---

## 🧰 Technologie

- **Engine:** Godot  
- **Genre:** First-Person Shooter / Survival  
- **Setting:** Lost Places / Post-Apokalypse  

---

## 👥 Teamstruktur & klare Aufgabenbereiche

Diese Aufteilung bildet den **aktuellen, im Repository sichtbaren Arbeitsstand** ab und trennt gleichzeitig die **weitere Verantwortung** so, dass sich die Bereiche möglichst wenig überschneiden.  
Stand dieser Zuordnung: **Commit-Verlauf bis 10. April 2026**.

Wichtig:
- Wenn ein Bereich bereits im Repo existiert, aber historisch noch nicht sauber über eigene Commits getrennt wurde, ist das ausdrücklich vermerkt.
- Wenn bei einer Person noch kein eigener fachlicher Commit sichtbar ist, bleibt der Bereich als **reservierter Zuständigkeitsbereich** bestehen.
- Ziel ist nicht nur Fairness in der Beschreibung, sondern vor allem **saubere Arbeitsgrenzen für die nächsten Schritte**.

---

## 1) Projektleitung, Repository, zentrale Integration & Web-Deployment

### **Tobias Halwax**
**Bisher sichtbar im Repo:**
- initialer Import und Grundstruktur des Godot-Projekts
- Render-Deployment und Web-Export-Setup
- Pflege zentraler Projektdateien und Build-Konfiguration
- Branch-/PR-Merges und Konfliktauflösung
- technische Integration zwischen HUD, Wave-System und Runtime
- Balancing- und Release-nahe Anpassungen im zentralen Game-Flow

**Verantwortlich ab jetzt für:**
- Projektverwaltung
- Git-Strategie / Branching / Merging
- Deployment über **Render**
- Web-Build / Export-Konfiguration
- Pflege gemeinsamer Projektdateien
- zentrale technische Integration zwischen Teilsystemen
- Release-Stabilität und zusammengeführte Runtime

**Darf bearbeiten:**
- `project.godot`
- `.github/workflows/*`
- `export_presets.cfg`
- `scenes/main.tscn`
- `scripts/game_manager.gd`
- `README.md` für technische Strukturthemen
- globale Projektstruktur und Build-/Release-Dateien

**Bearbeitet nicht direkt:**
- eigenständige Gegnerdefinitionen und Wave-Modelle
- HUD-Layout und UI-Design
- fachliche Player-/Combat-/Loot-Logik
- Map-Blockouts und Levelstruktur
- reine Asset-Erstellung für Umgebung oder Charaktere
- Wetter-/Tageszeit-Systeme

**Wichtige Abgrenzung:**  
Tobias ist der technische Integrations-Owner. Er verbindet vorhandene Systeme, veröffentlicht Builds und hält das Repo stabil, ist aber nicht der fachliche Owner für fremde Gameplay- oder Asset-Bereiche.

---

## 2) Gegner, Zombie-Daten, Spawning, Wave-Runtime & Handbook-Inhalte

### **Eneas Zuckerstätter**
**Bisher sichtbar im Repo:**
- umfangreiche Erweiterung des Gegner- und Wellen-Systems
- Zombie-Arten, Klassen, Ränge und Death-/Handbook-Daten
- Spawn-Modelle, Spawn-Validierung, Spawn-Ausführung und Wellenkomposition
- Handbook-Inhalte inklusive begleitender Enemy-/Wave-Dokumentation

**Verantwortlich ab jetzt für:**
- Gegner-KI und gegnerbezogene Runtime
- Zombie-Basislogik und gegnerische Zustände
- Spawnlogik und Wellen-System
- Difficulty-/Round-Scaling
- Zombie-Datenmodelle und Handbook-Inhalte
- gegnerbezogene technische Doku

**Darf bearbeiten:**
- `scenes/zombie.tscn`
- `scripts/zombie.gd`
- `scripts/zombie_hitbox.gd`
- `scripts/zombie_definitions.gd`
- `scripts/zombie_death_effects.gd`
- `scripts/zombie_handbook_data.gd`
- `scripts/handbook_book.gd`
- `scripts/wave/*`
- `assets/handbook/*`
- `docs/enemy_ai_wave/*`

**Bearbeitet nicht direkt:**
- Player Controller
- Waffenhandling und Loot-/Inventar-Logik
- HUD-Layout und Menü-UX
- Deployment-/Build-Konfiguration
- Map-Struktur und Environment-Assets

**Wichtige Abgrenzung:**  
Eneas bestimmt, **wie Gegner aufgebaut sind, spawnen und sich über Wellen entwickeln**.  
Die Darstellung dieser Daten im HUD gehört nicht ihm, sondern der UI-Schicht.

---

## 3) UI / HUD / Menüs / Combat Feedback

### **Lukas Baier**
**Bisher sichtbar im Repo:**
- großes HUD-/UX-Update
- Pause-Menü, Game-Over-Darstellung und Combat-Feedback
- visuelle Anzeige für Leben, Munition, Nachladen, Wave-Status, Treffer und Schaden
- UI-nahe Anpassungen an Signalfluss und Präsentation

**Verantwortlich ab jetzt für:**
- UI/UX Design
- HUD
- Pause-Menü
- visuelle Combat-Feedback-Systeme
- Anzeigen für Leben, Munition, Status, Wave-Infos und Game-Over
- Bedienfluss und UI-Struktur

**Darf bearbeiten:**
- `scenes/hud.tscn`
- `scripts/hud.gd`
- `assets/ui/*`
- UI-nahe Signal-/Feedback-Anbindung in `scripts/player.gd`, wenn sie nur der Darstellung dient
- UI-nahe Szenenstruktur nach Absprache mit Tobias

**Bearbeitet nicht direkt:**
- Berechnung von Munition, Leben oder Inventar
- Gegner-KI und Wave-Logik
- Zombie-Datenmodelle
- Deployment-/Projektkonfiguration
- Map-Design und Asset-Erstellung

**Wichtige Abgrenzung:**  
Lukas baut die **Oberfläche und das visuelle Feedback**.  
Die Werte selbst kommen aus Gameplay-Systemen, nicht aus der UI.

---

## 4) Core Gameplay: Player, Combat, Loot & Inventory

### **Philipp Kern**
**Bisher sichtbar im Repo:**
- README- und Projektdokumentation
- Teamrollen, Korrekturen und Projektbeschreibung

**Verantwortlich ab jetzt für:**
- First-Person Player Controller
- Kamera / Movement / Sprint / Springen / Interaktion
- Waffenmechaniken
- Schießen / Nachladen / Weapon Handling
- Loot-System
- Inventar-Logik
- Item-Aufnahme / Item-Nutzung

**Darf bearbeiten:**
- `scenes/player.tscn`
- `scripts/player.gd`
- künftige Waffen-Skripte und Waffen-Szenen
- künftige Loot-/Item-/Inventar-Dateien
- Interaktionslogik des Spielers

**Bearbeitet nicht direkt:**
- Gegner-KI und Wave-Runtime
- HUD-Layout
- Deployment-/Build-Dateien
- Map-Struktur
- Wetter-/Tageszeit-System

**Wichtige Abgrenzung:**  
Der Bereich Player / Combat / Loot ist **fachlich Philipp Kern zugeordnet**.  
Da das aktuelle Grundgerüst historisch aus frühem Projektimport und späteren Integrationen stammt, werden größere Änderungen an bestehendem Bestandscode zusätzlich mit **Tobias** abgestimmt.

---

## 5) Map-Design & spielbare Levelstruktur

### **Daniel Rehrl**
**Bisher sichtbar im Repo:**
- im aktuellen Commit-Verlauf noch kein eigener fachlicher Repo-Beitrag sichtbar

**Verantwortlich ab jetzt für:**
- Map-Design
- Levelstruktur
- spielbare Lost-Places-Layouts
- Wegeführung
- Raumaufbau
- Platzierung spielbarer Bereiche

**Darf bearbeiten:**
- Map-Szenen
- Level-Layouts
- Blockouts
- spielbare Struktur der Welt

**Bearbeitet nicht direkt:**
- Wetter-/Lichtsystem
- Gegner-KI
- Waffenlogik
- UI
- reine 3D-Asset-Erstellung

**Wichtige Abgrenzung:**  
Daniel baut die **spielbare Weltstruktur**.  
Er entscheidet, wie die Map funktioniert und lesbar aufgebaut ist, aber nicht, wie Gegner, UI oder Wetter intern implementiert werden.

---

## 6) Environment Assets / Lost-Places-Modelle / Map-Komponenten

### **Luka Dragic (Goty)**  
### **Moritz Wieland**
**Bisher sichtbar im Repo:**
- bei Moritz ein kleiner README-Beitrag
- im aktuellen Commit-Verlauf noch keine eigenen Environment-Asset-Commits sichtbar

**Verantwortlich ab jetzt für:**
- 3D-Modelle für Lost Places
- Umgebungsobjekte
- Map-Komponenten
- Props / Dekoration / Architekturteile
- modulare visuelle Bausteine für Level

**Darf bearbeiten:**
- 3D-Assets
- Modell-Dateien
- Environment-Komponenten
- statische Szenen für Map-Objekte

**Bearbeitet nicht direkt:**
- Map-Gameplay-Logik
- Gegnerlogik
- Waffenlogik
- UI
- Player Controller

**Wichtige Abgrenzung:**  
Luka und Moritz liefern die **visuellen Bausteine** der Welt.  
Die **spielbare Anordnung** dieser Bausteine in der Map gehört zu Daniel.

---

## 7) Charakter- und Gegnermodelle

### **Gabriel Schönauer**
**Bisher sichtbar im Repo:**
- kleiner README-Fix
- im aktuellen Commit-Verlauf noch keine eigenen Charakter-/Gegner-Assets sichtbar

**Verantwortlich ab jetzt für:**
- Charaktermodelle
- Gegner-/Zombie-Modelle
- visuelle Modelle für Spieler und Feinde
- visuelle Varianten
- ggf. Asset-Vorbereitung für Animationen

**Darf bearbeiten:**
- Charakter-Assets
- Gegner-Assets
- Modell-Dateien
- visuelle Varianten

**Bearbeitet nicht direkt:**
- Gegner-KI
- Player Controller
- Waffenlogik
- UI
- Map-Logik

**Wichtige Abgrenzung:**  
Gabriel liefert das **Aussehen** von Spieler und Gegnern.  
Das **Verhalten** der Gegner gehört weiterhin zu Eneas.

---

## 8) Environment Systems: Wetter & Tag-/Nachtzyklus

### **Philipp Wilding**
**Bisher sichtbar im Repo:**
- im aktuellen Commit-Verlauf noch kein eigener fachlicher Repo-Beitrag sichtbar

**Verantwortlich ab jetzt für:**
- Dynamisches Wetter
- Tag-/Nachtzyklus
- Lichtwechsel
- Umgebungsstimmung auf Systemebene
- atmosphärische Umwelteffekte

**Darf bearbeiten:**
- Wetter-Skripte
- Licht-/Atmosphäre-Systeme
- Tageszeit-System
- umgebungsbezogene Effekte

**Bearbeitet nicht direkt:**
- Map-Layout
- Gegner-KI
- Waffen
- UI
- Player Controller

**Wichtige Abgrenzung:**  
Philipp Wilding baut die **Umgebungssysteme für Stimmung und Zeitverlauf**, aber nicht die eigentliche Map-Struktur und nicht die Gameplay-Logik.

---

## 📦 Systemübersicht

| System | Sichtbarer Stand im Repo | Verantwortlich |
|--------|--------------------------|----------------|
| Projektorganisation / Git / Merging / Deployment | bereits klar sichtbar | Tobias Halwax |
| Zentrale technische Integration / Runtime / Release-Builds | bereits klar sichtbar | Tobias Halwax |
| Gegner-KI / Zombie-Daten / Handbook-Inhalte | bereits klar sichtbar | Eneas Zuckerstätter |
| Spawn- & Wellen-System | bereits klar sichtbar | Eneas Zuckerstätter |
| UI / HUD / Menüs / Combat Feedback | bereits klar sichtbar | Lukas Baier |
| Projektdokumentation / README | bereits klar sichtbar | Philipp Kern |
| Player Controller / Combat / Loot / Inventar | Grundgerüst vorhanden, Historie noch nicht sauber getrennt | Philipp Kern |
| Map-Design / Levelstruktur | aktuell noch nicht im Commit-Verlauf sichtbar | Daniel Rehrl |
| 3D Assets für Umgebung / Lost Places | aktuell noch nicht im Commit-Verlauf sichtbar | Luka Dragic, Moritz Wieland |
| Charakter- & Gegnermodelle | aktuell noch nicht im Commit-Verlauf sichtbar | Gabriel Schönauer |
| Wetter / Tag-Nacht / Atmosphäre | aktuell noch nicht im Commit-Verlauf sichtbar | Philipp Wilding |

---

## 🔌 Schnittstellen zwischen den Systemen

Damit sich Aufgaben nicht überschneiden, gelten folgende klaren Übergaben:

### Player ↔ UI
- **Philipp Kern** liefert die Werte und Gameplay-Zustände
- **Lukas** zeigt diese Werte im HUD an
- Änderungen an bestehendem Bestandscode werden bei größeren Umbauten zusätzlich mit **Tobias** abgestimmt

Beispiele:
- Leben
- Munition
- Reload-Zustand
- aktives Item
- Interaktionshinweise

### Combat ↔ Enemy System
- **Philipp Kern** löst Treffer, Waffeneffekte und spielerseitige Aktionen aus
- **Eneas** verarbeitet Gegnerreaktion, gegnerische Zustände, Spawnregeln und Wave-Fortschritt

### Enemy / Wave System ↔ UI
- **Eneas** liefert die gegner- und wavebezogenen Daten
- **Lukas** visualisiert Wave-Status, Meldungen und Feedback
- **Tobias** übernimmt die zentrale Laufzeit-Integration, wenn mehrere Systeme zusammengeführt werden

### Handbook ↔ UI
- **Eneas** verantwortet Inhalte, Datenmodell und gegnerbezogene Handbook-Logik
- **Lukas** verantwortet nur die allgemeine UI-Präsentation, falls Handbook-Zugänge in Menüs oder HUD eingebunden werden

### Map ↔ Assets
- **Daniel** baut die spielbare Levelstruktur
- **Luka / Moritz** liefern die visuellen Environment-Bausteine

### Map ↔ Environment Systems
- **Daniel** erstellt die Map-Struktur
- **Philipp Wilding** legt Wetter, Licht und Tageszeit darüber

### Assets ↔ Gameplay
- **Gabriel**, **Luka** und **Moritz** liefern visuelle Assets
- **Daniel**, **Philipp Kern** und **Eneas** binden diese in spielbare Systeme ein
- **Tobias** koordiniert die technische Zusammenführung in die Release-fähige Projektstruktur

---

## 🚫 Wichtige No-Go-Regeln gegen Überschneidungen

1. **Jede Person arbeitet nur im eigenen Hauptsystem.**
2. **Zentrale Projektdateien** werden nur von **Tobias** gepflegt oder nach Absprache geändert.
3. **`scripts/game_manager.gd` ist Integrationsbereich** und gehört fachlich nicht automatisch dem Enemy-, UI- oder Player-Bereich.
4. **`scripts/wave/*`, `scripts/zombie*.gd` und Handbook-Daten** gehören fachlich zu **Eneas**.
5. **`scenes/hud.tscn` und `scripts/hud.gd`** gehören fachlich zu **Lukas**.
6. **`scripts/player.gd` und künftige Combat-/Loot-Dateien** gehören fachlich zu **Philipp Kern**; reine UI-Signal-Anbindung darin nur nach Absprache.
7. **Asset-Verantwortliche ändern keine Core-Gameplay-Skripte.**
8. **Map-Design ändert keine Gegner-KI, HUD-Logik oder Build-Konfiguration.**
9. **Niemand übernimmt „einfach schnell“ ein fremdes System ohne klare Absprache.**

---

## 🤖 Arbeitsregel für Codex / Claude

Damit KI-Tools keine fremden Bereiche mitverändern, gilt:

### Jeder Prompt muss klar sagen:
- welcher Bereich bearbeitet wird
- welche Dateien geändert werden dürfen
- welche Dateien **nicht** geändert werden dürfen

### Beispiel:
> Arbeite nur am Enemy-/Wave-System.  
> Ändere keine UI-Dateien, keine Player-Dateien, keine Map-Dateien und keine Projektkonfiguration.

### Zusätzlich:
- Keine automatischen Refactorings über mehrere Systeme hinweg
- Keine Umbenennungen fremder Nodes / Signale / Dateien
- Keine Änderung globaler Szenen ohne Tobias
- Vor jedem größeren Prompt prüfen:
  - Gehört diese Aufgabe wirklich zu meinem Bereich?

---

## 🌿 Branch-Empfehlung

Jede Person arbeitet in einem **eigenen Branch**.

Namensschema:
- `chore/repo-integration`
- `chore/web-deploy`
- `feature/enemy-wave-runtime`
- `feature/handbook-content`
- `feature/ui-hud`
- `feature/player-combat-loot`
- `feature/map-layout`
- `feature/environment-assets`
- `feature/character-assets`
- `feature/weather-cycle`
- `docs/readme-project`

**Merge in `main` nur über Tobias.**

---

## 🚀 Ziel

Ein stabiles, spielbares und erweiterbares Zombie-Survival-Spiel mit:

- klarem Gameplay-Loop
- sauber getrennten Verantwortlichkeiten
- möglichst wenig Aufgabenüberschneidungen
- ehrlicher Zuordnung nach sichtbarem Repo-Stand
- besser kontrollierbarer Zusammenarbeit mit Codex / Claude

---

## 🧩 Mögliche Erweiterungen

- Multiplayer (LAN / Online)  
- Skill-System  
- Story / Missionen  
- Boss-Gegner  
- mehrere Maps  

---

## ⚠️ Hinweis

Dieses Projekt wird im Rahmen eines Schulprojekts entwickelt und dient primär Lern- und Demonstrationszwecken.
