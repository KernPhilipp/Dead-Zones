extends Node

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const MainWaveProgressionModel = preload("res://scripts/wave/main_wave_progression_model.gd")
const SpawnBudgetModel = preload("res://scripts/wave/spawn_budget_model.gd")
const ExtraLayerManager = preload("res://scripts/wave/extra_layer_manager.gd")
const WaveComposer = preload("res://scripts/wave/wave_composer.gd")
const SpawnScheduleBuilder = preload("res://scripts/wave/spawn_schedule_builder.gd")
const MapSpawnProvider = preload("res://scripts/wave/map_spawn_provider.gd")
const SpawnPositionValidator = preload("res://scripts/wave/spawn_position_validator.gd")
const SpawnExecutor = preload("res://scripts/wave/spawn_executor.gd")
const SpecialWaveModifierInterface = preload("res://scripts/wave/special_wave_modifier.gd")

@export_category("Wellen-Budgets")
@export_range(1, 200, 1) var base_wave_spawn_count: int = 8
@export_range(1, 200, 1) var alive_cap: int = 5
@export_range(0.001, 0.2, 0.001) var near_zero_threshold: float = 0.01

@export_category("Spawn-Timing")
@export_range(0.1, 5.0, 0.05) var base_spawn_interval_seconds: float = 2.0
@export_range(0.05, 2.0, 0.05) var spawn_delay_step_seconds: float = 0.25
@export_range(0.0, 15.0, 0.1) var intermission_seconds: float = 3.0

@export_category("Spawn-Position")
@export_range(1.0, 80.0, 0.5) var min_spawn_distance_from_player: float = 10.0
@export_range(1, 64, 1) var spawn_retry_limit: int = 12

@export_category("Profil-Zusatzlayer")
@export var allow_female_variants := true
@export_range(0, 10, 1) var mort_grade_min: int = 0
@export_range(0, 10, 1) var mort_grade_max: int = 10

@export_category("Runtime")
@export var wave_start_on_ready := true

@export_category("Debug & Tuning")
@export var show_wave_debug_overlay := false
@export var allow_runtime_curve_toggle := true
@export var use_tuned_wave_curve := false

var zombie_scene: PackedScene = preload("res://scenes/zombie.tscn")
var player: CharacterBody3D
var hud: CanvasLayer
var game_active: bool = true
var run_start_time_ms: int = 0
var debug_layer: CanvasLayer
var debug_label: Label
var curve_mode: String = "default"

var profile_rng: RandomNumberGenerator
var current_wave_index: int = 0
var wave_elapsed: float = 0.0
var intermission_remaining: float = 0.0
var wave_active: bool = false
var wave_plan: Dictionary = {}
var layer_state: Dictionary = {"layers": []}
var current_alive_cap: int = 0

var runtime_state: Dictionary = {}

var progression_model: RefCounted = MainWaveProgressionModel.new()
var spawn_budget_model: RefCounted = SpawnBudgetModel.new()
var extra_layer_manager: RefCounted = ExtraLayerManager.new()
var wave_composer: RefCounted = WaveComposer.new()
var schedule_builder: RefCounted = SpawnScheduleBuilder.new()
var map_spawn_provider: RefCounted = MapSpawnProvider.new()
var spawn_position_validator: RefCounted = SpawnPositionValidator.new()
var spawn_executor: RefCounted = SpawnExecutor.new()
var special_wave_modifier: RefCounted = SpecialWaveModifierInterface.new()

