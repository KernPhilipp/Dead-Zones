extends CharacterBody3D

signal shot_feedback(hit)
signal kill_feedback()
signal reload_feedback(message, color)
signal damage_feedback(amount, direction)
signal combat_text_feedback(message, color)
signal inventory_changed(current_medkits, max_medkits_value)

const WEAPON_SLOT_COUNT: int = 2
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

@export_category("Weapon Slot 1")
@export var weapon_one_name: String = "Pistol"
@export var weapon_one_mag_size: int = 12
@export var weapon_one_reserve_ammo_start: int = 48
@export var weapon_one_damage_per_shot: int = 32
@export var weapon_one_fire_rate: float = 0.26
@export var weapon_one_reload_time: float = 1.1
@export var weapon_one_is_automatic: bool = false
@export var weapon_one_base_spread: float = 0.16
@export var weapon_one_movement_spread_multiplier: float = 1.15
@export var weapon_one_recoil_pitch: float = 0.38
@export var weapon_one_recoil_yaw_random: float = 0.12
@export var weapon_one_recoil_recovery_speed: float = 16.0
@export var weapon_one_sprint_fire_penalty: float = 0.18
@export var weapon_one_bloom_per_shot: float = 0.04
@export var weapon_one_bloom_decay_speed: float = 1.8
@export var weapon_one_max_bloom: float = 0.22

@export_category("Weapon Slot 2")
@export var weapon_two_name: String = "Rifle"
@export var weapon_two_mag_size: int = 32
@export var weapon_two_reserve_ammo_start: int = 128
@export var weapon_two_damage_per_shot: int = 23
@export var weapon_two_fire_rate: float = 0.085
@export var weapon_two_reload_time: float = 1.25
@export var weapon_two_is_automatic: bool = true
@export var weapon_two_base_spread: float = 0.34
@export var weapon_two_movement_spread_multiplier: float = 1.7
@export var weapon_two_recoil_pitch: float = 0.82
@export var weapon_two_recoil_yaw_random: float = 0.4
@export var weapon_two_recoil_recovery_speed: float = 9.0
@export var weapon_two_sprint_fire_penalty: float = 0.45
@export var weapon_two_bloom_per_shot: float = 0.12
@export var weapon_two_bloom_decay_speed: float = 0.8
@export var weapon_two_max_bloom: float = 1.1

@export_category("Interaction")
@export var interaction_distance := 3.6

@export_category("Inventory")
@export var max_medkits: int = 3
@export var medkit_heal_amount: int = 35

@export_category("Camera Feedback")
@export var camera_fov_lerp_speed := 8.0
@export var fire_fov_kick_amount := 0.65
@export var fire_fov_kick_recovery_speed := 6.5
@export var gun_kick_recovery_speed := 14.0

@export_category("Health")
@export var max_health := 100
@export var damage_shake_strength := 0.09
@export var damage_shake_duration := 0.18

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float
var accel: float

var rotation_target_player: float
var rotation_target_head: float
var head_start_pos: Vector3
var base_gun_model_position: Vector3
var base_camera_fov: float = 75.0
var bob_time: float = 0.0

var health: int
var ammo: int = 0
var reserve_ammo: int = 0
var can_shoot: bool = true
var is_reloading: bool = false
var is_sprinting: bool = false
var fire_timer: Timer
var reload_timer: Timer
var damage_shake_timer: float = 0.0
var damage_shake_amount: float = 0.0
var current_weapon_index: int = 0
var weapon_name: String = ""
var max_ammo: int = 0
var damage_per_shot: int = 0
var fire_rate: float = 0.0
var reload_time: float = 0.0
var is_weapon_automatic: bool = false
var base_spread: float = 0.0
var movement_spread_multiplier: float = 1.0
var recoil_pitch: float = 0.0
var recoil_yaw_random: float = 0.0
var recoil_recovery_speed: float = 0.0
var sprint_fire_penalty: float = 0.0
var bloom_per_shot: float = 0.0
var bloom_decay_speed: float = 0.0
var max_bloom: float = 0.0

