extends RefCounted
class_name WaveComposer

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func sample_rank_counts(distribution: Dictionary, sample_count: int, rng: RandomNumberGenerator) -> Dictionary:
	var target_count: int = max(0, sample_count)
	var counts: Dictionary = {}
	for rank_id in distribution.keys():
		counts[int(rank_id)] = 0

	for _index in range(target_count):
		var sampled_rank: int = _pick_weighted_rank(distribution, rng)
		counts[sampled_rank] = int(counts.get(sampled_rank, 0)) + 1
	return counts

func build_entries(
	wave_index: int,
	main_rank_counts: Dictionary,
	extra_allocations: Array,
	allow_female_variants: bool,
	mort_grade_min: int,
	mort_grade_max: int,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var entry_counter: int = 0

	var sorted_main_ranks: Array[int] = []
	for rank_id in main_rank_counts.keys():
		sorted_main_ranks.append(int(rank_id))
	sorted_main_ranks.sort_custom(func(a: int, b: int) -> bool:
		return ZombieDefinitions.get_rank_power(a) > ZombieDefinitions.get_rank_power(b)
	)

	for rank_id in sorted_main_ranks:
		var count: int = int(main_rank_counts.get(rank_id, 0))
		for _count_index in range(count):
			entries.append(_build_entry(
				wave_index,
				entry_counter,
				rank_id,
				"main",
				allow_female_variants,
				mort_grade_min,
				mort_grade_max,
				rng
			))
			entry_counter += 1

	for allocation in extra_allocations:
		var rank_id: int = int(allocation.get("rank_id", ZombieDefinitions.Rank.EPSILON))
		var layer_depth: int = max(1, int(allocation.get("layer_depth", 1)))
		var count: int = max(0, int(allocation.get("count", 0)))
		var source_layer: String = "extra_l%d" % layer_depth
		for _count_index in range(count):
			entries.append(_build_entry(
				wave_index,
				entry_counter,
				rank_id,
				source_layer,
				allow_female_variants,
				mort_grade_min,
				mort_grade_max,
				rng
			))
			entry_counter += 1

	return entries

func _build_entry(
	wave_index: int,
	entry_counter: int,
	rank_id: int,
	source_layer: String,
	allow_female_variants: bool,
	mort_grade_min: int,
	mort_grade_max: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	var species_id: int = ZombieDefinitions.random_species_id(rng)
	var class_id: int = ZombieDefinitions.random_class_id(rng)
	var mort_grade: int = ZombieDefinitions.random_mort_grade(rng, mort_grade_min, mort_grade_max)
	var death_subtype_id: int = ZombieDefinitions.random_death_subtype_id(rng)
	var death_class_id: int = int(ZombieDefinitions.get_death_subtype_data(death_subtype_id)["death_class"])
	var visual_variant: String = ZombieDefinitions.resolve_visual_variant(species_id, allow_female_variants, rng)

	return {
		"entry_id": "wave_%02d_entry_%03d" % [wave_index, entry_counter],
		"rank_id": rank_id,
		"species_id": species_id,
		"class_id": class_id,
		"mort_grade": mort_grade,
		"death_class_id": death_class_id,
		"death_subtype_id": death_subtype_id,
		"visual_variant": visual_variant,
		"source_layer": source_layer,
		"planned_earliest_time": 0.0,
		"state": "planned",
		"spawn_attempts": 0
	}

func _pick_weighted_rank(distribution: Dictionary, rng: RandomNumberGenerator) -> int:
	var ranks: Array[int] = []
	var total_weight: float = 0.0
	for rank_id in distribution.keys():
		var rank_int: int = int(rank_id)
		var weight: float = maxf(0.0, float(distribution[rank_id]))
		if weight <= 0.0:
			continue
		ranks.append(rank_int)
		total_weight += weight

	if ranks.is_empty() or total_weight <= 0.0:
		return ZombieDefinitions.DEFAULT_RANK

	ranks.sort_custom(func(a: int, b: int) -> bool:
		return ZombieDefinitions.get_rank_power(a) > ZombieDefinitions.get_rank_power(b)
	)

	var roll: float = rng.randf() * total_weight
	var cumulative: float = 0.0
	for rank_id in ranks:
		cumulative += maxf(0.0, float(distribution.get(rank_id, 0.0)))
		if roll <= cumulative:
			return rank_id
	return ranks[ranks.size() - 1]
