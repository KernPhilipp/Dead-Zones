extends Node3D

func _enter_tree():
	var level_container := get_node_or_null("LevelContainer")
	if level_container != null:
		LevelFlow.instantiate_current_level(level_container)

func _ready():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