var weapon_names: Array[String] = []
var weapon_mag_sizes: Array[int] = []
var weapon_ammo: Array[int] = []
var weapon_reserve_ammo: Array[int] = []
var weapon_damage: Array[int] = []
var weapon_fire_rates: Array[float] = []
var weapon_reload_times: Array[float] = []
var weapon_is_automatic: Array[bool] = []
var weapon_base_spreads: Array[float] = []
var weapon_movement_spread_multipliers: Array[float] = []
var weapon_recoil_pitch: Array[float] = []
var weapon_recoil_yaw_random: Array[float] = []
var weapon_recoil_recovery_speed: Array[float] = []
var weapon_sprint_fire_penalty: Array[float] = []
var weapon_bloom_per_shot: Array[float] = []
var weapon_bloom_decay_speed: Array[float] = []
var weapon_max_bloom: Array[float] = []

var shots_fired: int = 0
var shots_hit: int = 0
var kills: int = 0
var headshots: int = 0
var last_kill_time_ms: int = -100000
var kill_streak_count: int = 0
var speed_ratio: float = 0.0
var medkit_count: int = 0
var last_interaction_target_id: int = -1
var last_interaction_prompt: String = ""
var weapon_bloom_ratio: float = 0.0

var recoil_pitch_offset: float = 0.0
var recoil_yaw_offset: float = 0.0
var current_fov_kick: float = 0.0
var gun_kick_offset: Vector3 = Vector3.ZERO
var current_bloom: float = 0.0
var fire_input_active_this_frame: bool = false
var highlighted_interaction_target: Node = null

func _ready():
	health = max_health
	_setup_weapons()
	_apply_weapon_state(0)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_start_pos = $Head.position
	base_gun_model_position = $Head/GunModel.position
	base_camera_fov = $Head/Camera3D.fov

	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

	reload_timer = Timer.new()
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(reload_timer)

	var interaction_ray: RayCast3D = $Head/InteractionRayCast3D
	interaction_ray.target_position = Vector3(0, 0, -interaction_distance)
	_emit_inventory_changed()

func _physics_process(delta):
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

	if Input.is_action_just_pressed("interact"):
		interact_with_target()

	if Input.is_action_just_pressed("use_item"):
		use_item()

	update_interaction_prompt()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_target_player += -event.relative.x * MOUSE_SENS
		rotation_target_head += -event.relative.y * MOUSE_SENS
		rotation_target_head = clamp(
			rotation_target_head,
			deg_to_rad(CLAMP_HEAD_ROTATION_MIN),
			deg_to_rad(CLAMP_HEAD_ROTATION_MAX)
		)

	if event is InputEventMouseButton and event.pressed:
		if Input.mouse_mode != Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func rotate_player(delta):
	var player_target: float = rotation_target_player + recoil_yaw_offset
	var head_target: float = rotation_target_head + recoil_pitch_offset
	if MOUSE_ACCEL:
		quaternion = quaternion.slerp(
			Quaternion(Vector3.UP, player_target),
			MOUSE_ACCEL_SPEED * delta
		)
		$Head.quaternion = $Head.quaternion.slerp(
			Quaternion(Vector3.RIGHT, head_target),
			MOUSE_ACCEL_SPEED * delta
		)
	else:
		quaternion = Quaternion(Vector3.UP, player_target)
		$Head.quaternion = Quaternion(Vector3.RIGHT, head_target)

func move_player(delta):
	if not is_on_floor():
		speed = IN_AIR_SPEED
		accel = IN_AIR_ACCEL
		is_sprinting = false
		velocity.y -= gravity * delta
	else:
		speed = SPEED
		accel = ACCEL
		var input_dir_length: float = Input.get_vector("move_left", "move_right", "move_forward", "move_back").length()
		is_sprinting = (
			input_dir_length > 0.0
			and Input.is_action_pressed("sprint")
			and not fire_input_active_this_frame
			and not is_reloading
		)
		if is_sprinting:
			speed *= sprint_speed_multiplier
			accel *= sprint_accel_multiplier

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	speed_ratio = clampf(
		Vector2(velocity.x, velocity.z).length() / maxf(SPEED * sprint_speed_multiplier, 0.001),
		0.0,
		1.0
	)

	move_and_slide()

