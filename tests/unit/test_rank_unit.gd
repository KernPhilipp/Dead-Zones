extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("unit.rank")

	var alpha: Dictionary = ZombieDefinitions.get_rank_data(ZombieDefinitions.Rank.ALPHA)
	var beta: Dictionary = ZombieDefinitions.get_rank_data(ZombieDefinitions.Rank.BETA)
	var gamma: Dictionary = ZombieDefinitions.get_rank_data(ZombieDefinitions.Rank.GAMMA)
	var delta: Dictionary = ZombieDefinitions.get_rank_data(ZombieDefinitions.Rank.DELTA)
	var epsilon: Dictionary = ZombieDefinitions.get_rank_data(ZombieDefinitions.Rank.EPSILON)

	tc.assert_true(int(alpha.get("rank_power", -1)) > int(beta.get("rank_power", -1)), "rank_power_alpha_gt_beta")
	tc.assert_true(int(beta.get("rank_power", -1)) > int(gamma.get("rank_power", -1)), "rank_power_beta_gt_gamma")
	tc.assert_true(int(gamma.get("rank_power", -1)) > int(delta.get("rank_power", -1)), "rank_power_gamma_gt_delta")
	tc.assert_true(int(delta.get("rank_power", -1)) > int(epsilon.get("rank_power", -1)), "rank_power_delta_gt_epsilon")

	tc.assert_true(float(alpha.get("health_mult", 0.0)) > float(beta.get("health_mult", 0.0)), "health_alpha_gt_beta")
	tc.assert_true(float(beta.get("health_mult", 0.0)) > float(gamma.get("health_mult", 0.0)), "health_beta_gt_gamma")
	tc.assert_true(float(gamma.get("health_mult", 0.0)) > float(delta.get("health_mult", 0.0)), "health_gamma_gt_delta")
	tc.assert_true(float(delta.get("health_mult", 0.0)) > float(epsilon.get("health_mult", 0.0)), "health_delta_gt_epsilon")

	tc.assert_true(float(alpha.get("damage_mult", 0.0)) > float(beta.get("damage_mult", 0.0)), "damage_alpha_gt_beta")
	tc.assert_true(float(beta.get("damage_mult", 0.0)) > float(gamma.get("damage_mult", 0.0)), "damage_beta_gt_gamma")

	tc.assert_true(float(alpha.get("speed_mult", 0.0)) < float(beta.get("speed_mult", 0.0)), "speed_alpha_lt_beta")
	tc.assert_true(float(beta.get("speed_mult", 0.0)) < float(gamma.get("speed_mult", 0.0)), "speed_beta_lt_gamma")
	tc.assert_true(float(gamma.get("speed_mult", 0.0)) < float(delta.get("speed_mult", 0.0)), "speed_gamma_lt_delta")
	tc.assert_true(float(delta.get("speed_mult", 0.0)) < float(epsilon.get("speed_mult", 0.0)), "speed_delta_lt_epsilon")

	tc.assert_true(float(alpha.get("spawn_interval_factor", 0.0)) > float(beta.get("spawn_interval_factor", 0.0)), "interval_alpha_gt_beta")
	tc.assert_true(float(beta.get("spawn_interval_factor", 0.0)) > float(gamma.get("spawn_interval_factor", 0.0)), "interval_beta_gt_gamma")

	return tc.to_dict()