func _ready():
	run_start_time_ms = Time.get_ticks_msec()
	player = get_tree().get_first_node_in_group("player")
	hud = get_node_or_null("../HUD")

	if player != null and hud != null:
		player.shot_feedback.connect(func(hit): if hud.has_method("show_shot_feedback"): hud.show_shot_feedback(hit))
		player.kill_feedback.connect(func(): if hud.has_method("show_kill_feedback"): hud.show_kill_feedback())
		player.reload_feedback.connect(func(msg, col): if hud.has_method("show_status"): hud.show_status(msg, col))
		player.damage_feedback.connect(func(amt, dir): if hud.has_method("show_damage_feedback"): hud.show_damage_feedback(amt, dir))
		player.combat_text_feedback.connect(func(msg, col): if hud.has_method("show_combat_text"): hud.show_combat_text(msg, col))
		player.unlock_feedback.connect(func(_type, _id, display_name): if hud.has_method("show_unlock_feedback"): hud.show_unlock_feedback(display_name))
		if hud.has_method("update_weapon"):
			hud.update_weapon(player.weapon_name)
		if hud.has_method("update_weapon_slots"):
			hud.update_weapon_slots(player.current_weapon_index)

	profile_rng = RandomNumberGenerator.new()
	profile_rng.randomize()
	curve_mode = "tuned" if use_tuned_wave_curve else "default"
	_refresh_spawn_sources()
	_initialize_runtime_state()
	_setup_debug_overlay()

	if wave_start_on_ready:
		_start_next_wave()
	else:
		intermission_remaining = intermission_seconds

func _process(delta: float):
	if not game_active:
		return

	_update_hud()
	if player and is_instance_valid(player) and player.health <= 0:
		game_over()
		return

	if wave_active:
		_process_active_wave(delta)
	else:
		_process_intermission(delta)

	_update_debug_overlay()

func _unhandled_input(event: InputEvent):
	if not allow_runtime_curve_toggle:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		var key_event: InputEventKey = event
		if key_event.keycode == KEY_F7:
			use_tuned_wave_curve = not use_tuned_wave_curve
			curve_mode = "tuned" if use_tuned_wave_curve else "default"
			if debug_label != null:
				_update_debug_overlay()
			get_viewport().set_input_as_handled()

func game_over():
	game_active = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	if hud and hud.has_method("show_game_over"):
		var stats: Dictionary = {}
		if player != null and is_instance_valid(player) and player.has_method("build_game_over_stats"):
			var run_time_seconds: int = maxi(int((Time.get_ticks_msec() - run_start_time_ms) / 1000), 0)
			stats = player.build_game_over_stats(current_wave_index, run_time_seconds)
		hud.show_game_over(stats)
	get_tree().paused = true

func get_runtime_state() -> Dictionary:
	var state: Dictionary = runtime_state.duplicate(true)
	state["current_wave_plan"] = wave_plan.duplicate(true)
	return state

func _update_hud():
	if hud == null or not is_instance_valid(hud):
		return
	if player == null or not is_instance_valid(player):
		return
	if hud.has_method("update_health"):
		hud.update_health(player.health)
	if hud.has_method("update_armor"):
		hud.update_armor(player.armor, player.max_armor)
	if hud.has_method("update_ammo"):
		hud.update_ammo(player.ammo, player.max_ammo, player.reserve_ammo)
	if hud.has_method("update_currency"):
		hud.update_currency(player.points)
	if hud.has_method("update_inventory"):
		hud.update_inventory(player.item_inventory.build_state(player.progression.get_unlocked_items()))
	if hud.has_method("update_weapon"):
		hud.update_weapon(player.weapon_name)
	if hud.has_method("update_weapon_slots"):
		hud.update_weapon_slots(player.current_weapon_index)
	if hud.has_method("update_reload"):
		hud.update_reload(player.is_reloading, player.get_reload_progress())
	if hud.has_method("update_crosshair"):
		hud.update_crosshair(player.speed_ratio)
	if hud.has_method("update_wave"):
		var total: int = int(wave_plan.get("total_count", 0))
		var pending: int = int(wave_plan.get("pending_index", 0))
		var remaining_to_spawn: int = max(0, total - pending)
		hud.update_wave(current_wave_index, _get_alive_zombie_count(), remaining_to_spawn)

func _process_intermission(delta: float):
	if intermission_remaining > 0.0:
		intermission_remaining = maxf(0.0, intermission_remaining - delta)
		runtime_state["intermission_remaining"] = intermission_remaining
		if intermission_remaining > 0.0:
			return

	_start_next_wave()

