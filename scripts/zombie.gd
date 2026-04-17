extends CharacterBody3D

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDeathVisualController = preload("res://scripts/zombie_death_visual_controller.gd")
const ZombieDeathEffects = preload("res://scripts/zombie_death_effects.gd")
const ZombieDeathVisuals = preload("res://scripts/zombie_death_visuals.gd")
const ZombieMortVisuals = preload("res://scripts/zombie_mort_visuals.gd")
const ZombieSpeciesVisuals = preload("res://scripts/zombie_species_visuals.gd")

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

@export_category("Jump")
@export var jump_force := 4.8
@export_range(0.2, 2.5, 0.05) var jump_gravity_scale := 1.0
@export_range(0.2, 3.0, 0.05) var fall_gravity_scale := 1.25
@export_range(0.0, 1.0, 0.01) var air_control_multiplier := 0.42
@export_range(0.0, 2.0, 0.01) var jump_cooldown_seconds := 0.45
@export_range(0.0, 1.0, 0.01) var landing_recovery_seconds := 0.08
@export var jump_requires_legs := false
@export var auto_jump_on_obstacle_probe := false
@export_range(0.4, 3.0, 0.05) var jump_obstacle_probe_distance := 1.15
@export_range(0.1, 2.0, 0.05) var jump_obstacle_probe_height := 0.65
@export var debug_jump_once := false
@export var debug_auto_jump_enabled := false
@export_range(0.1, 10.0, 0.1) var debug_auto_jump_interval := 2.2

@export_category("Hidder")
@export_range(2.0, 24.0, 0.1) var hidder_detect_radius := 8.0
@export_range(2.0, 12.0, 0.1) var hidder_attack_radius := 4.4
@export_range(1.0, 3.0, 0.05) var hidder_escape_speed_mult := 1.7
@export_range(0.1, 6.0, 0.1) var hidder_escape_boost_seconds := 1.8
@export_range(0.1, 6.0, 0.1) var hidder_repath_cooldown_seconds := 0.85
@export_range(2.0, 30.0, 0.1) var hidder_min_cover_player_distance := 5.8
@export_range(0.1, 8.0, 0.1) var hidder_aggressive_hold_seconds := 1.4

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
var resolved_jump_profile: Dictionary = {}

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
var hidder_escape_active: bool = false
var hidder_escape_target: Vector3 = Vector3.ZERO
var hidder_escape_boost_remaining: float = 0.0
var hidder_repath_cooldown: float = 0.0
var hidder_aggressive_remaining: float = 0.0
var hidder_current_cover: Node3D = null
var cover_nodes: Array[Node3D] = []
var current_barricade_target: Node3D = null
var is_grounded: bool = false
var is_jumping: bool = false
var is_falling: bool = false
var jump_cooldown_remaining: float = 0.0
var landing_recovery_remaining: float = 0.0
var debug_auto_jump_timer: float = 0.0

var part_health: Dictionary = {}
var missing_parts: Dictionary = {}
var species_visual_profile: Dictionary = {}
var mort_visual_profile: Dictionary = {}
var death_visual_profile: Dictionary = {}
var death_visual_instance: Dictionary = {}
var death_visual_controller: ZombieDeathVisualController = ZombieDeathVisualController.new()

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
var base_model_root_rotation := Vector3.ZERO
var species_base_model_root_position := Vector3.ZERO
var species_base_model_root_rotation := Vector3.ZERO
var profile_rng: RandomNumberGenerator
var visual_base_positions: Dictionary = {}
var visual_base_rotations: Dictionary = {}
var visual_base_scales: Dictionary = {}

var base_part_positions: Dictionary = {}
var base_part_rotations_deg: Dictionary = {}
var base_part_scales: Dictionary = {}
var hitbox_shape_nodes: Dictionary = {}
var base_hitbox_transforms: Dictionary = {}
var base_hitbox_box_sizes: Dictionary = {}
var base_hitbox_sphere_radii: Dictionary = {}
var base_body_collision_radius: float = 0.28
var base_body_collision_height: float = 1.5
var base_body_collision_y: float = 0.75
var base_weapon_socket_position := Vector3.ZERO
var base_weapon_socket_rotation_deg := Vector3.ZERO
var base_weapon_socket_scale := Vector3.ONE
var base_held_item_scale := Vector3.ONE

func _ready():
	randomize()
	add_to_group("zombie")
	player = get_tree().get_first_node_in_group("player")
	limp_phase = randf_range(0.0, TAU)
	base_model_root_position = model_root.position
	base_model_root_rotation = model_root.rotation
	species_base_model_root_position = base_model_root_position
	species_base_model_root_rotation = base_model_root_rotation
	base_head_rotation = part_nodes["head"].rotation
	_capture_visual_base_pose()
	profile_rng = RandomNumberGenerator.new()
	profile_rng.randomize()
	_cache_base_visual_state()

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
	debug_auto_jump_timer = maxf(0.1, debug_auto_jump_interval)
	is_grounded = false
	is_jumping = false
	is_falling = true
	_update_jump_debug_meta()
	state = ZombieState.SPAWN_RISE

