extends RefCounted
class_name MapSpawnProvider

const REGION_EDGE_MARGIN := 2.5
const FLOOR_SPAWN_HEIGHT_OFFSET := 1.0
const REGION_SAMPLE_RETRIES := 16

var spawn_points: Array[Node3D] = []
var spawn_regions: Array[Dictionary] = []
var scene_root: Node3D = null

func refresh_from_scene(context_node: Node):
	spawn_points.clear()
	spawn_regions.clear()
	scene_root = null
	if context_node == null:
		return

	var tree: SceneTree = context_node.get_tree()
	if tree == null:
		return
	if tree.current_scene is Node3D:
		scene_root = tree.current_scene as Node3D

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

	_collect_spawn_regions(context_node, tree)

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
	return spawn_points.size() + spawn_regions.size()

func pick_random_position(rng: RandomNumberGenerator) -> Dictionary:
	var valid_points: Array[Node3D] = []
	for spawn_point in spawn_points:
		if is_instance_valid(spawn_point):
			valid_points.append(spawn_point)
	spawn_points = valid_points

	var has_points: bool = not spawn_points.is_empty()
	var has_regions: bool = not spawn_regions.is_empty()
	if not has_points and not has_regions:
		return {
			"valid": false,
			"position": Vector3.ZERO,
			"point_name": ""
		}

	var try_regions_first: bool = has_regions and (not has_points or rng.randf() < 0.82)
	if try_regions_first:
		var region_sample: Dictionary = _sample_region_position(rng)
		if bool(region_sample.get("valid", false)):
			return region_sample

	if has_points:
		var index: int = rng.randi_range(0, spawn_points.size() - 1)
		var selected: Node3D = spawn_points[index]
		return {
			"valid": true,
			"position": selected.global_position,
			"point_name": selected.name
		}

	return _sample_region_position(rng)

func _collect_spawn_regions(context_node: Node, tree: SceneTree):
	if context_node.has_node("../Map/Floor"):
		var floor_node: Node = context_node.get_node("../Map/Floor")
		if floor_node is CSGBox3D:
			_append_region_from_floor_box(floor_node as CSGBox3D, "map_floor")

	for region_node in tree.get_nodes_in_group("map_spawn_region"):
		if region_node is CSGBox3D:
			_append_region_from_floor_box(region_node as CSGBox3D, String(region_node.name))

func _append_region_from_floor_box(floor_box: CSGBox3D, region_name: String):
	if floor_box == null or not is_instance_valid(floor_box):
		return

	var half_x: float = float(floor_box.size.x) * 0.5
	var half_z: float = float(floor_box.size.z) * 0.5
	var margin_x: float = minf(REGION_EDGE_MARGIN, maxf(0.0, half_x - 0.5))
	var margin_z: float = minf(REGION_EDGE_MARGIN, maxf(0.0, half_z - 0.5))
	var min_x: float = floor_box.global_position.x - half_x + margin_x
	var max_x: float = floor_box.global_position.x + half_x - margin_x
	var min_z: float = floor_box.global_position.z - half_z + margin_z
	var max_z: float = floor_box.global_position.z + half_z - margin_z

	if min_x >= max_x or min_z >= max_z:
		return

	var floor_top_y: float = floor_box.global_position.y + float(floor_box.size.y) * 0.5
	spawn_regions.append({
		"id": region_name,
		"min_x": min_x,
		"max_x": max_x,
		"min_z": min_z,
		"max_z": max_z,
		"floor_top_y": floor_top_y
	})

func _sample_region_position(rng: RandomNumberGenerator) -> Dictionary:
	if spawn_regions.is_empty():
		return {"valid": false, "position": Vector3.ZERO, "point_name": ""}

	for _attempt in range(REGION_SAMPLE_RETRIES):
		var region: Dictionary = spawn_regions[rng.randi_range(0, spawn_regions.size() - 1)]
		var x: float = rng.randf_range(float(region["min_x"]), float(region["max_x"]))
		var z: float = rng.randf_range(float(region["min_z"]), float(region["max_z"]))
		var probe_position: Vector3 = Vector3(x, float(region["floor_top_y"]) + 2.2, z)
		var resolved: Dictionary = _resolve_floor_spawn_position(probe_position)
		if not bool(resolved.get("valid", false)):
			continue
		return {
			"valid": true,
			"position": resolved.get("position", Vector3(x, float(region["floor_top_y"]) + FLOOR_SPAWN_HEIGHT_OFFSET, z)),
			"point_name": "region:%s" % String(region.get("id", "map"))
		}

	var fallback_region: Dictionary = spawn_regions[0]
	return {
		"valid": true,
		"position": Vector3(
			lerpf(float(fallback_region["min_x"]), float(fallback_region["max_x"]), 0.5),
			float(fallback_region["floor_top_y"]) + FLOOR_SPAWN_HEIGHT_OFFSET,
			lerpf(float(fallback_region["min_z"]), float(fallback_region["max_z"]), 0.5)
		),
		"point_name": "region:%s:fallback" % String(fallback_region.get("id", "map"))
	}

func _resolve_floor_spawn_position(probe_position: Vector3) -> Dictionary:
	if scene_root == null or not is_instance_valid(scene_root) or scene_root.get_world_3d() == null:
		return {"valid": true, "position": probe_position + Vector3.UP * FLOOR_SPAWN_HEIGHT_OFFSET}

	var space_state: PhysicsDirectSpaceState3D = scene_root.get_world_3d().direct_space_state
	var floor_query := PhysicsRayQueryParameters3D.create(
		probe_position,
		probe_position + Vector3.DOWN * 6.0
	)
	floor_query.collide_with_areas = false
	floor_query.collide_with_bodies = true
	var floor_hit: Dictionary = space_state.intersect_ray(floor_query)
	if floor_hit.is_empty():
		return {"valid": false}

	var floor_normal: Vector3 = floor_hit.get("normal", Vector3.UP)
	if floor_normal.y < 0.55:
		return {"valid": false}

	var floor_position: Vector3 = floor_hit.get("position", probe_position + Vector3.DOWN * 2.0)
	var spawn_origin: Vector3 = floor_position + Vector3.UP * FLOOR_SPAWN_HEIGHT_OFFSET

	var head_query := PhysicsRayQueryParameters3D.create(
		spawn_origin + Vector3.UP * 0.2,
		spawn_origin + Vector3.UP * 1.85
	)
	head_query.collide_with_areas = false
	head_query.collide_with_bodies = true
	var blocker: Dictionary = space_state.intersect_ray(head_query)
	if not blocker.is_empty():
		return {"valid": false}

	return {"valid": true, "position": spawn_origin}
