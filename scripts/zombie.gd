extends CharacterBody3D

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

@export_category("Profile")
@export var species_id: int = ZombieDefinitions.Species.WALKER
@export var zombie_class_id: int = ZombieDefinitions.ZombieClass.COMMON
@export var rank_id: int = ZombieDefinitions.Rank.DELTA
@export var mort_grade: int = ZombieDefinitions.DEFAULT_MORT_GRADE
@export var death_class_id: int = ZombieDefinitions.DEFAULT_DEATH_CLASS
@export var death_subtype_id: int = ZombieDefinitions.DEFAULT_DEATH_SUBTYPE

@export_category("Animation")
@export var idle_frequency: float = 1.2
@export var idle_amplitude: float = 0.025
@export var walk_frequency: float = 7.0
@export var walk_amplitude: float = 0.12
@export var attack_anim_duration: float = 0.28
@export var attack_lunge_distance: float = 0.15
@export var hit_react_duration: float = 0.18

var speed := 3.0
var health := 50
var damage := 10
var attack_cooldown := 1.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: CharacterBody3D = null
var can_attack: bool = true
var attack_timer: Timer
var rng: RandomNumberGenerator = RandomNumberGenerator.new()
var profile: Dictionary = {}
var animation_time: float = 0.0
var attack_anim_timer: float = 0.0
var hit_react_timer: float = 0.0
var is_dying: bool = false
var turn_agility: float = 1.0
var movement_jitter: float = 0.0
var desired_move_direction: Vector3 = Vector3.ZERO
var noise_seed: float = 0.0

var base_positions: Dictionary = {}
var base_rotations: Dictionary = {}
var base_scales: Dictionary = {}

@onready var model_root: Node3D = $ModelRoot
@onready var pelvis: MeshInstance3D = $ModelRoot/Pelvis
@onready var torso: MeshInstance3D = $ModelRoot/Torso
@onready var rib_wound: MeshInstance3D = $ModelRoot/RibWound
@onready var head_mesh: MeshInstance3D = $ModelRoot/Head
@onready var jaw: MeshInstance3D = $ModelRoot/Jaw
@onready var eye_l: MeshInstance3D = $ModelRoot/Eye_L
@onready var eye_r: MeshInstance3D = $ModelRoot/Eye_R
@onready var arm_l: MeshInstance3D = $ModelRoot/Arm_L
@onready var forearm_l: MeshInstance3D = $ModelRoot/Forearm_L
@onready var claw_l1: MeshInstance3D = $ModelRoot/Claw_L1
@onready var claw_l2: MeshInstance3D = $ModelRoot/Claw_L2
@onready var arm_r: MeshInstance3D = $ModelRoot/Arm_R
@onready var forearm_r: MeshInstance3D = $ModelRoot/Forearm_R
@onready var held_item: MeshInstance3D = $ModelRoot/Forearm_R/WeaponSocket_R/HeldItem
@onready var leg_l: MeshInstance3D = $ModelRoot/Leg_L
@onready var shin_l: MeshInstance3D = $ModelRoot/Shin_L
@onready var leg_r: MeshInstance3D = $ModelRoot/Leg_R
@onready var shin_r: MeshInstance3D = $ModelRoot/Shin_R

func _ready():
	add_to_group("zombie")
	rng.randomize()
	noise_seed = rng.randf_range(0.0, 100.0)
	player = get_tree().get_first_node_in_group("player")

	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	$DamageArea.body_entered.connect(_on_damage_area_body_entered)

	apply_profile(
		ZombieDefinitions.build_profile(
			species_id,
			zombie_class_id,
			mort_grade,
			rank_id,
			death_class_id,
			death_subtype_id
		)
	)
	_capture_base_pose()

func _physics_process(delta):
	if is_dying:
		return

	_update_motion(delta)
	_update_visual_animation(delta)
	move_and_slide()

