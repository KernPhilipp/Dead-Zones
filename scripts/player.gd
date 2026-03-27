extends CharacterBody3D

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
@export var max_ammo := 30
@export var damage_per_shot := 25
@export var fire_rate := 0.15

## Health
@export_category("Health")
@export var max_health := 100

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var speed: float
var accel: float

var rotation_target_player: float
var rotation_target_head: float
var head_start_pos: Vector3
var tick: int = 0

var health: int
var ammo: int
var can_shoot: bool = true
var fire_timer: Timer

func _ready():
	health = max_health
	ammo = max_ammo

	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	head_start_pos = $Head.position

	fire_timer = Timer.new()
	fire_timer.one_shot = true
	fire_timer.timeout.connect(_on_fire_timer_timeout)
	add_child(fire_timer)

func _physics_process(delta):
	tick += 1
	move_player(delta)
	rotate_player(delta)

	if HEAD_BOB:
		if velocity and is_on_floor():
			head_bob_motion()
		reset_head_bob(delta)

	if Input.is_action_just_pressed("shoot"):
		shoot()

func _input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		rotation_target_player += -event.relative.x * MOUSE_SENS
		rotation_target_head += -event.relative.y * MOUSE_SENS
		rotation_target_head = clamp(
			rotation_target_head,
			deg_to_rad(CLAMP_HEAD_ROTATION_MIN),
			deg_to_rad(CLAMP_HEAD_ROTATION_MAX)
		)

	# HTML5: capture mouse on first click
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

	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	velocity.x = move_toward(velocity.x, direction.x * speed, accel * delta)
	velocity.z = move_toward(velocity.z, direction.z * speed, accel * delta)

	move_and_slide()

func shoot():
	if ammo <= 0 or not can_shoot:
		return

	can_shoot = false
	ammo -= 1

	var ray: RayCast3D = $Head/RayCast3D
	ray.force_raycast_update()

	if ray.is_colliding():
		var target = ray.get_collider()
		if target.has_method("take_damage"):
			target.take_damage(damage_per_shot)

	fire_timer.start(fire_rate)

func _on_fire_timer_timeout():
	can_shoot = true

func take_damage(amount: int):
	health -= amount
	if health < 0:
		health = 0

func head_bob_motion():
	var pos = Vector3.ZERO
	pos.y += sin(tick * HEAD_BOB_FREQUENCY) * HEAD_BOB_AMPLITUDE
	pos.x += cos(tick * HEAD_BOB_FREQUENCY / 2.0) * HEAD_BOB_AMPLITUDE * 2.0
	$Head.position += pos

func reset_head_bob(delta):
	$Head.position = lerp($Head.position, head_start_pos, 2.0 * (1.0 / HEAD_BOB_FREQUENCY) * delta)
