extends CharacterBody3D

const WeaponDefinitions = preload("res://scripts/player/weapon_definitions.gd")
const WeaponLoadout = preload("res://scripts/player/weapon_loadout.gd")
const ItemDefinitions = preload("res://scripts/player/item_definitions.gd")
const ItemInventory = preload("res://scripts/player/item_inventory.gd")
const PlayerProgression = preload("res://scripts/player/player_progression.gd")
const GrenadeProjectileScene: PackedScene = preload("res://scenes/projectiles/grenade_projectile.tscn")
const CAMERA_FIRST_PERSON := "first_person"
const CAMERA_THIRD_PERSON := "third_person"

signal shot_feedback(hit)
signal kill_feedback()
signal reload_feedback(message, color)
signal damage_feedback(amount, direction)
signal combat_text_feedback(message, color)
signal inventory_changed(items_state)
signal currency_changed(points)
signal armor_changed(current_armor, max_armor_value)
signal unlock_feedback(unlock_type, unlock_id, display_name)

const WEAPON_SLOT_COUNT := 2
const DEFAULT_LOADOUT: Array[String] = ["pistol", "rifle"]
const INTERACTION_PROMPT_COLOR := Color(0.62, 0.88, 1.0, 1.0)
const POSITIVE_STATUS_COLOR := Color(0.45, 1.0, 0.55, 1.0)
const WARNING_STATUS_COLOR := Color(1.0, 0.8, 0.35, 1.0)
const ERROR_STATUS_COLOR := Color(1.0, 0.35, 0.35, 1.0)
const INFO_STATUS_COLOR := Color(0.96, 0.96, 1.0, 1.0)

@export_category("Movement")
@export var SPEED := 5.0
@export var ACCEL := 50.0
@export var IN_AIR_SPEED := 3.0
@export var IN_AIR_ACCEL := 5.0
@export var JUMP_VELOCITY := 4.5

@export_category("Sprint")
@export var sprint_speed_multiplier := 1.65
@export var sprint_accel_multiplier := 1.15
@export var sprint_fov_boost := 4.5

@export_category("Crouch")
@export var crouch_speed_multiplier := 0.58
@export var crouch_capsule_height := 1.0
@export var crouch_head_height_offset := 0.52
@export var crouch_transition_speed := 10.0

@export_category("Third Person")
@export var third_person_camera_fov := 78.0
@export var third_person_shoulder_offset := 0.58
@export var third_person_pitch_weight := 0.28

@export_category("Head Bob")
@export var HEAD_BOB := true
@export var HEAD_BOB_FREQUENCY := 0.3
@export var HEAD_BOB_AMPLITUDE := 0.01

@export_category("Mouse")
@export var MOUSE_SENS := 0.005
@export var MOUSE_ACCEL := true
@export var MOUSE_ACCEL_SPEED := 50.0
@export var CLAMP_HEAD_ROTATION_MIN := -90.0
@export var CLAMP_HEAD_ROTATION_MAX := 90.0

@export_category("Interaction")
@export var interaction_distance := 3.6

@export_category("Camera Feedback")
@export var camera_fov_lerp_speed := 8.0
@export var fire_fov_kick_amount := 0.65
@export var fire_fov_kick_recovery_speed := 6.5
@export var gun_kick_recovery_speed := 14.0

@export_category("Health")
@export var max_health := 100
@export var max_armor := 100
@export var damage_shake_strength := 0.09
@export var damage_shake_duration := 0.18

@export_category("Economy")
@export var points_per_hit := 10
@export var points_per_kill := 100
@export var points_per_headshot_kill := 50

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed := 0.0
var accel := 0.0
var rotation_target_player := 0.0
var rotation_target_head := 0.0
var head_start_pos := Vector3.ZERO
var base_gun_model_position := Vector3.ZERO
var base_camera_fov := 75.0
var bob_time := 0.0
var progression: PlayerProgression
var weapon_loadout: WeaponLoadout
var item_inventory: ItemInventory
var health := 0
var armor := 0
var ammo := 0
var reserve_ammo := 0
var can_shoot := true
var is_reloading := false
var is_sprinting := false
var fire_timer: Timer
var reload_timer: Timer
var damage_shake_timer := 0.0
var damage_shake_amount := 0.0
var current_weapon_index := 0
var weapon_name := ""
var max_ammo := 0
var current_weapon_data := {}
var is_weapon_automatic := false
var shots_fired := 0
var shots_hit := 0
var kills := 0
var headshots := 0
var points := 0
var last_kill_time_ms := -100000
var kill_streak_count := 0
var speed_ratio := 0.0
var last_interaction_target_id := -1
var last_interaction_prompt := ""
var weapon_bloom_ratio := 0.0
var recoil_pitch_offset := 0.0
var recoil_yaw_offset := 0.0
var current_fov_kick := 0.0
var gun_kick_offset := Vector3.ZERO
var current_bloom := 0.0
var fire_input_active_this_frame := false
var highlighted_interaction_target: Node = null
var movement_slow_multiplier := 1.0
var movement_slow_remaining := 0.0
var movement_slow_active := false
var active_camera_mode: String = CAMERA_FIRST_PERSON
var is_crouching: bool = false
var crouch_requested: bool = false
var standing_capsule_height: float = 0.0
var standing_collision_y: float = 0.0
var crouch_collision_y: float = 0.0
var standing_head_y: float = 0.0
var crouched_head_y: float = 0.0
var visual_anim_time: float = 0.0

@onready var player_collision: CollisionShape3D = $CollisionShape3D
@onready var player_capsule: CapsuleShape3D = $CollisionShape3D.shape as CapsuleShape3D
@onready var head: Node3D = $Head
@onready var first_person_camera: Camera3D = $Head/Camera3D
@onready var third_person_pivot: Node3D = $Head/ThirdPersonPivot
@onready var third_person_arm: SpringArm3D = $Head/ThirdPersonPivot/SpringArm3D
@onready var third_person_camera: Camera3D = $Head/ThirdPersonPivot/SpringArm3D/ThirdPersonCamera
@onready var gun_model: MeshInstance3D = $Head/GunModel
@onready var visual_root: Node3D = $VisualRoot
@onready var model_root: Node3D = $VisualRoot/ModelRoot
@onready var model_spine: Node3D = $VisualRoot/ModelRoot/Spine
@onready var model_neck: Node3D = $VisualRoot/ModelRoot/Spine/Neck
@onready var left_arm: Node3D = $VisualRoot/ModelRoot/LeftArm
@onready var right_arm: Node3D = $VisualRoot/ModelRoot/RightArm
@onready var left_leg: Node3D = $VisualRoot/ModelRoot/LeftLeg
@onready var right_leg: Node3D = $VisualRoot/ModelRoot/RightLeg

