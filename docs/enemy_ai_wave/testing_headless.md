# Headless Test- und Debug-Struktur

## Ziel

Diese Suite sichert die Kernregeln von Zombie-KI, Rang/Mort/Death-Layern und Wellenruntime reproduzierbar ab.
Alle Tests sind seed-basiert und fuer Headless-Ausfuehrung ausgelegt.

## Struktur

- `tests/core/`
  - `test_case.gd`: gemeinsame Assertions + Ergebnisformat.
- `tests/unit/`
  - Daten-/Definitionsvalidierung
  - Rangregeln
  - Mort-Grad-Verteilung und Modifikatoren
  - Todesarten-/Visualdaten
  - Jump-Profile (Species/Rank/Mort/Legs)
- `tests/system/`
  - Hauptwellenverteilung + Spawnbudget
  - Ebenensystem + Extra-Budget
  - SpawnSchedule (Spacing, Determinismus)
- `tests/integration/`
  - SpawnPositionValidator mit Retry-/Distanzlogik.
- `tests/simulation/`
  - Langlaeufe ueber Verteilungen/Wellenplaene.
- `tests/debug/`
  - `debug_dump_builder.gd`: Mort-/Rank-/Jump-Dumps fuer Diagnose.

## Headless Runner

- Szene: `res://tests/headless_test_runner.tscn`
- Script: `res://tests/run_headless_tests.gd`
- Ausgabe:
  - Konsole mit Suite-Status
  - JSON-Report unter `tests/reports/latest_headless_report.json`

## Starten

Beispiel (alle Gruppen, Seed 1337):

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --seed=1337
```

Oder ueber den Wrapper:

```powershell
powershell -ExecutionPolicy Bypass -File tests/run_headless_tests.ps1 -GodotExe "D:\...\Godot_v4.6.1-stable_mono_win64.exe" -Seed 1337
```

Nur Unit-Tests:

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --group=unit --seed=1337
```

Mehrere Gruppen:

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --groups=unit,system,simulation --seed=2026
```

## Abgesicherte Invarianten (Auszug)

- Rang-Hierarchie bleibt `Alpha > Beta > Gamma > Delta > Epsilon`.
- Hohe Ränge sind staerker, aber langsamer.
- Mort-Grad-Verteilung bleibt normalisiert mit Peak bei Grad 6.
- Mort-Daempfung bei hohen Graden ist staerker als Boost bei niedrigen.
- `MaxTotalSpawnCount = BaseWaveSpawnCount * 2`.
- Extra-Layer respektieren Extra-Budget.
- SpawnSchedule ist zeitlich monoton und seed-deterministisch.
- Jump-Regeln bleiben konsistent:
  - Crawler springt nicht normal,
  - no legs => kein Jump,
  - Sprinter > Walker > Brute bei Jump-Force.

## Diagnose

Bei Fehlern geben die Suiten konkrete Schluesselwerte aus (Welle, Rang, Seed, Regelname).
Fuer tiefere Analyse kann der JSON-Report direkt diffbar in Regression-Checks verwendet werden.