func shoot():
	if is_reloading or not can_shoot:
		return

	if ammo <= 0:
		shot_feedback.emit(false)
		reload_feedback.emit("EMPTY", ERROR_STATUS_COLOR)
		return

	var was_sprinting: bool = is_sprinting
	is_sprinting = false
	can_shoot = false
	ammo -= 1
	weapon_ammo[current_weapon_index] = ammo
	shots_fired += 1

	var shot_result: Dictionary = _perform_weapon_shot(was_sprinting)
	var did_hit: bool = bool(shot_result["hit"])
	var did_headshot: bool = bool(shot_result["headshot"])
	var did_kill: bool = bool(shot_result["killed"])

	if did_hit:
		shots_hit += 1
		if did_headshot:
			headshots += 1
			combat_text_feedback.emit("HEADSHOT", Color(1.0, 0.42, 0.3, 1.0))
		if did_kill:
			kills += 1
			_emit_kill_feedback()
			kill_feedback.emit()

	_apply_fire_feedback(was_sprinting)
	shot_feedback.emit(did_hit)
	fire_timer.start(fire_rate)

func reload_weapon():
	if is_reloading:
		return

	if ammo >= max_ammo or reserve_ammo <= 0:
		return

	is_sprinting = false
	is_reloading = true
	can_shoot = false
	reload_feedback.emit("RELOADING", WARNING_STATUS_COLOR)
	reload_timer.start(reload_time)

func switch_weapon(next_index: int):
	if next_index < 0 or next_index >= weapon_names.size():
		return
	if next_index == current_weapon_index:
		return

	if is_reloading:
		is_reloading = false
		reload_timer.stop()

	current_weapon_index = next_index
	_apply_weapon_state(current_weapon_index)
	can_shoot = true
	reload_feedback.emit("%s READY" % weapon_name.to_upper(), WARNING_STATUS_COLOR)
	combat_text_feedback.emit(_get_weapon_mode_text(), INFO_STATUS_COLOR)

func get_reload_progress() -> float:
	if not is_reloading or reload_time <= 0.0:
		return 0.0
	return clampf((reload_time - reload_timer.time_left) / reload_time, 0.0, 1.0)

func _on_fire_timer_timeout():
	can_shoot = not is_reloading

func _on_reload_timer_timeout():
	var needed_ammo: int = max_ammo - ammo
	var reloaded_ammo: int = mini(needed_ammo, reserve_ammo)
	ammo += reloaded_ammo
	reserve_ammo -= reloaded_ammo
	weapon_ammo[current_weapon_index] = ammo
	weapon_reserve_ammo[current_weapon_index] = reserve_ammo
	is_reloading = false
	can_shoot = true
	reload_feedback.emit("READY", POSITIVE_STATUS_COLOR)

func interact_with_target():
	var target: Object = _get_interactable_target()
	if target == null:
		return
	target.call("interact", self)

