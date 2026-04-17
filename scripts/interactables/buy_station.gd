extends StaticBody3D

const WeaponDefinitions = preload("res://scripts/player/weapon_definitions.gd")
const ItemDefinitions = preload("res://scripts/player/item_definitions.gd")

@export_enum("ammo_refill", "consumable_supply", "weapon_buy") var station_type: String = "ammo_refill"
@export var weapon_id: String = ""
@export var item_id: String = ""
@export_range(-1, 9999, 1) var amount: int = -1
@export_range(-1, 9999, 1) var cost_override: int = -1
@export var display_name: String = "Supply Station"
@export var rotation_speed: float = 0.45

var _runtime_material: StandardMaterial3D
var _base_color: Color = Color.WHITE
var _emission_color: Color = Color.WHITE
var _base_mesh_scale: Vector3 = Vector3.ONE
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

func can_interact(player: Node) -> bool:
	return player != null and is_instance_valid(player) and player.has_method("purchase_station")

func interact(player: Node) -> bool:
	if not can_interact(player):
		return false
	return bool(player.call("purchase_station", station_type, weapon_id, item_id, amount, cost_override, display_name))

func get_interaction_prompt() -> String:
	var cost_text: String = ""
	if cost_override >= 0:
		cost_text = " [%d]" % cost_override
	elif station_type == "weapon_buy" and WeaponDefinitions.has_weapon(weapon_id):
		cost_text = " [%d]" % int(WeaponDefinitions.get_weapon_data(weapon_id).get("buy_cost", 0))
	elif station_type == "consumable_supply" and ItemDefinitions.has_item(item_id):
		cost_text = " [%d]" % int(ItemDefinitions.get_item_data(item_id).get("buy_cost", 0))
	elif station_type == "ammo_refill":
		var resolved_weapon_id: String = weapon_id if not weapon_id.is_empty() else "ammo"
		if WeaponDefinitions.has_weapon(resolved_weapon_id):
			cost_text = " [%d]" % int(WeaponDefinitions.get_weapon_data(resolved_weapon_id).get("ammo_refill_cost", 0))
	return "PRESS E: %s%s" % [display_name, cost_text]

func _apply_visual_style() -> void:
	_runtime_material = StandardMaterial3D.new()
	_runtime_material.roughness = 0.24
	_runtime_material.metallic = 0.12
	_runtime_material.emission_enabled = true

	match station_type:
		"weapon_buy":
			_base_color = Color(0.92, 0.64, 0.18, 1.0)
			_emission_color = Color(0.38, 0.18, 0.03, 1.0)
			_base_mesh_scale = Vector3(1.15, 1.2, 0.55)
		"consumable_supply":
			_base_color = Color(0.22, 0.86, 0.68, 1.0)
			_emission_color = Color(0.04, 0.24, 0.18, 1.0)
			_base_mesh_scale = Vector3(1.05, 1.15, 0.5)
		_:
			_base_color = Color(0.26, 0.76, 1.0, 1.0)
			_emission_color = Color(0.06, 0.18, 0.34, 1.0)
			_base_mesh_scale = Vector3(1.2, 0.85, 0.5)

	mesh_instance.scale = _base_mesh_scale
	_runtime_material.albedo_color = _base_color
	_runtime_material.emission = _emission_color
	mesh_instance.material_override = _runtime_material

func _update_label() -> void:
	label_3d.text = display_name.to_upper()

func set_highlighted(active: bool) -> void:
	_is_highlighted = active
	if _runtime_material == null:
		return

	_runtime_material.emission_energy_multiplier = 2.4 if _is_highlighted else 0.95
	_runtime_material.albedo_color = _base_color.lightened(0.08 if _is_highlighted else 0.0)
	mesh_instance.scale = _base_mesh_scale * (1.06 if _is_highlighted else 1.0)
	label_3d.modulate = Color(1.0, 1.0, 1.0, 1.0)