func _physics_process(delta):
	_ensure_player_reference()
	_update_jump_runtime_timers(delta)
	_process_jump_debug_trigger()
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

func _ensure_player_reference():
	if player != null and is_instance_valid(player):
		return
	player = get_tree().get_first_node_in_group("player")

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
	resolved_jump_profile = ZombieDefinitions.get_species_jump_profile(species_id)

	var resolved_scale: float = float(profile_data["scale"])
	scale = Vector3.ONE * resolved_scale

	death_effect_profile = ZombieDeathEffects.resolve_runtime_profile(death_subtype_id, profile_rng)
	_apply_death_effect_profile_modifiers()
	_reset_death_effect_runtime_state()

	_apply_mort_visual_profile()
	_apply_species_visual_profile()
	_apply_death_subtype_visual_layer()
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
	set_meta("mort_visual_darkness", float(mort_visual_profile.get("darkness", 0.0)))
	set_meta("mort_visual_tier", String(mort_visual_profile.get("tier_label", "")))
	set_meta("death_visual_mode", String(death_visual_profile.get("visual_mode", ZombieDeathVisuals.VISUAL_MODE_NONE)))
	set_meta("death_visual_color_hex", String(death_visual_profile.get("display_color_hex", "#7a92a1")))
	set_meta("death_visual_intensity", float(death_visual_profile.get("intensity", 0.0)))
	set_meta("death_visual_anchor", String(death_visual_profile.get("spawn_anchor", "torso")))
	set_meta("death_visual_placeholder", bool(death_visual_profile.get("is_placeholder", true)))
	set_meta("jump_species_can_jump", bool(resolved_jump_profile.get("can_jump", true)))
	set_meta("jump_species_force_mult", float(resolved_jump_profile.get("force_mult", 1.0)))
	set_meta("jump_species_cooldown_mult", float(resolved_jump_profile.get("cooldown_mult", 1.0)))

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

func _apply_mort_visual_profile():
	var resolved_mort_grade: int = int(profile_data.get("mort_grade", mort_grade))
	mort_visual_profile = ZombieMortVisuals.get_visual_profile(resolved_mort_grade)

func _apply_death_subtype_visual_layer():
	_clear_death_subtype_visual_layer()
	death_visual_profile = ZombieDeathVisuals.get_visual_profile(death_subtype_id)
	var anchor_map: Dictionary = _build_death_visual_anchor_map()
	death_visual_instance = death_visual_controller.spawn_visual_instance(self, death_visual_profile, anchor_map)
	if death_visual_instance.is_empty():
		return

	var visual_mode: String = String(death_visual_instance.get("mode", ZombieDeathVisuals.VISUAL_MODE_NONE))
	var is_active: bool = bool(death_visual_instance.get("is_active", false))
	var is_placeholder: bool = bool(death_visual_instance.get("is_placeholder", true))

	death_visual_profile["runtime_mode"] = visual_mode
	death_visual_profile["runtime_active"] = is_active
	death_visual_profile["is_placeholder"] = is_placeholder

func _clear_death_subtype_visual_layer():
	if death_visual_instance.is_empty():
		return
	death_visual_controller.clear_instance(death_visual_instance)
	death_visual_instance.clear()

func _build_death_visual_anchor_map() -> Dictionary:
	return {
		"root": model_root,
		"torso": part_nodes.get("torso", model_root),
		"head": part_nodes.get("head", model_root),
		"arm_l": part_nodes.get("arm_l", model_root),
		"arm_r": part_nodes.get("arm_r", model_root)
	}

func _cache_base_visual_state():
	base_part_positions.clear()
	base_part_rotations_deg.clear()
	base_part_scales.clear()
	hitbox_shape_nodes.clear()
	base_hitbox_transforms.clear()
	base_hitbox_box_sizes.clear()
	base_hitbox_sphere_radii.clear()

	for part_key_variant in part_nodes.keys():
		var part_key: String = String(part_key_variant)
		var part_node: Node3D = part_nodes[part_key]
		base_part_positions[part_key] = part_node.position
		base_part_rotations_deg[part_key] = part_node.rotation_degrees
		base_part_scales[part_key] = part_node.scale

	var weapon_socket: Node3D = $ModelRoot/Arm_R/WeaponSocket_R
	base_weapon_socket_position = weapon_socket.position
	base_weapon_socket_rotation_deg = weapon_socket.rotation_degrees
	base_weapon_socket_scale = weapon_socket.scale
	base_held_item_scale = held_item.scale

	for part_key_variant in hitbox_nodes.keys():
		var part_key: String = String(part_key_variant)
		var hitbox: StaticBody3D = hitbox_nodes[part_key]
		var shape_node: CollisionShape3D = _find_hitbox_collision_shape(hitbox)
		if shape_node == null:
			continue

		if shape_node.shape != null:
			shape_node.shape = shape_node.shape.duplicate(true)

		hitbox_shape_nodes[part_key] = shape_node
		base_hitbox_transforms[part_key] = shape_node.transform

		if shape_node.shape is BoxShape3D:
			base_hitbox_box_sizes[part_key] = (shape_node.shape as BoxShape3D).size
		elif shape_node.shape is SphereShape3D:
			base_hitbox_sphere_radii[part_key] = (shape_node.shape as SphereShape3D).radius

	if body_collision.shape != null:
		body_collision.shape = body_collision.shape.duplicate(true)
	if body_collision.shape is CapsuleShape3D:
		var capsule: CapsuleShape3D = body_collision.shape as CapsuleShape3D
		base_body_collision_radius = capsule.radius
		base_body_collision_height = capsule.height
	base_body_collision_y = body_collision.position.y

