extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const SpawnScheduleBuilder = preload("res://scripts/wave/spawn_schedule_builder.gd")

func run(seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("system.schedule")
	var builder: SpawnScheduleBuilder = SpawnScheduleBuilder.new()

	var entries: Array[Dictionary] = []
	var entry_index: int = 0
	for rank_id in [
		ZombieDefinitions.Rank.ALPHA,
		ZombieDefinitions.Rank.BETA,
		ZombieDefinitions.Rank.GAMMA,
		ZombieDefinitions.Rank.DELTA,
		ZombieDefinitions.Rank.EPSILON
	]:
		for _i in range(4):
			entries.append({
				"entry_id": "e_%d" % entry_index,
				"rank_id": rank_id,
				"species_id": ZombieDefinitions.Species.WALKER,
				"class_id": ZombieDefinitions.ZombieClass.COMMON,
				"mort_grade": 6,
				"death_class_id": ZombieDefinitions.DeathClass.VERWESUNG,
				"death_subtype_id": ZombieDefinitions.DeathSubtype.FRISCH_VERSTORBEN,
				"visual_variant": "male",
				"source_layer": "main",
				"planned_earliest_time": 0.0,
				"state": "planned",
				"spawn_attempts": 0
			})
			entry_index += 1

	var rng_a := RandomNumberGenerator.new()
	rng_a.seed = int(seed)
	var scheduled_a: Array[Dictionary] = builder.build_schedule(entries, 12, 1.2, null, rng_a)
	tc.assert_eq(scheduled_a.size(), entries.size(), "scheduled_size_matches")

	var previous_time: float = -INF
	for entry in scheduled_a:
		var t: float = float(entry.get("planned_earliest_time", -1.0))
		tc.assert_true(t > previous_time, "schedule_time_monotonic")
		previous_time = t

	var alpha_indices: Array[int] = _collect_rank_indices(scheduled_a, ZombieDefinitions.Rank.ALPHA)
	tc.assert_true(_min_spacing(alpha_indices) >= 4 or alpha_indices.size() <= 1, "alpha_spacing")

	var beta_gamma_indices: Array[int] = _collect_rank_group_indices(scheduled_a, [ZombieDefinitions.Rank.BETA, ZombieDefinitions.Rank.GAMMA])
	tc.assert_true(_min_spacing(beta_gamma_indices) >= 2 or beta_gamma_indices.size() <= 1, "beta_gamma_spacing")

	var rng_b := RandomNumberGenerator.new()
	rng_b.seed = int(seed)
	var scheduled_b: Array[Dictionary] = builder.build_schedule(entries, 12, 1.2, null, rng_b)
	tc.assert_eq(JSON.stringify(scheduled_a), JSON.stringify(scheduled_b), "schedule_deterministic_same_seed")

	return tc.to_dict()

func _collect_rank_indices(entries: Array[Dictionary], target_rank: int) -> Array[int]:
	var indices: Array[int] = []
	for i in range(entries.size()):
		if int(entries[i].get("rank_id", -1)) == target_rank:
			indices.append(i)
	return indices

func _collect_rank_group_indices(entries: Array[Dictionary], rank_group: Array[int]) -> Array[int]:
	var lookup: Dictionary = {}
	for rank_id in rank_group:
		lookup[int(rank_id)] = true
	var indices: Array[int] = []
	for i in range(entries.size()):
		if lookup.has(int(entries[i].get("rank_id", -1))):
			indices.append(i)
	return indices

func _min_spacing(indices: Array[int]) -> int:
	if indices.size() <= 1:
		return 9999
	var min_delta: int = 9999
	for i in range(1, indices.size()):
		min_delta = mini(min_delta, indices[i] - indices[i - 1])
	return min_delta
