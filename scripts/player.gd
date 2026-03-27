extends CharacterBody3D

signal shot_feedback(hit)
signal kill_feedback()
signal reload_feedback(message, color)
signal damage_feedback(amount, direction)
signal combat_text_feedback(message, color)

const WEAPON_SLOT_COUNT: int = 2

## Movement Settings
@export_category("Movement")
@export var SPEED := 5.0
@export var ACCEL := 50.0
@export var IN_AIR_SPEED := 3.0
@export var IN_AIR_ACCEL := 5.0
@export var JUMP_VELOCITY := 4.5

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

## Weapon Settings
@export_category("Weapon")
@export var weapon_one_name: String = "Pistol"
@export var weapon_one_mag_size: int = 12
@export var weapon_one_reserve_ammo_start: int = 48
@export var weapon_one_damage_per_shot: int = 34
@export var weapon_one_fire_rate: float = 0.24
@export var weapon_one_reload_time: float = 1.1
@export var weapon_two_name: String = "Rifle"
@export var weapon_two_mag_size: int = 30
@export var weapon_two_reserve_ammo_start: int = 120
@export var weapon_two_damage_per_shot: int = 18
@export var weapon_two_fire_rate: float = 0.1
@export var weapon_two_reload_time: float = 1.45

## Health
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
var tick: int = 0

var health: int
var ammo: int = 0
var reserve_ammo: int = 0
var can_shoot: bool = true
var is_reloading: bool = false
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
var weapon_names: Array[String] = []
var weapon_mag_sizes: Array[int] = []
var weapon_ammo: Array[int] = []
var weapon_reserve_ammo: Array[int] = []
var weapon_damage: Array[int] = []
var weapon_fire_rates: Array[float] = []
var weapon_reload_times: Array[float] = []
var shots_fired: int = 0
var shots_hit: int = 0
var kills: int = 0
var headshots: int = 0
var last_kill_time_ms: int = -100000
var kill_streak_count: int = 0
var speed_ratio: float = 0.0

func _ready():
	health = max_health
	_setup_weapons()
	_apply_weapon_state(0)

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_start_pos = $Head.position

	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

	reload_timer = Timer.new()
	reload_timer.one_shot = true
	reload_timer.timeout.connect(_on_reload_timer_timeout)
	add_child(reload_timer)

func _physics_process(delta):
	tick += 1
	move_player(delta)
	rotate_player(delta)
	update_damage_shake(delta)

	if HEAD_BOB:
		if velocity and is_on_floor():
			head_bob_motion()
		reset_head_bob(delta)

	if Input.is_action_just_pressed("shoot"):
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
	if MOUSE_ACCEL:
		quaternion = quaternion.slerp(
			Quaternion(Vector3.UP, rotation_target_player),
			MOUSE_ACCEL_SPEED * delta
		)
		$Head.quaternion = $Head.quaternion.slerp(
			Quaternion(Vector3.RIGHT, rotation_target_head),
			MOUSE_ACCEL_SPEED * delta
		)
	else:
		quaternion = Quaternion(Vector3.UP, rotation_target_player)
		$Head.quaternion = Quaternion(Vector3.RIGHT, rotation_target_head)

func move_player(delta):
	if not is_on_floor():
		speed = IN_AIR_SPEED
		accel = IN_AIR_ACCEL
		velocity.y -= gravity * delta
	else:
		speed = SPEED
		accel = ACCEL

	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = JUMP_VELOCITY

	var input_dir: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction: Vector3 = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)
	speed_ratio = clampf(Vector2(velocity.x, velocity.z).length() / maxf(SPEED, 0.001), 0.0, 1.0)

	move_and_slide()

func shoot():
	if is_reloading or not can_shoot:
		return

	if ammo <= 0:
		shot_feedback.emit(false)
		reload_feedback.emit("EMPTY", Color(1, 0.35, 0.35, 1))
		return

	can_shoot = false
	ammo -= 1
	weapon_ammo[current_weapon_index] = ammo
	shots_fired += 1

	var ray: RayCast3D = $Head/RayCast3D
	ray.force_raycast_update()
	var did_hit: bool = false

	if ray.is_colliding():
		var target: Object = ray.get_collider()
		if target.has_method("take_damage"):
			var headshot: bool = _is_headshot(ray)
			var applied_damage: int = damage_per_shot * (2 if headshot else 1)
			var killed: bool = target.take_damage(applied_damage)
			did_hit = true
			shots_hit += 1
			if headshot:
				headshots += 1
				combat_text_feedback.emit("HEADSHOT", Color(1.0, 0.42, 0.3, 1.0))
			if killed:
				kills += 1
				_emit_kill_feedback()
				kill_feedback.emit()

	shot_feedback.emit(did_hit)
	fire_timer.start(fire_rate)

func reload_weapon():
	if is_reloading:
		return

	if ammo >= max_ammo or reserve_ammo <= 0:
		return

	is_reloading = true
	can_shoot = false
	reload_feedback.emit("RELOADING", Color(1, 0.8, 0.35, 1))
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
	reload_feedback.emit("%s READY" % weapon_name.to_upper(), Color(1, 0.85, 0.45, 1))

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
	reload_feedback.emit("READY", Color(0.45, 1, 0.55, 1))

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

func head_bob_motion():
	var pos := Vector3.ZERO
	pos.y += sin(tick * HEAD_BOB_FREQUENCY) * HEAD_BOB_AMPLITUDE
	pos.x += cos(tick * HEAD_BOB_FREQUENCY / 2.0) * HEAD_BOB_AMPLITUDE * 2.0
	$Head.position += pos

func reset_head_bob(delta):
	$Head.position = lerp($Head.position, head_start_pos, 2.0 * (1.0 / HEAD_BOB_FREQUENCY) * delta)

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

func _apply_weapon_state(index: int):
	current_weapon_index = index
	weapon_name = weapon_names[index]
	max_ammo = weapon_mag_sizes[index]
	ammo = weapon_ammo[index]
	reserve_ammo = weapon_reserve_ammo[index]
	damage_per_shot = weapon_damage[index]
	fire_rate = weapon_fire_rates[index]
	reload_time = weapon_reload_times[index]

func get_accuracy() -> float:
	if shots_fired <= 0:
		return 0.0
	return float(shots_hit) / float(shots_fired)

func _is_headshot(ray: RayCast3D) -> bool:
	var target: Object = ray.get_collider()
	if target == null or not target.is_in_group("zombie"):
		return false

	var collision_point: Vector3 = ray.get_collision_point()
	var target_node: Node3D = target as Node3D
	if target_node == null:
		return false

	var local_hit_point: Vector3 = target_node.to_local(collision_point)
	return local_hit_point.y >= 1.25

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