func _find_hitbox_collision_shape(hitbox: StaticBody3D) -> CollisionShape3D:
	for child in hitbox.get_children():
		if child is CollisionShape3D:
			return child as CollisionShape3D
	return null

func _apply_species_visual_profile():
	species_visual_profile = ZombieSpeciesVisuals.get_species_visual_config(species_id)
	if species_visual_profile.is_empty():
		return

	var model_root_offset: Vector3 = _read_vec3(species_visual_profile, "model_root_offset", Vector3.ZERO)
	var model_root_rotation_deg: Vector3 = _read_vec3(species_visual_profile, "model_root_rotation_deg", Vector3.ZERO)

	species_base_model_root_position = base_model_root_position + model_root_offset
	species_base_model_root_rotation = base_model_root_rotation + Vector3(
		deg_to_rad(model_root_rotation_deg.x),
		deg_to_rad(model_root_rotation_deg.y),
		deg_to_rad(model_root_rotation_deg.z)
	)

	model_root.position = species_base_model_root_position
	model_root.rotation = species_base_model_root_rotation

	_apply_species_part_profile()
	_apply_species_hitbox_profile()
	_apply_species_body_collision_profile()
	_apply_species_placeholder_materials()

	base_head_rotation = part_nodes["head"].rotation

	set_meta("species_visual_template_id", String(species_visual_profile.get("template_id", "default_visual_template")))
	set_meta("species_visual_reference_image", String(species_visual_profile.get("reference_image", "")))
	set_meta("species_visual_silhouette_tags", species_visual_profile.get("silhouette_tags", []))

func _apply_species_part_profile():
	var part_scale_map: Dictionary = species_visual_profile.get("part_scale", {})
	var part_offset_map: Dictionary = species_visual_profile.get("part_offset", {})
	var part_rotation_map: Dictionary = species_visual_profile.get("part_rotation_deg", {})

	for part_key_variant in part_nodes.keys():
		var part_key: String = String(part_key_variant)
		var part_node: Node3D = part_nodes[part_key]
		var base_position: Vector3 = base_part_positions.get(part_key, part_node.position)
		var base_rotation_deg: Vector3 = base_part_rotations_deg.get(part_key, part_node.rotation_degrees)
		var base_scale: Vector3 = base_part_scales.get(part_key, part_node.scale)

		var part_offset: Vector3 = _read_map_vec3(part_offset_map, part_key, Vector3.ZERO)
		var part_rotation_deg: Vector3 = _read_map_vec3(part_rotation_map, part_key, Vector3.ZERO)
		var part_scale: Vector3 = _read_map_vec3(part_scale_map, part_key, Vector3.ONE)

		part_node.position = base_position + part_offset
		part_node.rotation_degrees = base_rotation_deg + part_rotation_deg
		part_node.scale = Vector3(
			base_scale.x * maxf(0.05, part_scale.x),
			base_scale.y * maxf(0.05, part_scale.y),
			base_scale.z * maxf(0.05, part_scale.z)
		)

	var weapon_socket: Node3D = $ModelRoot/Arm_R/WeaponSocket_R
	var weapon_socket_offset: Vector3 = _read_vec3(species_visual_profile, "weapon_socket_offset", Vector3.ZERO)
	var weapon_socket_rotation: Vector3 = _read_vec3(species_visual_profile, "weapon_socket_rotation_deg", Vector3.ZERO)
	var held_item_scale: Vector3 = _read_vec3(species_visual_profile, "held_item_scale", Vector3.ONE)

	weapon_socket.position = base_weapon_socket_position + weapon_socket_offset
	weapon_socket.rotation_degrees = base_weapon_socket_rotation_deg + weapon_socket_rotation
	weapon_socket.scale = base_weapon_socket_scale
	held_item.scale = Vector3(
		base_held_item_scale.x * maxf(0.0, held_item_scale.x),
		base_held_item_scale.y * maxf(0.0, held_item_scale.y),
		base_held_item_scale.z * maxf(0.0, held_item_scale.z)
	)