func use_item():
	if medkit_count <= 0:
		reload_feedback.emit("NO MEDKIT", ERROR_STATUS_COLOR)
		_emit_medkit_count_feedback()
		return
	if health >= max_health:
		reload_feedback.emit("HEALTH FULL", WARNING_STATUS_COLOR)
		_emit_medkit_count_feedback()
		return

	medkit_count -= 1
	var previous_health: int = health
	health = mini(health + medkit_heal_amount, max_health)
	var healed_amount: int = health - previous_health
	reload_feedback.emit("USED MEDKIT", POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit("+%d HP" % healed_amount, POSITIVE_STATUS_COLOR)
	_emit_inventory_changed()
	_emit_medkit_count_feedback()

func take_damage(amount: int, source_position: Vector3 = Vector3.ZERO):
	health -= amount
	if health < 0:
		health = 0
	damage_shake_timer = damage_shake_duration
	damage_shake_amount = damage_shake_strength
	var direction: Vector2 = Vector2.ZERO
	if source_position != Vector3.ZERO:
		var source_direction: Vector3 = (source_position - global_position).normalized()
		var local_direction: Vector3 = global_transform.basis.inverse() * source_direction
		direction = Vector2(local_direction.x, local_direction.z)
	damage_feedback.emit(amount, direction)

func head_bob_motion(delta):
	var horizontal_speed: float = Vector2(velocity.x, velocity.z).length()
	var bob_ratio: float = clampf(horizontal_speed / maxf(SPEED, 0.001), 0.0, sprint_speed_multiplier)
	var bob_amplitude: float = HEAD_BOB_AMPLITUDE * bob_ratio * (1.18 if is_sprinting else 1.0)
	var bob_frequency: float = HEAD_BOB_FREQUENCY * 60.0 * (1.2 if is_sprinting else 1.0)
	bob_time += delta * bob_frequency * maxf(bob_ratio, 0.35)
	var pos := Vector3.ZERO
	pos.y += sin(bob_time) * bob_amplitude
	pos.x += cos(bob_time * 0.5) * bob_amplitude * 2.0
	$Head.position = head_start_pos + pos

func reset_head_bob(delta):
	$Head.position = $Head.position.lerp(head_start_pos, clampf(12.0 * delta, 0.0, 1.0))

func update_damage_shake(delta):
	if damage_shake_timer <= 0.0:
		return

	damage_shake_timer = maxf(damage_shake_timer - delta, 0.0)
	var shake_progress: float = damage_shake_timer / damage_shake_duration
	var offset: Vector3 = Vector3(
		randf_range(-damage_shake_amount, damage_shake_amount),
		randf_range(-damage_shake_amount, damage_shake_amount),
		0.0
	) * shake_progress
	$Head.position += offset

func _setup_weapons():
	weapon_names = [weapon_one_name, weapon_two_name]
	weapon_mag_sizes = [weapon_one_mag_size, weapon_two_mag_size]
	weapon_ammo = [weapon_one_mag_size, weapon_two_mag_size]
	weapon_reserve_ammo = [weapon_one_reserve_ammo_start, weapon_two_reserve_ammo_start]
	weapon_damage = [weapon_one_damage_per_shot, weapon_two_damage_per_shot]
	weapon_fire_rates = [weapon_one_fire_rate, weapon_two_fire_rate]
	weapon_reload_times = [weapon_one_reload_time, weapon_two_reload_time]
	weapon_is_automatic = [weapon_one_is_automatic, weapon_two_is_automatic]
	weapon_base_spreads = [weapon_one_base_spread, weapon_two_base_spread]
	weapon_movement_spread_multipliers = [
		weapon_one_movement_spread_multiplier,
		weapon_two_movement_spread_multiplier
	]
	weapon_recoil_pitch = [weapon_one_recoil_pitch, weapon_two_recoil_pitch]
	weapon_recoil_yaw_random = [weapon_one_recoil_yaw_random, weapon_two_recoil_yaw_random]
	weapon_recoil_recovery_speed = [
		weapon_one_recoil_recovery_speed,
		weapon_two_recoil_recovery_speed
	]
	weapon_sprint_fire_penalty = [
		weapon_one_sprint_fire_penalty,
		weapon_two_sprint_fire_penalty
	]
	weapon_bloom_per_shot = [weapon_one_bloom_per_shot, weapon_two_bloom_per_shot]
	weapon_bloom_decay_speed = [weapon_one_bloom_decay_speed, weapon_two_bloom_decay_speed]
	weapon_max_bloom = [weapon_one_max_bloom, weapon_two_max_bloom]

func _apply_weapon_state(index: int):
	current_weapon_index = index
	weapon_name = weapon_names[index]
	max_ammo = weapon_mag_sizes[index]
	ammo = weapon_ammo[index]
	reserve_ammo = weapon_reserve_ammo[index]
	damage_per_shot = weapon_damage[index]
	fire_rate = weapon_fire_rates[index]
	reload_time = weapon_reload_times[index]
	is_weapon_automatic = weapon_is_automatic[index]
	base_spread = weapon_base_spreads[index]
	movement_spread_multiplier = weapon_movement_spread_multipliers[index]
	recoil_pitch = weapon_recoil_pitch[index]
	recoil_yaw_random = weapon_recoil_yaw_random[index]
	recoil_recovery_speed = weapon_recoil_recovery_speed[index]
	sprint_fire_penalty = weapon_sprint_fire_penalty[index]
	bloom_per_shot = weapon_bloom_per_shot[index]
	bloom_decay_speed = weapon_bloom_decay_speed[index]
	max_bloom = weapon_max_bloom[index]
	current_bloom = 0.0
	weapon_bloom_ratio = 0.0

func get_accuracy() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)

func _perform_weapon_shot(was_sprinting: bool) -> Dictionary:
	var ray: RayCast3D = $Head/RayCast3D
	var original_target_position: Vector3 = ray.target_position
	var shot_direction: Vector3 = _build_shot_direction(_get_current_shot_spread(was_sprinting))
	var max_distance: float = maxf(original_target_position.length(), 100.0)
	var world_target: Vector3 = ray.global_position + shot_direction * max_distance
	ray.target_position = ray.to_local(world_target)
	ray.force_raycast_update()

	var result: Dictionary = {
		"hit": false,
		"headshot": false,
		"killed": false
	}

	if ray.is_colliding():
		var target: Object = ray.get_collider()
		if target.has_method("take_damage"):
			result["hit"] = true
			result["headshot"] = _is_headshot(target, ray.get_collision_point())
			var applied_damage: int = damage_per_shot * (2 if bool(result["headshot"]) else 1)
			result["killed"] = bool(target.take_damage(applied_damage))

	ray.target_position = original_target_position
	return result

