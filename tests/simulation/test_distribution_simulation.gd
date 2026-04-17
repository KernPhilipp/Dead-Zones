extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const MainWaveProgressionModel = preload("res://scripts/wave/main_wave_progression_model.gd")

func run(seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("simulation.distribution")
	var progression: MainWaveProgressionModel = MainWaveProgressionModel.new()
	var rng := RandomNumberGenerator.new()
	rng.seed = int(seed)

	for wave in range(1, 101):
		var dist: Dictionary = progression.build_distribution(wave)
		var sum_prob: float = 0.0
		for value in dist.values():
			var v: float = float(value)
			tc.assert_true(is_finite(v), "distribution_finite_wave_%d" % wave)
			tc.assert_true(v >= 0.0, "distribution_nonnegative_wave_%d" % wave)
			sum_prob += v
		tc.assert_near(sum_prob, 1.0, 0.0001, "distribution_sum_wave_%d" % wave)

		if wave <= 5:
			tc.assert_true(float(dist.get(ZombieDefinitions.Rank.ALPHA, 0.0)) < 0.002, "early_alpha_low_wave_%d" % wave)

	var mort_counts: Dictionary = {}
	for grade in range(0, 11):
		mort_counts[grade] = 0
	for _i in range(1000):
		var rolled: int = ZombieDefinitions.random_mort_grade(rng, 0, 10)
		mort_counts[rolled] = int(mort_counts.get(rolled, 0)) + 1

	var center_count: int = int(mort_counts.get(6, 0))
	tc.assert_true(center_count > int(mort_counts.get(3, 0)), "mort_center_gt_far")
	tc.assert_true(center_count > int(mort_counts.get(10, 0)), "mort_center_gt_extreme")

	return tc.to_dict()