func _ready() -> void:
	health = max_health
	progression = PlayerProgression.new()
	weapon_loadout = WeaponLoadout.new()
	weapon_loadout.initialize(DEFAULT_LOADOUT)
	item_inventory = ItemInventory.new()
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_start_pos = head.position
	base_gun_model_position = gun_model.position
	base_camera_fov = first_person_camera.fov
	standing_capsule_height = player_capsule.height
	standing_collision_y = player_collision.transform.origin.y
	crouch_collision_y = standing_collision_y - ((standing_capsule_height - crouch_capsule_height) * 0.5)
	standing_head_y = head.position.y
	crouched_head_y = standing_head_y - crouch_head_height_offset
	third_person_pivot.position.x = third_person_shoulder_offset
	third_person_camera.fov = third_person_camera_fov
	_set_camera_mode(CAMERA_FIRST_PERSON)
	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)
	reload_timer = Timer.new()
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(reload_timer)
	$Head/InteractionRayCast3D.target_position = Vector3(0, 0, -interaction_distance)
	_sync_current_weapon_view(true)
	item_inventory.ensure_selected_item(_get_unlocked_item_ids())
	_update_visual_model(0.0)
	_emit_runtime_state()

func _physics_process(delta: float) -> void:
	_update_movement_slow(delta)
	if Input.is_action_just_pressed("toggle_camera"):
		toggle_camera_mode()
	if Input.is_action_just_pressed("crouch"):
		crouch_requested = not crouch_requested
	if crouch_requested and not is_crouching:
		is_crouching = true
	elif not crouch_requested and is_crouching and _can_exit_crouch():
		is_crouching = false
	_update_crouch_pose(delta)
	fire_input_active_this_frame = _should_fire_this_frame()
	move_player(delta)
	rotate_player(delta)
	_update_weapon_feedback(delta)
	update_damage_shake(delta)
	if HEAD_BOB:
		if Vector2(velocity.x, velocity.z).length() > 0.05 and is_on_floor():
			head_bob_motion(delta)
		else:
			reset_head_bob(delta)
	if fire_input_active_this_frame:
		shoot()
	if Input.is_action_just_pressed("reload"):
		reload_weapon()
	if Input.is_action_just_pressed("weapon_slot_1"):
		switch_weapon(0)
	elif Input.is_action_just_pressed("weapon_slot_2"):
		switch_weapon(1)
	elif Input.is_action_just_pressed("weapon_next"):
		switch_weapon((current_weapon_index + 1) % WEAPON_SLOT_COUNT)
	elif Input.is_action_just_pressed("weapon_prev"):
		switch_weapon(posmod(current_weapon_index - 1, WEAPON_SLOT_COUNT))
	if Input.is_action_just_pressed("item_next"):
		cycle_selected_item(1)
	elif Input.is_action_just_pressed("item_prev"):
		cycle_selected_item(-1)
	if Input.is_action_just_pressed("interact"):
		interact_with_target()
	if Input.is_action_just_pressed("use_item"):
		use_item()
	_update_visual_model(delta)
	update_interaction_prompt()

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_target_player += -event.relative.x * MOUSE_SENS
		rotation_target_head += -event.relative.y * MOUSE_SENS
		rotation_target_head = clamp(rotation_target_head, deg_to_rad(CLAMP_HEAD_ROTATION_MIN), deg_to_rad(CLAMP_HEAD_ROTATION_MAX))
	if event is InputEventMouseButton and event.pressed and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func rotate_player(delta: float) -> void:
	var player_target := rotation_target_player + recoil_yaw_offset
	var head_target := rotation_target_head + recoil_pitch_offset
	if MOUSE_ACCEL:
		quaternion = quaternion.slerp(Quaternion(Vector3.UP, player_target), MOUSE_ACCEL_SPEED * delta)
		$Head.quaternion = $Head.quaternion.slerp(Quaternion(Vector3.RIGHT, head_target), MOUSE_ACCEL_SPEED * delta)
	else:
		quaternion = Quaternion(Vector3.UP, player_target)
		$Head.quaternion = Quaternion(Vector3.RIGHT, head_target)

func move_player(delta: float) -> void:
	var movement_multiplier: float = movement_slow_multiplier
	if not is_on_floor():
		speed = IN_AIR_SPEED * movement_multiplier
		accel = IN_AIR_ACCEL
		is_sprinting = false
		velocity.y -= gravity * delta
	else:
		speed = SPEED * movement_multiplier
		accel = ACCEL
		var input_dir_length := Input.get_vector("move_left", "move_right", "move_forward", "move_back").length()
		is_sprinting = input_dir_length > 0.0 and Input.is_action_pressed("sprint") and not fire_input_active_this_frame and not is_reloading and not is_crouching
		if is_crouching:
			speed *= crouch_speed_multiplier
			accel *= 0.9
		if is_sprinting:
			speed *= sprint_speed_multiplier
			accel *= sprint_accel_multiplier
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	speed_ratio = clampf(Vector2(velocity.x, velocity.z).length() / maxf(SPEED * sprint_speed_multiplier, 0.001), 0.0, 1.0)
	move_and_slide()

func shoot() -> void:
	if is_reloading or not can_shoot:
		return
	if ammo <= 0:
		shot_feedback.emit(false)
		reload_feedback.emit("EMPTY", ERROR_STATUS_COLOR)
		return
	var was_sprinting := is_sprinting
	is_sprinting = false
	can_shoot = false
	weapon_loadout.consume_current_shot()
	_sync_current_weapon_view(false)
	var shot_result: Dictionary = _apply_damage_events(_perform_weapon_shot(was_sprinting), true)
	_apply_fire_feedback(was_sprinting)
	shot_feedback.emit(bool(shot_result.get("hit", false)))
	fire_timer.start(float(current_weapon_data.get("fire_rate", 0.1)))

func reload_weapon() -> void:
	if is_reloading or not weapon_loadout.can_reload_current():
		return
	is_sprinting = false
	is_reloading = true
	can_shoot = false
	reload_feedback.emit("RELOADING", WARNING_STATUS_COLOR)
	reload_timer.start(float(current_weapon_data.get("reload_time", 1.0)))

func switch_weapon(next_index: int) -> void:
	if next_index < 0 or next_index >= weapon_loadout.get_slot_count() or next_index == current_weapon_index:
		return
	if is_reloading:
		is_reloading = false
		reload_timer.stop()
	weapon_loadout.set_current_slot(next_index)
	can_shoot = true
	_sync_current_weapon_view(true)
	reload_feedback.emit("%s READY" % weapon_name.to_upper(), WARNING_STATUS_COLOR)
	combat_text_feedback.emit(_get_weapon_mode_text(), INFO_STATUS_COLOR)

