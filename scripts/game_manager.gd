extends Node

@export var spawn_interval := 5.0
@export var max_zombies := 10

var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var spawn_points: Array[Marker3D] = []
var player: CharacterBody3D
var hud: CanvasLayer
var spawn_timer: Timer
var game_active: bool = true

func _ready():
	var current_scene := get_tree().current_scene
	player = get_tree().get_first_node_in_group("player")
	hud = current_scene.find_child("HUD", true, false) as CanvasLayer

	var player_start := current_scene.find_child("PlayerStart", true, false) as Marker3D
	if player and player_start:
		player.global_position = player_start.global_position
		player.global_rotation.y = player_start.global_rotation.y

	var zombie_spawns := current_scene.find_child("ZombieSpawns", true, false)
	if zombie_spawns:
		for child in zombie_spawns.get_children():
			if child is Marker3D:
				spawn_points.append(child)
	else:
		var fallback_spawns := current_scene.find_child("SpawnPoints", true, false)
		if fallback_spawns:
			for child in fallback_spawns.get_children():
				if child is Marker3D:
					spawn_points.append(child)

	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	spawn_timer.start(spawn_interval)

func _process(_delta):
	if not game_active or player == null or hud == null:
		return

	hud.update_health(player.health)
	hud.update_ammo(player.ammo, player.max_ammo)

	if player.health <= 0:
		game_over()

func _on_spawn_timer_timeout():
	if not game_active:
		return

	var current_zombies = get_tree().get_nodes_in_group("zombie").size()
	if current_zombies >= max_zombies:
		return

	if spawn_points.is_empty():
		return

	var spawn_point = spawn_points.pick_random()
	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_point.global_position
	get_tree().current_scene.add_child(zombie)

func game_over():
	game_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	hud.show_game_over()
	get_tree().paused = true