func _apply_species_hitbox_profile():
	var part_scale_map: Dictionary = species_visual_profile.get("part_scale", {})
	var part_offset_map: Dictionary = species_visual_profile.get("part_offset", {})
	var part_rotation_map: Dictionary = species_visual_profile.get("part_rotation_deg", {})
	var hitbox_scale_map: Dictionary = species_visual_profile.get("hitbox_scale", {})
	var hitbox_offset_map: Dictionary = species_visual_profile.get("hitbox_offset", {})
	var hitbox_rotation_map: Dictionary = species_visual_profile.get("hitbox_rotation_deg", {})

	for part_key_variant in hitbox_shape_nodes.keys():
		var part_key: String = String(part_key_variant)
		var shape_node: CollisionShape3D = hitbox_shape_nodes[part_key]
		var base_transform: Transform3D = base_hitbox_transforms.get(part_key, shape_node.transform)
		shape_node.transform = base_transform

		var offset_from_part: Vector3 = _read_map_vec3(part_offset_map, part_key, Vector3.ZERO)
		var offset_from_hitbox: Vector3 = _read_map_vec3(hitbox_offset_map, part_key, Vector3.ZERO)
		shape_node.position += offset_from_part + offset_from_hitbox

		var rotation_from_part: Vector3 = _read_map_vec3(part_rotation_map, part_key, Vector3.ZERO)
		var rotation_from_hitbox: Vector3 = _read_map_vec3(hitbox_rotation_map, part_key, Vector3.ZERO)
		shape_node.rotation_degrees += rotation_from_part + rotation_from_hitbox

		var shape_scale: Vector3 = _read_map_vec3(hitbox_scale_map, part_key, _read_map_vec3(part_scale_map, part_key, Vector3.ONE))
		if shape_node.shape is BoxShape3D:
			var shape_box: BoxShape3D = shape_node.shape as BoxShape3D
			var base_size: Vector3 = base_hitbox_box_sizes.get(part_key, shape_box.size)
			shape_box.size = Vector3(
				maxf(0.05, base_size.x * maxf(0.05, shape_scale.x)),
				maxf(0.05, base_size.y * maxf(0.05, shape_scale.y)),
				maxf(0.05, base_size.z * maxf(0.05, shape_scale.z))
			)
		elif shape_node.shape is SphereShape3D:
			var shape_sphere: SphereShape3D = shape_node.shape as SphereShape3D
			var base_radius: float = float(base_hitbox_sphere_radii.get(part_key, shape_sphere.radius))
			var avg_scale: float = (shape_scale.x + shape_scale.y + shape_scale.z) / 3.0
			shape_sphere.radius = maxf(0.05, base_radius * maxf(0.1, avg_scale))

func _apply_species_body_collision_profile():
	if not (body_collision.shape is CapsuleShape3D):
		return

	var body_collision_cfg: Dictionary = species_visual_profile.get("body_collision", {})
	var radius_mult: float = maxf(0.5, float(body_collision_cfg.get("radius_mult", 1.0)))
	var height_mult: float = maxf(0.35, float(body_collision_cfg.get("height_mult", 1.0)))
	var y_offset: float = float(body_collision_cfg.get("y_offset", 0.0))

	var capsule: CapsuleShape3D = body_collision.shape as CapsuleShape3D
	capsule.radius = maxf(0.1, base_body_collision_radius * radius_mult)
	capsule.height = maxf(0.35, base_body_collision_height * height_mult)
	body_collision.position.y = base_body_collision_y + y_offset

func _apply_species_placeholder_materials():
	var palette: Dictionary = species_visual_profile.get("palette", {})
	for part_key_variant in part_nodes.keys():
		var part_key: String = String(part_key_variant)
		var part_node: MeshInstance3D = part_nodes[part_key]
		var base_part_color: Color = _read_color_map(palette, part_key, Color(0.2, 0.45, 0.15, 1.0))
		var part_color: Color = ZombieMortVisuals.apply_to_color(base_part_color, mort_visual_profile, 1.0)
		part_node.material_override = _build_placeholder_material(part_color)

	var base_weapon_color: Color = _read_color_map(palette, "weapon", Color(0.18, 0.18, 0.19, 1.0))
	var weapon_color: Color = ZombieMortVisuals.apply_to_color(base_weapon_color, mort_visual_profile, 0.45)
	held_item.material_override = _build_placeholder_material(weapon_color, 0.85)

func _build_placeholder_material(base_color: Color, roughness: float = 0.95) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = base_color
	material.roughness = clampf(roughness, 0.0, 1.0)
	return material

func _read_vec3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if value is Vector3:
		return value
	return fallback

func _read_map_vec3(source: Dictionary, key: String, fallback: Vector3) -> Vector3:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if value is Vector3:
		return value
	return fallback

func _read_color_map(source: Dictionary, key: String, fallback: Color) -> Color:
	if not source.has(key):
		return fallback
	var value: Variant = source[key]
	if value is Color:
		return value
	return fallback

func _apply_visual_variant_placeholder():
	var allowed: Array = profile_data.get("allowed_visual_variants", [ZombieDefinitions.DEFAULT_VISUAL_VARIANT])
	if not allowed.has(visual_variant):
		visual_variant = ZombieDefinitions.DEFAULT_VISUAL_VARIANT
	set_meta("visual_variant", visual_variant)

