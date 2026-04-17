extends CharacterBody3D

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDeathEffects = preload("res://scripts/zombie_death_effects.gd")

enum ZombieState {
	SPAWN_RISE,
	CHASE,
	ATTACK,
	HURT,
	DEAD
}

@export_category("Profile")
@export var species_id: int = ZombieDefinitions.Species.WALKER
@export var class_id: int = ZombieDefinitions.ZombieClass.COMMON
@export_range(0, 10, 1) var mort_grade: int = ZombieDefinitions.DEFAULT_MORT_GRADE
@export var rank_id: int = ZombieDefinitions.Rank.GAMMA
@export var visual_variant: String = ZombieDefinitions.DEFAULT_VISUAL_VARIANT
@export var death_class_id: int = ZombieDefinitions.DEFAULT_DEATH_CLASS
@export var death_subtype_id: int = ZombieDefinitions.DEFAULT_DEATH_SUBTYPE

@export_category("Spawn")
@export var rise_depth := 1.0
@export var rise_duration := 0.85

@export_category("Movement Variation")
@export var limp_frequency := 4.0
@export var limp_strength := 0.2
@export var strafe_jitter := 0.12

@export_category("Combat Reactions")
@export var hurt_recovery_time := 0.22
@export var headshot_instant_death := true

@export_category("Death")
@export var corpse_fall_duration := 0.35

const PART_MAX_HEALTH: Dictionary = {
	"head": 25,
	"torso": 60,
	"arm_l": 28,
	"arm_r": 28,
	"leg_l": 35,
	"leg_r": 35
}

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: CharacterBody3D = null
var state: ZombieState = ZombieState.SPAWN_RISE

var profile_data: Dictionary = {}
var resolved_speed: float = 3.0
var resolved_health: int = 80
var resolved_damage: int = 12
var resolved_attack_cooldown: float = 1.0
var resolved_turn_agility: float = 1.0
var resolved_movement_jitter: float = 0.1
var resolved_pain_resistance: float = 0.2
var resolved_behavior_mode: String = "default"
var resolved_death_behavior: String = "collapse"
var resolved_explosion_radius: float = 0.0
var resolved_explosion_damage: float = 0.0
var resolved_weapon_affinity_ranged: bool = false
var resolved_death_class_key: String = ""
var resolved_death_subtype_key: String = ""
var resolved_death_rarity_key: String = ""
var resolved_limp_frequency: float = 4.0
var resolved_limp_strength: float = 0.2
var resolved_attack_cooldown_variance: float = 0.0
var resolved_part_fragility_mult: float = 1.0
var resolved_crawl_transition_threshold: float = 0.0
var resolved_revenge_bonus: bool = false

var death_effect_profile: Dictionary = {}
var death_effect_status_id: String = ZombieDeathEffects.STATUS_SIMPLIFIED_NOW
var death_effect_status_name: String = ZombieDeathEffects.get_status_label(ZombieDeathEffects.STATUS_SIMPLIFIED_NOW)
var death_touch_dot_remaining: float = 0.0
var death_touch_dot_dps: float = 0.0
var death_touch_dot_tick: float = 0.0
var death_aura_tick: float = 0.0
var death_pulse_tick: float = 0.0
var death_stumble_tick: float = 0.0
var death_stumble_remaining: float = 0.0
var death_ally_pull_tick: float = 0.0
var death_ally_buff_tick: float = 0.0
var death_heading_wobble_time: float = 0.0
var death_head_wobble_time: float = 0.0
var dot_damage_buffer: float = 0.0
var revenge_buff_remaining: float = 0.0
var revenge_speed_mult: float = 1.0
var revenge_damage_mult: float = 1.0
var revenge_attack_cooldown_mult: float = 1.0
var ally_buff_remaining: float = 0.0
var ally_buff_speed_mult: float = 1.0
var ally_buff_attack_cooldown_mult: float = 1.0
var external_pull_vector: Vector3 = Vector3.ZERO
var external_pull_remaining: float = 0.0
var death_crawl_mode: bool = false

var health: int = 0
var can_attack: bool = false
var attack_timer: Timer
var hurt_timer: Timer
var idle_sound_timer: Timer

var rise_elapsed := 0.0
var rise_start_position := Vector3.ZERO
var rise_end_position := Vector3.ZERO
var limp_time := 0.0
var limp_phase := 0.0
var move_direction := Vector3.ZERO
var base_head_rotation := Vector3.ZERO

var behavior_triggered: bool = false
var hidder_ground_mode: bool = false
var cover_nodes: Array[Node3D] = []
var current_barricade_target: Node3D = null

var part_health: Dictionary = {}
var missing_parts: Dictionary = {}

@onready var body_collision: CollisionShape3D = $CollisionShape3D
@onready var damage_area: Area3D = $DamageArea
@onready var model_root: Node3D = $ModelRoot
@onready var pelvis_mesh: MeshInstance3D = $ModelRoot/Pelvis
@onready var torso_mesh: MeshInstance3D = $ModelRoot/Torso
@onready var rib_wound_mesh: MeshInstance3D = $ModelRoot/RibWound
@onready var head_mesh: MeshInstance3D = $ModelRoot/Head
@onready var jaw_mesh: MeshInstance3D = $ModelRoot/Jaw
@onready var eye_left_mesh: MeshInstance3D = $ModelRoot/Eye_L
@onready var eye_right_mesh: MeshInstance3D = $ModelRoot/Eye_R
@onready var arm_left_mesh: MeshInstance3D = $ModelRoot/Arm_L
@onready var forearm_left_mesh: MeshInstance3D = $ModelRoot/Forearm_L
@onready var claw_left_mesh_a: MeshInstance3D = $ModelRoot/Claw_L1
@onready var claw_left_mesh_b: MeshInstance3D = $ModelRoot/Claw_L2
@onready var arm_right_mesh: MeshInstance3D = $ModelRoot/Arm_R
@onready var forearm_right_mesh: MeshInstance3D = $ModelRoot/Forearm_R
@onready var held_item: MeshInstance3D = $ModelRoot/Forearm_R/WeaponSocket_R/HeldItem
@onready var leg_left_mesh: MeshInstance3D = $ModelRoot/Leg_L
@onready var shin_left_mesh: MeshInstance3D = $ModelRoot/Shin_L
@onready var leg_right_mesh: MeshInstance3D = $ModelRoot/Leg_R
@onready var shin_right_mesh: MeshInstance3D = $ModelRoot/Shin_R
@onready var part_nodes: Dictionary = {
	"head": $ModelRoot/Head,
	"torso": $ModelRoot/Torso,
	"arm_l": $ModelRoot/Arm_L,
	"arm_r": $ModelRoot/Arm_R,
	"leg_l": $ModelRoot/Leg_L,
	"leg_r": $ModelRoot/Leg_R
}
@onready var hitbox_nodes: Dictionary = {
	"head": $Hitboxes/Hitbox_Head,
	"torso": $Hitboxes/Hitbox_Torso,
	"arm_l": $Hitboxes/Hitbox_Arm_L,
	"arm_r": $Hitboxes/Hitbox_Arm_R,
	"leg_l": $Hitboxes/Hitbox_Leg_L,
	"leg_r": $Hitboxes/Hitbox_Leg_R
}

