extends RefCounted
class_name SpecialWaveModifierInterface

# Default no-op modifier. Future special wave types can override these methods.
func get_rank_weight_multiplier(_rank_id: int, _wave_index: int) -> float:
	return 1.0

func get_spawn_interval_multiplier(_source_layer: String, _rank_id: int, _wave_index: int) -> float:
	return 1.0

func get_extra_budget_multiplier(_wave_index: int) -> float:
	return 1.0
