extends Node

const DebugDumpBuilder = preload("res://tests/debug/debug_dump_builder.gd")

const UNIT_SUITES: Array[Script] = [
	preload("res://tests/unit/test_definitions_unit.gd"),
	preload("res://tests/unit/test_rank_unit.gd"),
	preload("res://tests/unit/test_mort_unit.gd"),
	preload("res://tests/unit/test_death_unit.gd"),
	preload("res://tests/unit/test_jump_profiles_unit.gd")
]

const SYSTEM_SUITES: Array[Script] = [
	preload("res://tests/system/test_wave_system.gd"),
	preload("res://tests/system/test_layer_system.gd"),
	preload("res://tests/system/test_schedule_system.gd")
]

const INTEGRATION_SUITES: Array[Script] = [
	preload("res://tests/integration/test_spawn_position_integration.gd")
]

const SIMULATION_SUITES: Array[Script] = [
	preload("res://tests/simulation/test_distribution_simulation.gd"),
	preload("res://tests/simulation/test_wave_plan_simulation.gd")
]

func _ready():
	var args: Dictionary = _parse_args(OS.get_cmdline_user_args())
	var groups: Array[String] = args.get("groups", [])
	var seed: int = int(args.get("seed", 1337))

	var report: Dictionary = _run_all(groups, seed)
	_write_report(report)
	_print_summary(report)

	var failed: int = int(report.get("failed", 0))
	get_tree().quit(1 if failed > 0 else 0)

func _run_all(selected_groups: Array[String], seed: int) -> Dictionary:
	var available: Dictionary = {
		"unit": UNIT_SUITES,
		"system": SYSTEM_SUITES,
		"integration": INTEGRATION_SUITES,
		"simulation": SIMULATION_SUITES
	}

	var groups_to_run: Array[String] = []
	if selected_groups.is_empty():
		groups_to_run = ["unit", "system", "integration", "simulation"]
	else:
		for group_name in selected_groups:
			if available.has(group_name):
				groups_to_run.append(group_name)

	if groups_to_run.is_empty():
		groups_to_run = ["unit", "system", "integration", "simulation"]

	var suite_results: Array[Dictionary] = []
	var total: int = 0
	var passed: int = 0
	var failed: int = 0

	for group_name in groups_to_run:
		var suites: Array = available[group_name]
		for suite_script in suites:
			var result: Dictionary = _run_suite(suite_script, seed)
			result["group"] = group_name
			suite_results.append(result)
			total += 1
			if bool(result.get("passed", false)):
				passed += 1
			else:
				failed += 1

	var dump_builder: DebugDumpBuilder = DebugDumpBuilder.new()
	var debug_dump: Dictionary = dump_builder.build_debug_dump(seed)

	return {
		"timestamp_unix": Time.get_unix_time_from_system(),
		"seed": seed,
		"groups": groups_to_run,
		"total": total,
		"passed": passed,
		"failed": failed,
		"suites": suite_results,
		"debug_dump": debug_dump
	}

func _run_suite(suite_script: Script, seed: int) -> Dictionary:
	var suite_instance: Object = suite_script.new()
	if suite_instance == null or not suite_instance.has_method("run"):
		return {
			"name": str(suite_script.resource_path),
			"checks": 0,
			"passed": false,
			"failure_count": 1,
			"failures": ["suite_missing_run_method"],
			"notes": []
		}
	var result: Dictionary = suite_instance.call("run", seed)
	if not result.has("name"):
		result["name"] = str(suite_script.resource_path)
	return result

func _print_summary(report: Dictionary):
	print("=== Dead-Zones Headless Test Summary ===")
	print("Seed: %d" % int(report.get("seed", 0)))
	print("Groups: %s" % str(report.get("groups", [])))
	print("Suites: total=%d passed=%d failed=%d" % [
		int(report.get("total", 0)),
		int(report.get("passed", 0)),
		int(report.get("failed", 0))
	])

	for suite in report.get("suites", []):
		var suite_result: Dictionary = suite
		var status: String = "PASS" if bool(suite_result.get("passed", false)) else "FAIL"
		print("[%s] %s (checks=%d failures=%d)" % [
			status,
			str(suite_result.get("name", "unknown")),
			int(suite_result.get("checks", 0)),
			int(suite_result.get("failure_count", 0))
		])
		if not bool(suite_result.get("passed", false)):
			for failure in suite_result.get("failures", []):
				print("  - %s" % str(failure))

func _write_report(report: Dictionary):
	var report_dir_abs: String = ProjectSettings.globalize_path("res://tests/reports")
	DirAccess.make_dir_recursive_absolute(report_dir_abs)
	var report_file_abs: String = report_dir_abs.path_join("latest_headless_report.json")
	var file: FileAccess = FileAccess.open(report_file_abs, FileAccess.WRITE)
	if file == null:
		push_warning("Headless report could not be written: %s" % report_file_abs)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()

func _parse_args(args: PackedStringArray) -> Dictionary:
	var groups: Array[String] = []
	var seed: int = 1337
	for arg in args:
		if arg.begins_with("--group="):
			var value: String = arg.trim_prefix("--group=").strip_edges().to_lower()
			if not value.is_empty():
				groups.append(value)
		elif arg.begins_with("--groups="):
			var raw: String = arg.trim_prefix("--groups=")
			for chunk in raw.split(",", false):
				var value: String = chunk.strip_edges().to_lower()
				if not value.is_empty():
					groups.append(value)
		elif arg.begins_with("--seed="):
			var raw_seed: String = arg.trim_prefix("--seed=").strip_edges()
			if raw_seed.is_valid_int():
				seed = int(raw_seed)

	return {
		"groups": groups,
		"seed": seed
	}
