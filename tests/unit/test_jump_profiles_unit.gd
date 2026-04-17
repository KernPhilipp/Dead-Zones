extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("unit.jump_profiles")

	for species_id in ZombieDefinitions.SPECIES_ORDER:
		var profile: Dictionary = ZombieDefinitions.get_species_jump_profile(int(species_id))
		tc.assert_true(profile.has("can_jump"), "jump_profile_has_can_jump:%s" % str(species_id))
		tc.assert_true(profile.has("force_mult"), "jump_profile_has_force:%s" % str(species_id))
		tc.assert_true(profile.has("cooldown_mult"), "jump_profile_has_cooldown:%s" % str(species_id))
		tc.assert_true(float(profile.get("force_mult", 0.0)) >= 0.0, "jump_profile_force_nonnegative:%s" % str(species_id))
		tc.assert_true(float(profile.get("cooldown_mult", 0.0)) > 0.0, "jump_profile_cooldown_positive:%s" % str(species_id))

	var walker_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.WALKER,
		ZombieDefinitions.Rank.DELTA,
		6,
		{}
	)
	var sprinter_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.SPRINTER,
		ZombieDefinitions.Rank.DELTA,
		6,
		{}
	)
	var brute_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.BRUTE,
		ZombieDefinitions.Rank.DELTA,
		6,
		{}
	)
	var buffed_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.BUFFED,
		ZombieDefinitions.Rank.DELTA,
		6,
		{}
	)
	var crawler_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.CRAWLER,
		ZombieDefinitions.Rank.DELTA,
		6,
		{}
	)

	tc.assert_true(float(sprinter_jump.get("force_mult", 0.0)) > float(walker_jump.get("force_mult", 0.0)), "sprinter_jump_gt_walker")
	tc.assert_true(float(brute_jump.get("force_mult", 0.0)) < float(walker_jump.get("force_mult", 0.0)), "brute_jump_lt_walker")
	tc.assert_true(float(buffed_jump.get("force_mult", 0.0)) > float(brute_jump.get("force_mult", 0.0)), "buffed_jump_gt_brute")
	tc.assert_false(bool(crawler_jump.get("can_jump", true)), "crawler_cannot_jump")

	var no_leg_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.WALKER,
		ZombieDefinitions.Rank.DELTA,
		6,
		{"leg_l_missing": true, "leg_r_missing": true}
	)
	var one_leg_jump: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.WALKER,
		ZombieDefinitions.Rank.DELTA,
		6,
		{"leg_l_missing": true, "leg_r_missing": false}
	)
	tc.assert_false(bool(no_leg_jump.get("can_jump", true)), "no_legs_block_jump")
	tc.assert_true(float(one_leg_jump.get("force_mult", 0.0)) < float(walker_jump.get("force_mult", 0.0)), "one_leg_force_reduced")

	var alpha_brute_m10: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.BRUTE,
		ZombieDefinitions.Rank.ALPHA,
		10,
		{}
	)
	var walker_m0: Dictionary = ZombieDefinitions.build_jump_runtime_profile(
		ZombieDefinitions.Species.WALKER,
		ZombieDefinitions.Rank.DELTA,
		0,
		{}
	)
	tc.assert_true(float(alpha_brute_m10.get("force_mult", 0.0)) < float(walker_m0.get("force_mult", 0.0)), "alpha_brute_m10_not_absurd_jump")

	return tc.to_dict()