var base_model_root_position := Vector3.ZERO
var profile_rng: RandomNumberGenerator
var visual_base_positions: Dictionary = {}
var visual_base_rotations: Dictionary = {}
var visual_base_scales: Dictionary = {}

func _is_net_server() -> bool:
	return NetworkManager.is_active() and multiplayer.is_server()

func _get_chase_target() -> CharacterBody3D:
	# In multiplayer find the nearest living player
	if NetworkManager.is_active():
		var all_players := get_tree().get_nodes_in_group("player")
		var nearest: CharacterBody3D = null
		var best := INF
		for p in all_players:
			if p is CharacterBody3D and p.has_method("get") and int(p.get("health")) > 0:
				var d := global_position.distance_squared_to((p as CharacterBody3D).global_position)
				if d < best:
					best = d
					nearest = p as CharacterBody3D
		return nearest
	return player

func _ready():
	randomize()
	add_to_group("zombie")
	player = get_tree().get_first_node_in_group("player")
	limp_phase = randf_range(0.0, TAU)
	base_model_root_position = model_root.position
	base_head_rotation = part_nodes["head"].rotation
	_capture_visual_base_pose()
	profile_rng = RandomNumberGenerator.new()
	profile_rng.randomize()

	_collect_cover_nodes()
	_apply_profile_data()
	health = resolved_health
	_initialize_part_states()

	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	hurt_timer = Timer.new()
	hurt_timer.one_shot = true
	hurt_timer.timeout.connect(_on_hurt_timer_timeout)
	add_child(hurt_timer)

	idle_sound_timer = Timer.new()
	idle_sound_timer.one_shot = true
	idle_sound_timer.timeout.connect(_on_idle_sound_timer_timeout)
	add_child(idle_sound_timer)

	damage_area.body_entered.connect(_on_damage_area_body_entered)

	rise_end_position = global_position
	rise_start_position = rise_end_position + Vector3.DOWN * rise_depth
	global_position = rise_start_position
	body_collision.set_deferred("disabled", true)
	damage_area.monitoring = false
	velocity = Vector3.ZERO
	state = ZombieState.SPAWN_RISE

func _physics_process(delta):
	if NetworkManager.is_active() and not multiplayer.is_server():
		# Clients only apply gravity; position comes from MultiplayerSynchronizer
		if not is_on_floor():
			velocity.y -= gravity * delta
		move_and_slide()
		return

	_process_death_effect_runtime(delta)

	match state:
		ZombieState.SPAWN_RISE:
			_process_spawn_rise(delta)
		ZombieState.CHASE:
			_process_chase(delta)
		ZombieState.ATTACK:
			_process_attack(delta)
		ZombieState.HURT:
			_process_hurt(delta)
		ZombieState.DEAD:
			pass

func configure_profile(
	new_species_id: int,
	new_class_id: int,
	new_mort_grade: int,
	new_rank_id: int,
	new_visual_variant: String = ZombieDefinitions.DEFAULT_VISUAL_VARIANT,
	new_death_class_id: int = ZombieDefinitions.DEFAULT_DEATH_CLASS,
	new_death_subtype_id: int = ZombieDefinitions.DEFAULT_DEATH_SUBTYPE
):
	species_id = new_species_id
	class_id = new_class_id
	mort_grade = ZombieDefinitions.clamp_mort_grade(new_mort_grade)
	rank_id = new_rank_id
	visual_variant = new_visual_variant
	death_class_id = new_death_class_id
	death_subtype_id = new_death_subtype_id

	if is_inside_tree():
		_apply_profile_data()
		_initialize_part_states()
		health = resolved_health

func _apply_profile_data():
	profile_data = ZombieDefinitions.build_profile(
		species_id,
		class_id,
		mort_grade,
		rank_id,
		death_class_id,
		death_subtype_id
	)
	resolved_speed = float(profile_data["speed"])
	resolved_health = int(profile_data["health"])
	resolved_damage = int(profile_data["damage"])
	resolved_attack_cooldown = float(profile_data["attack_cooldown"])
	resolved_turn_agility = float(profile_data["turn_agility"])
	resolved_movement_jitter = float(profile_data["movement_jitter"])
	resolved_pain_resistance = float(profile_data["pain_resistance"])
	resolved_behavior_mode = String(profile_data["behavior_mode"])
	resolved_death_behavior = String(profile_data["death_behavior"])
	resolved_explosion_radius = float(profile_data["explosion_radius"])
	resolved_explosion_damage = float(profile_data["explosion_damage"])
	resolved_weapon_affinity_ranged = bool(profile_data["weapon_affinity_ranged"])
	resolved_death_class_key = String(profile_data["death_class_id"])
	resolved_death_subtype_key = String(profile_data["death_subtype_id"])
	resolved_death_rarity_key = String(profile_data["death_rarity_id"])
	resolved_limp_frequency = limp_frequency
	resolved_limp_strength = limp_strength

	var resolved_scale: float = float(profile_data["scale"])
	scale = Vector3.ONE * resolved_scale

	death_effect_profile = ZombieDeathEffects.resolve_runtime_profile(death_subtype_id, profile_rng)
	_apply_death_effect_profile_modifiers()
	_reset_death_effect_runtime_state()

	_apply_visual_variant_placeholder()
	_apply_behavior_pose_reset()
	set_meta("death_class_id", resolved_death_class_key)
	set_meta("death_subtype_id", resolved_death_subtype_key)
	set_meta("death_rarity_id", resolved_death_rarity_key)
	set_meta("death_effect_status", death_effect_status_name)
	set_meta("death_effect_status_id", death_effect_status_id)
	set_meta("death_effect_id", String(death_effect_profile.get("id", resolved_death_subtype_key)))
	set_meta("death_effect_runtime", String(death_effect_profile.get("runtime_effect", "")))
	set_meta("mort_grade", int(profile_data.get("mort_grade", ZombieDefinitions.DEFAULT_MORT_GRADE)))
	set_meta("mort_speed_mult", float(profile_data.get("mort_speed_mult", 1.0)))
	set_meta("mort_damage_mult", float(profile_data.get("mort_damage_mult", 1.0)))
	set_meta("mort_attack_cooldown_mult", float(profile_data.get("mort_attack_cooldown_mult", 1.0)))

