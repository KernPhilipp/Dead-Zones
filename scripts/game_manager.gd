extends Node

@export var spawn_interval := 5.0
@export var max_zombies := 10
@export var base_wave_size := 6
@export var wave_growth := 3
@export var time_between_waves := 2.0

var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var spawn_points: Array[Marker3D] = []
var player: CharacterBody3D
var hud: CanvasLayer
var spawn_timer: Timer
var game_active: bool = true
var current_wave: int = 0
var zombies_to_spawn_in_wave: int = 0
var spawned_in_wave: int = 0
var waiting_for_next_wave: bool = false
var game_start_time_ms: int = 0

func _ready():
	player = get_tree().get_first_node_in_group("player")
	hud = get_node("../HUD")
	player.shot_feedback.connect(hud.show_shot_feedback)
	player.kill_feedback.connect(hud.show_kill_feedback)
	player.reload_feedback.connect(hud.show_status)
	player.damage_feedback.connect(hud.show_damage_feedback)
	player.combat_text_feedback.connect(hud.show_combat_text)
	game_start_time_ms = Time.get_ticks_msec()

	for child in get_node("../SpawnPoints").get_children():
		if child is Marker3D:
			spawn_points.append(child)

	spawn_timer = Timer.new()
	spawn_timer.timeout.connect(_on_spawn_timer_timeout)
	add_child(spawn_timer)
	start_next_wave()

func _process(_delta):
	if not game_active:
		return
	if hud.is_pause_open():
		return

	var living_zombies: int = get_tree().get_nodes_in_group("zombie").size()
	var remaining_to_spawn: int = maxi(zombies_to_spawn_in_wave - spawned_in_wave, 0)
	hud.update_health(player.health)
	hud.update_weapon(player.weapon_name)
	hud.update_ammo(player.ammo, player.max_ammo, player.reserve_ammo)
	hud.update_reload(player.is_reloading, player.get_reload_progress())
	hud.update_wave(current_wave, living_zombies, remaining_to_spawn)
	hud.update_crosshair(player.speed_ratio)
	hud.update_weapon_slots(player.current_weapon_index)

	if player.health <= 0:
		game_over()
		return

	if not waiting_for_next_wave and spawned_in_wave >= zombies_to_spawn_in_wave and living_zombies == 0:
		waiting_for_next_wave = true
		hud.show_status("WAVE %d CLEAR" % current_wave, Color(0.45, 1, 0.55, 1), 1.2)
		hud.show_combat_text("WAVE CLEAR", Color(0.45, 1.0, 0.55, 1.0))
		spawn_timer.start(time_between_waves)

func _on_spawn_timer_timeout():
	if not game_active:
		return
	if hud.is_pause_open():
		return

	if waiting_for_next_wave:
		start_next_wave()
		return

	var current_zombies = get_tree().get_nodes_in_group("zombie").size()
	if current_zombies >= max_zombies or spawned_in_wave >= zombies_to_spawn_in_wave:
		return

	if spawn_points.is_empty():
		return

	var spawn_point = spawn_points.pick_random()
	var zombie = zombie_scene.instantiate()
	zombie.global_position = spawn_point.global_position
	get_tree().current_scene.add_child(zombie)
	spawned_in_wave += 1
	if spawned_in_wave < zombies_to_spawn_in_wave:
		spawn_timer.start(spawn_interval)

func start_next_wave():
	current_wave += 1
	zombies_to_spawn_in_wave = base_wave_size + ((current_wave - 1) * wave_growth)
	spawned_in_wave = 0
	waiting_for_next_wave = false
	hud.show_wave_announcement(current_wave)
	hud.show_status("WAVE %d" % current_wave, Color(1, 0.85, 0.45, 1), 1.1)
	spawn_timer.start(0.25)

func game_over():
	game_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	var elapsed_seconds: int = maxi((Time.get_ticks_msec() - game_start_time_ms) / 1000, 0)
	var stats: Dictionary = {
		"wave": current_wave,
		"kills": player.kills,
		"headshots": player.headshots,
		"accuracy": player.get_accuracy(),
		"time_seconds": elapsed_seconds
	}
	hud.show_game_over(stats)
	get_tree().paused = true