func get_reload_progress() -> float:
	var reload_time: float = float(current_weapon_data.get("reload_time", 0.0))
	if not is_reloading or reload_time <= 0.0:
		return 0.0
	return clampf((reload_time - reload_timer.time_left) / reload_time, 0.0, 1.0)

func get_current_weapon_id() -> String:
	return weapon_loadout.get_current_weapon_id()

func get_current_weapon_upgrade_tier() -> int:
	return weapon_loadout.get_current_upgrade_tier()

func _on_fire_timer_timeout() -> void:
	can_shoot = not is_reloading

func _on_reload_timer_timeout() -> void:
	weapon_loadout.finish_reload_current()
	is_reloading = false
	can_shoot = true
	_sync_current_weapon_view(false)
	reload_feedback.emit("READY", POSITIVE_STATUS_COLOR)

func interact_with_target() -> void:
	var target: Object = _get_interactable_target()
	if target != null:
		target.call("interact", self)

func cycle_selected_item(step: int) -> void:
	var item_id: String = item_inventory.cycle_selection(step, _get_unlocked_item_ids())
	if item_id.is_empty():
		reload_feedback.emit("NO ITEM UNLOCKED", WARNING_STATUS_COLOR)
		return
	reload_feedback.emit("ITEM %s" % ItemDefinitions.get_display_name(item_id).to_upper(), INFO_STATUS_COLOR)
	_emit_inventory_changed()

func use_item() -> void:
	var item_id: String = item_inventory.ensure_selected_item(_get_unlocked_item_ids())
	if item_id.is_empty():
		reload_feedback.emit("NO ITEM", ERROR_STATUS_COLOR)
		return
	if item_inventory.get_count(item_id) <= 0:
		reload_feedback.emit("%s EMPTY" % ItemDefinitions.get_display_name(item_id).to_upper(), ERROR_STATUS_COLOR)
		_emit_inventory_changed()
		return
	var item_data := ItemDefinitions.get_item_data(item_id)
	match String(item_data.get("effect_type", "")):
		"heal":
			if health >= max_health:
				reload_feedback.emit("HEALTH FULL", WARNING_STATUS_COLOR)
				return
			item_inventory.consume_item(item_id)
			var previous_health := health
			health = mini(health + int(item_data.get("effect_value", 0)), max_health)
			reload_feedback.emit("USED MEDKIT", POSITIVE_STATUS_COLOR)
			combat_text_feedback.emit("+%d HP" % (health - previous_health), POSITIVE_STATUS_COLOR)
		"armor":
			if armor >= max_armor:
				reload_feedback.emit("ARMOR FULL", WARNING_STATUS_COLOR)
				return
			item_inventory.consume_item(item_id)
			var previous_armor := armor
			armor = mini(armor + int(item_data.get("effect_value", 0)), max_armor)
			reload_feedback.emit("ARMOR RESTORED", POSITIVE_STATUS_COLOR)
			combat_text_feedback.emit("+%d ARM" % (armor - previous_armor), INFO_STATUS_COLOR)
			armor_changed.emit(armor, max_armor)
		"grenade":
			item_inventory.consume_item(item_id)
			_throw_grenade()
			reload_feedback.emit("GRENADE OUT", POSITIVE_STATUS_COLOR)
	_emit_inventory_changed()

func toggle_camera_mode() -> void:
	_set_camera_mode(CAMERA_THIRD_PERSON if active_camera_mode == CAMERA_FIRST_PERSON else CAMERA_FIRST_PERSON)
	show_runtime_status("CAMERA %s" % ("TP" if active_camera_mode == CAMERA_THIRD_PERSON else "FP"), "info", true)

func get_camera_mode() -> String:
	return active_camera_mode

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO) -> void:
	var incoming_damage := maxi(amount, 0)
	if incoming_damage <= 0:
		return
	var remaining_damage := incoming_damage
	if armor > 0:
		var absorbed := mini(armor, remaining_damage)
		armor -= absorbed
		remaining_damage -= absorbed
		armor_changed.emit(armor, max_armor)
	if remaining_damage > 0:
		health = max(0, health - remaining_damage)
	damage_shake_timer = damage_shake_duration
	damage_shake_amount = damage_shake_strength
	var direction: Vector2 = Vector2.ZERO
	var resolved_source_position: Vector3 = source_position
	if resolved_source_position == Vector3.ZERO:
		resolved_source_position = _get_nearest_zombie_position()
	if resolved_source_position != Vector3.ZERO:
		var source_direction: Vector3 = (resolved_source_position - global_position).normalized()
		var local_direction: Vector3 = global_transform.basis.inverse() * source_direction
		direction = Vector2(local_direction.x, local_direction.z)
	damage_feedback.emit(incoming_damage, direction)

func apply_movement_slow(strength: float, duration: float) -> void:
	var clamped_duration: float = maxf(0.0, duration)
	if clamped_duration <= 0.0:
		return
	var clamped_strength: float = clampf(strength, 0.2, 1.0)
	movement_slow_multiplier = min(movement_slow_multiplier, clamped_strength)
	movement_slow_remaining = maxf(movement_slow_remaining, clamped_duration)
	if not movement_slow_active:
		movement_slow_active = true
		show_runtime_status("SLOWED", "warning", true)

func register_external_damage_events(damage_events: Array[Dictionary]) -> Dictionary:
	return _apply_damage_events(damage_events, false)

