extends Area3D

@export var fatal_damage: int = 9999

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _on_body_entered(body: Node) -> void:
	if body == null or not body.is_in_group("player"):
		return
	if not body.has_method("take_damage"):
		return
	body.call_deferred("take_damage", fatal_damage, global_position)