func _apply_death_effect_profile_modifiers():
	var speed_mult: float = float(death_effect_profile.get("speed_mult", 1.0))
	var health_mult: float = float(death_effect_profile.get("health_mult", 1.0))
	var damage_mult: float = float(death_effect_profile.get("damage_mult", 1.0))
	var attack_cooldown_mult: float = float(death_effect_profile.get("attack_cooldown_mult", 1.0))
	var turn_agility_mult: float = float(death_effect_profile.get("turn_agility_mult", 1.0))
	var movement_jitter_add: float = float(death_effect_profile.get("movement_jitter_add", 0.0))
	var limp_strength_add: float = float(death_effect_profile.get("limp_strength_add", 0.0))
	var limp_frequency_mult: float = float(death_effect_profile.get("limp_frequency_mult", 1.0))
	var pain_resistance_add: float = float(death_effect_profile.get("pain_resistance_add", 0.0))

	resolved_speed = maxf(0.2, resolved_speed * speed_mult)
	resolved_health = max(1, int(round(float(resolved_health) * health_mult)))
	resolved_damage = max(1, int(round(float(resolved_damage) * damage_mult)))
	resolved_attack_cooldown = maxf(0.16, resolved_attack_cooldown * attack_cooldown_mult)
	resolved_turn_agility = maxf(0.05, resolved_turn_agility * turn_agility_mult)
	resolved_movement_jitter = maxf(0.0, resolved_movement_jitter + movement_jitter_add)
	resolved_limp_strength = maxf(0.0, limp_strength + limp_strength_add)
	resolved_limp_frequency = maxf(0.15, limp_frequency * limp_frequency_mult)
	resolved_pain_resistance = clampf(resolved_pain_resistance + pain_resistance_add, 0.0, 0.97)
	resolved_attack_cooldown_variance = clampf(float(death_effect_profile.get("attack_cooldown_variance", 0.0)), 0.0, 0.45)
	resolved_part_fragility_mult = maxf(0.3, float(death_effect_profile.get("part_fragility_mult", 1.0)))
	resolved_crawl_transition_threshold = clampf(float(death_effect_profile.get("crawl_transition_threshold", 0.0)), 0.0, 0.95)
	resolved_revenge_bonus = bool(death_effect_profile.get("revenge_bonus", false))

	death_effect_status_id = String(death_effect_profile.get("implementation_status", ZombieDeathEffects.STATUS_SIMPLIFIED_NOW))
	death_effect_status_name = String(death_effect_profile.get("implementation_status_name", ZombieDeathEffects.get_status_label(death_effect_status_id)))

func _reset_death_effect_runtime_state():
	death_touch_dot_remaining = 0.0
	death_touch_dot_dps = 0.0
	death_touch_dot_tick = 0.0
	death_aura_tick = 0.0
	death_pulse_tick = 0.0
	death_stumble_tick = 0.0
	death_stumble_remaining = 0.0
	death_ally_pull_tick = 0.0
	death_ally_buff_tick = 0.0
	death_heading_wobble_time = 0.0
	death_head_wobble_time = 0.0
	dot_damage_buffer = 0.0
	revenge_buff_remaining = 0.0
	revenge_speed_mult = 1.0
	revenge_damage_mult = 1.0
	revenge_attack_cooldown_mult = 1.0
	ally_buff_remaining = 0.0
	ally_buff_speed_mult = 1.0
	ally_buff_attack_cooldown_mult = 1.0
	external_pull_vector = Vector3.ZERO
	external_pull_remaining = 0.0
	death_crawl_mode = false

func _apply_visual_variant_placeholder():
	var allowed: Array = profile_data.get("allowed_visual_variants", [ZombieDefinitions.DEFAULT_VISUAL_VARIANT])
	if not allowed.has(visual_variant):
		visual_variant = ZombieDefinitions.DEFAULT_VISUAL_VARIANT
	set_meta("visual_variant", visual_variant)

func _apply_behavior_pose_reset():
	_restore_visual_base_pose()
	model_root.position = base_model_root_position
	model_root.rotation.x = 0.0
	if resolved_behavior_mode == "low_crawl":
		model_root.position = base_model_root_position + Vector3(0.0, -0.35, 0.0)

func _capture_visual_base_pose():
	visual_base_positions.clear()
	visual_base_rotations.clear()
	visual_base_scales.clear()

	for node in [
		model_root,
		pelvis_mesh,
		torso_mesh,
		rib_wound_mesh,
		head_mesh,
		jaw_mesh,
		eye_left_mesh,
		eye_right_mesh,
		arm_left_mesh,
		forearm_left_mesh,
		claw_left_mesh_a,
		claw_left_mesh_b,
		arm_right_mesh,
		forearm_right_mesh,
		held_item,
		leg_left_mesh,
		shin_left_mesh,
		leg_right_mesh,
		shin_right_mesh
	]:
		_store_visual_pose(node)

func _restore_visual_base_pose():
	for node in [
		model_root,
		pelvis_mesh,
		torso_mesh,
		rib_wound_mesh,
		head_mesh,
		jaw_mesh,
		eye_left_mesh,
		eye_right_mesh,
		arm_left_mesh,
		forearm_left_mesh,
		claw_left_mesh_a,
		claw_left_mesh_b,
		arm_right_mesh,
		forearm_right_mesh,
		held_item,
		leg_left_mesh,
		shin_left_mesh,
		leg_right_mesh,
		shin_right_mesh
	]:
		_restore_visual_pose(node)

func _store_visual_pose(node: Node3D):
	if node == null:
		return
	visual_base_positions[node.name] = node.position
	visual_base_rotations[node.name] = node.rotation
	visual_base_scales[node.name] = node.scale

func _restore_visual_pose(node: Node3D):
	if node == null:
		return
	node.position = visual_base_positions.get(node.name, node.position)
	node.rotation = visual_base_rotations.get(node.name, node.rotation)
	node.scale = visual_base_scales.get(node.name, node.scale)

func _initialize_part_states():
	part_health.clear()
	missing_parts.clear()
	behavior_triggered = false
	hidder_ground_mode = false
	move_direction = Vector3.ZERO

	for part in part_nodes.keys():
		var part_node: Node3D = part_nodes[part]
		part_node.visible = true

	for hitbox_node in hitbox_nodes.values():
		var hitbox: StaticBody3D = hitbox_node
		hitbox.collision_layer = 2
		hitbox.collision_mask = 0
		for child in hitbox.get_children():
			if child is CollisionShape3D:
				child.disabled = false

	held_item.visible = true

	var part_health_mult: float = float(profile_data.get("part_health_mult", 1.0))
	part_health_mult *= float(death_effect_profile.get("health_mult", 1.0))
	for part in PART_MAX_HEALTH.keys():
		var base_part_health: int = int(PART_MAX_HEALTH[part])
		part_health[part] = max(1, int(round(float(base_part_health) * part_health_mult)))
		missing_parts[part] = false

	_apply_visual_profile()
	_apply_starting_part_losses()