func _process_active_wave(delta: float):
	wave_elapsed += delta
	runtime_state["elapsed_wave_time"] = wave_elapsed
	runtime_state["current_wave"] = current_wave_index

	var alive_count: int = _get_alive_zombie_count()
	runtime_state["alive_count"] = alive_count

	var execution_result: Dictionary = spawn_executor.execute_due_entries(
		wave_plan,
		wave_elapsed,
		alive_count,
		current_alive_cap,
		spawn_delay_step_seconds,
		spawn_retry_limit,
		Callable(self, "_spawn_wave_entry")
	)
	wave_plan = execution_result.get("wave_plan", wave_plan)
	runtime_state["pending_index"] = int(wave_plan.get("pending_index", 0))

	alive_count = _get_alive_zombie_count()
	runtime_state["alive_count"] = alive_count
	if _is_wave_complete(alive_count):
		_finish_wave()

func _start_next_wave():
	if not game_active:
		return

	_refresh_spawn_sources()
	current_wave_index += 1
	wave_elapsed = 0.0
	intermission_remaining = 0.0

	var wave_scale: int = current_wave_index - 1
	var scaled_spawn_count: int = base_wave_spawn_count + wave_scale * 2
	var scaled_interval: float = maxf(0.5, base_spawn_interval_seconds - wave_scale * 0.15)
	current_alive_cap = mini(alive_cap + wave_scale, 15)

	var budget: Dictionary = spawn_budget_model.build_budget(scaled_spawn_count)
	var main_distribution: Dictionary = progression_model.build_distribution(
		current_wave_index,
		special_wave_modifier,
		curve_mode
	)
	var main_counts: Dictionary = wave_composer.sample_rank_counts(
		main_distribution,
		int(budget["main_spawn_budget"]),
		profile_rng
	)
	var displaced_ranks: Array[int] = progression_model.get_displaced_ranks(
		main_distribution,
		near_zero_threshold,
		current_wave_index,
		special_wave_modifier,
		curve_mode
	)
	layer_state = extra_layer_manager.update_layers(layer_state, displaced_ranks)

	var raw_extra_budget: int = int(budget["extra_spawn_budget"])
	var extra_budget_mult: float = 1.0
	if special_wave_modifier != null and special_wave_modifier.has_method("get_extra_budget_multiplier"):
		extra_budget_mult = maxf(0.0, float(special_wave_modifier.call("get_extra_budget_multiplier", current_wave_index)))
	var adjusted_extra_budget: int = clampi(
		int(floor(float(raw_extra_budget) * extra_budget_mult)),
		0,
		raw_extra_budget
	)
	var extra_result: Dictionary = extra_layer_manager.compose_extra_spawns(layer_state, adjusted_extra_budget)

	var entries: Array[Dictionary] = wave_composer.build_entries(
		current_wave_index,
		main_counts,
		extra_result.get("allocations", []),
		allow_female_variants,
		mort_grade_min,
		mort_grade_max,
		profile_rng
	)
	var scheduled_entries: Array[Dictionary] = schedule_builder.build_schedule(
		entries,
		current_wave_index,
		scaled_interval,
		special_wave_modifier,
		profile_rng
	)

	wave_plan = {
		"wave_index": current_wave_index,
		"main_count": int(budget["main_spawn_budget"]),
		"extra_count": int(extra_result.get("total_extra", 0)),
		"total_count": scheduled_entries.size(),
		"entries": scheduled_entries,
		"created_at": Time.get_unix_time_from_system(),
		"pending_index": 0,
		"main_distribution": main_distribution,
		"main_rank_counts": main_counts,
		"layer_state": layer_state.duplicate(true),
		"extra_activation": float(extra_result.get("activation", 0.0))
	}

	wave_active = true
	_initialize_runtime_state()
	if hud != null and is_instance_valid(hud) and hud.has_method("show_wave_announcement"):
		hud.show_wave_announcement(current_wave_index)
	runtime_state["current_wave"] = current_wave_index
	runtime_state["elapsed_wave_time"] = 0.0
	runtime_state["pending_index"] = 0
	runtime_state["alive_count"] = _get_alive_zombie_count()
	runtime_state["curve_mode"] = curve_mode