func apply_profile(next_profile: Dictionary):
	profile = next_profile.duplicate(true)
	species_id = int(profile.get("species", species_id))
	zombie_class_id = int(profile.get("class", zombie_class_id))
	rank_id = int(profile.get("rank", rank_id))
	mort_grade = int(profile.get("mort_grade", mort_grade))
	death_class_id = int(profile.get("death_class", death_class_id))
	death_subtype_id = int(profile.get("death_subtype", death_subtype_id))
	speed = float(profile.get("speed", speed))
	health = int(profile.get("health", health))
	damage = int(profile.get("damage", damage))
	attack_cooldown = float(profile.get("attack_cooldown", attack_cooldown))
	turn_agility = float(profile.get("turn_agility", 1.0))
	movement_jitter = float(profile.get("movement_jitter", 0.0))
	_apply_visual_profile()

func _update_motion(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player and is_instance_valid(player):
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		if to_player.length() > 0.01:
			var target_dir: Vector3 = to_player.normalized()
			var jitter_phase: float = animation_time * (2.4 + movement_jitter * 4.0) + noise_seed
			var jitter_vector: Vector3 = Vector3(
				sin(jitter_phase * 1.7),
				0.0,
				cos(jitter_phase * 1.2)
			) * movement_jitter * 0.35
			target_dir = (target_dir + jitter_vector).normalized()
			desired_move_direction = desired_move_direction.lerp(target_dir, clampf(turn_agility * delta * 3.6, 0.0, 1.0))
			if desired_move_direction.length() > 0.01:
				desired_move_direction = desired_move_direction.normalized()

			velocity.x = desired_move_direction.x * speed
			velocity.z = desired_move_direction.z * speed

			var look_angle: float = atan2(-desired_move_direction.x, -desired_move_direction.z)
			rotation.y = lerp_angle(rotation.y, look_angle, clampf(turn_agility * delta * 4.4, 0.0, 1.0))
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta)

func _update_visual_animation(delta: float):
	animation_time += delta
	_restore_base_pose()

	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var move_blend: float = clampf(horizontal_speed / maxf(speed, 0.001), 0.0, 1.0)
	var idle_wave: float = sin(animation_time * idle_frequency + noise_seed) * idle_amplitude
	var stride_wave: float = sin(animation_time * walk_frequency + noise_seed) * walk_amplitude * move_blend
	var counter_stride: float = sin(animation_time * walk_frequency + PI + noise_seed) * walk_amplitude * move_blend

	model_root.position.y += idle_wave + absf(stride_wave) * 0.06
	model_root.rotation.z += sin(animation_time * idle_frequency * 0.5 + noise_seed) * 0.03 + stride_wave * 0.18
	torso.rotation.x += -0.16 * move_blend + idle_wave * 0.8
	head_mesh.rotation.z += -stride_wave * 0.2
	head_mesh.rotation.x += idle_wave * 0.65
	pelvis.rotation.z += counter_stride * 0.18

	arm_l.rotation.x += -0.38 * move_blend + counter_stride * 1.3
	forearm_l.rotation.x += -0.14 * move_blend + counter_stride * 0.8
	arm_r.rotation.x += -0.32 * move_blend + stride_wave * 1.15
	forearm_r.rotation.x += -0.1 * move_blend + stride_wave * 0.7

	leg_l.rotation.x += stride_wave * 1.45
	shin_l.rotation.x += maxf(-stride_wave, 0.0) * 1.2
	leg_r.rotation.x += counter_stride * 1.45
	shin_r.rotation.x += maxf(-counter_stride, 0.0) * 1.2

	if attack_anim_timer > 0.0:
		attack_anim_timer = maxf(attack_anim_timer - delta, 0.0)
		var attack_progress: float = 1.0 - (attack_anim_timer / maxf(attack_anim_duration, 0.001))
		var attack_wave: float = sin(attack_progress * PI)
		model_root.position.z -= attack_wave * attack_lunge_distance
		torso.rotation.x += attack_wave * 0.55
		arm_r.rotation.x += attack_wave * 1.35
		forearm_r.rotation.x += attack_wave * 0.95
		head_mesh.rotation.x += attack_wave * 0.2

	if hit_react_timer > 0.0:
		hit_react_timer = maxf(hit_react_timer - delta, 0.0)
		var hit_progress: float = hit_react_timer / maxf(hit_react_duration, 0.001)
		model_root.rotation.x -= hit_progress * 0.22
		model_root.rotation.z += hit_progress * 0.14

