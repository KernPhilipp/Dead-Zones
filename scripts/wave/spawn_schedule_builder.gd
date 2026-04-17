extends RefCounted
class_name SpawnScheduleBuilder

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func build_schedule(
	entries: Array[Dictionary],
	wave_index: int,
	base_spawn_interval_seconds: float,
	wave_modifier: RefCounted,
	rng: RandomNumberGenerator
) -> Array[Dictionary]:
	if entries.is_empty():
		return []

	var scheduled: Array[Dictionary] = entries.duplicate(true)
	_shuffle_entries(scheduled, rng)
	var protected_group_ranks := {
		ZombieDefinitions.Rank.BETA: true,
		ZombieDefinitions.Rank.GAMMA: true
	}
	_enforce_single_rank_spacing(scheduled, ZombieDefinitions.Rank.ALPHA, 4, protected_group_ranks)
	_enforce_rank_group_spacing(
		scheduled,
		[ZombieDefinitions.Rank.BETA, ZombieDefinitions.Rank.GAMMA],
		2
	)
	_enforce_single_rank_spacing(scheduled, ZombieDefinitions.Rank.ALPHA, 4, protected_group_ranks)

	var base_interval: float = maxf(0.08, base_spawn_interval_seconds)
	var current_time: float = 0.0
	for index in range(scheduled.size()):
		var entry: Dictionary = scheduled[index]
		var rank_id: int = int(entry.get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		var source_layer: String = String(entry.get("source_layer", "main"))
		var rank_interval_factor: float = ZombieDefinitions.get_rank_spawn_interval_factor(rank_id)
		var source_layer_factor: float = 1.05 if source_layer.begins_with("extra_") else 1.0
		var wave_factor: float = 1.0
		if wave_modifier != null and wave_modifier.has_method("get_spawn_interval_multiplier"):
			wave_factor = maxf(
				0.1,
				float(wave_modifier.call("get_spawn_interval_multiplier", source_layer, rank_id, wave_index))
			)

		var interval: float = base_interval * rank_interval_factor * source_layer_factor * wave_factor
		var jitter: float = 1.0 + rng.randf_range(-0.08, 0.08)
		current_time += maxf(0.08, interval * jitter)

		entry["planned_earliest_time"] = current_time
		entry["state"] = "planned"
		scheduled[index] = entry

	return scheduled

func _shuffle_entries(entries: Array[Dictionary], rng: RandomNumberGenerator):
	for index in range(entries.size() - 1, 0, -1):
		var swap_index: int = rng.randi_range(0, index)
		if swap_index == index:
			continue
		var current: Dictionary = entries[index]
		entries[index] = entries[swap_index]
		entries[swap_index] = current

func _enforce_single_rank_spacing(
	entries: Array[Dictionary],
	target_rank: int,
	min_index_distance: int,
	avoid_swap_ranks: Dictionary = {}
):
	var last_seen_index: int = -9999
	for index in range(entries.size()):
		var rank_id: int = int(entries[index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if rank_id != target_rank:
			continue

		if index - last_seen_index < min_index_distance:
			var swap_index: int = _find_non_target_swap_index(entries, index, target_rank, avoid_swap_ranks)
			if swap_index != -1:
				var current: Dictionary = entries[index]
				entries[index] = entries[swap_index]
				entries[swap_index] = current
				rank_id = int(entries[index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if rank_id == target_rank:
			last_seen_index = index

func _enforce_rank_group_spacing(entries: Array[Dictionary], rank_group: Array[int], min_index_distance: int):
	var group_lookup: Dictionary = {}
	for rank_id in rank_group:
		group_lookup[rank_id] = true

	var last_seen_index: int = -9999
	for index in range(entries.size()):
		var rank_id: int = int(entries[index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if not group_lookup.has(rank_id):
			continue

		if index - last_seen_index < min_index_distance:
			var swap_index: int = _find_non_group_swap_index(entries, index, group_lookup)
			if swap_index != -1:
				var current: Dictionary = entries[index]
				entries[index] = entries[swap_index]
				entries[swap_index] = current
				rank_id = int(entries[index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if group_lookup.has(rank_id):
			last_seen_index = index

func _find_non_target_swap_index(
	entries: Array[Dictionary],
	from_index: int,
	target_rank: int,
	avoid_swap_ranks: Dictionary = {}
) -> int:
	var fallback_index: int = -1
	for candidate_index in range(from_index + 1, entries.size()):
		var candidate_rank: int = int(entries[candidate_index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if candidate_rank == target_rank:
			continue
		if avoid_swap_ranks.is_empty() or not avoid_swap_ranks.has(candidate_rank):
			return candidate_index
		if fallback_index == -1:
			fallback_index = candidate_index
	return fallback_index

func _find_non_group_swap_index(entries: Array[Dictionary], from_index: int, rank_group_lookup: Dictionary) -> int:
	for candidate_index in range(from_index + 1, entries.size()):
		var candidate_rank: int = int(entries[candidate_index].get("rank_id", ZombieDefinitions.DEFAULT_RANK))
		if not rank_group_lookup.has(candidate_rank):
			return candidate_index
	return -1
