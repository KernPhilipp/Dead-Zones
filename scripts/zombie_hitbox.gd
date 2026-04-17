extends StaticBody3D

@export var body_part: String = "torso"

func take_damage(amount: int) -> bool:
	var zombie = _find_zombie_owner()
	if zombie and zombie.has_method("take_part_damage"):
		return zombie.take_part_damage(body_part, amount)
	elif zombie and zombie.has_method("take_damage"):
		return zombie.take_damage(amount)
	return false

func _find_zombie_owner() -> Node:
	var current: Node = get_parent()
	while current:
		if current.has_method("take_part_damage"):
			return current
		current = current.get_parent()
	return null

func get_body_part() -> String:
	return body_part

func get_zombie_owner() -> Node:
	return _find_zombie_owner()
