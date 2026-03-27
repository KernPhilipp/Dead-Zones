extends StaticBody3D

@export var body_part: String = "torso"

func take_damage(amount: int):
	var zombie = _find_zombie_owner()
	if zombie and zombie.has_method("take_part_damage"):
		zombie.take_part_damage(body_part, amount)

func _find_zombie_owner() -> Node:
	var current: Node = get_parent()
	while current:
		if current.has_method("take_part_damage"):
			return current
		current = current.get_parent()
	return null