func _finish_wave():
	wave_active = false
	intermission_remaining = intermission_seconds
	runtime_state["intermission_remaining"] = intermission_remaining
	for corpse in get_tree().get_nodes_in_group("zombie_corpse"):
		if corpse.has_method("despawn_immediately"):
			corpse.despawn_immediately()
		else:
			corpse.queue_free()

func _is_wave_complete(alive_count: int) -> bool:
	if not wave_active:
		return false

	var entries: Array = wave_plan.get("entries", [])
	if int(wave_plan.get("pending_index", 0)) < entries.size():
		return false

	for entry in entries:
		var state: String = String(entry.get("state", "planned"))
		if state == "planned" or state == "delayed":
			return false

	return alive_count <= 0

func _spawn_wave_entry(entry: Dictionary) -> bool:
	var scene_root: Node = get_tree().current_scene
	if scene_root == null:
		return false

	var zombie: Node3D = zombie_scene.instantiate() as Node3D
	if zombie == null:
		return false

	var spawn_result: Dictionary = spawn_position_validator.find_valid_position(
		map_spawn_provider,
		player,
		min_spawn_distance_from_player,
		spawn_retry_limit,
		profile_rng
	)
	if not bool(spawn_result.get("valid", false)):
		zombie.queue_free()
		return false

	var spawn_position: Vector3 = spawn_result.get("position", Vector3.ZERO)
	var local_spawn_position: Vector3 = spawn_position
	if scene_root is Node3D:
		local_spawn_position = (scene_root as Node3D).to_local(spawn_position)
	zombie.position = local_spawn_position

	_apply_profile_from_entry(zombie, entry)
	scene_root.add_child(zombie)
	zombie.global_position = spawn_position
	return true

func _apply_profile_from_entry(zombie: Node, entry: Dictionary):
	if not zombie.has_method("configure_profile"):
		return

	zombie.call(
		"configure_profile",
		int(entry.get("species_id", ZombieDefinitions.DEFAULT_SPECIES)),
		int(entry.get("class_id", ZombieDefinitions.DEFAULT_CLASS)),
		int(entry.get("mort_grade", ZombieDefinitions.DEFAULT_MORT_GRADE)),
		int(entry.get("rank_id", ZombieDefinitions.DEFAULT_RANK)),
		String(entry.get("visual_variant", ZombieDefinitions.DEFAULT_VISUAL_VARIANT)),
		int(entry.get("death_class_id", ZombieDefinitions.DEFAULT_DEATH_CLASS)),
		int(entry.get("death_subtype_id", ZombieDefinitions.DEFAULT_DEATH_SUBTYPE))
	)

func _refresh_spawn_sources():
	if map_spawn_provider != null and map_spawn_provider.has_method("refresh_from_scene"):
		map_spawn_provider.call("refresh_from_scene", self)

func _get_alive_zombie_count() -> int:
	return get_tree().get_nodes_in_group("zombie").size()

func _initialize_runtime_state():
	runtime_state = {
		"current_wave": current_wave_index,
		"elapsed_wave_time": wave_elapsed,
		"pending_index": int(wave_plan.get("pending_index", 0)),
		"alive_count": _get_alive_zombie_count(),
		"layer_state": layer_state.duplicate(true),
		"intermission_remaining": intermission_remaining,
		"curve_mode": curve_mode
	}

func _setup_debug_overlay():
	if not show_wave_debug_overlay:
		return
	if debug_layer != null and is_instance_valid(debug_layer):
		return

	debug_layer = CanvasLayer.new()
	debug_layer.layer = 50
	add_child(debug_layer)

	debug_label = Label.new()
	debug_label.name = "WaveDebugLabel"
	debug_label.position = Vector2(20.0, 20.0)
	debug_label.size = Vector2(900.0, 300.0)
	debug_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	debug_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	debug_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	debug_layer.add_child(debug_label)