func _apply_behavior_pose_reset():
	_restore_visual_base_pose()
	model_root.position = species_base_model_root_position
	model_root.rotation = species_base_model_root_rotation
	if resolved_behavior_mode == "low_crawl":
		model_root.position = species_base_model_root_position + Vector3(0.0, -0.35, 0.0)

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
	hidder_escape_active = false
	hidder_escape_target = Vector3.ZERO
	hidder_escape_boost_remaining = 0.0
	hidder_repath_cooldown = 0.0
	hidder_aggressive_remaining = 0.0
	hidder_current_cover = null
	move_direction = Vector3.ZERO
	jump_cooldown_remaining = 0.0
	landing_recovery_remaining = 0.0
	debug_auto_jump_timer = maxf(0.1, debug_auto_jump_interval)
	is_grounded = is_on_floor()
	is_jumping = false
	is_falling = not is_grounded
	_update_jump_debug_meta()

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

func take_part_damage(part: String, amount: int) -> bool:
	if state == ZombieState.DEAD or amount <= 0:
		return false

	if resolved_behavior_mode == "corpse_feeder" or resolved_behavior_mode == "passive_trigger":
		behavior_triggered = true
	elif resolved_behavior_mode == "cover_ambush":
		behavior_triggered = true
		hidder_repath_cooldown = 0.0

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
	_reset_jump_state_on_death()

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
	_reset_jump_state_on_death()
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
	is_grounded = false
	is_jumping = false
	is_falling = true
	rise_elapsed += delta
	var t: float = clampf(rise_elapsed / rise_duration, 0.0, 1.0)
	global_position = rise_start_position.lerp(rise_end_position, t)

	if t >= 1.0:
		body_collision.disabled = false
		damage_area.monitoring = true
		damage_area.monitorable = true
		can_attack = true
		_update_air_state(delta)
		state = ZombieState.CHASE
		_play_world_sound("zombie_spawn")
		_schedule_idle_sound()

func _process_chase(delta: float):
	_apply_gravity(delta)
	if not _is_airborne():
		if _can_request_state_driven_jump():
			request_jump("state_chase")
	if resolved_behavior_mode == "cover_ambush":
		_update_hidder_runtime_state(delta)
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
		if _is_airborne():
			speed *= air_control_multiplier
		velocity.x = walk_direction.x * speed
		velocity.z = walk_direction.z * speed
		_look_at_point(global_position + move_direction)
	else:
		velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
		velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)

	move_and_slide()
	_update_air_state(delta)
	_refresh_barricade_target()

	if hidder_ground_mode:
		return
	if _is_airborne():
		return

	if resolved_behavior_mode == "cover_ambush" and _is_hidder_attack_radius_reached():
		hidder_aggressive_remaining = maxf(hidder_aggressive_remaining, hidder_aggressive_hold_seconds)
		state = ZombieState.ATTACK
		return

	if can_attack and _is_player_in_damage_area():
		state = ZombieState.ATTACK
	elif can_attack and _has_attackable_barricade():
		state = ZombieState.ATTACK

func _process_attack(delta: float):
	if hidder_ground_mode:
		state = ZombieState.CHASE
		return

	if resolved_behavior_mode == "cover_ambush":
		_update_hidder_runtime_state(delta)
		if _is_hidder_attack_radius_reached():
			hidder_aggressive_remaining = maxf(hidder_aggressive_remaining, hidder_aggressive_hold_seconds)

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
	_update_air_state(delta)
	if _is_airborne():
		state = ZombieState.CHASE
		return

	if not _is_player_in_damage_area() and not _has_attackable_barricade():
		if resolved_behavior_mode == "cover_ambush" and hidder_aggressive_remaining > 0.0:
			state = ZombieState.CHASE
			return
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
	_update_air_state(delta)

func _apply_gravity(delta: float):
	if not is_on_floor():
		var gravity_scale: float = fall_gravity_scale
		if velocity.y > 0.0:
			gravity_scale = jump_gravity_scale
		velocity.y -= gravity * gravity_scale * delta
	elif velocity.y < 0.0:
		velocity.y = 0.0

func request_jump(reason: String = "manual") -> bool:
	if not can_jump():
		return false
	_start_jump(reason)
	return true

func request_jump_for_obstacle(_obstacle: Node3D = null) -> bool:
	return request_jump("obstacle_hook")

func can_jump() -> bool:
	if state == ZombieState.DEAD or state == ZombieState.SPAWN_RISE:
		return false
	if jump_cooldown_remaining > 0.0:
		return false
	if landing_recovery_remaining > 0.0:
		return false
	if is_jumping or is_falling:
		return false
	if not is_on_floor() and not is_grounded:
		return false
	var runtime_jump_profile: Dictionary = _get_jump_runtime_profile()
	if not bool(runtime_jump_profile.get("can_jump", true)):
		return false
	if jump_requires_legs and not _has_functional_jump_legs():
		return false
	return true

func _start_jump(reason: String):
	var runtime_jump_profile: Dictionary = _get_jump_runtime_profile()
	is_grounded = false
	is_jumping = true
	is_falling = false
	velocity.y = _get_jump_force()
	var jump_cooldown_mult: float = clampf(float(runtime_jump_profile.get("cooldown_mult", 1.0)), 0.4, 3.0)
	jump_cooldown_remaining = maxf(jump_cooldown_remaining, jump_cooldown_seconds * jump_cooldown_mult)
	set_meta("jump_last_reason", reason)
	set_meta("jump_last_force", velocity.y)

