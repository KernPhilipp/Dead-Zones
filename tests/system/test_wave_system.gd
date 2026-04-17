extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const MainWaveProgressionModel = preload("res://scripts/wave/main_wave_progression_model.gd")
const SpawnBudgetModel = preload("res://scripts/wave/spawn_budget_model.gd")
const WaveComposer = preload("res://scripts/wave/wave_composer.gd")

func run(seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("system.wave")
	var progression: MainWaveProgressionModel = MainWaveProgressionModel.new()
	var budget_model: SpawnBudgetModel = SpawnBudgetModel.new()
	var composer: WaveComposer = WaveComposer.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed)

	var wave1: Dictionary = progression.build_distribution(1)
	var wave5: Dictionary = progression.build_distribution(5)
	var wave15: Dictionary = progression.build_distribution(15)
	var wave40: Dictionary = progression.build_distribution(40)

	tc.assert_true(float(wave1.get(ZombieDefinitions.Rank.ALPHA, 1.0)) < 0.001, "wave1_alpha_practically_zero")
	tc.assert_true(float(wave1.get(ZombieDefinitions.Rank.EPSILON, 0.0)) > 0.8, "wave1_epsilon_dominant")
	tc.assert_true(float(wave5.get(ZombieDefinitions.Rank.DELTA, 0.0)) > float(wave1.get(ZombieDefinitions.Rank.DELTA, 0.0)), "wave5_delta_gt_wave1")
	tc.assert_true(float(wave15.get(ZombieDefinitions.Rank.DELTA, 0.0)) > float(wave15.get(ZombieDefinitions.Rank.EPSILON, 1.0)), "wave15_delta_gt_epsilon")
	tc.assert_true(float(wave40.get(ZombieDefinitions.Rank.ALPHA, 0.0)) > float(wave5.get(ZombieDefinitions.Rank.ALPHA, 0.0)), "alpha_rises_late")

	for wave in [wave1, wave5, wave15, wave40]:
		var sum_prob: float = 0.0
		for value in wave.values():
			sum_prob += float(value)
		tc.assert_near(sum_prob, 1.0, 0.0001, "distribution_normalized")

	var budget: Dictionary = budget_model.build_budget(20)
	tc.assert_eq(int(budget.get("main_spawn_budget", -1)), 20, "budget_main")
	tc.assert_eq(int(budget.get("max_total_spawn_budget", -1)), 40, "budget_max_total")
	tc.assert_eq(int(budget.get("extra_spawn_budget", -1)), 20, "budget_extra")

	var counts: Dictionary = composer.sample_rank_counts(wave15, 20, rng)
	var sampled_total: int = 0
	for value in counts.values():
		sampled_total += int(value)
	tc.assert_eq(sampled_total, 20, "sampled_total_matches_requested")

	return tc.to_dict()