func _update_debug_overlay():
	if not show_wave_debug_overlay:
		if debug_layer != null and is_instance_valid(debug_layer):
			debug_layer.visible = false
		return
	if debug_label == null or not is_instance_valid(debug_label):
		return

	if debug_layer != null and is_instance_valid(debug_layer):
		debug_layer.visible = true

	var plan_total: int = int(wave_plan.get("total_count", 0))
	var plan_pending_index: int = int(wave_plan.get("pending_index", 0))
	var plan_remaining: int = max(0, plan_total - plan_pending_index)
	var main_count: int = int(wave_plan.get("main_count", 0))
	var extra_count: int = int(wave_plan.get("extra_count", 0))
	var alive_count: int = _get_alive_zombie_count()
	var spawn_points_count: int = 0
	if map_spawn_provider != null and map_spawn_provider.has_method("get_point_count"):
		spawn_points_count = int(map_spawn_provider.call("get_point_count"))

	var layers_summary: String = _build_layer_debug_summary()
	var distribution_summary: String = _build_distribution_debug_summary()
	var phase: String = "ACTIVE" if wave_active else "INTERMISSION"

	debug_label.text = "Wave %d [%s] | Curve=%s (F7 Toggle)\nPlan total=%d main=%d extra=%d pending=%d alive=%d\nElapsed=%.2fs Intermission=%.2fs AliveCap=%d BaseInterval=%.2fs\nSpawnPoints=%d MinDist=%.1fm Retry=%d\nDistribution: %s\nLayers: %s" % [
		current_wave_index,
		phase,
		curve_mode,
		plan_total,
		main_count,
		extra_count,
		plan_remaining,
		alive_count,
		wave_elapsed,
		intermission_remaining,
		alive_cap,
		base_spawn_interval_seconds,
		spawn_points_count,
		min_spawn_distance_from_player,
		spawn_retry_limit,
		distribution_summary,
		layers_summary
	]

func _build_distribution_debug_summary() -> String:
	var distribution: Dictionary = wave_plan.get("main_distribution", {})
	if distribution.is_empty():
		return "-"

	var rank_order: Array[int] = [
		ZombieDefinitions.Rank.ALPHA,
		ZombieDefinitions.Rank.BETA,
		ZombieDefinitions.Rank.GAMMA,
		ZombieDefinitions.Rank.DELTA,
		ZombieDefinitions.Rank.EPSILON
	]
	var chunks: Array[String] = []
	for rank_id in rank_order:
		var rank_cfg: Dictionary = ZombieDefinitions.get_rank_data(rank_id)
		var name: String = String(rank_cfg.get("display_name", String(rank_cfg.get("id", "rank"))))
		var prob: float = float(distribution.get(rank_id, 0.0)) * 100.0
		chunks.append("%s %.2f%%" % [name, prob])
	return _join_chunks(chunks)

func _build_layer_debug_summary() -> String:
	var layers: Array = layer_state.get("layers", [])
	if layers.is_empty():
		return "-"

	var chunks: Array[String] = []
	for index in range(layers.size()):
		var layer_depth: int = index + 1
		var layer_entry: Dictionary = layers[index]
		var rank_id: int = int(layer_entry.get("rank_id", ZombieDefinitions.Rank.EPSILON))
		var rank_cfg: Dictionary = ZombieDefinitions.get_rank_data(rank_id)
		var rank_name: String = String(rank_cfg.get("display_name", String(rank_cfg.get("id", "rank"))))
		var waves_in_layer: int = int(layer_entry.get("waves_in_layer", 0))
		chunks.append("L%d:%s(w%d)" % [layer_depth, rank_name, waves_in_layer])
	return _join_chunks(chunks)

func _join_chunks(chunks: Array[String]) -> String:
	if chunks.is_empty():
		return "-"
	var output: String = ""
	for index in range(chunks.size()):
		output += chunks[index]
		if index < chunks.size() - 1:
			output += " | "
	return output
