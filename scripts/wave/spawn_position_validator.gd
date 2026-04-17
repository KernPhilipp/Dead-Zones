extends RefCounted
class_name SpawnPositionValidator

func find_valid_position(
	map_spawn_provider: RefCounted,
	player_node: Node3D,
	min_spawn_distance_from_player: float,
	retry_limit: int,
	rng: RandomNumberGenerator
) -> Dictionary:
	if map_spawn_provider == null or not map_spawn_provider.has_method("pick_random_position"):
		return _invalid_result(0)

	var tries: int = max(1, retry_limit)
	for attempt in range(tries):
		var sampled: Dictionary = map_spawn_provider.call("pick_random_position", rng)
		if not bool(sampled.get("valid", false)):
			return _invalid_result(attempt + 1)

		var position: Vector3 = sampled.get("position", Vector3.ZERO)
		if _is_distance_valid(position, player_node, min_spawn_distance_from_player):
			return {
				"valid": true,
				"position": position,
				"attempts": attempt + 1,
				"point_name": String(sampled.get("point_name", ""))
			}

	return _invalid_result(tries)

func _is_distance_valid(position: Vector3, player_node: Node3D, min_spawn_distance_from_player: float) -> bool:
	if player_node == null or not is_instance_valid(player_node):
		return true
	var min_distance: float = maxf(0.0, min_spawn_distance_from_player)
	var player_position: Vector3 = player_node.global_position if player_node.is_inside_tree() else player_node.position
	return position.distance_to(player_position) >= min_distance

func _invalid_result(attempts: int) -> Dictionary:
	return {
		"valid": false,
		"position": Vector3.ZERO,
		"attempts": attempts,
		"point_name": ""
	}