func _is_headshot(target: Object, collision_point: Vector3) -> bool:
	if target == null or not target.is_in_group("zombie"):
		return false

	var target_node: Node3D = target as Node3D
	if target_node == null:
		return false

	var local_hit_point: Vector3 = target_node.to_local(collision_point)
	return local_hit_point.y >= 1.25

func _build_shot_direction(spread_degrees: float) -> Vector3:
	var camera: Camera3D = $Head/Camera3D
	var forward: Vector3 = -camera.global_transform.basis.z
	var right: Vector3 = camera.global_transform.basis.x
	var up: Vector3 = camera.global_transform.basis.y
	var spread_factor: float = tan(deg_to_rad(spread_degrees))
	return (
		forward
		+ right * randf_range(-spread_factor, spread_factor)
		+ up * randf_range(-spread_factor, spread_factor)
	).normalized()

func _get_current_shot_spread(was_sprinting: bool) -> float:
	var movement_penalty: float = base_spread * maxf(movement_spread_multiplier - 1.0, 0.0) * speed_ratio
	var sprint_penalty: float = sprint_fire_penalty if was_sprinting else 0.0
	return base_spread + movement_penalty + sprint_penalty + current_bloom

func _apply_fire_feedback(was_sprinting: bool):
	recoil_pitch_offset += deg_to_rad(recoil_pitch)
	recoil_yaw_offset += deg_to_rad(randf_range(-recoil_yaw_random, recoil_yaw_random))
	current_fov_kick = min(current_fov_kick + fire_fov_kick_amount, sprint_fov_boost + fire_fov_kick_amount)
	gun_kick_offset += Vector3(
		randf_range(-0.01, 0.01),
		0.008,
		0.05 + weapon_bloom_ratio * 0.035
	)
	var bloom_boost: float = bloom_per_shot + (sprint_fire_penalty * 0.5 if was_sprinting else 0.0)
	current_bloom = clampf(current_bloom + bloom_boost, 0.0, max_bloom)
	weapon_bloom_ratio = clampf(current_bloom / maxf(max_bloom, 0.001), 0.0, 1.0)

func _update_weapon_feedback(delta: float):
	var recoil_recovery_step: float = deg_to_rad(recoil_recovery_speed) * delta
	recoil_pitch_offset = move_toward(recoil_pitch_offset, 0.0, recoil_recovery_step)
	recoil_yaw_offset = move_toward(recoil_yaw_offset, 0.0, recoil_recovery_step)
	current_bloom = move_toward(current_bloom, 0.0, bloom_decay_speed * delta)
	weapon_bloom_ratio = clampf(current_bloom / maxf(max_bloom, 0.001), 0.0, 1.0)
	current_fov_kick = move_toward(current_fov_kick, 0.0, fire_fov_kick_recovery_speed * delta)
	gun_kick_offset = gun_kick_offset.lerp(Vector3.ZERO, clampf(gun_kick_recovery_speed * delta, 0.0, 1.0))
	$Head/GunModel.position = base_gun_model_position + gun_kick_offset
	var target_fov: float = base_camera_fov + (sprint_fov_boost if is_sprinting else 0.0) + current_fov_kick
	$Head/Camera3D.fov = lerpf(
		$Head/Camera3D.fov,
		target_fov,
		clampf(camera_fov_lerp_speed * delta, 0.0, 1.0)
	)

func _emit_kill_feedback():
	var now_ms: int = Time.get_ticks_msec()
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

func try_collect_pickup(pickup_type: String, amount: int, weapon_slot: int = -1, display_name: String = "") -> bool:
	var safe_amount: int = maxi(amount, 1)

	match pickup_type:
		"ammo":
			return _collect_ammo_pickup(safe_amount, weapon_slot, display_name)
		"medkit":
			return _collect_medkit_pickup(safe_amount, display_name)
		_:
			reload_feedback.emit("UNKNOWN PICKUP", ERROR_STATUS_COLOR)
			return false