func take_damage(amount: int):
	if is_dying:
		return false

	health -= amount
	hit_react_timer = hit_react_duration
	if health <= 0:
		die()
		return true
	return false

func die():
	if is_dying:
		return

	is_dying = true
	remove_from_group("zombie")
	collision_layer = 0
	collision_mask = 0
	$DamageArea.monitoring = false
	$DamageArea.set_deferred("monitorable", false)

	var fall_sign: float = -1.0 if rng.randf() < 0.5 else 1.0
	var tween: Tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(model_root, "rotation", model_root.rotation + Vector3(0.35, 0.0, deg_to_rad(62.0) * fall_sign), 0.26)
	tween.tween_property(model_root, "position", model_root.position + Vector3(0.0, -0.58, 0.16), 0.26)
	tween.finished.connect(queue_free)

func _on_damage_area_body_entered(body):
	if is_dying:
		return
	if body.is_in_group("player") and can_attack:
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		can_attack = false
		attack_anim_timer = attack_anim_duration
		attack_timer.start(attack_cooldown)

func _on_attack_timer_timeout():
	can_attack = true
	if is_dying:
		return
	if player and is_instance_valid(player):
		var bodies = $DamageArea.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage, global_position)
				can_attack = false
				attack_anim_timer = attack_anim_duration
				attack_timer.start(attack_cooldown)
				break

func _capture_base_pose():
	base_positions.clear()
	base_rotations.clear()
	base_scales.clear()

	for node in [
		model_root,
		pelvis,
		torso,
		head_mesh,
		arm_l,
		forearm_l,
		arm_r,
		forearm_r,
		leg_l,
		shin_l,
		leg_r,
		shin_r
	]:
		_store_pose(node)

func _restore_base_pose():
	for node in [
		model_root,
		pelvis,
		torso,
		head_mesh,
		arm_l,
		forearm_l,
		arm_r,
		forearm_r,
		leg_l,
		shin_l,
		leg_r,
		shin_r
	]:
		_restore_pose(node)

func _store_pose(node: Node3D):
	base_positions[node.name] = node.position
	base_rotations[node.name] = node.rotation
	base_scales[node.name] = node.scale

func _restore_pose(node: Node3D):
	node.position = base_positions.get(node.name, node.position)
	node.rotation = base_rotations.get(node.name, node.rotation)
	node.scale = base_scales.get(node.name, node.scale)

