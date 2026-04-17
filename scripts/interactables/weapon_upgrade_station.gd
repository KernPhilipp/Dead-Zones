extends StaticBody3D

@export_range(-1, 9999, 1) var cost_override: int = -1
@export var display_name: String = "Weapon Upgrade"
@export var rotation_speed: float = 0.35

var _runtime_material: StandardMaterial3D
var _base_color: Color = Color(0.95, 0.7, 0.2, 1.0)
var _emission_color: Color = Color(0.45, 0.22, 0.05, 1.0)
var _base_mesh_scale: Vector3 = Vector3(1.0, 1.2, 0.75)
var _is_highlighted: bool = false

@onready var visual_root: Node3D = $VisualRoot
@onready var mesh_instance: MeshInstance3D = $VisualRoot/MeshInstance3D
@onready var label_3d: Label3D = $VisualRoot/Label3D

func _ready() -> void:
	_apply_visual_style()
	_update_label()
	set_highlighted(false)

func _process(delta: float) -> void:
	visual_root.rotate_y(rotation_speed * delta)

func interact(player: Node) -> bool:
	if player == null or not is_instance_valid(player) or not player.has_method("upgrade_current_weapon"):
		return false
	return bool(player.call("upgrade_current_weapon", cost_override, display_name))

func get_interaction_prompt() -> String:
	var cost_text: String = " [VARIES]"
	if cost_override >= 0:
		cost_text = " [%d]" % cost_override
	return "PRESS E: %s%s" % [display_name, cost_text]

func _apply_visual_style() -> void:
	_runtime_material = StandardMaterial3D.new()
	_runtime_material.roughness = 0.18
	_runtime_material.metallic = 0.22
	_runtime_material.emission_enabled = true
	_runtime_material.albedo_color = _base_color
	_runtime_material.emission = _emission_color
	mesh_instance.scale = _base_mesh_scale
	mesh_instance.material_override = _runtime_material

func _update_label() -> void:
	label_3d.text = display_name.to_upper()

func set_highlighted(active: bool) -> void:
	_is_highlighted = active
	if _runtime_material == null:
		return

	_runtime_material.emission_energy_multiplier = 2.7 if _is_highlighted else 1.05
	_runtime_material.albedo_color = _base_color.lightened(0.08 if _is_highlighted else 0.0)
	mesh_instance.scale = _base_mesh_scale * (1.06 if _is_highlighted else 1.0)
	label_3d.modulate = Color(1.0, 1.0, 1.0, 1.0)
