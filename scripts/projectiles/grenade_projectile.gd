extends CharacterBody3D

@export var throw_speed: float = 14.0
@export var gravity_scale: float = 1.0
@export var lifetime: float = 1.35
@export var explosion_radius: float = 4.6
@export var explosion_damage: int = 90

var _remaining_lifetime: float = 0.0
var _exploded: bool = false
var _gravity: float = 9.8

func _ready() -> void:
	_gravity = float(ProjectSettings.get_setting("physics/3d/default_gravity"))
	_remaining_lifetime = lifetime

func launch(origin: Vector3, direction: Vector3) -> void:
	global_position = origin
	velocity = direction.normalized() * throw_speed

func _physics_process(delta: float) -> void:
	if _exploded:
		return

	_remaining_lifetime -= delta
	velocity.y -= _gravity * gravity_scale * delta
	var collision: KinematicCollision3D = move_and_collide(velocity * delta)
	if collision != null or _remaining_lifetime <= 0.0:
		_explode()

func _explode() -> void:
	if _exploded:
		return
	_exploded = true

	for zombie in get_tree().get_nodes_in_group("zombie"):
		if not is_instance_valid(zombie) or not (zombie is Node3D):
			continue
		var distance: float = global_position.distance_to((zombie as Node3D).global_position)
		if distance > explosion_radius:
			continue
		var falloff: float = 1.0 - (distance / maxf(explosion_radius, 0.001))
		var applied_damage: int = max(1, int(round(explosion_damage * falloff)))
		if zombie.has_method("take_damage"):
			zombie.call("take_damage", applied_damage)

	queue_free()
