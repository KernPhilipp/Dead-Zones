extends RefCounted
class_name ExtraLayerManager

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

func update_layers(previous_state: Dictionary, displaced_ranks: Array[int]) -> Dictionary:
	var previous_layers: Array = previous_state.get("layers", [])
	var displaced_lookup: Dictionary = {}
	for rank_id in displaced_ranks:
		displaced_lookup[rank_id] = true

	var next_layers: Array[Dictionary] = []
	for layer_entry in previous_layers:
		var rank_id: int = int(layer_entry.get("rank_id", ZombieDefinitions.Rank.EPSILON))
		if not displaced_lookup.has(rank_id):
			continue
		next_layers.append({
			"rank_id": rank_id,
			"waves_in_layer": max(0, int(layer_entry.get("waves_in_layer", 0)))
		})

	var existing_lookup: Dictionary = {}
	for layer_entry in next_layers:
		existing_lookup[int(layer_entry["rank_id"])] = true

	var new_displaced: Array[int] = []
	for rank_id in displaced_ranks:
		if not existing_lookup.has(rank_id):
			new_displaced.append(rank_id)

	new_displaced.sort_custom(func(a: int, b: int) -> bool:
		return ZombieDefinitions.get_rank_power(a) > ZombieDefinitions.get_rank_power(b)
	)

	for rank_id in new_displaced:
		next_layers.insert(0, {
			"rank_id": rank_id,
			"waves_in_layer": 0
		})

	var inserted_lookup: Dictionary = {}
	for rank_id in new_displaced:
		inserted_lookup[rank_id] = true

	for layer_entry in next_layers:
		var rank_id: int = int(layer_entry["rank_id"])
		if inserted_lookup.has(rank_id):
			continue
		layer_entry["waves_in_layer"] = int(layer_entry["waves_in_layer"]) + 1

	return {"layers": next_layers}

func compose_extra_spawns(layer_state: Dictionary, extra_budget: int) -> Dictionary:
	var budget: int = max(0, extra_budget)
	var layers: Array = layer_state.get("layers", [])
	if budget <= 0 or layers.is_empty():
		return {
			"total_extra": 0,
			"allocations": [],
			"activation": 0.0,
			"target_extra_budget": 0
		}

	var weighted_layers: Array[Dictionary] = []
	var total_effective: float = 0.0
	for index in range(layers.size()):
		var layer_depth: int = index + 1
		var layer_entry: Dictionary = layers[index]
		var rank_id: int = int(layer_entry.get("rank_id", ZombieDefinitions.Rank.EPSILON))
		var waves_in_layer: int = max(0, int(layer_entry.get("waves_in_layer", 0)))
		var intensity: float = _compute_layer_intensity(waves_in_layer, layer_depth)
		var layer_weight: float = _compute_layer_weight(layer_depth)
		var effective: float = intensity * layer_weight
		if effective <= 0.0:
			continue
		weighted_layers.append({
			"rank_id": rank_id,
			"layer_depth": layer_depth,
			"waves_in_layer": waves_in_layer,
			"intensity": intensity,
			"layer_weight": layer_weight,
			"effective": effective
		})
		total_effective += effective

	if weighted_layers.is_empty() or total_effective <= 0.0:
		return {
			"total_extra": 0,
			"allocations": [],
			"activation": 0.0,
			"target_extra_budget": 0
		}

	var activation: float = clampf(total_effective / maxf(1.0, float(weighted_layers.size())), 0.0, 1.0)
	var target_extra_budget: int = int(floor(float(budget) * activation))
	if target_extra_budget <= 0 and activation >= 0.15:
		target_extra_budget = 1
	target_extra_budget = clampi(target_extra_budget, 0, budget)

	if target_extra_budget <= 0:
		return {
			"total_extra": 0,
			"allocations": [],
			"activation": activation,
			"target_extra_budget": 0
		}

	var preliminary_allocations: Array[Dictionary] = []
	var fractions: Array[Dictionary] = []
	var allocated_total: int = 0
	for weighted_entry in weighted_layers:
		var exact_share: float = float(weighted_entry["effective"]) / total_effective * float(target_extra_budget)
		var base_count: int = int(floor(exact_share))
		allocated_total += base_count
		var allocation: Dictionary = weighted_entry.duplicate(true)
		allocation["count"] = base_count
		preliminary_allocations.append(allocation)
		fractions.append({
			"index": preliminary_allocations.size() - 1,
			"fraction": exact_share - float(base_count)
		})

	fractions.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return float(a["fraction"]) > float(b["fraction"])
	)

	var remaining: int = target_extra_budget - allocated_total
	for idx in range(remaining):
		if idx >= fractions.size():
			break
		var target_index: int = int(fractions[idx]["index"])
		var allocation: Dictionary = preliminary_allocations[target_index]
		allocation["count"] = int(allocation["count"]) + 1
		preliminary_allocations[target_index] = allocation

	var final_allocations: Array[Dictionary] = []
	var total_extra: int = 0
	for allocation in preliminary_allocations:
		var count: int = int(allocation.get("count", 0))
		if count <= 0:
			continue
		total_extra += count
		final_allocations.append({
			"rank_id": int(allocation["rank_id"]),
			"layer_depth": int(allocation["layer_depth"]),
			"waves_in_layer": int(allocation["waves_in_layer"]),
			"intensity": float(allocation["intensity"]),
			"layer_weight": float(allocation["layer_weight"]),
			"count": count
		})

	return {
		"total_extra": total_extra,
		"allocations": final_allocations,
		"activation": activation,
		"target_extra_budget": target_extra_budget
	}

func _compute_layer_intensity(waves_in_layer: int, layer_depth: int) -> float:
	if waves_in_layer <= 0:
		return 0.0
	var denominator: float = 3.0 + 0.8 * float(layer_depth)
	return 1.0 - exp(-float(waves_in_layer) / denominator)

func _compute_layer_weight(layer_depth: int) -> float:
	return minf(1.0, 0.22 + 0.18 * float(layer_depth))
