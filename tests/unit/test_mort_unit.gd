extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("unit.mort")

	var probabilities: Dictionary = ZombieDefinitions.get_mort_grade_probability_table(0, 10)
	tc.assert_eq(probabilities.size(), 11, "mort_probability_size")

	var probability_sum: float = 0.0
	var max_grade: int = -1
	var max_prob: float = -1.0
	for grade in range(0, 11):
		var p: float = float(probabilities.get(grade, 0.0))
		probability_sum += p
		if p > max_prob:
			max_prob = p
			max_grade = grade
	tc.assert_near(probability_sum, 1.0, 0.0001, "mort_probability_sum")
	tc.assert_eq(max_grade, 6, "mort_mode_grade_6")

	var raw_6: float = ZombieDefinitions.get_mort_grade_raw_weight(6)
	var raw_5: float = ZombieDefinitions.get_mort_grade_raw_weight(5)
	var raw_4: float = ZombieDefinitions.get_mort_grade_raw_weight(4)
	tc.assert_near(raw_5 / raw_6, 0.5, 0.0001, "mort_raw_half_step_5")
	tc.assert_near(raw_4 / raw_5, 0.5, 0.0001, "mort_raw_half_step_4")

	var mod_0: Dictionary = ZombieDefinitions.get_mort_grade_modifiers(0)
	var mod_6: Dictionary = ZombieDefinitions.get_mort_grade_modifiers(6)
	var mod_10: Dictionary = ZombieDefinitions.get_mort_grade_modifiers(10)
	tc.assert_true(float(mod_0.get("speed_mult", 1.0)) > float(mod_6.get("speed_mult", 1.0)), "mort_speed_0_gt_6")
	tc.assert_true(float(mod_10.get("speed_mult", 1.0)) < float(mod_6.get("speed_mult", 1.0)), "mort_speed_10_lt_6")
	tc.assert_true(float(mod_0.get("damage_mult", 1.0)) > float(mod_6.get("damage_mult", 1.0)), "mort_damage_0_gt_6")
	tc.assert_true(float(mod_10.get("damage_mult", 1.0)) < float(mod_6.get("damage_mult", 1.0)), "mort_damage_10_lt_6")
	tc.assert_true((1.0 - float(mod_10.get("damage_mult", 1.0))) > (float(mod_0.get("damage_mult", 1.0)) - 1.0), "mort_damage_damping_stronger_than_boost")

	return tc.to_dict()
