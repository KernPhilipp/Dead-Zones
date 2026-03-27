extends RefCounted
class_name SpawnBudgetModel

const MAX_TOTAL_MULTIPLIER: int = 2

func build_budget(base_wave_spawn_count: int) -> Dictionary:
	var main_spawn_budget: int = max(1, base_wave_spawn_count)
	var max_total_spawn_budget: int = main_spawn_budget * MAX_TOTAL_MULTIPLIER
	return {
		"main_spawn_budget": main_spawn_budget,
		"max_total_spawn_budget": max_total_spawn_budget,
		"extra_spawn_budget": max_total_spawn_budget - main_spawn_budget
	}