func _apply_visual_profile():
	_restore_visual_base_pose()

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
			torso_mesh.scale = Vector3(1.22, 1.18, 1.08)
			pelvis_mesh.scale = Vector3(1.18, 1.0, 1.0)
			arm_left_mesh.scale = Vector3(1.2, 1.15, 1.15)
			arm_right_mesh.scale = Vector3(1.2, 1.15, 1.15)
			forearm_left_mesh.scale = Vector3(1.14, 1.12, 1.12)
			forearm_right_mesh.scale = Vector3(1.14, 1.12, 1.12)
			skin_color = Color(0.31, 0.36, 0.24, 1.0)
			shirt_color = Color(0.18, 0.14, 0.12, 1.0)
			pants_color = Color(0.12, 0.11, 0.1, 1.0)
			held_item.visible = false
		ZombieDefinitions.Species.SPRINTER:
			model_root.scale *= 0.92
			torso_mesh.scale = Vector3(0.88, 1.02, 0.92)
			pelvis_mesh.scale = Vector3(0.9, 0.95, 0.92)
			arm_left_mesh.scale = Vector3(0.88, 1.08, 0.88)
			arm_right_mesh.scale = Vector3(0.88, 1.08, 0.88)
			leg_left_mesh.scale = Vector3(0.92, 1.08, 0.92)
			leg_right_mesh.scale = Vector3(0.92, 1.08, 0.92)
			model_root.rotation.x += 0.08
			skin_color = Color(0.36, 0.43, 0.24, 1.0)
			shirt_color = Color(0.09, 0.1, 0.1, 1.0)
			pants_color = Color(0.16, 0.15, 0.14, 1.0)
			eye_energy = 0.78
			held_item.visible = false
		ZombieDefinitions.Species.SKULLY:
			model_root.scale *= 1.03
			torso_mesh.scale = Vector3(0.98, 1.0, 0.9)
			skin_color = bone_color
			shirt_color = Color(0.08, 0.08, 0.09, 1.0)
			pants_color = Color(0.1, 0.1, 0.11, 1.0)
			flesh_color = Color(0.28, 0.08, 0.08, 1.0)
			eye_color = Color(0.74, 0.92, 1.0, 1.0)
			eye_energy = 0.95
			held_item.visible = true
		_:
			held_item.visible = species_id == ZombieDefinitions.Species.WALKER

	if class_id == ZombieDefinitions.ZombieClass.ARMORED:
		shirt_color = shirt_color.darkened(0.18)
		pants_color = pants_color.darkened(0.1)
		metal_color = Color(0.28, 0.29, 0.31, 1.0)
	if class_id == ZombieDefinitions.ZombieClass.FERAL:
		eye_energy += 0.16
		flesh_color = flesh_color.lightened(0.08)

	_set_mesh_material_color(head_mesh, skin_color)
	_set_mesh_material_color(arm_left_mesh, skin_color)
	_set_mesh_material_color(forearm_left_mesh, skin_color)
	_set_mesh_material_color(arm_right_mesh, skin_color)
	_set_mesh_material_color(forearm_right_mesh, skin_color)
	_set_mesh_material_color(shin_left_mesh, skin_color)
	_set_mesh_material_color(shin_right_mesh, skin_color)
	_set_mesh_material_color(torso_mesh, shirt_color)
	_set_mesh_material_color(pelvis_mesh, pants_color)
	_set_mesh_material_color(leg_left_mesh, pants_color)
	_set_mesh_material_color(leg_right_mesh, pants_color)
	_set_mesh_material_color(rib_wound_mesh, flesh_color)
	_set_mesh_material_color(jaw_mesh, bone_color)
	_set_mesh_material_color(claw_left_mesh_a, bone_color)
	_set_mesh_material_color(claw_left_mesh_b, bone_color)
	_set_mesh_material_color(held_item, metal_color)
	_set_mesh_material_color(eye_left_mesh, eye_color, eye_energy)
	_set_mesh_material_color(eye_right_mesh, eye_color, eye_energy)

func take_damage(amount: int) -> bool:
	return take_part_damage("torso", amount)

@rpc("any_peer", "call_local", "reliable")
func take_part_damage_rpc(part: String, amount: int):
	if not multiplayer.is_server():
		return
	take_part_damage(part, amount)

func take_part_damage(part: String, amount: int) -> bool:
	if state == ZombieState.DEAD or amount <= 0:
		return false

	if resolved_behavior_mode == "corpse_feeder" or resolved_behavior_mode == "passive_trigger":
		behavior_triggered = true

	var effective_part = part
	if not part_health.has(effective_part):
		effective_part = "torso"

	var scaled_amount: int = max(1, int(round(float(amount) * resolved_part_fragility_mult)))
	part_health[effective_part] = max(0, int(part_health[effective_part]) - scaled_amount)
	health -= scaled_amount

	if part_health[effective_part] <= 0 and not missing_parts[effective_part]:
		_remove_part(effective_part)

	if health <= 0 or missing_parts["torso"]:
		die()
		return true

	if state != ZombieState.SPAWN_RISE:
		_enter_hurt_state()
	return false


func die():
	if state == ZombieState.DEAD:
		return

	_broadcast_ally_death_event()
	current_barricade_target = null
	if idle_sound_timer != null:
		idle_sound_timer.stop()

	if resolved_death_behavior == "explode":
		_die_with_explosion()
		return

	state = ZombieState.DEAD
	remove_from_group("zombie")
	add_to_group("zombie_corpse")
	can_attack = false
	velocity = Vector3.ZERO

	damage_area.monitoring = false
	damage_area.monitorable = false
	body_collision.set_deferred("disabled", true)
	_disable_all_hitboxes()
	_apply_death_subtype_burst()
	_play_world_sound("zombie_death")

	var fall_direction: float = 1.0
	if randf() < 0.5:
		fall_direction = -1.0

	var target_rotation: Vector3 = model_root.rotation
	target_rotation.z = deg_to_rad(82.0) * fall_direction

	var tween = create_tween()
	tween.tween_property(model_root, "rotation", target_rotation, corpse_fall_duration)
	tween.finished.connect(_on_corpse_fall_finished)

func _die_with_explosion():
	state = ZombieState.DEAD
	remove_from_group("zombie")
	can_attack = false
	current_barricade_target = null
	damage_area.monitoring = false
	damage_area.monitorable = false
	body_collision.set_deferred("disabled", true)
	_disable_all_hitboxes()

	_apply_death_subtype_burst()
	_apply_explosion_damage()
	_play_world_sound("zombie_explode")
	model_root.visible = false
	queue_free()

func _apply_explosion_damage():
	var radius: float = maxf(0.1, resolved_explosion_radius)
	var damage_out: int = max(1, int(round(resolved_explosion_damage)))

	if player and is_instance_valid(player) and player.has_method("take_damage"):
		if global_position.distance_to(player.global_position) <= radius:
			player.take_damage(damage_out)

	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node is Node3D:
			var other_zombie: Node3D = zombie_node
			if global_position.distance_to(other_zombie.global_position) <= radius and zombie_node.has_method("take_damage"):
				zombie_node.take_damage(max(1, int(round(float(damage_out) * 0.5))))

func _process_spawn_rise(delta: float):
	rise_elapsed += delta
	var t: float = clampf(rise_elapsed / rise_duration, 0.0, 1.0)
	global_position = rise_start_position.lerp(rise_end_position, t)

	if t >= 1.0:
		body_collision.disabled = false
		damage_area.monitoring = true
		damage_area.monitorable = true
		can_attack = true
		state = ZombieState.CHASE
		_play_world_sound("zombie_spawn")
		_schedule_idle_sound()

