extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const MainWaveProgressionModel = preload("res://scripts/wave/main_wave_progression_model.gd")
const SpawnBudgetModel = preload("res://scripts/wave/spawn_budget_model.gd")
const ExtraLayerManager = preload("res://scripts/wave/extra_layer_manager.gd")
const WaveComposer = preload("res://scripts/wave/wave_composer.gd")
const SpawnScheduleBuilder = preload("res://scripts/wave/spawn_schedule_builder.gd")

func run(seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("simulation.wave_plan")
	var progression: MainWaveProgressionModel = MainWaveProgressionModel.new()
	var budget_model: SpawnBudgetModel = SpawnBudgetModel.new()
	var layers: ExtraLayerManager = ExtraLayerManager.new()
	var composer: WaveComposer = WaveComposer.new()
	var scheduler: SpawnScheduleBuilder = SpawnScheduleBuilder.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed)

	var layer_state: Dictionary = {"layers": []}
	var base_wave_spawn_count: int = 20
	var near_zero_threshold: float = 0.01

	for wave in range(1, 101):
		var budget: Dictionary = budget_model.build_budget(base_wave_spawn_count)
		var distribution: Dictionary = progression.build_distribution(wave)
		var main_counts: Dictionary = composer.sample_rank_counts(distribution, int(budget["main_spawn_budget"]), rng)
		var displaced: Array[int] = progression.get_displaced_ranks(distribution, near_zero_threshold, wave)
		layer_state = layers.update_layers(layer_state, displaced)
		var extra_result: Dictionary = layers.compose_extra_spawns(layer_state, int(budget["extra_spawn_budget"]))

		var entries: Array[Dictionary] = composer.build_entries(
			wave,
			main_counts,
			extra_result.get("allocations", []),
			true,
			0,
			10,
			rng
		)
		var scheduled: Array[Dictionary] = scheduler.build_schedule(entries, wave, 1.2, null, rng)

		var expected_total_max: int = int(budget["max_total_spawn_budget"])
		tc.assert_true(scheduled.size() <= expected_total_max, "wave_%d_total_budget" % wave)
		tc.assert_true(int(extra_result.get("total_extra", 0)) <= int(budget["extra_spawn_budget"]), "wave_%d_extra_budget" % wave)

		var previous_time: float = -INF
		for entry in scheduled:
			var rank_id: int = int(entry.get("rank_id", -1))
			tc.assert_true(ZombieDefinitions.RANK_DATA.has(rank_id), "wave_%d_rank_valid" % wave)
			tc.assert_true(ZombieDefinitions.SPECIES_DATA.has(int(entry.get("species_id", -1))), "wave_%d_species_valid" % wave)
			tc.assert_true(ZombieDefinitions.CLASS_DATA.has(int(entry.get("class_id", -1))), "wave_%d_class_valid" % wave)
			tc.assert_true(int(entry.get("mort_grade", -1)) >= 0 and int(entry.get("mort_grade", -1)) <= 10, "wave_%d_mort_valid" % wave)
			tc.assert_true(ZombieDefinitions.DEATH_CLASS_DATA.has(int(entry.get("death_class_id", -1))), "wave_%d_death_class_valid" % wave)
			tc.assert_true(ZombieDefinitions.DEATH_SUBTYPE_DATA.has(int(entry.get("death_subtype_id", -1))), "wave_%d_death_subtype_valid" % wave)
			var t: float = float(entry.get("planned_earliest_time", -1.0))
			tc.assert_true(t > previous_time, "wave_%d_schedule_monotonic" % wave)
			previous_time = t

	var a := RandomNumberGenerator.new()
	var b := RandomNumberGenerator.new()
	a.seed = int(seed + 77)
	b.seed = int(seed + 77)
	var wave_ref: int = 25
	var distribution_ref: Dictionary = progression.build_distribution(wave_ref)
	var budget_ref: Dictionary = budget_model.build_budget(base_wave_spawn_count)
	var counts_a: Dictionary = composer.sample_rank_counts(distribution_ref, int(budget_ref["main_spawn_budget"]), a)
	var counts_b: Dictionary = composer.sample_rank_counts(distribution_ref, int(budget_ref["main_spawn_budget"]), b)
	tc.assert_eq(JSON.stringify(counts_a), JSON.stringify(counts_b), "deterministic_counts_same_seed")

	return tc.to_dict()