func update_interaction_prompt():
	var target: Object = _get_interactable_target()
	_set_interaction_highlight(target as Node if target is Node else null)
	if target == null:
		last_interaction_target_id = -1
		last_interaction_prompt = ""
		return

	var prompt: String = "PRESS E"
	if target.has_method("get_interaction_prompt"):
		prompt = String(target.call("get_interaction_prompt"))

	var target_id: int = target.get_instance_id()
	if target_id == last_interaction_target_id and prompt == last_interaction_prompt:
		return

	last_interaction_target_id = target_id
	last_interaction_prompt = prompt
	reload_feedback.emit(prompt.to_upper(), INTERACTION_PROMPT_COLOR)
	combat_text_feedback.emit(prompt.to_upper(), INTERACTION_PROMPT_COLOR)

func _get_interactable_target() -> Object:
	var interaction_ray: RayCast3D = $Head/InteractionRayCast3D
	interaction_ray.force_raycast_update()
	if not interaction_ray.is_colliding():
		return null

	var collider: Object = interaction_ray.get_collider()
	if collider == null or not collider.has_method("interact"):
		return null

	return collider

func _set_interaction_highlight(next_target: Node):
	if highlighted_interaction_target == next_target:
		return

	if highlighted_interaction_target != null and is_instance_valid(highlighted_interaction_target):
		if highlighted_interaction_target.has_method("set_highlighted"):
			highlighted_interaction_target.call("set_highlighted", false)

	highlighted_interaction_target = next_target
	if highlighted_interaction_target != null and is_instance_valid(highlighted_interaction_target):
		if highlighted_interaction_target.has_method("set_highlighted"):
			highlighted_interaction_target.call("set_highlighted", true)

func _collect_ammo_pickup(amount: int, weapon_slot: int, display_name: String) -> bool:
	var slot_index: int = current_weapon_index if weapon_slot < 0 else weapon_slot
	if slot_index < 0 or slot_index >= weapon_reserve_ammo.size():
		reload_feedback.emit("AMMO TARGET INVALID", ERROR_STATUS_COLOR)
		return false

	weapon_reserve_ammo[slot_index] += amount
	if slot_index == current_weapon_index:
		reserve_ammo = weapon_reserve_ammo[slot_index]

	var pickup_name: String = _build_pickup_name(display_name, slot_index, "ammo")
	reload_feedback.emit("%s +%d" % [pickup_name.to_upper(), amount], POSITIVE_STATUS_COLOR)
	combat_text_feedback.emit(
		"%s RESERVE %03d" % [weapon_names[slot_index].to_upper(), weapon_reserve_ammo[slot_index]],
		INFO_STATUS_COLOR
	)
	return true

func _collect_medkit_pickup(amount: int, display_name: String) -> bool:
	var available_space: int = maxi(max_medkits - medkit_count, 0)
	if available_space <= 0:
		reload_feedback.emit("MEDKITS FULL", WARNING_STATUS_COLOR)
		return false

	var added_amount: int = mini(amount, available_space)
	medkit_count += added_amount
	var pickup_name: String = _build_pickup_name(display_name, -1, "medkit")
	reload_feedback.emit("%s +%d" % [pickup_name.to_upper(), added_amount], POSITIVE_STATUS_COLOR)
	_emit_inventory_changed()
	_emit_medkit_count_feedback()
	return true

func _build_pickup_name(display_name: String, weapon_slot: int, pickup_type: String) -> String:
	if not display_name.is_empty():
		return display_name
	if pickup_type == "medkit":
		return "Medkit"
	if weapon_slot >= 0 and weapon_slot < weapon_names.size():
		return "%s Ammo" % weapon_names[weapon_slot]
	return "Ammo"

func _should_fire_this_frame() -> bool:
	if is_weapon_automatic:
		return Input.is_action_pressed("shoot")
	return Input.is_action_just_pressed("shoot")

func _emit_medkit_count_feedback():
	combat_text_feedback.emit("MEDKITS %d/%d" % [medkit_count, max_medkits], INFO_STATUS_COLOR)

func _emit_inventory_changed():
	inventory_changed.emit(medkit_count, max_medkits)

func _get_weapon_mode_text() -> String:
	var mode: String = "AUTO" if is_weapon_automatic else "SEMI"
	return "%s %s" % [weapon_name.to_upper(), mode]
