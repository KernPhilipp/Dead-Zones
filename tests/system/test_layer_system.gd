extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ExtraLayerManager = preload("res://scripts/wave/extra_layer_manager.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("system.layer")
	var manager: ExtraLayerManager = ExtraLayerManager.new()

	var state: Dictionary = {"layers": []}
	state = manager.update_layers(state, [ZombieDefinitions.Rank.EPSILON])
	var layers: Array = state.get("layers", [])
	tc.assert_eq(layers.size(), 1, "layer_insert_first_displaced")
	tc.assert_eq(int((layers[0] as Dictionary).get("rank_id", -1)), ZombieDefinitions.Rank.EPSILON, "layer1_is_epsilon")
	tc.assert_eq(int((layers[0] as Dictionary).get("waves_in_layer", -1)), 0, "layer1_reset_zero")

	state = manager.update_layers(state, [ZombieDefinitions.Rank.EPSILON])
	layers = state.get("layers", [])
	tc.assert_eq(int((layers[0] as Dictionary).get("waves_in_layer", -1)), 1, "layer1_increments_next_wave")

	state = manager.update_layers(state, [ZombieDefinitions.Rank.DELTA, ZombieDefinitions.Rank.EPSILON])
	layers = state.get("layers", [])
	tc.assert_true(layers.size() >= 2, "second_rank_creates_cascade")
	tc.assert_eq(int((layers[0] as Dictionary).get("rank_id", -1)), ZombieDefinitions.Rank.DELTA, "new_displaced_moves_to_layer1")
	tc.assert_eq(int((layers[0] as Dictionary).get("waves_in_layer", -1)), 0, "new_layer1_resets_zero")

	var composed: Dictionary = manager.compose_extra_spawns(state, 20)
	var total_extra: int = int(composed.get("total_extra", 0))
	tc.assert_true(total_extra <= 20, "extra_budget_not_exceeded")
	for allocation in composed.get("allocations", []):
		var alloc: Dictionary = allocation
		tc.assert_true(int(alloc.get("count", 0)) >= 1, "allocation_count_positive")
		tc.assert_true(int(alloc.get("layer_depth", 0)) >= 1, "allocation_layer_depth_positive")

	return tc.to_dict()