func upgrade_current_weapon(cost_override: int = -1, display_name: String = "") -> bool:
	var weapon_id: String = weapon_loadout.get_current_weapon_id()
	var current_tier: int = weapon_loadout.get_current_upgrade_tier()
	var next_tier: int = current_tier + 1
	if next_tier > WeaponDefinitions.get_max_upgrade_tier(weapon_id):
		reload_feedback.emit("%s MAXED" % WeaponDefinitions.get_display_name(weapon_id, current_tier).to_upper(), WARNING_STATUS_COLOR)
		return false
	var price: int = cost_override if cost_override >= 0 else WeaponDefinitions.get_upgrade_cost(weapon_id, next_tier)
	if price <= 0:
		reload_feedback.emit("UPGRADE UNAVAILABLE", ERROR_STATUS_COLOR)
		return false
	if not _try_spend_points(price):
		reload_feedback.emit("NOT ENOUGH POINTS", ERROR_STATUS_COLOR)
		return false
	if not weapon_loadout.apply_upgrade_to_current():
		_add_points(price)
		reload_feedback.emit("UPGRADE FAILED", ERROR_STATUS_COLOR)
		return false
	_sync_current_weapon_view(true)
	var label_name: String = display_name if not display_name.is_empty() else weapon_name
	reload_feedback.emit("%s UPGRADED" % label_name.to_upper(), POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("-%d PTS" % price, WARNING_STATUS_COLOR)
	combat_text_feedback.emit("%s TIER %d" % [weapon_name.to_upper(), next_tier], POSITIVE_STATUS_COLOR)
	return true

func reward_points(amount: int, combat_text: String = "") -> void:
	var resolved_amount: int = maxi(amount, 0)
	if resolved_amount <= 0:
		return
	_add_points(resolved_amount)
	var resolved_text: String = combat_text if not combat_text.is_empty() else "+%d PTS" % resolved_amount
	combat_text_feedback.emit(resolved_text, POSITIVE_STATUS_COLOR)

func show_runtime_status(message: String, style: String = "info", show_combat_text: bool = false) -> void:
	var color: Color = _get_status_color(style)
	reload_feedback.emit(message, color)
	if show_combat_text:
		combat_text_feedback.emit(message, color)

func _set_camera_mode(next_mode: String) -> void:
	active_camera_mode = next_mode if next_mode == CAMERA_THIRD_PERSON else CAMERA_FIRST_PERSON
	first_person_camera.current = active_camera_mode == CAMERA_FIRST_PERSON
	third_person_camera.current = active_camera_mode == CAMERA_THIRD_PERSON
	gun_model.visible = active_camera_mode == CAMERA_FIRST_PERSON
	visual_root.visible = active_camera_mode == CAMERA_THIRD_PERSON

func _get_active_camera() -> Camera3D:
	return third_person_camera if active_camera_mode == CAMERA_THIRD_PERSON else first_person_camera

func _get_target_head_position() -> Vector3:
	return Vector3(head_start_pos.x, crouched_head_y if is_crouching else standing_head_y, head_start_pos.z)

func _can_exit_crouch() -> bool:
	var from: Vector3 = global_position + Vector3.UP * crouched_head_y
	var to: Vector3 = global_position + Vector3.UP * standing_head_y
	return _intersect_ray(from, to, 4).is_empty()

func _update_crouch_pose(delta: float) -> void:
	if not is_crouching and crouch_requested and not _can_exit_crouch():
		is_crouching = true
	var target_height: float = crouch_capsule_height if is_crouching else standing_capsule_height
	var target_collision_y: float = crouch_collision_y if is_crouching else standing_collision_y
	player_capsule.height = lerpf(player_capsule.height, target_height, clampf(crouch_transition_speed * delta, 0.0, 1.0))
	var collision_transform: Transform3D = player_collision.transform
	collision_transform.origin.y = lerpf(collision_transform.origin.y, target_collision_y, clampf(crouch_transition_speed * delta, 0.0, 1.0))
	player_collision.transform = collision_transform
	var head_position: Vector3 = head.position
	head_position.y = lerpf(head_position.y, _get_target_head_position().y, clampf(crouch_transition_speed * delta, 0.0, 1.0))
	head.position = head_position

func _update_visual_model(delta: float) -> void:
	if model_root == null:
		return
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var motion_ratio: float = clampf(horizontal_speed / maxf(SPEED * sprint_speed_multiplier, 0.001), 0.0, 1.0)
	var anim_speed: float = 3.0 + motion_ratio * (5.0 if is_sprinting else 3.0)
	visual_anim_time += delta * anim_speed
	var crouch_blend: float = 1.0 if is_crouching else 0.0
	var swing: float = sin(visual_anim_time)
	var counter_swing: float = sin(visual_anim_time + PI)
	var arm_amount: float = deg_to_rad(16.0) * motion_ratio
	var leg_amount: float = deg_to_rad(22.0) * motion_ratio
	var torso_bob: float = sin(visual_anim_time * 2.0) * 0.03 * motion_ratio
	model_root.position.y = lerpf(model_root.position.y, -0.28 * crouch_blend + torso_bob, clampf(8.0 * delta, 0.0, 1.0))
	model_spine.rotation.x = lerpf(model_spine.rotation.x, deg_to_rad(12.0) * crouch_blend, clampf(8.0 * delta, 0.0, 1.0))
	model_neck.rotation.x = lerpf(model_neck.rotation.x, -rotation_target_head * third_person_pitch_weight, clampf(10.0 * delta, 0.0, 1.0))
	left_arm.rotation.x = lerpf(left_arm.rotation.x, counter_swing * arm_amount - deg_to_rad(8.0) * crouch_blend, clampf(10.0 * delta, 0.0, 1.0))
	right_arm.rotation.x = lerpf(right_arm.rotation.x, swing * arm_amount - deg_to_rad(8.0) * crouch_blend, clampf(10.0 * delta, 0.0, 1.0))
	left_leg.rotation.x = lerpf(left_leg.rotation.x, swing * leg_amount + deg_to_rad(14.0) * crouch_blend, clampf(10.0 * delta, 0.0, 1.0))
	right_leg.rotation.x = lerpf(right_leg.rotation.x, counter_swing * leg_amount + deg_to_rad(14.0) * crouch_blend, clampf(10.0 * delta, 0.0, 1.0))
	if not is_on_floor():
		left_leg.rotation.x = lerpf(left_leg.rotation.x, deg_to_rad(-18.0), clampf(8.0 * delta, 0.0, 1.0))
		right_leg.rotation.x = lerpf(right_leg.rotation.x, deg_to_rad(18.0), clampf(8.0 * delta, 0.0, 1.0))
	if horizontal_speed <= 0.05:
		visual_anim_time = lerpf(visual_anim_time, floor(visual_anim_time / TAU) * TAU, clampf(2.0 * delta, 0.0, 1.0))

func _intersect_camera_ray(camera: Camera3D, distance: float, collision_mask: int) -> Dictionary:
	if camera == null:
		return {}
	var origin: Vector3 = camera.global_position
	var target: Vector3 = origin + (-camera.global_transform.basis.z * distance)
	return _intersect_ray(origin, target, collision_mask)

func _intersect_ray(from: Vector3, to: Vector3, collision_mask: int) -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(from, to, collision_mask)
	query.exclude = [get_rid()]
	return get_world_3d().direct_space_state.intersect_ray(query)

func head_bob_motion(delta: float) -> void:
	var horizontal_speed := Vector2(velocity.x, velocity.z).length()
	var bob_ratio := clampf(horizontal_speed / maxf(SPEED, 0.001), 0.0, sprint_speed_multiplier)
	var bob_amplitude := HEAD_BOB_AMPLITUDE * bob_ratio * (1.18 if is_sprinting else 1.0)
	var bob_frequency := HEAD_BOB_FREQUENCY * 60.0 * (1.2 if is_sprinting else 1.0)
	bob_time += delta * bob_frequency * maxf(bob_ratio, 0.35)
	var pos := Vector3.ZERO
	pos.y += sin(bob_time) * bob_amplitude
	pos.x += cos(bob_time * 0.5) * bob_amplitude * 2.0
	head.position = _get_target_head_position() + pos

func reset_head_bob(delta: float) -> void:
	head.position = head.position.lerp(_get_target_head_position(), clampf(12.0 * delta, 0.0, 1.0))

func update_damage_shake(delta: float) -> void:
	if damage_shake_timer <= 0.0:
		return
	damage_shake_timer = maxf(damage_shake_timer - delta, 0.0)
	var shake_progress := damage_shake_timer / damage_shake_duration
	var offset := Vector3(
		randf_range(-damage_shake_amount, damage_shake_amount),
		randf_range(-damage_shake_amount, damage_shake_amount),
		0.0
	) * shake_progress
	head.position += offset

func get_accuracy() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)