func _update_jump_runtime_timers(delta: float):
	if jump_cooldown_remaining > 0.0:
		jump_cooldown_remaining = maxf(0.0, jump_cooldown_remaining - delta)
	if landing_recovery_remaining > 0.0:
		landing_recovery_remaining = maxf(0.0, landing_recovery_remaining - delta)
	if debug_auto_jump_enabled:
		debug_auto_jump_timer = maxf(0.0, debug_auto_jump_timer - delta)
	else:
		debug_auto_jump_timer = maxf(0.1, debug_auto_jump_interval)

func _process_jump_debug_trigger():
	if state == ZombieState.DEAD or state == ZombieState.SPAWN_RISE:
		return
	if debug_jump_once:
		debug_jump_once = false
		request_jump("debug_once")
		return
	if debug_auto_jump_enabled and debug_auto_jump_timer <= 0.0:
		request_jump("debug_auto")
		debug_auto_jump_timer = maxf(0.1, debug_auto_jump_interval)

func _can_request_state_driven_jump() -> bool:
	if not auto_jump_on_obstacle_probe:
		return false
	return _has_jumpable_obstacle_ahead()

func _update_air_state(_delta: float):
	var on_floor_now: bool = is_on_floor()
	if on_floor_now:
		if not is_grounded and (is_jumping or is_falling):
			_handle_landing()
		is_grounded = true
		is_jumping = false
		is_falling = false
	else:
		if is_grounded:
			is_grounded = false
		if velocity.y > 0.02:
			is_jumping = true
			is_falling = false
		else:
			is_jumping = false
			is_falling = true
	_update_jump_debug_meta()

func _handle_landing():
	is_grounded = true
	is_jumping = false
	is_falling = false
	landing_recovery_remaining = maxf(landing_recovery_remaining, landing_recovery_seconds)

func _is_airborne() -> bool:
	return is_jumping or is_falling or (not is_on_floor() and not is_grounded)

func _get_jump_force() -> float:
	return maxf(0.2, jump_force * _get_jump_force_multiplier())

func _get_jump_force_multiplier() -> float:
	var runtime_jump_profile: Dictionary = _get_jump_runtime_profile()
	return clampf(float(runtime_jump_profile.get("force_mult", 1.0)), 0.0, 1.6)

func _get_jump_runtime_profile() -> Dictionary:
	var leg_state: Dictionary = _build_current_leg_jump_state()
	return ZombieDefinitions.build_jump_runtime_profile(species_id, rank_id, mort_grade, leg_state)

func _build_current_leg_jump_state() -> Dictionary:
	var max_left: float = float(PART_MAX_HEALTH.get("leg_l", 35))
	var max_right: float = float(PART_MAX_HEALTH.get("leg_r", 35))
	var current_left: float = float(part_health.get("leg_l", max_left))
	var current_right: float = float(part_health.get("leg_r", max_right))
	var left_missing: bool = bool(missing_parts.get("leg_l", false))
	var right_missing: bool = bool(missing_parts.get("leg_r", false))
	var left_damaged: bool = (not left_missing) and current_left < max_left * 0.6
	var right_damaged: bool = (not right_missing) and current_right < max_right * 0.6
	return {
		"leg_l_missing": left_missing,
		"leg_r_missing": right_missing,
		"leg_l_damaged": left_damaged,
		"leg_r_damaged": right_damaged
	}

func _has_functional_jump_legs() -> bool:
	if missing_parts.is_empty():
		return true
	var left_missing: bool = bool(missing_parts.get("leg_l", false))
	var right_missing: bool = bool(missing_parts.get("leg_r", false))
	return not (left_missing and right_missing)

func _update_jump_debug_meta():
	var runtime_jump_profile: Dictionary = _get_jump_runtime_profile()
	set_meta("jump_grounded", is_grounded)
	set_meta("jump_is_jumping", is_jumping)
	set_meta("jump_is_falling", is_falling)
	set_meta("jump_cooldown_remaining", jump_cooldown_remaining)
	set_meta("jump_landing_recovery_remaining", landing_recovery_remaining)
	set_meta("jump_runtime_can_jump", bool(runtime_jump_profile.get("can_jump", true)))
	set_meta("jump_runtime_force_mult", float(runtime_jump_profile.get("force_mult", 1.0)))
	set_meta("jump_runtime_cooldown_mult", float(runtime_jump_profile.get("cooldown_mult", 1.0)))
	set_meta("jump_runtime_willingness", float(runtime_jump_profile.get("willingness", 1.0)))

func _reset_jump_state_on_death():
	is_grounded = false
	is_jumping = false
	is_falling = false
	jump_cooldown_remaining = 0.0
	landing_recovery_remaining = 0.0
	debug_auto_jump_timer = maxf(0.1, debug_auto_jump_interval)
	_update_jump_debug_meta()

