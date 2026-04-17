# Headless Tests

## Einstieg

- Runner-Szene: `res://tests/headless_test_runner.tscn`
- Runner-Skript: `res://tests/run_headless_tests.gd`
- JSON-Report: `res://tests/reports/latest_headless_report.json`
- PowerShell-Wrapper: `tests/run_headless_tests.ps1`

## Gruppen

- `unit`
- `system`
- `integration`
- `simulation`

## Beispiele

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --seed=1337
```

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --group=unit --seed=1337
```

```powershell
Godot_v4.6.1-stable_mono_win64.exe --headless --scene res://tests/headless_test_runner.tscn -- --groups=unit,system,simulation --seed=2026
```