func try_collect_pickup(pickup_type: String, amount: int = 1, weapon_id: String = "", item_id: String = "", display_name: String = "") -> bool:
	match pickup_type:
		"ammo":
			return _collect_ammo_pickup(amount, weapon_id, display_name)
		"weapon":
			return _collect_weapon_pickup(weapon_id, display_name)
		"consumable":
			return _collect_consumable_pickup(item_id, amount, display_name)
		_:
			reload_feedback.emit("UNKNOWN PICKUP", ERROR_STATUS_COLOR)
			return false

func purchase_station(station_type: String, weapon_id: String = "", item_id: String = "", amount: int = -1, cost_override: int = -1, display_name: String = "") -> bool:
	match station_type:
		"ammo_refill":
			return _purchase_ammo_refill(weapon_id, amount, cost_override, display_name)
		"consumable_supply":
			return _purchase_consumable_supply(item_id, amount, cost_override, display_name)
		"weapon_buy":
			return _purchase_weapon_buy(weapon_id, cost_override, display_name)
		_:
			reload_feedback.emit("UNKNOWN STATION", ERROR_STATUS_COLOR)
			return false

func _collect_ammo_pickup(amount: int, weapon_id: String, display_name: String) -> bool:
	var target_weapon_id := weapon_id if not weapon_id.is_empty() else weapon_loadout.get_current_weapon_id()
	var slot_index := weapon_loadout.get_slot_index_by_weapon_id(target_weapon_id)
	if slot_index == -1:
		reload_feedback.emit("NO MATCHING WEAPON", ERROR_STATUS_COLOR)
		return false
	var weapon_data := WeaponDefinitions.get_weapon_data(target_weapon_id, weapon_loadout.get_upgrade_tier(slot_index))
	var resolved_amount := amount if amount > 0 else int(weapon_data.get("ammo_pickup_amount", 0))
	var added_amount := weapon_loadout.add_reserve_ammo_for_weapon(target_weapon_id, resolved_amount)
	_sync_current_weapon_view(false)
	var pickup_name := display_name if not display_name.is_empty() else "%s Ammo" % WeaponDefinitions.get_display_name(target_weapon_id)
	reload_feedback.emit("%s +%d" % [pickup_name.to_upper(), added_amount], POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("%s RESERVE %03d" % [WeaponDefinitions.get_display_name(target_weapon_id).to_upper(), int(weapon_loadout.get_slot_state(slot_index).get("reserve_ammo", 0))], INFO_STATUS_COLOR)
	return true

func _collect_weapon_pickup(weapon_id: String, display_name: String) -> bool:
	if not WeaponDefinitions.has_weapon(weapon_id):
		reload_feedback.emit("INVALID WEAPON", ERROR_STATUS_COLOR)
		return false
	if not progression.is_weapon_unlocked(weapon_id):
		reload_feedback.emit("%s LOCKED" % WeaponDefinitions.get_display_name(weapon_id).to_upper(), ERROR_STATUS_COLOR)
		return false
	var existing_slot := weapon_loadout.get_slot_index_by_weapon_id(weapon_id)
	if existing_slot != -1:
		var owned_weapon_data := WeaponDefinitions.get_weapon_data(weapon_id, weapon_loadout.get_upgrade_tier(existing_slot))
		weapon_loadout.add_reserve_ammo_for_weapon(weapon_id, int(owned_weapon_data.get("ammo_pickup_amount", 0)))
		weapon_loadout.set_current_slot(existing_slot)
		_sync_current_weapon_view(false)
		reload_feedback.emit("%s RESTOCKED" % WeaponDefinitions.get_display_name(weapon_id).to_upper(), POSITIVE_STATUS_COLOR)
		return true
	weapon_loadout.assign_weapon(current_weapon_index, weapon_id)
	weapon_loadout.set_current_slot(current_weapon_index)
	_sync_current_weapon_view(true)
	reload_feedback.emit("%s EQUIPPED" % (display_name if not display_name.is_empty() else WeaponDefinitions.get_display_name(weapon_id)).to_upper(), POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit(_get_weapon_mode_text(), INFO_STATUS_COLOR)
	return true

func _collect_consumable_pickup(item_id: String, amount: int, display_name: String) -> bool:
	if not ItemDefinitions.has_item(item_id):
		reload_feedback.emit("INVALID ITEM", ERROR_STATUS_COLOR)
		return false
	if not progression.is_item_unlocked(item_id):
		reload_feedback.emit("%s LOCKED" % ItemDefinitions.get_display_name(item_id).to_upper(), ERROR_STATUS_COLOR)
		return false
	var added_amount := item_inventory.add_item(item_id, maxi(amount, 1))
	if added_amount <= 0:
		reload_feedback.emit("%s FULL" % ItemDefinitions.get_display_name(item_id).to_upper(), WARNING_STATUS_COLOR)
		return false
	reload_feedback.emit("%s +%d" % [(display_name if not display_name.is_empty() else ItemDefinitions.get_display_name(item_id)).to_upper(), added_amount], POSITIVE_STATUS_COLOR)
	_emit_inventory_changed()
	return true

func _purchase_ammo_refill(weapon_id: String, amount: int, cost_override: int, display_name: String) -> bool:
	var target_weapon_id := weapon_id if not weapon_id.is_empty() else weapon_loadout.get_current_weapon_id()
	var slot_index: int = weapon_loadout.get_slot_index_by_weapon_id(target_weapon_id)
	if slot_index == -1:
		reload_feedback.emit("WEAPON NOT EQUIPPED", ERROR_STATUS_COLOR)
		return false
	var weapon_data := WeaponDefinitions.get_weapon_data(target_weapon_id, weapon_loadout.get_upgrade_tier(slot_index))
	var price := cost_override if cost_override >= 0 else int(weapon_data.get("ammo_refill_cost", 0))
	if not _try_spend_points(price):
		reload_feedback.emit("NOT ENOUGH POINTS", ERROR_STATUS_COLOR)
		return false
	var refill_amount := amount if amount > 0 else int(weapon_data.get("ammo_pickup_amount", 0))
	weapon_loadout.add_reserve_ammo_for_weapon(target_weapon_id, refill_amount)
	_sync_current_weapon_view(false)
	reload_feedback.emit("%s BOUGHT" % (display_name if not display_name.is_empty() else "%s Ammo" % WeaponDefinitions.get_display_name(target_weapon_id)).to_upper(), POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("-%d PTS" % price, WARNING_STATUS_COLOR)
	return true

func _purchase_consumable_supply(item_id: String, amount: int, cost_override: int, display_name: String) -> bool:
	if not ItemDefinitions.has_item(item_id):
		reload_feedback.emit("INVALID ITEM", ERROR_STATUS_COLOR)
		return false
	if not progression.is_item_unlocked(item_id):
		reload_feedback.emit("%s LOCKED" % ItemDefinitions.get_display_name(item_id).to_upper(), ERROR_STATUS_COLOR)
		return false
	if not item_inventory.can_add_item(item_id, maxi(amount, 1)):
		reload_feedback.emit("%s FULL" % ItemDefinitions.get_display_name(item_id).to_upper(), WARNING_STATUS_COLOR)
		return false
	var item_data := ItemDefinitions.get_item_data(item_id)
	var price := cost_override if cost_override >= 0 else int(item_data.get("buy_cost", 0))
	if not _try_spend_points(price):
		reload_feedback.emit("NOT ENOUGH POINTS", ERROR_STATUS_COLOR)
		return false
	var added_amount := item_inventory.add_item(item_id, maxi(amount, 1))
	reload_feedback.emit("%s +%d" % [(display_name if not display_name.is_empty() else ItemDefinitions.get_display_name(item_id)).to_upper(), added_amount], POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("-%d PTS" % price, WARNING_STATUS_COLOR)
	_emit_inventory_changed()
	return true

func _purchase_weapon_buy(weapon_id: String, cost_override: int, display_name: String) -> bool:
	if not WeaponDefinitions.has_weapon(weapon_id):
		reload_feedback.emit("INVALID WEAPON", ERROR_STATUS_COLOR)
		return false
	if not progression.is_weapon_unlocked(weapon_id):
		reload_feedback.emit("%s LOCKED" % WeaponDefinitions.get_display_name(weapon_id).to_upper(), ERROR_STATUS_COLOR)
		return false
	var weapon_data := WeaponDefinitions.get_weapon_data(weapon_id)
	var price := cost_override if cost_override >= 0 else int(weapon_data.get("buy_cost", 0))
	if not _try_spend_points(price):
		reload_feedback.emit("NOT ENOUGH POINTS", ERROR_STATUS_COLOR)
		return false
	var existing_slot := weapon_loadout.get_slot_index_by_weapon_id(weapon_id)
	if existing_slot != -1:
		weapon_loadout.set_current_slot(existing_slot)
		weapon_loadout.add_reserve_ammo_for_weapon(weapon_id, int(weapon_data.get("ammo_pickup_amount", 0)))
	else:
		weapon_loadout.assign_weapon(current_weapon_index, weapon_id)
		weapon_loadout.set_current_slot(current_weapon_index)
	_sync_current_weapon_view(true)
	reload_feedback.emit("%s ACQUIRED" % (display_name if not display_name.is_empty() else WeaponDefinitions.get_display_name(weapon_id)).to_upper(), POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("-%d PTS" % price, WARNING_STATUS_COLOR)
	return true

func update_interaction_prompt() -> void:
	var target: Object = _get_interactable_target()
	_set_interaction_highlight(target as Node if target is Node else null)
	if target == null:
		last_interaction_target_id = -1
		last_interaction_prompt = ""
		return
	var prompt := "PRESS E"
	if target.has_method("get_interaction_prompt"):
		prompt = String(target.call("get_interaction_prompt"))
	var target_id := target.get_instance_id()
	if target_id == last_interaction_target_id and prompt == last_interaction_prompt:
		return
	last_interaction_target_id = target_id
	last_interaction_prompt = prompt
	reload_feedback.emit(prompt.to_upper(), INTERACTION_PROMPT_COLOR)
	combat_text_feedback.emit(prompt.to_upper(), INTERACTION_PROMPT_COLOR)

func _get_interactable_target() -> Object:
	var camera: Camera3D = _get_active_camera()
	if camera == null:
		return null
	var result: Dictionary = _intersect_camera_ray(camera, interaction_distance, 8)
	if result.is_empty():
		return null
	var collider: Object = result.get("collider", null)
	if collider == null or not collider.has_method("interact"):
		return null
	return collider

func _set_interaction_highlight(next_target: Node) -> void:
	if highlighted_interaction_target == next_target:
		return
	if highlighted_interaction_target != null and is_instance_valid(highlighted_interaction_target) and highlighted_interaction_target.has_method("set_highlighted"):
		highlighted_interaction_target.call("set_highlighted", false)
	highlighted_interaction_target = next_target
	if highlighted_interaction_target != null and is_instance_valid(highlighted_interaction_target) and highlighted_interaction_target.has_method("set_highlighted"):
		highlighted_interaction_target.call("set_highlighted", true)

func _sync_current_weapon_view(reset_feedback: bool) -> void:
	current_weapon_index = weapon_loadout.get_current_slot_index()
	current_weapon_data = weapon_loadout.get_current_weapon_data()
	weapon_name = String(current_weapon_data.get("display_name", "Weapon"))
	max_ammo = int(current_weapon_data.get("mag_size", 0))
	ammo = weapon_loadout.current_ammo_in_mag()
	reserve_ammo = weapon_loadout.current_reserve_ammo()
	is_weapon_automatic = bool(current_weapon_data.get("is_automatic", false))
	if reset_feedback:
		current_bloom = 0.0
		weapon_bloom_ratio = 0.0

func _perform_weapon_shot(was_sprinting: bool) -> Array[Dictionary]:
	var camera: Camera3D = _get_active_camera()
	if camera == null:
		return []
	var pellet_count: int = maxi(int(current_weapon_data.get("pellet_count", 1)), 1)
	var pellet_spread: float = _get_current_shot_spread(was_sprinting) * maxf(float(current_weapon_data.get("pellet_spread_multiplier", 1.0)), 0.05)
	var base_damage: int = max(1, int(current_weapon_data.get("damage", 1)))
	var headshot_multiplier: float = maxf(float(current_weapon_data.get("headshot_multiplier", 2.0)), 1.0)
	var max_distance := 100.0
	var aggregated_events: Dictionary = {}
	var shot_origin: Vector3 = camera.global_position

	for _pellet_index in range(pellet_count):
		var shot_direction := _build_shot_direction(pellet_spread)
		var result: Dictionary = _intersect_ray(shot_origin, shot_origin + shot_direction * max_distance, 2)
		if result.is_empty():
			continue

		var target_info: Dictionary = _resolve_damage_target(result.get("collider", null), result.get("position", Vector3.ZERO))
		if not bool(target_info.get("valid", false)):
			continue

		var body_part: String = String(target_info.get("body_part", ""))
		var pellet_damage: int = base_damage
		var did_headshot: bool = body_part == "head"
		if did_headshot:
			pellet_damage = max(1, int(round(float(base_damage) * headshot_multiplier)))

		var damage_target: Object = target_info.get("damage_target", null)
		if damage_target == null:
			continue

		var killed := false
		if not body_part.is_empty() and damage_target.has_method("take_part_damage"):
			killed = bool(damage_target.call("take_part_damage", body_part, pellet_damage))
		elif damage_target.has_method("take_damage"):
			killed = bool(damage_target.call("take_damage", pellet_damage))

		var event_key: int = int(target_info.get("event_key", 0))
		var event_data: Dictionary = aggregated_events.get(event_key, {"hit": true, "headshot": false, "killed": false})
		event_data["headshot"] = bool(event_data.get("headshot", false)) or did_headshot
		event_data["killed"] = bool(event_data.get("killed", false)) or killed
		aggregated_events[event_key] = event_data

	var result: Array[Dictionary] = []
	for event_data in aggregated_events.values():
		result.append(event_data)
	return result

func _resolve_damage_target(collider: Object, collision_point: Vector3) -> Dictionary:
	if collider == null:
		return {"valid": false}

	if collider.has_method("get_zombie_owner"):
		var zombie_owner: Object = collider.call("get_zombie_owner")
		if zombie_owner != null and is_instance_valid(zombie_owner):
			var body_part: String = ""
			if collider.has_method("get_body_part"):
				body_part = String(collider.call("get_body_part"))
			else:
				var collider_body_part: Variant = collider.get("body_part")
				if collider_body_part is String:
					body_part = String(collider_body_part)
			if body_part.is_empty() and _is_headshot(zombie_owner, collision_point):
				body_part = "head"
			return {
				"valid": true,
				"damage_target": zombie_owner,
				"event_key": zombie_owner.get_instance_id(),
				"body_part": body_part,
			}

	if collider.has_method("take_part_damage"):
		var resolved_body_part: String = "head" if _is_headshot(collider, collision_point) else "torso"
		return {
			"valid": true,
			"damage_target": collider,
			"event_key": collider.get_instance_id(),
			"body_part": resolved_body_part,
		}

	if collider.has_method("take_damage"):
		var direct_body_part: String = "head" if _is_headshot(collider, collision_point) else ""
		return {
			"valid": true,
			"damage_target": collider,
			"event_key": collider.get_instance_id(),
			"body_part": direct_body_part,
		}

	return {"valid": false}

func _is_headshot(target: Object, collision_point: Vector3) -> bool:
	if target == null:
		return false

	var body_part: Variant = target.get("body_part") if target != null else null
	if body_part is String:
		return String(body_part) == "head"

	if target.has_method("get_body_part"):
		return String(target.call("get_body_part")) == "head"

	if not target.is_in_group("zombie"):
		return false
	var target_node: Node3D = target as Node3D
	if target_node == null:
		return false
	return target_node.to_local(collision_point).y >= 1.25

func _build_shot_direction(spread_degrees: float) -> Vector3:
	var camera: Camera3D = _get_active_camera()
	if camera == null:
		return -global_transform.basis.z
	var forward := -camera.global_transform.basis.z
	var right := camera.global_transform.basis.x
	var up := camera.global_transform.basis.y
	var spread_factor := tan(deg_to_rad(spread_degrees))
	return (forward + right * randf_range(-spread_factor, spread_factor) + up * randf_range(-spread_factor, spread_factor)).normalized()

func _get_current_shot_spread(was_sprinting: bool) -> float:
	var base_spread := float(current_weapon_data.get("base_spread", 0.0))
	var movement_penalty := base_spread * maxf(float(current_weapon_data.get("movement_spread_multiplier", 1.0)) - 1.0, 0.0) * speed_ratio
	var sprint_penalty := float(current_weapon_data.get("sprint_fire_penalty", 0.0)) if was_sprinting else 0.0
	return base_spread + movement_penalty + sprint_penalty + current_bloom

func _apply_fire_feedback(was_sprinting: bool) -> void:
	recoil_pitch_offset += deg_to_rad(float(current_weapon_data.get("recoil_pitch", 0.0)))
	recoil_yaw_offset += deg_to_rad(randf_range(-float(current_weapon_data.get("recoil_yaw_random", 0.0)), float(current_weapon_data.get("recoil_yaw_random", 0.0))))
	current_fov_kick = min(current_fov_kick + fire_fov_kick_amount, sprint_fov_boost + fire_fov_kick_amount)
	gun_kick_offset += Vector3(randf_range(-0.01, 0.01), 0.008, 0.05 + weapon_bloom_ratio * 0.035)
	var bloom_boost := float(current_weapon_data.get("bloom_per_shot", 0.0))
	if was_sprinting:
		bloom_boost += float(current_weapon_data.get("sprint_fire_penalty", 0.0)) * 0.5
	var max_bloom := float(current_weapon_data.get("max_bloom", 0.0))
	current_bloom = clampf(current_bloom + bloom_boost, 0.0, max_bloom)
	weapon_bloom_ratio = clampf(current_bloom / maxf(max_bloom, 0.001), 0.0, 1.0)

func _update_weapon_feedback(delta: float) -> void:
	var recoil_recovery_step := deg_to_rad(float(current_weapon_data.get("recoil_recovery_speed", 0.0))) * delta
	recoil_pitch_offset = move_toward(recoil_pitch_offset, 0.0, recoil_recovery_step)
	recoil_yaw_offset = move_toward(recoil_yaw_offset, 0.0, recoil_recovery_step)
	current_bloom = move_toward(current_bloom, 0.0, float(current_weapon_data.get("bloom_decay_speed", 0.0)) * delta)
	weapon_bloom_ratio = clampf(current_bloom / maxf(float(current_weapon_data.get("max_bloom", 0.001)), 0.001), 0.0, 1.0)
	current_fov_kick = move_toward(current_fov_kick, 0.0, fire_fov_kick_recovery_speed * delta)
	gun_kick_offset = gun_kick_offset.lerp(Vector3.ZERO, clampf(gun_kick_recovery_speed * delta, 0.0, 1.0))
	gun_model.position = base_gun_model_position + gun_kick_offset
	var target_fov := base_camera_fov + (sprint_fov_boost if is_sprinting else 0.0) + current_fov_kick
	first_person_camera.fov = lerpf(first_person_camera.fov, target_fov, clampf(camera_fov_lerp_speed * delta, 0.0, 1.0))
	third_person_camera.fov = lerpf(third_person_camera.fov, third_person_camera_fov + current_fov_kick * 0.6, clampf(camera_fov_lerp_speed * delta, 0.0, 1.0))

func _emit_kill_feedback() -> void:
	var now_ms := Time.get_ticks_msec()
	if now_ms - last_kill_time_ms <= 2200:
		kill_streak_count += 1
	else:
		kill_streak_count = 1
	if kill_streak_count == 2:
		combat_text_feedback.emit("DOUBLE KILL", Color(1.0, 0.78, 0.22, 1.0))
	elif kill_streak_count == 3:
		combat_text_feedback.emit("TRIPLE KILL", Color(1.0, 0.52, 0.2, 1.0))
	elif kill_streak_count >= 4:
		combat_text_feedback.emit("MULTI KILL", Color(1.0, 0.28, 0.18, 1.0))
	last_kill_time_ms = now_ms

func _throw_grenade() -> void:
	var grenade: Node = GrenadeProjectileScene.instantiate()
	var scene_root: Node = get_tree().current_scene
	if scene_root == null or grenade == null:
		return
	scene_root.add_child(grenade)
	var camera: Camera3D = _get_active_camera()
	if camera == null:
		return
	var throw_direction := (-camera.global_transform.basis.z + Vector3.UP * 0.18).normalized()
	if grenade.has_method("launch"):
		grenade.call("launch", camera.global_position + throw_direction * 0.7, throw_direction, self)

func _should_fire_this_frame() -> bool:
	return Input.is_action_pressed("shoot") if is_weapon_automatic else Input.is_action_just_pressed("shoot")

func _emit_runtime_state() -> void:
	_emit_inventory_changed()
	_emit_currency_changed()
	armor_changed.emit(armor, max_armor)

func _emit_inventory_changed() -> void:
	inventory_changed.emit(item_inventory.build_state(_get_unlocked_item_ids()))

func _emit_currency_changed() -> void:
	currency_changed.emit(points)

func _get_unlocked_item_ids() -> Array[String]:
	return progression.get_unlocked_items()

func _handle_unlock_entry(unlocked_entry: Dictionary) -> void:
	var unlock_type := String(unlocked_entry.get("unlock_type", ""))
	var unlock_id := String(unlocked_entry.get("unlock_id", ""))
	var display_name := String(unlocked_entry.get("display_name", unlock_id.capitalize()))
	unlock_feedback.emit(unlock_type, unlock_id, display_name)
	reload_feedback.emit("UNLOCKED %s" % display_name.to_upper(), POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("UNLOCKED %s" % display_name.to_upper(), POSITIVE_STATUS_COLOR)
	_emit_inventory_changed()

func _add_points(amount: int) -> void:
	if amount > 0:
		points += amount
		_emit_currency_changed()

func _try_spend_points(amount: int) -> bool:
	if amount <= 0:
		return true
	if points < amount:
		return false
	points -= amount
	_emit_currency_changed()
	return true

func _get_weapon_mode_text() -> String:
	return "%s %s" % [weapon_name.to_upper(), "AUTO" if is_weapon_automatic else "SEMI"]

func _apply_damage_events(damage_events: Array[Dictionary], counts_as_shot: bool) -> Dictionary:
	var any_hit := false
	var any_headshot := false
	var any_kill := false
	var total_headshots := 0
	var total_kills := 0

	if counts_as_shot:
		shots_fired += 1

	for damage_event in damage_events:
		if not bool(damage_event.get("hit", false)):
			continue

		any_hit = true
		_add_points(points_per_hit)

		var did_headshot: bool = bool(damage_event.get("headshot", false))
		if did_headshot:
			any_headshot = true
			total_headshots += 1

		if bool(damage_event.get("killed", false)):
			any_kill = true
			total_kills += 1
			_add_points(points_per_kill)
			if did_headshot:
				_add_points(points_per_headshot_kill)
			_emit_kill_feedback()
			kill_feedback.emit()
			for unlocked_entry in progression.register_kill(did_headshot):
				_handle_unlock_entry(unlocked_entry)

	if counts_as_shot and any_hit:
		shots_hit += 1
	if total_headshots > 0:
		headshots += total_headshots
		combat_text_feedback.emit("HEADSHOT" if total_headshots == 1 else "%d HEADSHOTS" % total_headshots, Color(1.0, 0.42, 0.3, 1.0))
	if total_kills > 0:
		kills += total_kills

	return {"hit": any_hit, "headshot": any_headshot, "killed": any_kill}

func _update_movement_slow(delta: float) -> void:
	if movement_slow_remaining > 0.0:
		movement_slow_remaining = maxf(0.0, movement_slow_remaining - delta)
		if movement_slow_remaining > 0.0:
			return
	if movement_slow_multiplier < 1.0:
		movement_slow_multiplier = 1.0
		if movement_slow_active:
			movement_slow_active = false
			show_runtime_status("MOBILITY RESTORED", "positive")

func _get_status_color(style: String) -> Color:
	match style:
		"positive":
			return POSITIVE_STATUS_COLOR
		"warning":
			return WARNING_STATUS_COLOR
		"error":
			return ERROR_STATUS_COLOR
		"prompt":
			return INTERACTION_PROMPT_COLOR
		_:
			return INFO_STATUS_COLOR

func build_game_over_stats(current_wave: int, total_seconds: int) -> Dictionary:
	return {"wave": current_wave, "kills": kills, "headshots": headshots, "accuracy": get_accuracy(), "time_seconds": total_seconds, "points": points}

func _get_nearest_zombie_position() -> Vector3:
	var nearest_position: Vector3 = Vector3.ZERO
	var nearest_distance_sq: float = INF
	for zombie_node in get_tree().get_nodes_in_group("zombie"):
		var zombie: Node3D = zombie_node as Node3D
		if zombie == null or not is_instance_valid(zombie):
			continue
		var distance_sq: float = global_position.distance_squared_to(zombie.global_position)
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_position = zombie.global_position
	return nearest_position