func _process_chase(delta: float):
	_apply_gravity(delta)
	var target_position: Vector3 = _get_behavior_target_position()
	_update_behavior_pose(delta)

	var desired_direction: Vector3 = target_position - global_position
	desired_direction.y = 0.0
	if desired_direction.length_squared() > 0.0001:
		desired_direction = desired_direction.normalized()
	else:
		desired_direction = Vector3.ZERO

	if desired_direction != Vector3.ZERO:
		var heading_wobble_strength: float = float(death_effect_profile.get("heading_wobble_strength", 0.0))
		if heading_wobble_strength > 0.0:
			var heading_wobble_frequency: float = maxf(0.1, float(death_effect_profile.get("heading_wobble_frequency", 1.0)))
			death_heading_wobble_time += delta * heading_wobble_frequency
			var heading_right: Vector3 = Vector3(-desired_direction.z, 0.0, desired_direction.x)
			var heading_wobble: float = sin(death_heading_wobble_time) * heading_wobble_strength
			desired_direction = (desired_direction + heading_right * heading_wobble).normalized()

		if external_pull_remaining > 0.0 and external_pull_vector != Vector3.ZERO:
			var external_blend: float = clampf(external_pull_remaining / 0.45, 0.0, 1.0)
			desired_direction = (desired_direction + external_pull_vector * external_blend).normalized()

		limp_time += delta * resolved_limp_frequency
		var limp_multiplier: float = 1.0 + sin(limp_time + limp_phase) * resolved_limp_strength
		var jitter_strength: float = strafe_jitter + resolved_movement_jitter
		var discipline_rating: float = clampf(float(death_effect_profile.get("discipline_rating", 0.0)), 0.0, 1.0)
		jitter_strength *= lerpf(1.0, 0.4, discipline_rating)
		if resolved_behavior_mode == "panic_fast":
			jitter_strength *= 1.4

		if move_direction == Vector3.ZERO:
			move_direction = desired_direction

		var turn_factor: float = clampf(resolved_turn_agility * delta * 4.0 * lerpf(1.0, 1.45, discipline_rating), 0.0, 1.0)
		move_direction = move_direction.slerp(desired_direction, turn_factor).normalized()

		var right: Vector3 = Vector3(-move_direction.z, 0.0, move_direction.x)
		var jitter: float = sin((limp_time * 0.5) + limp_phase * 1.7) * jitter_strength
		var walk_direction: Vector3 = (move_direction + right * jitter).normalized()
		var speed: float = _get_current_speed() * limp_multiplier
		velocity.x = walk_direction.x * speed
		velocity.z = walk_direction.z * speed
		_look_at_point(global_position + move_direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	move_and_slide()
	_refresh_barricade_target()

	if hidder_ground_mode:
		return

	if can_attack and _is_player_in_damage_area():
		state = ZombieState.ATTACK
	elif can_attack and _has_attackable_barricade():
		state = ZombieState.ATTACK

func _process_attack(delta: float):
	if hidder_ground_mode:
		state = ZombieState.CHASE
		return

	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 16.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 16.0 * delta)
	if _is_player_in_damage_area():
		_look_at_player()
	elif _has_attackable_barricade():
		_look_at_barricade_target()
	else:
		current_barricade_target = null
		_look_at_player()
	move_and_slide()

	if not _is_player_in_damage_area() and not _has_attackable_barricade():
		if _try_species_ranged_attack():
			state = ZombieState.CHASE
			return
		state = ZombieState.CHASE
		return

	if can_attack:
		_perform_attack()

func _process_hurt(delta: float):
	_apply_gravity(delta)
	velocity.x = move_toward(velocity.x, 0.0, 18.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 18.0 * delta)
	_look_at_player()
	move_and_slide()

func _apply_gravity(delta: float):
	if not is_on_floor():
		velocity.y -= gravity * delta

func _get_behavior_target_position() -> Vector3:
	if not player or not is_instance_valid(player):
		return global_position

	match resolved_behavior_mode:
		"corpse_feeder":
			return _get_feeder_target_position()
		"passive_trigger":
			return _get_passive_target_position()
		"cover_ambush":
			return _get_hidder_target_position()
		_:
			return player.global_position

func _get_feeder_target_position() -> Vector3:
	if _is_player_close_for_trigger(2.5):
		behavior_triggered = true

	if behavior_triggered:
		return player.global_position

	var corpse: Node3D = _find_closest_corpse()
	if corpse:
		return corpse.global_position
	return player.global_position

func _get_passive_target_position() -> Vector3:
	if not behavior_triggered and not _is_player_close_for_trigger(2.8):
		return global_position
	behavior_triggered = true
	return player.global_position

func _get_hidder_target_position() -> Vector3:
	hidder_ground_mode = false

	var cover: Node3D = _find_best_cover_node()
	if cover:
		var cover_pos: Vector3 = cover.global_position
		var away: Vector3 = cover_pos - player.global_position
		away.y = 0.0
		if away.length_squared() <= 0.0001:
			away = Vector3.FORWARD
		else:
			away = away.normalized()
		return cover_pos + away * 1.25

	var ally: Node3D = _find_nearest_live_zombie()
	if ally:
		var ally_pos: Vector3 = ally.global_position
		var away_from_player: Vector3 = ally_pos - player.global_position
		away_from_player.y = 0.0
		if away_from_player.length_squared() <= 0.0001:
			away_from_player = Vector3.FORWARD
		else:
			away_from_player = away_from_player.normalized()
		return ally_pos + away_from_player * 0.8

	hidder_ground_mode = true
	return global_position

func _update_behavior_pose(delta: float):
	if state == ZombieState.DEAD:
		return

	if resolved_behavior_mode == "cover_ambush" and hidder_ground_mode:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, deg_to_rad(72.0), minf(1.0, delta * 8.0))
	elif death_crawl_mode:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, deg_to_rad(42.0), minf(1.0, delta * 8.0))
	else:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, 0.0, minf(1.0, delta * 8.0))

	if part_nodes.has("head") and not bool(missing_parts.get("head", false)):
		var head_node: Node3D = part_nodes["head"]
		var target_head_rotation: Vector3 = base_head_rotation
		var head_wobble_strength: float = float(death_effect_profile.get("head_wobble_strength", 0.0))
		if head_wobble_strength > 0.0:
			var head_wobble_frequency: float = maxf(0.1, float(death_effect_profile.get("head_wobble_frequency", 1.0)))
			death_head_wobble_time += delta * head_wobble_frequency
			target_head_rotation.z += sin(death_head_wobble_time) * head_wobble_strength
		head_node.rotation = head_node.rotation.lerp(target_head_rotation, minf(1.0, delta * 8.0))

func _collect_cover_nodes():
	cover_nodes.clear()
	var current_scene: Node = get_tree().current_scene
	if current_scene == null:
		return

	var nodes: Array = current_scene.find_children("*", "Node3D", true, false)
	for candidate in nodes:
		var node3d: Node3D = candidate as Node3D
		if node3d == null or node3d == self:
			continue
		if node3d.is_in_group("hide_obstacle") or node3d.name.begins_with("Cover"):
			cover_nodes.append(node3d)

func _find_best_cover_node() -> Node3D:
	if cover_nodes.is_empty():
		return null

	var best_node: Node3D = null
	var best_distance: float = INF
	for node in cover_nodes:
		if not is_instance_valid(node):
			continue
		var dist: float = global_position.distance_squared_to(node.global_position)
		if dist < best_distance:
			best_distance = dist
			best_node = node
	return best_node

