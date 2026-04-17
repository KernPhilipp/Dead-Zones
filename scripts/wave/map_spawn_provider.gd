extends RefCounted
class_name MapSpawnProvider

var spawn_points: Array[Node3D] = []

func refresh_from_scene(context_node: Node):
	spawn_points.clear()
	if context_node == null:
		return

	var tree: SceneTree = context_node.get_tree()
	if tree == null:
		return

	var current_scene: Node = tree.current_scene
	if current_scene != null:
		_collect_marker_children(current_scene.find_child("ZombieSpawns", true, false))
		_collect_marker_children(current_scene.find_child("SpawnPoints", true, false))

	if context_node.has_node("../SpawnPoints"):
		_collect_marker_children(context_node.get_node("../SpawnPoints"))

	for group_node in tree.get_nodes_in_group("map_spawn_point"):
		var spawn_point: Node3D = group_node as Node3D
		if spawn_point == null:
			continue
		if spawn_points.has(spawn_point):
			continue
		spawn_points.append(spawn_point)

func _collect_marker_children(spawn_root: Node):
	if spawn_root == null:
		return
	for child in spawn_root.get_children():
		var spawn_point: Node3D = child as Node3D
		if spawn_point == null:
			continue
		if spawn_points.has(spawn_point):
			continue
		spawn_points.append(spawn_point)

func get_point_count() -> int:
	return spawn_points.size()

func pick_random_position(rng: RandomNumberGenerator) -> Dictionary:
	var valid_points: Array[Node3D] = []
	for spawn_point in spawn_points:
		if is_instance_valid(spawn_point):
			valid_points.append(spawn_point)
	spawn_points = valid_points

	if spawn_points.is_empty():
		return {
			"valid": false,
			"position": Vector3.ZERO,
			"point_name": ""
		}

	var index: int = rng.randi_range(0, spawn_points.size() - 1)
	var selected: Node3D = spawn_points[index]
	return {
		"valid": true,
		"position": selected.global_position,
		"point_name": selected.name
	}