func _has_jumpable_obstacle_ahead() -> bool:
	if get_world_3d() == null:
		return false
	var probe_direction: Vector3 = _get_jump_probe_direction()
	if probe_direction == Vector3.ZERO:
		return false

	var origin: Vector3 = global_position + Vector3.UP * jump_obstacle_probe_height
	var target: Vector3 = origin + probe_direction * jump_obstacle_probe_distance
	var query := PhysicsRayQueryParameters3D.create(origin, target)
	query.exclude = [self]
	query.collide_with_areas = false
	query.collide_with_bodies = true
	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return false

	var collider: Variant = hit.get("collider")
	if collider is Node:
		var hit_node: Node = collider
		if hit_node.is_in_group("jumpable_candidate"):
			return true
		if hit_node.get_parent() != null and hit_node.get_parent().is_in_group("jumpable_candidate"):
			return true
		if hit_node.get_parent() != null and hit_node.get_parent().get_parent() != null:
			var parent2: Node = hit_node.get_parent().get_parent()
			if parent2.is_in_group("jumpable_candidate"):
				return true
	return false

func _get_jump_probe_direction() -> Vector3:
	if move_direction != Vector3.ZERO:
		return move_direction.normalized()
	var planar_velocity: Vector3 = Vector3(velocity.x, 0.0, velocity.z)
	if planar_velocity.length_squared() > 0.01:
		return planar_velocity.normalized()
	if player and is_instance_valid(player):
		var to_player: Vector3 = player.global_position - global_position
		to_player.y = 0.0
		if to_player.length_squared() > 0.01:
			return to_player.normalized()
	return Vector3.ZERO

func _get_behavior_target_position() -> Vector3:
	if not player or not is_instance_valid(player):
		return global_position

	# Player-Tracking ist fuer alle Arten dauerhaft aktiv, ausser Hidder.
	if resolved_behavior_mode == "cover_ambush":
		return _get_hidder_target_position()

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
	if _is_hidder_attack_radius_reached():
		hidder_aggressive_remaining = maxf(hidder_aggressive_remaining, hidder_aggressive_hold_seconds)

	if hidder_aggressive_remaining > 0.0:
		hidder_escape_active = false
		return player.global_position

	if _is_hidder_detected():
		_trigger_hidder_escape()

	if hidder_escape_active:
		return hidder_escape_target

	var cover_target: Dictionary = _resolve_hidder_cover_target(false)
	if bool(cover_target.get("valid", false)):
		hidder_current_cover = cover_target.get("cover", null)
		return cover_target.get("position", global_position)

	var ally_target: Dictionary = _resolve_hidder_ally_target_position()
	if bool(ally_target.get("valid", false)):
		return ally_target.get("position", global_position)

	hidder_ground_mode = true
	return global_position

func _update_hidder_runtime_state(delta: float):
	if hidder_escape_boost_remaining > 0.0:
		hidder_escape_boost_remaining = maxf(0.0, hidder_escape_boost_remaining - delta)
	if hidder_repath_cooldown > 0.0:
		hidder_repath_cooldown = maxf(0.0, hidder_repath_cooldown - delta)

	if hidder_aggressive_remaining > 0.0:
		if _is_hidder_attack_radius_reached():
			hidder_aggressive_remaining = hidder_aggressive_hold_seconds
		else:
			hidder_aggressive_remaining = maxf(0.0, hidder_aggressive_remaining - delta)

	if hidder_escape_active and global_position.distance_to(hidder_escape_target) <= 0.9:
		hidder_escape_active = false

func _is_hidder_detected() -> bool:
	if not player or not is_instance_valid(player):
		return false
	if behavior_triggered:
		return true
	if _is_hidder_attack_radius_reached():
		return true
	if _is_player_close_for_trigger(hidder_detect_radius):
		return true
	return _hidder_has_player_line_of_sight()

func _is_hidder_attack_radius_reached() -> bool:
	if not player or not is_instance_valid(player):
		return false
	return global_position.distance_to(player.global_position) <= hidder_attack_radius

func _trigger_hidder_escape():
	if hidder_repath_cooldown > 0.0 and hidder_escape_active:
		return

	var cover_target: Dictionary = _resolve_hidder_cover_target(true)
	if bool(cover_target.get("valid", false)):
		hidder_escape_target = cover_target.get("position", global_position)
		hidder_current_cover = cover_target.get("cover", null)
		hidder_escape_active = true
		hidder_escape_boost_remaining = maxf(hidder_escape_boost_remaining, hidder_escape_boost_seconds)
		hidder_repath_cooldown = hidder_repath_cooldown_seconds
		return

	var ally_target: Dictionary = _resolve_hidder_ally_target_position()
	if bool(ally_target.get("valid", false)):
		hidder_escape_target = ally_target.get("position", global_position)
		hidder_escape_active = true
		hidder_escape_boost_remaining = maxf(hidder_escape_boost_remaining, hidder_escape_boost_seconds)
		hidder_repath_cooldown = hidder_repath_cooldown_seconds
		return

	hidder_escape_active = false