func _find_nearest_live_zombie() -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = INF
	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node is Node3D:
			var node3d: Node3D = zombie_node
			var dist: float = global_position.distance_squared_to(node3d.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = node3d
	return closest

func _find_closest_corpse() -> Node3D:
	var closest: Node3D = null
	var closest_dist: float = INF
	for corpse_node in get_tree().get_nodes_in_group("zombie_corpse"):
		if corpse_node is Node3D:
			var node3d: Node3D = corpse_node
			if not is_instance_valid(node3d):
				continue
			var dist: float = global_position.distance_squared_to(node3d.global_position)
			if dist < closest_dist:
				closest_dist = dist
				closest = node3d
	return closest

func _is_player_close_for_trigger(distance_limit: float) -> bool:
	if not player or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= distance_limit

func _look_at_player():
	if not player or not is_instance_valid(player):
		return
	_look_at_point(player.global_position)

func _look_at_barricade_target():
	if not _has_attackable_barricade():
		return
	_look_at_point(current_barricade_target.global_position)

func _refresh_barricade_target():
	if _has_attackable_barricade():
		return

	current_barricade_target = null
	for collision_index in range(get_slide_collision_count()):
		var collision: KinematicCollision3D = get_slide_collision(collision_index)
		if collision == null:
			continue
		var collider: Object = collision.get_collider()
		if _is_valid_barricade_target(collider):
			current_barricade_target = collider as Node3D
			return

	if not player or not is_instance_valid(player):
		return

	var player_direction: Vector3 = (player.global_position - global_position)
	player_direction.y = 0.0
	if player_direction.length_squared() <= 0.0001:
		return
	player_direction = player_direction.normalized()

	var best_distance := INF
	for barricade in get_tree().get_nodes_in_group("barricade"):
		if not _is_valid_barricade_target(barricade):
			continue
		var barricade_node: Node3D = barricade as Node3D
		if barricade_node == null:
			continue
		var delta_to_barricade: Vector3 = barricade_node.global_position - global_position
		delta_to_barricade.y = 0.0
		var distance: float = delta_to_barricade.length()
		if distance > 1.95 or distance <= 0.001:
			continue
		var forward_alignment: float = delta_to_barricade.normalized().dot(player_direction)
		if forward_alignment < 0.3 or distance >= best_distance:
			continue
		best_distance = distance
		current_barricade_target = barricade_node

func _is_valid_barricade_target(target: Object) -> bool:
	if target == null or not is_instance_valid(target):
		return false
	if not (target is Node):
		return false
	var target_node: Node = target as Node
	if not target_node.is_in_group("barricade"):
		return false
	if not target_node.has_method("blocks_zombies"):
		return false
	return bool(target_node.call("blocks_zombies"))

func _has_attackable_barricade() -> bool:
	if not _is_valid_barricade_target(current_barricade_target):
		current_barricade_target = null
		return false
	var barricade_position: Vector3 = current_barricade_target.global_position
	barricade_position.y = global_position.y
	return global_position.distance_to(barricade_position) <= 1.95

func _look_at_point(point: Vector3):
	var look_target: Vector3 = Vector3(point.x, global_position.y, point.z)
	if global_position.distance_to(look_target) > 0.1:
		look_at(look_target)

func _is_player_in_damage_area() -> bool:
	for body in damage_area.get_overlapping_bodies():
		if body.is_in_group("player"):
			return true
	return false

func _try_species_ranged_attack() -> bool:
	if not resolved_weapon_affinity_ranged:
		return false
	if not can_attack:
		return false
	if not player or not is_instance_valid(player):
		return false
	if _is_player_in_damage_area():
		return false

	var dist_to_player: float = global_position.distance_to(player.global_position)
	if dist_to_player < 2.0 or dist_to_player > 11.0:
		return false

	if player.has_method("take_damage"):
		var ranged_damage: int = max(1, int(round(float(_get_current_damage()) * 0.7)))
		_play_world_sound("zombie_ranged_attack")
		player.take_damage(ranged_damage)

	_start_attack_cooldown(1.2)
	return true

func _perform_attack():
	var target_damage = _get_current_damage()
	if target_damage <= 0:
		_start_attack_cooldown()
		return

	if _is_player_in_damage_area() and player and is_instance_valid(player) and player.has_method("take_damage"):
		_play_world_sound("zombie_attack")
		player.take_damage(target_damage)
		_apply_touch_effect_on_player()
		_apply_on_attack_self_heal()
		_start_attack_cooldown()
		return

	if _has_attackable_barricade() and current_barricade_target.has_method("take_zombie_damage"):
		_play_world_sound("zombie_barricade_hit")
		current_barricade_target.call("take_zombie_damage", target_damage)
		_start_attack_cooldown(1.05)
		return

	_start_attack_cooldown()

func _get_current_damage() -> int:
	if hidder_ground_mode:
		return 0
	if missing_parts["arm_l"] and missing_parts["arm_r"]:
		return 0

	var result: float = float(resolved_damage)

	if missing_parts["arm_l"]:
		result *= 0.75
	if missing_parts["arm_r"]:
		result *= 0.45

	result += float(death_effect_profile.get("touch_bonus_damage", 0.0))

	if revenge_buff_remaining > 0.0:
		result *= revenge_damage_mult
	if ally_buff_remaining > 0.0:
		result *= 1.05

	var rage_distance: float = float(death_effect_profile.get("rage_close_distance", 0.0))
	if rage_distance > 0.0 and _distance_to_player() <= rage_distance:
		result *= 1.08

	return max(0, int(round(result)))

func _get_current_speed() -> float:
	var speed: float = resolved_speed
	var missing_leg_count: int = 0
	if missing_parts["leg_l"]:
		missing_leg_count += 1
	if missing_parts["leg_r"]:
		missing_leg_count += 1

	if missing_leg_count == 1:
		speed *= 0.65
	elif missing_leg_count >= 2:
		speed *= 0.35

	if resolved_behavior_mode == "passive_trigger" and not behavior_triggered:
		speed *= 0.2

	if death_crawl_mode:
		speed *= 0.45
	if death_stumble_remaining > 0.0:
		speed *= float(death_effect_profile.get("stumble_speed_mult", 1.0))
	if revenge_buff_remaining > 0.0:
		speed *= revenge_speed_mult
	if ally_buff_remaining > 0.0:
		speed *= ally_buff_speed_mult

	var rage_distance: float = float(death_effect_profile.get("rage_close_distance", 0.0))
	if rage_distance > 0.0 and _distance_to_player() <= rage_distance:
		speed *= float(death_effect_profile.get("rage_speed_mult", 1.0))

	return speed

func _process_death_effect_runtime(delta: float):
	if state == ZombieState.DEAD:
		return

	if external_pull_remaining > 0.0:
		external_pull_remaining = maxf(0.0, external_pull_remaining - delta)
	else:
		external_pull_vector = Vector3.ZERO

	if revenge_buff_remaining > 0.0:
		revenge_buff_remaining = maxf(0.0, revenge_buff_remaining - delta)
		if revenge_buff_remaining <= 0.0:
			revenge_speed_mult = 1.0
			revenge_damage_mult = 1.0
			revenge_attack_cooldown_mult = 1.0

	if ally_buff_remaining > 0.0:
		ally_buff_remaining = maxf(0.0, ally_buff_remaining - delta)
		if ally_buff_remaining <= 0.0:
			ally_buff_speed_mult = 1.0
			ally_buff_attack_cooldown_mult = 1.0

	if state == ZombieState.SPAWN_RISE:
		return

	_process_touch_dot(delta)
	_process_aura_dot(delta)
	_process_pulse_damage(delta)
	_process_stumble_cycle(delta)
	_process_ally_pull_emit(delta)
	_process_ally_buff_emit(delta)
	_apply_crawl_transition_if_needed()

func _process_touch_dot(delta: float):
	if death_touch_dot_remaining <= 0.0:
		return

	death_touch_dot_remaining = maxf(0.0, death_touch_dot_remaining - delta)
	death_touch_dot_tick -= delta
	if death_touch_dot_tick > 0.0:
		return

	var tick_interval: float = maxf(0.1, float(death_effect_profile.get("touch_dot_tick_interval", 0.4)))
	death_touch_dot_tick = tick_interval
	_apply_player_damage_float(death_touch_dot_dps * tick_interval)

func _process_aura_dot(delta: float):
	var aura_radius: float = float(death_effect_profile.get("aura_radius", 0.0))
	var aura_dps: float = float(death_effect_profile.get("aura_dps", 0.0))
	if aura_radius <= 0.0 or aura_dps <= 0.0:
		return
	if _distance_to_player() > aura_radius:
		return

	death_aura_tick -= delta
	if death_aura_tick > 0.0:
		return

	var tick_interval: float = maxf(0.1, float(death_effect_profile.get("aura_tick_interval", 0.45)))
	death_aura_tick = tick_interval
	_apply_player_damage_float(aura_dps * tick_interval)

func _process_pulse_damage(delta: float):
	var pulse_interval: float = float(death_effect_profile.get("pulse_interval", 0.0))
	var pulse_radius: float = float(death_effect_profile.get("pulse_radius", 0.0))
	var pulse_damage: float = float(death_effect_profile.get("pulse_damage", 0.0))
	if pulse_interval <= 0.0 or pulse_radius <= 0.0 or pulse_damage <= 0.0:
		return

	death_pulse_tick -= delta
	if death_pulse_tick > 0.0:
		return

	death_pulse_tick = pulse_interval
	if _distance_to_player() <= pulse_radius:
		_apply_player_damage_float(pulse_damage)

func _process_stumble_cycle(delta: float):
	var stumble_interval: float = float(death_effect_profile.get("stumble_interval", 0.0))
	var stumble_duration: float = float(death_effect_profile.get("stumble_duration", 0.0))
	if stumble_interval > 0.0 and stumble_duration > 0.0:
		death_stumble_tick -= delta
		if death_stumble_tick <= 0.0:
			death_stumble_tick = stumble_interval
			death_stumble_remaining = maxf(death_stumble_remaining, stumble_duration)

	if death_stumble_remaining > 0.0:
		death_stumble_remaining = maxf(0.0, death_stumble_remaining - delta)

func _process_ally_pull_emit(delta: float):
	var pull_radius: float = float(death_effect_profile.get("ally_pull_radius", 0.0))
	var pull_strength: float = float(death_effect_profile.get("ally_pull_strength", 0.0))
	var pull_interval: float = float(death_effect_profile.get("ally_pull_interval", 0.65))
	if pull_radius <= 0.0 or pull_strength <= 0.0:
		return

	death_ally_pull_tick -= delta
	if death_ally_pull_tick > 0.0:
		return
	death_ally_pull_tick = maxf(0.15, pull_interval)

	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node.has_method("receive_ally_attraction") and zombie_node is Node3D:
			var ally_node: Node3D = zombie_node
			if global_position.distance_to(ally_node.global_position) <= pull_radius:
				zombie_node.call("receive_ally_attraction", global_position, pull_strength, 0.45)

func _process_ally_buff_emit(delta: float):
	var buff_radius: float = float(death_effect_profile.get("ally_buff_radius", 0.0))
	var buff_interval: float = float(death_effect_profile.get("ally_buff_interval", 0.0))
	if buff_radius <= 0.0 or buff_interval <= 0.0:
		return

	death_ally_buff_tick -= delta
	if death_ally_buff_tick > 0.0:
		return
	death_ally_buff_tick = maxf(0.25, buff_interval)

	var buff_speed_mult: float = float(death_effect_profile.get("ally_buff_speed_mult", 1.0))
	var buff_cd_mult: float = float(death_effect_profile.get("ally_buff_attack_cooldown_mult", 1.0))
	var require_class_id: String = String(death_effect_profile.get("ally_buff_require_death_class_id", ""))
	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node.has_method("apply_external_ally_buff") and zombie_node is Node3D:
			var ally_node: Node3D = zombie_node
			if global_position.distance_to(ally_node.global_position) <= buff_radius:
				zombie_node.call("apply_external_ally_buff", buff_speed_mult, buff_cd_mult, 1.35, require_class_id)

func _apply_player_damage_float(amount: float):
	if amount <= 0.0:
		return
	if not player or not is_instance_valid(player) or not player.has_method("take_damage"):
		return

	dot_damage_buffer += amount
	var damage_int: int = int(floor(dot_damage_buffer))
	if damage_int <= 0:
		return
	dot_damage_buffer -= float(damage_int)
	player.take_damage(damage_int)

func _distance_to_player() -> float:
	if not player or not is_instance_valid(player):
		return INF
	return global_position.distance_to(player.global_position)

func _start_attack_cooldown(multiplier: float = 1.0):
	can_attack = false
	var cooldown: float = maxf(0.16, resolved_attack_cooldown * maxf(0.1, multiplier))
	cooldown *= _get_attack_cooldown_runtime_mult()

	if resolved_attack_cooldown_variance > 0.0:
		var variance_factor: float = 1.0 + randf_range(-resolved_attack_cooldown_variance, resolved_attack_cooldown_variance)
		cooldown *= maxf(0.35, variance_factor)

	attack_timer.start(maxf(0.14, cooldown))

func _get_attack_cooldown_runtime_mult() -> float:
	var mult: float = 1.0
	if revenge_buff_remaining > 0.0:
		mult *= revenge_attack_cooldown_mult
	if ally_buff_remaining > 0.0:
		mult *= ally_buff_attack_cooldown_mult

	var rage_distance: float = float(death_effect_profile.get("rage_close_distance", 0.0))
	if rage_distance > 0.0 and _distance_to_player() <= rage_distance:
		mult *= float(death_effect_profile.get("rage_attack_cooldown_mult", 1.0))

	return maxf(0.18, mult)

func _apply_touch_effect_on_player():
	var dot_duration: float = float(death_effect_profile.get("touch_dot_duration", 0.0))
	var dot_dps: float = float(death_effect_profile.get("touch_dot_dps", 0.0))
	if dot_duration > 0.0 and dot_dps > 0.0:
		death_touch_dot_remaining = maxf(death_touch_dot_remaining, dot_duration)
		death_touch_dot_dps = maxf(death_touch_dot_dps, dot_dps)
		death_touch_dot_tick = 0.0

	var slow_duration: float = float(death_effect_profile.get("contact_slow_duration", 0.0))
	var slow_strength: float = float(death_effect_profile.get("contact_slow_strength", 1.0))
	if slow_duration > 0.0:
		if player and is_instance_valid(player) and player.has_method("apply_movement_slow"):
			player.call("apply_movement_slow", slow_strength, slow_duration)

func _apply_on_attack_self_heal():
	var heal_amount: float = float(death_effect_profile.get("heal_on_attack", 0.0))
	if heal_amount <= 0.0:
		return
	health = min(resolved_health, health + int(round(heal_amount)))

func _apply_death_subtype_burst():
	var radius: float = float(death_effect_profile.get("death_burst_radius", 0.0))
	var base_damage: float = float(death_effect_profile.get("death_burst_damage", 0.0))
	var burst_dot_duration: float = float(death_effect_profile.get("death_burst_dot_duration", 0.0))
	var burst_dot_dps: float = float(death_effect_profile.get("death_burst_dot_dps", 0.0))
	var total_damage: float = base_damage + burst_dot_duration * burst_dot_dps
	if radius <= 0.0 or total_damage <= 0.0:
		return

	if _distance_to_player() <= radius:
		_apply_player_damage_float(total_damage)

	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node is Node3D and zombie_node.has_method("take_damage"):
			var other: Node3D = zombie_node
			if global_position.distance_to(other.global_position) <= radius:
				zombie_node.take_damage(max(1, int(round(total_damage * 0.5))))

func _broadcast_ally_death_event():
	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		if zombie_node == self:
			continue
		if zombie_node.has_method("notify_ally_died"):
			zombie_node.call_deferred("notify_ally_died", global_position)

func notify_ally_died(death_position: Vector3):
	if state == ZombieState.DEAD:
		return
	if not resolved_revenge_bonus:
		return
	if global_position.distance_to(death_position) > float(death_effect_profile.get("revenge_radius", 8.0)):
		return

	revenge_buff_remaining = maxf(revenge_buff_remaining, float(death_effect_profile.get("revenge_duration", 5.0)))
	revenge_speed_mult = maxf(revenge_speed_mult, float(death_effect_profile.get("revenge_speed_mult", 1.15)))
	revenge_damage_mult = maxf(revenge_damage_mult, float(death_effect_profile.get("revenge_damage_mult", 1.2)))
	revenge_attack_cooldown_mult = minf(revenge_attack_cooldown_mult, float(death_effect_profile.get("revenge_attack_cooldown_mult", 0.85)))

func receive_ally_attraction(origin: Vector3, strength: float, duration: float = 0.45):
	if state == ZombieState.DEAD:
		return

	var direction: Vector3 = origin - global_position
	direction.y = 0.0
	if direction.length_squared() <= 0.0001:
		return

	external_pull_vector = direction.normalized() * clampf(strength, 0.0, 2.0)
	external_pull_remaining = maxf(external_pull_remaining, maxf(0.1, duration))

func apply_external_ally_buff(speed_mult: float, attack_cooldown_mult: float, duration: float, require_death_class_id: String = ""):
	if state == ZombieState.DEAD:
		return
	if require_death_class_id != "" and resolved_death_class_key != require_death_class_id:
		return

	ally_buff_remaining = maxf(ally_buff_remaining, maxf(0.1, duration))
	ally_buff_speed_mult = maxf(ally_buff_speed_mult, maxf(0.1, speed_mult))
	ally_buff_attack_cooldown_mult = minf(ally_buff_attack_cooldown_mult, maxf(0.1, attack_cooldown_mult))

func _apply_starting_part_losses():
	var start_missing_parts: int = max(0, int(death_effect_profile.get("start_missing_part_count", 0)))
	if start_missing_parts <= 0:
		return

	var candidates: Array[String] = ["arm_l", "arm_r", "leg_l", "leg_r"]
	candidates.shuffle()
	var remove_count: int = min(start_missing_parts, candidates.size())
	for index in range(remove_count):
		var part_name: String = candidates[index]
		if bool(missing_parts.get(part_name, false)):
			continue
		part_health[part_name] = 0
		_remove_part(part_name)

func _apply_crawl_transition_if_needed():
	if death_crawl_mode:
		return
	if resolved_crawl_transition_threshold <= 0.0:
		return
	if resolved_health <= 0:
		return

	var health_ratio: float = float(health) / float(resolved_health)
	if health_ratio > resolved_crawl_transition_threshold:
		return

	death_crawl_mode = true
	model_root.position = base_model_root_position + Vector3(0.0, -0.28, 0.0)

func _remove_part(part: String):
	missing_parts[part] = true

	if part_nodes.has(part):
		var part_node: Node3D = part_nodes[part]
		part_node.visible = false

	if hitbox_nodes.has(part):
		var hitbox: StaticBody3D = hitbox_nodes[part]
		hitbox.collision_layer = 0
		hitbox.collision_mask = 0
		for child in hitbox.get_children():
			if child is CollisionShape3D:
				child.disabled = true

	if part == "arm_r":
		held_item.visible = false

	if part == "head" and headshot_instant_death:
		die()
		return

func _disable_all_hitboxes():
	for hitbox in hitbox_nodes.values():
		hitbox.collision_layer = 0
		hitbox.collision_mask = 0
		for child in hitbox.get_children():
			if child is CollisionShape3D:
				child.disabled = true

func _enter_hurt_state():
	if state == ZombieState.DEAD:
		return
	if randf() < resolved_pain_resistance:
		return

	_play_world_sound("zombie_hurt")
	state = ZombieState.HURT
	var reduced_hurt_time: float = maxf(0.03, hurt_recovery_time * lerpf(1.0, 0.15, resolved_pain_resistance))
	hurt_timer.start(reduced_hurt_time)

func _on_damage_area_body_entered(body):
	if state == ZombieState.SPAWN_RISE or state == ZombieState.DEAD:
		return
	if hidder_ground_mode:
		return

	if body.is_in_group("player") and can_attack:
		state = ZombieState.ATTACK

func _on_attack_timer_timeout():
	if state == ZombieState.DEAD:
		return

	can_attack = true
	if state == ZombieState.HURT:
		return

	if _is_player_in_damage_area():
		state = ZombieState.ATTACK
	else:
		state = ZombieState.CHASE

func _on_hurt_timer_timeout():
	if state == ZombieState.DEAD:
		return

	if _is_player_in_damage_area():
		state = ZombieState.ATTACK
	else:
		state = ZombieState.CHASE

func _on_corpse_fall_finished():
	set_physics_process(false)
	await get_tree().create_timer(5.0).timeout
	if not is_instance_valid(self):
		return
	var tween = create_tween()
	tween.tween_property(model_root, "scale", Vector3.ZERO, 0.6)
	tween.tween_callback(queue_free)

func _on_idle_sound_timer_timeout() -> void:
	if state == ZombieState.DEAD or state == ZombieState.SPAWN_RISE:
		return
	_play_world_sound("zombie_idle")
	_schedule_idle_sound()

func despawn_immediately():
	if not is_instance_valid(self):
		return
	if idle_sound_timer != null:
		idle_sound_timer.stop()
	var tween = create_tween()
	tween.tween_property(model_root, "scale", Vector3.ZERO, 0.3)
	tween.tween_callback(queue_free)

func _schedule_idle_sound() -> void:
	if idle_sound_timer == null:
		return
	idle_sound_timer.start(profile_rng.randf_range(2.8, 6.5))

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

func _play_world_sound(event_id: String) -> void:
	if event_id.is_empty():
		return
	AudioManager.play_sfx(event_id, global_position, true)
