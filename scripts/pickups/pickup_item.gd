extends StaticBody3D

@export_enum("ammo", "weapon", "consumable") var pickup_type: String = "ammo"
@export_range(1, 999, 1) var amount: int = 12
@export var weapon_id: String = ""
@export var item_id: String = ""
@export var display_name: String = "Pistol Ammo"
@export var rotation_speed: float = 1.4
@export var hover_amplitude: float = 0.08
@export var hover_speed: float = 2.2

var _float_time: float = 0.0
var _base_visual_position: Vector3 = Vector3.ZERO
var _runtime_material: StandardMaterial3D
var _base_mesh_scale: Vector3 = Vector3.ONE
var _base_color: Color = Color.WHITE
var _emission_color: Color = Color.WHITE
var _is_highlighted: bool = false

@onready var visual_root: Node3D = $VisualRoot
@onready var mesh_instance: MeshInstance3D = $VisualRoot/MeshInstance3D
@onready var label_3d: Label3D = $VisualRoot/Label3D

func _ready():
	_base_visual_position = visual_root.position
	_apply_visual_style()
	_update_label()
	set_highlighted(false)

func _process(delta: float):
	_float_time += delta
	visual_root.rotate_y(rotation_speed * delta)
	visual_root.position = _base_visual_position + Vector3(
		0.0,
		sin(_float_time * hover_speed) * hover_amplitude,
		0.0
	)

func interact(player: Node) -> bool:
	if player == null or not is_instance_valid(player) or not player.has_method("try_collect_pickup"):
		return false

	var collected: bool = bool(player.call("try_collect_pickup", pickup_type, amount, weapon_id, item_id, display_name))
	if collected:
		queue_free()
	return collected

func get_interaction_prompt() -> String:
	match pickup_type:
		"weapon":
			return "PRESS E: %s" % display_name
		"consumable":
			return "PRESS E: %s x%d" % [display_name, amount]
		_:
			return "PRESS E: %s +%d" % [display_name, amount]

func _apply_visual_style():
	_runtime_material = StandardMaterial3D.new()
	_runtime_material.roughness = 0.35
	_runtime_material.metallic = 0.15
	_runtime_material.emission_enabled = true

	match pickup_type:
		"weapon":
			_base_color = Color(0.92, 0.66, 0.18, 1.0)
			_emission_color = Color(0.38, 0.2, 0.04, 1.0)
			_base_mesh_scale = Vector3(1.0, 0.3, 1.4)
		"consumable":
			_base_color = Color(0.84, 0.22, 0.26, 1.0)
			_emission_color = Color(0.45, 0.08, 0.12, 1.0)
			_base_mesh_scale = Vector3(0.88, 0.48, 0.88)
		_:
			if weapon_id == "pistol":
				_base_color = Color(0.95, 0.72, 0.22, 1.0)
				_emission_color = Color(0.38, 0.24, 0.04, 1.0)
				_base_mesh_scale = Vector3(0.8, 0.34, 0.92)
			else:
				_base_color = Color(0.24, 0.86, 1.0, 1.0)
				_emission_color = Color(0.04, 0.24, 0.34, 1.0)
				_base_mesh_scale = Vector3(1.02, 0.32, 1.26)

	mesh_instance.scale = _base_mesh_scale
	_runtime_material.albedo_color = _base_color
	_runtime_material.emission = _emission_color
	mesh_instance.material_override = _runtime_material

func _update_label():
	var suffix: String = ""
	match pickup_type:
		"weapon":
			suffix = ""
		"consumable":
			suffix = " x%d" % amount
		_:
			suffix = " +%d" % amount
	label_3d.text = "%s%s" % [display_name.to_upper(), suffix]

func set_highlighted(active: bool):
	_is_highlighted = active
	if _runtime_material == null:
		return

	var label_alpha: float = 1.0 if _is_highlighted else 0.45
	var scale_boost: float = 1.08 if _is_highlighted else 1.0
	_runtime_material.emission_energy_multiplier = 2.35 if _is_highlighted else 0.85
	_runtime_material.albedo_color = _base_color.lightened(0.08 if _is_highlighted else 0.0)
	label_3d.modulate = Color(1.0, 1.0, 1.0, label_alpha)
	mesh_instance.scale = _base_mesh_scale * scale_boost