func _apply_visual_profile():
	var rank_scale: float = float(profile.get("scale", 1.0))
	model_root.scale = Vector3.ONE * rank_scale

	var skin_color: Color = Color(0.34, 0.42, 0.25, 1.0)
	var shirt_color: Color = Color(0.14, 0.16, 0.15, 1.0)
	var pants_color: Color = Color(0.19, 0.18, 0.16, 1.0)
	var flesh_color: Color = Color(0.42, 0.12, 0.11, 1.0)
	var bone_color: Color = Color(0.72, 0.68, 0.58, 1.0)
	var metal_color: Color = Color(0.2, 0.2, 0.22, 1.0)
	var eye_color: Color = Color(1.0, 0.48, 0.16, 1.0)
	var eye_energy: float = 0.55

	match species_id:
		ZombieDefinitions.Species.BRUTE:
			model_root.scale *= 1.12
			torso.scale = Vector3(1.22, 1.18, 1.08)
			pelvis.scale = Vector3(1.18, 1.0, 1.0)
			arm_l.scale = Vector3(1.2, 1.15, 1.15)
			arm_r.scale = Vector3(1.2, 1.15, 1.15)
			forearm_l.scale = Vector3(1.14, 1.12, 1.12)
			forearm_r.scale = Vector3(1.14, 1.12, 1.12)
			skin_color = Color(0.31, 0.36, 0.24, 1.0)
			shirt_color = Color(0.18, 0.14, 0.12, 1.0)
			pants_color = Color(0.12, 0.11, 0.1, 1.0)
			held_item.visible = false
		ZombieDefinitions.Species.SPRINTER:
			model_root.scale *= 0.92
			torso.scale = Vector3(0.88, 1.02, 0.92)
			pelvis.scale = Vector3(0.9, 0.95, 0.92)
			arm_l.scale = Vector3(0.88, 1.08, 0.88)
			arm_r.scale = Vector3(0.88, 1.08, 0.88)
			leg_l.scale = Vector3(0.92, 1.08, 0.92)
			leg_r.scale = Vector3(0.92, 1.08, 0.92)
			model_root.rotation.x += 0.08
			skin_color = Color(0.36, 0.43, 0.24, 1.0)
			shirt_color = Color(0.09, 0.1, 0.1, 1.0)
			pants_color = Color(0.16, 0.15, 0.14, 1.0)
			eye_energy = 0.78
			held_item.visible = false
		ZombieDefinitions.Species.SKULLY:
			model_root.scale *= 1.03
			torso.scale = Vector3(0.98, 1.0, 0.9)
			skin_color = bone_color
			shirt_color = Color(0.08, 0.08, 0.09, 1.0)
			pants_color = Color(0.1, 0.1, 0.11, 1.0)
			flesh_color = Color(0.28, 0.08, 0.08, 1.0)
			eye_color = Color(0.74, 0.92, 1.0, 1.0)
			eye_energy = 0.95
			held_item.visible = true
		_:
			held_item.visible = species_id == ZombieDefinitions.Species.WALKER

	if zombie_class_id == ZombieDefinitions.ZombieClass.ARMORED:
		shirt_color = shirt_color.darkened(0.18)
		pants_color = pants_color.darkened(0.1)
		metal_color = Color(0.28, 0.29, 0.31, 1.0)
	if zombie_class_id == ZombieDefinitions.ZombieClass.FERAL:
		eye_energy += 0.16
		flesh_color = flesh_color.lightened(0.08)

	_set_mesh_material_color(head_mesh, skin_color)
	_set_mesh_material_color(arm_l, skin_color)
	_set_mesh_material_color(forearm_l, skin_color)
	_set_mesh_material_color(arm_r, skin_color)
	_set_mesh_material_color(forearm_r, skin_color)
	_set_mesh_material_color(shin_l, skin_color)
	_set_mesh_material_color(shin_r, skin_color)
	_set_mesh_material_color(torso, shirt_color)
	_set_mesh_material_color(pelvis, pants_color)
	_set_mesh_material_color(leg_l, pants_color)
	_set_mesh_material_color(leg_r, pants_color)
	_set_mesh_material_color(rib_wound, flesh_color)
	_set_mesh_material_color(jaw, bone_color)
	_set_mesh_material_color(claw_l1, bone_color)
	_set_mesh_material_color(claw_l2, bone_color)
	_set_mesh_material_color(held_item, metal_color)
	_set_mesh_material_color(eye_l, eye_color, eye_energy)
	_set_mesh_material_color(eye_r, eye_color, eye_energy)

func _set_mesh_material_color(mesh_instance: MeshInstance3D, color: Color, emission_energy: float = -1.0):
	if mesh_instance == null:
		return

	var source_material: StandardMaterial3D = mesh_instance.material_override as StandardMaterial3D
	if source_material == null and mesh_instance.mesh != null:
		source_material = mesh_instance.mesh.surface_get_material(0) as StandardMaterial3D
	if source_material == null:
		source_material = StandardMaterial3D.new()

	var material: StandardMaterial3D = source_material.duplicate()
	material.albedo_color = color
	if emission_energy >= 0.0:
		material.emission_enabled = true
		material.emission = color
		material.emission_energy_multiplier = emission_energy
	mesh_instance.material_override = material
