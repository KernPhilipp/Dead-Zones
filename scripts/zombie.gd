extends CharacterBody3D

@export var speed := 3.0
@export var health := 50
@export var damage := 10
@export var attack_cooldown := 1.0

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var player: CharacterBody3D = null
var can_attack: bool = true
var attack_timer: Timer

func _ready():
	add_to_group("zombie")
	player = get_tree().get_first_node_in_group("player")

	attack_timer = Timer.new()
	attack_timer.one_shot = true
	attack_timer.timeout.connect(_on_attack_timer_timeout)
	add_child(attack_timer)

	$DamageArea.body_entered.connect(_on_damage_area_body_entered)

func _physics_process(delta):
	if not is_on_floor():
		velocity.y -= gravity * delta

	if player and is_instance_valid(player):
		var direction = player.global_position - global_position
		direction.y = 0
		direction = direction.normalized()

		velocity.x = direction.x * speed
		velocity.z = direction.z * speed

		var look_target = Vector3(player.global_position.x, global_position.y, player.global_position.z)
		if global_position.distance_to(look_target) > 0.1:
			look_at(look_target)

	move_and_slide()

func take_damage(amount: int):
	health -= amount
	if health <= 0:
		die()
		return true
	return false

func die():
	queue_free()

func _on_damage_area_body_entered(body):
	if body.is_in_group("player") and can_attack:
		if body.has_method("take_damage"):
			body.take_damage(damage, global_position)
		can_attack = false
		attack_timer.start(attack_cooldown)

func _on_attack_timer_timeout():
	can_attack = true
	# Check if player is still in range
	if player and is_instance_valid(player):
		var bodies = $DamageArea.get_overlapping_bodies()
		for body in bodies:
			if body.is_in_group("player") and body.has_method("take_damage"):
				body.take_damage(damage, global_position)
				can_attack = false
				attack_timer.start(attack_cooldown)
				break