func _resolve_hidder_cover_target(exclude_current_cover: bool) -> Dictionary:
	if not player or not is_instance_valid(player):
		return {"valid": false}

	var best_cover: Node3D = null
	var best_target: Vector3 = Vector3.ZERO
	var best_score: float = -INF
	var can_exclude: bool = exclude_current_cover and cover_nodes.size() > 1

	for node in cover_nodes:
		if not is_instance_valid(node):
			continue
		if can_exclude and node == hidder_current_cover:
			continue

		var candidate_target: Vector3 = _get_hidder_position_behind_cover(node)
		var distance_to_player: float = candidate_target.distance_to(player.global_position)
		if distance_to_player < hidder_min_cover_player_distance:
			continue

		var distance_to_self: float = candidate_target.distance_to(global_position)
		var score: float = distance_to_player * 1.35 - distance_to_self * 0.4
		if score > best_score:
			best_score = score
			best_cover = node
			best_target = candidate_target

	if best_cover == null:
		var fallback_cover: Node3D = _find_best_cover_node()
		if fallback_cover != null and (not can_exclude or fallback_cover != hidder_current_cover):
			best_cover = fallback_cover
			best_target = _get_hidder_position_behind_cover(fallback_cover)

	if best_cover == null:
		return {"valid": false}

	return {
		"valid": true,
		"cover": best_cover,
		"position": best_target
	}

func _resolve_hidder_ally_target_position() -> Dictionary:
	if not player or not is_instance_valid(player):
		return {"valid": false}

	var ally: Node3D = _find_nearest_live_zombie()
	if ally == null:
		return {"valid": false}

	var ally_pos: Vector3 = ally.global_position
	var away_from_player: Vector3 = ally_pos - player.global_position
	away_from_player.y = 0.0
	if away_from_player.length_squared() <= 0.0001:
		away_from_player = Vector3.FORWARD
	else:
		away_from_player = away_from_player.normalized()

	return {
		"valid": true,
		"position": ally_pos + away_from_player * 1.1
	}

func _get_hidder_position_behind_cover(cover: Node3D) -> Vector3:
	var cover_pos: Vector3 = cover.global_position
	var away: Vector3 = cover_pos - player.global_position
	away.y = 0.0
	if away.length_squared() <= 0.0001:
		away = Vector3.FORWARD
	else:
		away = away.normalized()
	return cover_pos + away * 1.25

func _hidder_has_player_line_of_sight() -> bool:
	if not player or not is_instance_valid(player):
		return false
	if get_world_3d() == null:
		return false

	var from: Vector3 = global_position + Vector3(0.0, 1.0, 0.0)
	var to: Vector3 = player.global_position + Vector3(0.0, 1.0, 0.0)
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.collide_with_areas = false
	query.collide_with_bodies = true
	query.exclude = [self]

	var hit: Dictionary = get_world_3d().direct_space_state.intersect_ray(query)
	if hit.is_empty():
		return true

	var collider: Variant = hit.get("collider")
	if collider == player:
		return true
	if collider is Node and (collider as Node).is_in_group("player"):
		return true
	return false

func _update_behavior_pose(delta: float):
	if state == ZombieState.DEAD:
		return

	if resolved_behavior_mode == "cover_ambush" and hidder_ground_mode:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, deg_to_rad(72.0), minf(1.0, delta * 8.0))
	elif death_crawl_mode:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, deg_to_rad(42.0), minf(1.0, delta * 8.0))
	else:
		model_root.rotation.x = lerp_angle(model_root.rotation.x, species_base_model_root_rotation.x, minf(1.0, delta * 8.0))

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
		if not _is_force_global_chase_for_this_zombie():
			speed *= 0.2
	elif resolved_behavior_mode == "cover_ambush":
		if hidder_escape_boost_remaining > 0.0:
			speed *= hidder_escape_speed_mult
		elif hidder_aggressive_remaining > 0.0:
			speed *= 1.12

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

func _is_force_global_chase_for_this_zombie() -> bool:
	return resolved_behavior_mode != "cover_ambush"

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
	model_root.position = species_base_model_root_position + Vector3(0.0, -0.28, 0.0)

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
	if _is_airborne():
		return
	if hidder_ground_mode and resolved_behavior_mode != "cover_ambush":
		return

	if body.is_in_group("player") and can_attack:
		if resolved_behavior_mode == "cover_ambush":
			hidder_ground_mode = false
			hidder_aggressive_remaining = maxf(hidder_aggressive_remaining, hidder_aggressive_hold_seconds)
		state = ZombieState.ATTACK

func _on_attack_timer_timeout():
	if state == ZombieState.DEAD:
		return

	can_attack = true
	if state == ZombieState.HURT:
		return

	if _is_airborne():
		state = ZombieState.CHASE
		return

	if (resolved_behavior_mode == "cover_ambush" and _is_hidder_attack_radius_reached()) or _is_player_in_damage_area():
		state = ZombieState.ATTACK
	else:
		state = ZombieState.CHASE

func _on_hurt_timer_timeout():
	if state == ZombieState.DEAD:
		return

	if _is_airborne():
		state = ZombieState.CHASE
		return

	if (resolved_behavior_mode == "cover_ambush" and _is_hidder_attack_radius_reached()) or _is_player_in_damage_area():
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

func _exit_tree():
	_clear_death_subtype_visual_layer()
