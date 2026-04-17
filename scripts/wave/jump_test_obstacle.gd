@tool
extends Node3D
class_name JumpTestObstacle

@export var jump_test_id: String = "jump_obstacle"
@export var obstacle_type: String = "box"
@export_enum("very_low", "low", "medium", "borderline") var obstacle_height_class: String = "low"
@export var jump_test_enabled: bool = true
@export var traversal_hint: String = "jumpable_candidate"
@export var display_color: Color = Color(0.58, 0.48, 0.33, 1.0)
@export var show_debug_label: bool = true

@onready var visual_mesh: MeshInstance3D = $Visual
@onready var collision_shape: CollisionShape3D = $Body/CollisionShape3D
@onready var debug_label: Label3D = $DebugLabel

const HEIGHT_GROUPS: Array[String] = [
	"jump_height_very_low",
	"jump_height_low",
	"jump_height_medium",
	"jump_height_borderline"
]

func _ready():
	_apply_obstacle_profile()

func _apply_obstacle_profile():
	if visual_mesh == null or collision_shape == null or debug_label == null:
		return

	_apply_groups()
	_apply_metadata()
	_apply_visual()
	_apply_debug_label()

func _apply_groups():
	for group_name in HEIGHT_GROUPS:
		if is_in_group(group_name):
			remove_from_group(group_name)

	var typed_groups: Array[String] = [
		"jump_test_obstacle",
		"jumpable_candidate",
		"jump_type_" + obstacle_type
	]
	for group_name in typed_groups:
		if not is_in_group(group_name):
			add_to_group(group_name)

	if jump_test_enabled:
		var height_group: String = "jump_height_" + obstacle_height_class
		if HEIGHT_GROUPS.has(height_group) and not is_in_group(height_group):
			add_to_group(height_group)

func _apply_metadata():
	set_meta("obstacle_type", obstacle_type)
	set_meta("traversal_hint", traversal_hint)
	set_meta("obstacle_height_class", obstacle_height_class)
	set_meta("jump_test_enabled", jump_test_enabled)
	set_meta("jump_test_id", jump_test_id)
	set_meta("obstacle_dimensions", _get_scaled_dimensions())

func _apply_visual():
	var material: StandardMaterial3D = null
	if visual_mesh.material_override is StandardMaterial3D:
		material = visual_mesh.material_override as StandardMaterial3D
	else:
		material = StandardMaterial3D.new()

	material.albedo_color = display_color
	material.roughness = 0.94
	material.metallic = 0.02
	visual_mesh.material_override = material

func _apply_debug_label():
	debug_label.visible = show_debug_label
	if not show_debug_label:
		return

	var size_data: Vector3 = _get_scaled_dimensions()
	debug_label.text = "%s | %s | %.2fm" % [jump_test_id, obstacle_height_class, size_data.y]

func _get_scaled_dimensions() -> Vector3:
	if collision_shape == null or collision_shape.shape == null:
		return Vector3.ONE

	var base_size := Vector3.ONE
	if collision_shape.shape is BoxShape3D:
		base_size = (collision_shape.shape as BoxShape3D).size

	return Vector3(
		absf(base_size.x * scale.x),
		absf(base_size.y * scale.y),
		absf(base_size.z * scale.z)
	)
