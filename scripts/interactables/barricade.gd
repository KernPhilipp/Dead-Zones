extends StaticBody3D

@export_range(1, 200, 1) var segment_max_health: int = 45
@export_range(1, 200, 1) var repair_reward: int = 40
@export var display_name: String = "Barricade"

var _segment_healths: Array[int] = []
var _segment_materials: Array[StandardMaterial3D] = []
var _base_color: Color = Color(0.56, 0.39, 0.2, 1.0)
var _emission_color: Color = Color(0.18, 0.08, 0.03, 1.0)

@onready var visual_root: Node3D = $VisualRoot
@onready var label_3d: Label3D = $VisualRoot/Label3D
@onready var segment_meshes: Array[MeshInstance3D] = [
	$VisualRoot/BoardBottom,
	$VisualRoot/BoardMid,
	$VisualRoot/BoardTop,
]
@onready var segment_shapes: Array[CollisionShape3D] = [
	$SegmentShapeBottom,
	$SegmentShapeMid,
	$SegmentShapeTop,
]

func _ready() -> void:
	_initialize_segments()
	_update_all_segments()
	_update_label()
	set_highlighted(false)

func interact(player: Node) -> bool:
	if player == null or not is_instance_valid(player):
		return false
	var repaired_index: int = _repair_next_segment()
	if repaired_index == -1:
		if player.has_method("show_runtime_status"):
			player.call("show_runtime_status", "BARRICADE FULL", "warning")
		return false
	if player.has_method("reward_points"):
		player.call("reward_points", repair_reward, "+%d PTS REPAIR" % repair_reward)
	if player.has_method("show_runtime_status"):
		player.call("show_runtime_status", "BARRICADE REPAIRED", "positive")
	return true

func get_interaction_prompt() -> String:
	if _get_destroyed_segment_count() <= 0:
		return "PRESS E: %s READY" % display_name
	return "PRESS E: REPAIR %s [+%d]" % [display_name, repair_reward]

func take_zombie_damage(amount: int) -> bool:
	var target_index: int = _get_damage_target_index()
	if target_index == -1:
		return false
	_segment_healths[target_index] = max(0, _segment_healths[target_index] - maxi(amount, 1))
	_update_segment_state(target_index)
	_update_label()
	return true

func blocks_zombies() -> bool:
	return _get_intact_segment_count() > 0

func set_highlighted(active: bool) -> void:
	var label_alpha: float = 1.0 if active else 0.7
	visual_root.scale = Vector3.ONE * (1.04 if active else 1.0)
	label_3d.modulate = Color(1.0, 1.0, 1.0, label_alpha)
	for index in range(segment_meshes.size()):
		var material: StandardMaterial3D = _segment_materials[index]
		if material == null:
			continue
		material.emission_energy_multiplier = 2.0 if active and _segment_healths[index] > 0 else 0.9
		material.albedo_color = _base_color.lightened(0.08 if active and _segment_healths[index] > 0 else 0.0)

func _initialize_segments() -> void:
	_segment_healths.clear()
	_segment_materials.clear()
	for mesh in segment_meshes:
		_segment_healths.append(segment_max_health)
		var material := StandardMaterial3D.new()
		material.roughness = 0.94
		material.metallic = 0.04
		material.emission_enabled = true
		material.albedo_color = _base_color
		material.emission = _emission_color
		mesh.material_override = material
		_segment_materials.append(material)

func _repair_next_segment() -> int:
	for index in range(segment_healths_size()):
		if _segment_healths[index] > 0:
			continue
		_segment_healths[index] = segment_max_health
		_update_segment_state(index)
		_update_label()
		return index
	return -1

func _get_damage_target_index() -> int:
	for index in range(segment_healths_size()):
		if _segment_healths[index] > 0:
			return index
	return -1

func _get_destroyed_segment_count() -> int:
	var destroyed_segments := 0
	for health_value in _segment_healths:
		if health_value <= 0:
			destroyed_segments += 1
	return destroyed_segments

func _get_intact_segment_count() -> int:
	return segment_healths_size() - _get_destroyed_segment_count()

func _update_all_segments() -> void:
	for index in range(segment_healths_size()):
		_update_segment_state(index)

func _update_segment_state(index: int) -> void:
	var is_active: bool = _segment_healths[index] > 0
	segment_meshes[index].visible = is_active
	segment_shapes[index].disabled = not is_active
	var material: StandardMaterial3D = _segment_materials[index]
	if material != null:
		material.albedo_color = _base_color
		material.emission_energy_multiplier = 0.9 if is_active else 0.0

func _update_label() -> void:
	label_3d.text = "%s %d/3" % [display_name.to_upper(), _get_intact_segment_count()]

func segment_healths_size() -> int:
	return _segment_healths.size()
