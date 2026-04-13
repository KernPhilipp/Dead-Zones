extends CanvasLayer

const HANDBOOK_SCENE := preload("res://scenes/handbook_book.tscn")

var health_bar: ProgressBar
var health_damage_bar: ProgressBar
var health_value_label: Label
var low_health_label: Label
var start_hint_label: Label
var weapon_label: Label
var ammo_label: Label
var ammo_state_label: Label
var reserve_label: Label
var weapon_grip: ColorRect
var weapon_body: ColorRect
var weapon_slide: ColorRect
var weapon_muzzle: ColorRect
var slot_label_one: Label
var slot_label_two: Label
var status_label: Label
var wave_label: Label
var zombie_label: Label
var wave_announce_label: Label
var combat_text_primary: Label
var combat_text_secondary: Label
var reload_panel: PanelContainer
var reload_bar: ProgressBar
var hit_marker: Control
var kill_confirm_label: Label
var crosshair_root: Control
var crosshair_left: ColorRect
var crosshair_right: ColorRect
var crosshair_top: ColorRect
var crosshair_bottom: ColorRect
var crosshair_dot: ColorRect
var damage_compass: Control
var damage_compass_marker: Control
var damage_compass_marker_alt_a: Control
var damage_compass_marker_alt_b: Control
var damage_flash: ColorRect
var low_health_overlay: ColorRect
var blood_overlay: TextureRect
var pause_dimmer: ColorRect
var pause_panel: PanelContainer
var pause_summary_label: Label
var pause_controls_label: Label
var pause_settings_label: Label
var resume_button: Button
var handbook_button: Button
var pause_restart_button: Button
var game_over_panel: PanelContainer
var game_over_label: Label
var game_over_summary_label: Label
var game_over_stats_label: Label
var game_over_hint_label: Label
var restart_button: Button
var health_panel: PanelContainer
var wave_panel: PanelContainer
var weapon_panel: PanelContainer

var status_timer: SceneTreeTimer
var damage_flash_tween: Tween
var blood_overlay_tween: Tween
var wave_announce_tween: Tween
var game_over_tween: Tween
var hit_marker_tween: Tween
var kill_confirm_tween: Tween
var pause_tween: Tween
var combat_primary_tween: Tween
var combat_secondary_tween: Tween
var ammo_warning_tween: Tween
var damage_compass_tween: Tween
var low_health_strength: float = 0.0
var low_health_time: float = 0.0
var displayed_health: float = 100.0
var target_health: float = 100.0
var nodes_initialized: bool = false
var crosshair_spread: float = 4.0
var current_ammo_state: String = "READY"
var session_start_msec: int = 0
var low_health_panel_pulse: float = 0.0
var last_wave_number: int = 0
var wave_clear_announced: bool = false
var reload_was_active: bool = false
var tracked_total_eliminations: int = 0
var tracked_wave_index: int = 0
var tracked_wave_total: int = 0
var tracked_wave_eliminations: int = 0
var crosshair_flash_color: Color = Color(0.95, 0.97, 1.0, 0.92)
var crosshair_dot_flash_color: Color = Color(0.95, 0.97, 1.0, 1.0)
var crosshair_scale_target: Vector2 = Vector2.ONE
var crosshair_scale_velocity: float = 0.18
var crosshair_extra_spread: float = 0.0
var crosshair_base_color: Color = Color(0.95, 0.97, 1.0, 0.92)
var crosshair_dot_base_color: Color = Color(0.95, 0.97, 1.0, 1.0)
var damage_compass_markers: Array[Control] = []
var damage_compass_next_index: int = 0
var combat_message_priorities: Dictionary = {}
var combat_primary_priority: int = -1
var combat_secondary_priority: int = -1
var recent_threat_time: float = 0.0
var milestone_kills_announced: int = 0
var active_weapon_slot_index: int = 0
var adaptive_threat_level: float = 0.0
var handbook_book: Control
var handbook_opened_from_pause: bool = false

func _enter_tree():
	_ensure_nodes()

func _ready():
	_ensure_nodes()
	session_start_msec = Time.get_ticks_msec()
	game_over_panel.visible = false
	hit_marker.visible = false
	kill_confirm_label.visible = false
	kill_confirm_label.modulate.a = 0.0
	damage_flash.visible = true
	damage_flash.modulate.a = 0.0
	low_health_overlay.visible = true
	low_health_overlay.modulate.a = 0.0
	blood_overlay.visible = true
	blood_overlay.modulate.a = 0.0
	wave_announce_label.visible = false
	wave_announce_label.modulate.a = 0.0
	combat_text_primary.text = ""
	combat_text_primary.modulate.a = 0.0
	combat_text_secondary.text = ""
	combat_text_secondary.modulate.a = 0.0
	health_bar.value = 100.0
	health_damage_bar.value = 100.0
	low_health_label.visible = false
	low_health_label.modulate.a = 0.0
	start_hint_label.visible = false
	start_hint_label.modulate.a = 0.0
	pause_dimmer.visible = false
	pause_dimmer.modulate.a = 0.0
	pause_panel.visible = false
	pause_panel.modulate.a = 0.0
	pause_panel.scale = Vector2(0.94, 0.94)
	reload_panel.visible = false
	reload_bar.value = 0.0
	status_label.text = "READY"
	ammo_state_label.text = "READY"
	ammo_state_label.modulate = Color(0.82, 0.86, 0.92, 0.9)
	ammo_label.text = "030 | 120"
	game_over_panel.modulate.a = 0.0
	game_over_label.scale = Vector2(0.75, 0.75)
	game_over_summary_label.modulate.a = 0.0
	game_over_stats_label.modulate.a = 0.0
	game_over_hint_label.modulate.a = 0.0
	restart_button.modulate.a = 0.0
	damage_compass_marker.visible = false
	damage_compass_marker.modulate.a = 0.0
	damage_compass_marker_alt_a.visible = false
	damage_compass_marker_alt_a.modulate.a = 0.0
	damage_compass_marker_alt_b.visible = false
	damage_compass_marker_alt_b.modulate.a = 0.0
	_hide_legacy_damage_indicators()
	update_weapon_slots(0)
	_set_crosshair_state("default")
	update_crosshair(0.0)
	resume_button.pressed.connect(_on_resume)
	handbook_button.pressed.connect(_on_handbook_pressed)
	pause_restart_button.pressed.connect(_on_restart)
	restart_button.pressed.connect(_on_restart)
	_setup_handbook_overlay()
	_show_start_hints()

func _ensure_nodes():
	if nodes_initialized:
		return

	health_bar = _find_required_node("HealthBar") as ProgressBar
	health_damage_bar = _find_required_node("HealthDamageBar") as ProgressBar
	health_value_label = _find_required_node("HealthValueLabel") as Label
	low_health_label = _find_required_node("LowHealthLabel") as Label
	start_hint_label = _find_required_node("StartHintLabel") as Label
	weapon_label = _find_required_node("WeaponLabel") as Label
	ammo_label = _find_required_node("AmmoLabel") as Label
	ammo_state_label = _find_required_node("AmmoStateLabel") as Label
	reserve_label = _find_required_node("ReserveLabel") as Label
	weapon_grip = _find_required_node("Grip") as ColorRect
	weapon_body = _find_required_node("Body") as ColorRect
	weapon_slide = _find_required_node("Slide") as ColorRect
	weapon_muzzle = _find_required_node("Muzzle") as ColorRect
	slot_label_one = _find_required_node("SlotLabelOne") as Label
	slot_label_two = _find_required_node("SlotLabelTwo") as Label
	status_label = _find_required_node("StatusLabel") as Label
	wave_label = _find_required_node("WaveLabel") as Label
	zombie_label = _find_required_node("ZombieLabel") as Label
	wave_announce_label = _find_required_node("WaveAnnounceLabel") as Label
	combat_text_primary = _find_required_node("CombatTextPrimary") as Label
	combat_text_secondary = _find_required_node("CombatTextSecondary") as Label
	reload_panel = _find_required_node("ReloadPanel") as PanelContainer
	reload_bar = _find_required_node("ReloadBar") as ProgressBar
	hit_marker = _find_required_node("HitMarker") as Control
	kill_confirm_label = _find_required_node("KillConfirmLabel") as Label
	crosshair_root = _find_required_node("CrosshairRoot") as Control
	crosshair_left = _find_required_node("HorizontalLeft") as ColorRect
	crosshair_right = _find_required_node("HorizontalRight") as ColorRect
	crosshair_top = _find_required_node("VerticalTop") as ColorRect
	crosshair_bottom = _find_required_node("VerticalBottom") as ColorRect
	crosshair_dot = _find_required_node("Dot") as ColorRect
	damage_compass = _find_required_node("DamageCompass") as Control
	damage_compass_marker = _find_required_node("DamageCompassMarker") as Control
	damage_compass_marker_alt_a = _find_required_node("DamageCompassMarkerAltA") as Control
	damage_compass_marker_alt_b = _find_required_node("DamageCompassMarkerAltB") as Control
	damage_flash = _find_required_node("DamageFlash") as ColorRect
	low_health_overlay = _find_required_node("LowHealthOverlay") as ColorRect
	blood_overlay = _find_required_node("BloodOverlay") as TextureRect
	pause_dimmer = _find_required_node("PauseDimmer") as ColorRect
	pause_panel = _find_required_node("PausePanel") as PanelContainer
	pause_summary_label = _find_required_node("PauseSummaryLabel") as Label
	pause_controls_label = _find_required_node("PauseControlsLabel") as Label
	pause_settings_label = _find_required_node("PauseSettingsLabel") as Label
	resume_button = _find_required_node("ResumeButton") as Button
	handbook_button = _find_required_node("HandbookButton") as Button
	pause_restart_button = _find_required_node("PauseRestartButton") as Button
	game_over_panel = _find_required_node("GameOverPanel") as PanelContainer
	game_over_label = _find_required_node("GameOverLabel") as Label
	game_over_summary_label = _find_required_node("GameOverSummaryLabel") as Label
	game_over_stats_label = _find_required_node("GameOverStatsLabel") as Label
	game_over_hint_label = _find_required_node("GameOverHintLabel") as Label
	restart_button = _find_required_node("RestartButton") as Button
	health_panel = _find_required_node("HealthPanel") as PanelContainer
	wave_panel = _find_required_node("WavePanel") as PanelContainer
	weapon_panel = _find_required_node("WeaponPanel") as PanelContainer
	damage_compass_markers = [damage_compass_marker, damage_compass_marker_alt_a, damage_compass_marker_alt_b]
	nodes_initialized = true

func _find_required_node(node_name: String) -> Node:
	var node := find_child(node_name, true, false)
	if node == null:
		push_error("HUD node not found: %s" % node_name)
	return node

func _process(delta):
	_ensure_nodes()
	displayed_health = lerpf(displayed_health, target_health, clampf(delta * 10.0, 0.0, 1.0))
	health_damage_bar.value = displayed_health
	crosshair_root.scale = crosshair_root.scale.lerp(crosshair_scale_target, clampf(delta / maxf(crosshair_scale_velocity, 0.001), 0.0, 1.0))
	crosshair_extra_spread = lerpf(crosshair_extra_spread, 0.0, clampf(delta * 9.0, 0.0, 1.0))
	_update_crosshair_colors(delta)
	recent_threat_time = maxf(0.0, recent_threat_time - delta)
	_update_adaptive_hud(delta)
	_update_session_milestones()

	if handbook_book != null and handbook_book.visible:
		if Input.is_action_just_pressed("pause_game"):
			_close_handbook_overlay()
		return

	if handbook_opened_from_pause and handbook_book != null and not handbook_book.visible:
		_restore_pause_menu_after_handbook()
		handbook_opened_from_pause = false

	if Input.is_action_just_pressed("pause_game") and not game_over_panel.visible:
		toggle_pause_menu()

	low_health_time += delta
	if low_health_strength <= 0.0:
		low_health_overlay.modulate.a = 0.0
		low_health_label.visible = false
		low_health_label.modulate.a = 0.0
		low_health_label.scale = Vector2.ONE
		health_panel.scale = health_panel.scale.lerp(Vector2.ONE, clampf(delta * 8.0, 0.0, 1.0))
		health_panel.modulate.a = 1.0
		return

	var pulse: float = 0.48 + (sin(low_health_time * 5.8) * 0.24)
	var hard_pulse: float = 0.7 + (sin(low_health_time * 8.2) * 0.18)
	low_health_panel_pulse = 1.0 + (sin(low_health_time * 7.2) * 0.025 * low_health_strength)
	low_health_overlay.modulate.a = low_health_strength * (pulse + 0.28)
	low_health_label.visible = true
	low_health_label.modulate.a = clampf(low_health_strength * hard_pulse, 0.0, 1.0)
	low_health_label.scale = Vector2.ONE * (1.0 + low_health_strength * 0.16)
	health_panel.scale = Vector2.ONE * low_health_panel_pulse
	health_panel.modulate.a = clampf(0.9 + low_health_strength * 0.22, 0.0, 1.0)

func update_health(value: int):
	_ensure_nodes()
	target_health = float(value)
	health_bar.value = value
	var health_ratio_visual: float = float(value) / 100.0
	health_bar.modulate = Color(
		lerpf(1.0, 0.25, health_ratio_visual),
		lerpf(0.18, 0.95, health_ratio_visual),
		lerpf(0.18, 0.3, health_ratio_visual),
		1.0
	)
	health_value_label.text = "HP %03d" % value
	var health_ratio: float = float(value) / 100.0
	low_health_strength = clampf((0.4 - health_ratio) / 0.4, 0.0, 0.78)
	if low_health_strength > 0.0:
		low_health_label.text = "CRITICAL" if value > 15 else "BLEEDING OUT"
	else:
		low_health_label.text = ""
	health_panel.modulate = Color(
		1.0,
		lerpf(0.45, 1.0, health_ratio),
		lerpf(0.45, 1.0, health_ratio),
		1.0
	)
	health_value_label.modulate = Color(1.0, lerpf(0.42, 0.98, health_ratio), lerpf(0.42, 0.98, health_ratio), 1.0)
	_apply_adaptive_hud_presence()

func update_weapon(weapon_name: String):
	_ensure_nodes()
	weapon_label.text = weapon_name.to_upper()
	_update_weapon_icon(weapon_name)

func update_weapon_slots(active_index: int):
	_ensure_nodes()
	active_weapon_slot_index = active_index
	var active_color: Color = Color(1.0, 0.85, 0.45, 1.0)
	var inactive_color: Color = Color(0.65, 0.65, 0.65, 1.0)
	slot_label_one.text = "[1]" if active_index == 0 else " 1 "
	slot_label_two.text = "[2]" if active_index == 1 else " 2 "
	slot_label_one.modulate = active_color if active_index == 0 else inactive_color
	slot_label_two.modulate = active_color if active_index == 1 else inactive_color
	slot_label_one.scale = Vector2.ONE * (1.12 if active_index == 0 else 0.94)
	slot_label_two.scale = Vector2.ONE * (1.12 if active_index == 1 else 0.94)
	_apply_adaptive_hud_presence()

func update_ammo(current: int, max_val: int, reserve: int):
	_ensure_nodes()
	ammo_label.text = "%03d | %03d" % [current, reserve]
	reserve_label.text = "MAG CAP %02d" % max_val
	var ammo_ratio: float = float(current) / maxf(float(max_val), 1.0)
	if current <= 0:
		current_ammo_state = "EMPTY"
		ammo_label.modulate = Color(1.0, 0.28, 0.22, 1.0)
		reserve_label.modulate = Color(0.98, 0.52, 0.42, 0.96)
		ammo_state_label.modulate = Color(1.0, 0.28, 0.22, 1.0)
		ammo_state_label.text = "MAG EMPTY"
		_set_crosshair_state("empty")
		recent_threat_time = maxf(recent_threat_time, 0.8)
		_start_ammo_warning()
	elif ammo_ratio <= 0.2:
		current_ammo_state = "LOW AMMO"
		ammo_label.modulate = Color(1.0, 0.34, 0.28, 1.0)
		reserve_label.modulate = Color(1.0, 0.54, 0.46, 0.96)
		ammo_state_label.modulate = Color(1.0, 0.34, 0.28, 1.0)
		ammo_state_label.text = "LOW AMMO"
		_set_crosshair_state("warning")
		recent_threat_time = maxf(recent_threat_time, 0.4)
		_start_ammo_warning()
	elif ammo_ratio <= 0.4:
		current_ammo_state = "CHECK MAG"
		ammo_label.modulate = Color(1.0, 0.82, 0.35, 1.0)
		reserve_label.modulate = Color(0.98, 0.82, 0.38, 0.96)
		ammo_state_label.modulate = Color(1.0, 0.82, 0.35, 0.96)
		ammo_state_label.text = "CHECK MAG"
		_set_crosshair_state("warning")
		_stop_ammo_warning()
	else:
		current_ammo_state = "READY"
		ammo_label.modulate = Color(1.0, 1.0, 1.0, 1.0)
		reserve_label.modulate = Color(0.82, 0.86, 0.92, 0.9)
		ammo_state_label.modulate = Color(0.82, 0.86, 0.92, 0.9)
		ammo_state_label.text = "READY"
		_set_crosshair_state("default")
		_stop_ammo_warning()
	_apply_adaptive_hud_presence()

func update_reload(active: bool, progress: float):
	_ensure_nodes()
	reload_panel.visible = active
	reload_bar.value = progress * 100.0
	if active:
		reload_was_active = true
		_set_crosshair_state("reload")
		recent_threat_time = maxf(recent_threat_time, 0.3)
		ammo_state_label.text = "RELOADING %02d%%" % int(round(progress * 100.0))
		ammo_state_label.modulate = Color(1.0, 0.8, 0.35, 1.0)
		ammo_label.modulate = Color(1.0, 0.92, 0.66, 1.0)
		reserve_label.modulate = Color(1.0, 0.82, 0.42, 0.96)
		_stop_ammo_warning()
	else:
		ammo_state_label.text = current_ammo_state
		if current_ammo_state == "EMPTY":
			_set_crosshair_state("empty")
		elif current_ammo_state == "LOW AMMO" or current_ammo_state == "CHECK MAG":
			_set_crosshair_state("warning")
		else:
			_set_crosshair_state("default")
		if reload_was_active:
			reload_was_active = false
			show_status("RELOAD COMPLETE", Color(0.46, 1.0, 0.56, 1.0), 0.3)
			show_combat_text("RELOADED", Color(0.76, 1.0, 0.82, 1.0))

func update_wave(wave: int, living_zombies: int, remaining_to_spawn: int):
	_ensure_nodes()
	_update_elimination_tracking(wave, living_zombies, remaining_to_spawn)
	wave_label.text = "WAVE %02d" % wave
	zombie_label.text = "Zombies: %d  Incoming: %d" % [living_zombies, remaining_to_spawn]
	if wave != last_wave_number:
		last_wave_number = wave
		wave_clear_announced = false
	if wave > 0 and living_zombies <= 0 and remaining_to_spawn <= 0 and not wave_clear_announced:
		wave_clear_announced = true
		show_combat_text("WAVE CLEAR", Color(1.0, 0.28, 0.24, 1.0))
		show_status("AREA SECURE", Color(1.0, 0.28, 0.24, 1.0), 0.55)
	_apply_adaptive_hud_presence()

func update_crosshair(movement_ratio: float):
	_ensure_nodes()
	var ratio: float = clampf(movement_ratio, 0.0, 1.0)
	var target_spread: float = lerpf(2.0, 5.0, ratio) + crosshair_extra_spread
	crosshair_spread = lerpf(crosshair_spread, target_spread, 0.2)
	var center: float = 16.0
	crosshair_left.position = Vector2(center - crosshair_spread - 5.0, 15.0)
	crosshair_right.position = Vector2(center + crosshair_spread, 15.0)
	crosshair_top.position = Vector2(15.0, center - crosshair_spread - 5.0)
	crosshair_bottom.position = Vector2(15.0, center + crosshair_spread)
	crosshair_dot.modulate.a = lerpf(crosshair_dot.modulate.a, lerpf(1.0, 0.68, ratio), 0.22)
	if ratio > 0.45 and current_ammo_state == "READY":
		_set_crosshair_state("move")
	elif current_ammo_state == "READY":
		_set_crosshair_state("default")

func show_wave_announcement(wave: int):
	_ensure_nodes()
	if wave_announce_tween:
		wave_announce_tween.kill()
	wave_announce_label.text = "WAVE %02d\nINCOMING" % wave
	wave_announce_label.visible = true
	wave_announce_label.scale = Vector2(1.38, 1.38)
	wave_announce_label.modulate = Color(0.95, 0.98, 1.0, 0.0)
	wave_announce_tween = create_tween()
	wave_announce_tween.tween_property(wave_announce_label, "modulate:a", 1.0, 0.1)
	wave_announce_tween.parallel().tween_property(wave_announce_label, "scale", Vector2(1.02, 1.02), 0.18)
	wave_announce_tween.tween_interval(0.65)
	wave_announce_tween.tween_property(wave_announce_label, "modulate:a", 0.0, 0.24)
	wave_announce_tween.tween_callback(func(): wave_announce_label.visible = false)
	if combat_text_primary.text == "WAVE CLEAR":
		combat_text_primary.text = ""
		combat_text_primary.modulate.a = 0.0
		combat_text_primary.position = Vector2.ZERO
	if combat_text_secondary.text == "WAVE CLEAR":
		combat_text_secondary.text = ""
		combat_text_secondary.modulate.a = 0.0
		combat_text_secondary.position = Vector2.ZERO

func show_combat_text(message: String, color: Color):
	_ensure_nodes()
	var priority: int = _get_combat_text_priority(message)
	if (combat_text_primary.text == "" or combat_text_primary.modulate.a <= 0.05):
		_show_combat_label(combat_text_primary, message, color, true, priority)
		return
	if priority > combat_primary_priority:
		_show_combat_label(combat_text_primary, message, color, true, priority)
		return
	if combat_text_secondary.text == "" or combat_text_secondary.modulate.a <= 0.05:
		_show_combat_label(combat_text_secondary, message, color, false, priority)
		return
	if priority >= combat_secondary_priority:
		_show_combat_label(combat_text_secondary, message, color, false, priority)

func show_kill_feedback():
	_ensure_nodes()
	if hit_marker_tween:
		hit_marker_tween.kill()
	_set_crosshair_state("kill")
	recent_threat_time = maxf(recent_threat_time, 0.9)
	hit_marker_tween = create_tween()
	hit_marker_tween.tween_property(crosshair_root, "scale", Vector2(1.22, 1.22), 0.05)
	hit_marker_tween.tween_property(crosshair_root, "scale", Vector2(1.0, 1.0), 0.1)
	_show_kill_confirm()
	show_status("KILL CONFIRMED", Color(1.0, 0.18, 0.12, 1.0), 0.36)
	show_combat_text("ELIMINATION", Color(1.0, 0.22, 0.16, 1.0))

func show_shot_feedback(hit: bool):
	_ensure_nodes()
	if hit_marker_tween:
		hit_marker_tween.kill()
	if hit:
		_set_crosshair_state("hit")
		recent_threat_time = maxf(recent_threat_time, 0.45)
		hit_marker.visible = true
		hit_marker.modulate = Color(1, 0.32, 0.32, 0.0)
		hit_marker.scale = Vector2(0.55, 0.55)
		hit_marker_tween = create_tween()
		hit_marker_tween.tween_property(hit_marker, "modulate:a", 1.0, 0.06)
		hit_marker_tween.parallel().tween_property(hit_marker, "scale", Vector2(1.2, 1.2), 0.08)
		hit_marker_tween.parallel().tween_property(crosshair_root, "scale", Vector2(1.18, 1.18), 0.08)
		hit_marker_tween.tween_property(hit_marker, "scale", Vector2(0.9, 0.9), 0.08)
		hit_marker_tween.parallel().tween_property(crosshair_root, "scale", Vector2(1.0, 1.0), 0.1)
		hit_marker_tween.tween_property(hit_marker, "modulate:a", 0.0, 0.14)
		hit_marker_tween.tween_callback(func(): hit_marker.visible = false)
		show_status("TARGET HIT", Color(1, 0.35, 0.35, 1), 0.18)
	else:
		_set_crosshair_state("default")
		hit_marker_tween = create_tween()
		hit_marker_tween.tween_property(crosshair_root, "scale", Vector2(1.08, 1.08), 0.05)
		hit_marker_tween.tween_property(crosshair_root, "scale", Vector2(1.0, 1.0), 0.08)
		show_status("NO CONTACT", Color(0.82, 0.84, 0.88, 1), 0.14)

func show_damage_feedback(amount: int, direction: Vector2):
	_ensure_nodes()
	recent_threat_time = maxf(recent_threat_time, 1.6)
	show_status("TAKING FIRE -" + str(amount), Color(1, 0.25, 0.25, 1), 0.38)
	show_combat_text("INCOMING", Color(1.0, 0.24, 0.22, 1.0))
	if damage_flash_tween:
		damage_flash_tween.kill()
	damage_flash.modulate = Color(1, 0.15, 0.15, 0.38)
	damage_flash_tween = create_tween()
	damage_flash_tween.tween_property(damage_flash, "modulate:a", 0.0, 0.28)
	if blood_overlay_tween:
		blood_overlay_tween.kill()
	blood_overlay.modulate = Color(1, 1, 1, 0.72)
	blood_overlay_tween = create_tween()
	blood_overlay_tween.tween_property(blood_overlay, "modulate:a", 0.0, 0.55)
	_show_damage_indicator(direction)

func show_status(message: String, color: Color, duration: float = 0.45):
	_ensure_nodes()
	status_label.text = message
	status_label.modulate = Color(color.r, color.g, color.b, 0.0)
	var tween: Tween = create_tween()
	tween.tween_property(status_label, "modulate:a", 1.0, 0.08)
	if status_timer:
		status_timer = null
	status_timer = get_tree().create_timer(duration)
	await status_timer.timeout
	if status_label.text == message:
		var fade_out: Tween = create_tween()
		fade_out.tween_property(status_label, "modulate:a", 0.0, 0.12)
		await fade_out.finished
		status_label.text = "READY"
		status_label.modulate = Color(0.82, 0.14, 0.12, 1)

func show_game_over(stats: Dictionary = {}):
	_ensure_nodes()
	var resolved_stats: Dictionary = _resolve_game_over_stats(stats)
	if pause_tween:
		pause_tween.kill()
	pause_dimmer.visible = false
	pause_dimmer.modulate.a = 0.0
	pause_panel.visible = false
	pause_panel.modulate.a = 0.0
	pause_panel.scale = Vector2(0.94, 0.94)
	game_over_panel.visible = true
	game_over_panel.modulate.a = 0.0
	game_over_label.scale = Vector2(0.56, 0.56)
	game_over_label.modulate = Color(0.95, 0.08, 0.08, 0.0)
	game_over_summary_label.text = _format_game_over_summary(resolved_stats)
	game_over_summary_label.modulate.a = 0.0
	game_over_stats_label.text = _format_game_over_stats(resolved_stats)
	game_over_stats_label.modulate.a = 0.0
	game_over_hint_label.text = "Press Restart to redeploy."
	game_over_hint_label.modulate.a = 0.0
	restart_button.modulate.a = 0.0
	if game_over_tween:
		game_over_tween.kill()
	game_over_tween = create_tween()
	game_over_tween.tween_property(game_over_panel, "modulate:a", 1.0, 0.2)
	game_over_tween.parallel().tween_property(game_over_label, "modulate:a", 1.0, 0.16)
	game_over_tween.parallel().tween_property(game_over_label, "scale", Vector2(1.08, 1.08), 0.16)
	game_over_tween.tween_property(game_over_label, "scale", Vector2(1.0, 1.0), 0.1)
	game_over_tween.tween_property(game_over_summary_label, "modulate:a", 1.0, 0.14)
	game_over_tween.parallel().tween_property(game_over_stats_label, "modulate:a", 1.0, 0.18)
	game_over_tween.tween_property(game_over_hint_label, "modulate:a", 1.0, 0.14)
	game_over_tween.parallel().tween_property(restart_button, "modulate:a", 1.0, 0.18)

func toggle_pause_menu():
	_ensure_nodes()
	_set_pause_menu_visible(not pause_panel.visible)

func is_pause_open() -> bool:
	_ensure_nodes()
	return pause_panel.visible

func _set_pause_menu_visible(next_visible: bool):
	if pause_tween:
		pause_tween.kill()

	pause_dimmer.visible = true
	pause_panel.visible = true
	pause_tween = create_tween()
	pause_tween.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)

	if next_visible:
		_update_pause_menu_content()
		pause_dimmer.modulate.a = 0.0
		pause_panel.modulate.a = 0.0
		pause_panel.scale = Vector2(0.94, 0.94)
		get_tree().paused = true
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		pause_tween.tween_property(pause_dimmer, "modulate:a", 1.0, 0.16)
		pause_tween.parallel().tween_property(pause_panel, "modulate:a", 1.0, 0.14)
		pause_tween.parallel().tween_property(pause_panel, "scale", Vector2(1.0, 1.0), 0.16)
	else:
		get_tree().paused = false
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
		pause_tween.tween_property(pause_dimmer, "modulate:a", 0.0, 0.14)
		pause_tween.parallel().tween_property(pause_panel, "modulate:a", 0.0, 0.12)
		pause_tween.parallel().tween_property(pause_panel, "scale", Vector2(0.96, 0.96), 0.14)
		pause_tween.tween_callback(func():
			pause_dimmer.visible = false
			pause_panel.visible = false
		)

func _show_damage_indicator(direction: Vector2):
	var normalized_direction: Vector2 = direction.normalized()
	if normalized_direction == Vector2.ZERO:
		normalized_direction = Vector2(0.0, -1.0)

	var angle: float = atan2(normalized_direction.x, -normalized_direction.y)
	var marker: Control = damage_compass_markers[damage_compass_next_index % damage_compass_markers.size()]
	damage_compass_next_index += 1
	var radius: float = 136.0 + float((damage_compass_next_index % 3) * 12)
	var center: Vector2 = damage_compass.size * 0.5
	marker.position = center + (Vector2(sin(angle), -cos(angle)) * radius) - (marker.size * 0.5)
	marker.rotation = angle
	marker.visible = true
	marker.modulate.a = 0.0
	marker.scale = Vector2(0.68, 1.1)
	var tween: Tween = create_tween()
	tween.tween_property(marker, "modulate:a", 1.0, 0.06)
	tween.parallel().tween_property(marker, "scale", Vector2(1.05, 1.28), 0.08)
	tween.tween_interval(0.12)
	tween.tween_property(marker, "modulate:a", 0.0, 0.32)
	tween.parallel().tween_property(marker, "scale", Vector2(1.18, 1.42), 0.32)
	tween.tween_callback(func(): marker.visible = false)

func _hide_legacy_damage_indicators():
	for indicator_name in ["DamageIndicatorTop", "DamageIndicatorBottom", "DamageIndicatorLeft", "DamageIndicatorRight"]:
		var indicator: Control = _find_required_node(indicator_name) as Control
		indicator.visible = false
		indicator.modulate.a = 0.0

func _on_resume():
	_set_pause_menu_visible(false)

func _on_handbook_pressed():
	if handbook_book == null:
		return
	handbook_opened_from_pause = true
	pause_panel.visible = false
	if handbook_book.has_method("open_book"):
		handbook_book.call("open_book")
	call_deferred("_apply_handbook_theme")

func _on_restart():
	if pause_tween:
		pause_tween.kill()
	get_tree().paused = false
	pause_dimmer.visible = false
	pause_dimmer.modulate.a = 0.0
	pause_panel.visible = false
	pause_panel.modulate.a = 0.0
	pause_panel.scale = Vector2(0.94, 0.94)
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	get_tree().reload_current_scene()

func _update_weapon_icon(weapon_name: String):
	var weapon_key: String = weapon_name.to_lower()
	if weapon_key.contains("rifle"):
		weapon_grip.position = Vector2(5.0, 8.0)
		weapon_grip.size = Vector2(5.0, 14.0)
		weapon_grip.rotation = -0.18
		weapon_body.position = Vector2(10.0, 7.0)
		weapon_body.size = Vector2(22.0, 4.0)
		weapon_slide.position = Vector2(14.0, 4.0)
		weapon_slide.size = Vector2(21.0, 4.0)
		weapon_muzzle.position = Vector2(33.0, 5.0)
		weapon_muzzle.size = Vector2(7.0, 3.0)
		weapon_body.color = Color(0.72, 0.76, 0.8, 1.0)
		weapon_slide.color = Color(0.42, 0.47, 0.52, 1.0)
		weapon_grip.color = Color(0.12, 0.12, 0.13, 1.0)
		weapon_muzzle.color = Color(0.92, 0.12, 0.08, 1.0)
	else:
		weapon_grip.position = Vector2(7.0, 9.0)
		weapon_grip.size = Vector2(6.0, 13.0)
		weapon_grip.rotation = -0.35
		weapon_body.position = Vector2(10.0, 6.0)
		weapon_body.size = Vector2(21.0, 5.0)
		weapon_slide.position = Vector2(15.0, 3.0)
		weapon_slide.size = Vector2(18.0, 4.0)
		weapon_muzzle.position = Vector2(30.0, 5.0)
		weapon_muzzle.size = Vector2(6.0, 4.0)
		weapon_body.color = Color(0.58, 0.62, 0.66, 1.0)
		weapon_slide.color = Color(0.84, 0.87, 0.9, 0.92)
		weapon_grip.color = Color(0.14, 0.14, 0.15, 1.0)
		weapon_muzzle.color = Color(0.92, 0.12, 0.08, 1.0)

func _show_combat_label(label: Label, message: String, color: Color, primary: bool, priority: int):
	var style: Dictionary = _get_combat_text_style(message, color)
	label.position = Vector2.ZERO
	label.text = message
	label.modulate = style["color"]
	label.modulate.a = 0.0
	label.scale = style["start_scale"]
	var tween: Tween = combat_primary_tween if primary else combat_secondary_tween
	if tween:
		tween.kill()
	tween = create_tween()
	tween.tween_property(label, "modulate:a", 1.0, float(style["fade_in"]))
	tween.parallel().tween_property(label, "scale", style["end_scale"], float(style["settle_time"]))
	tween.tween_interval(float(style["hold_time"]))
	tween.tween_property(label, "modulate:a", 0.0, float(style["fade_out"]))
	tween.parallel().tween_property(label, "position:y", float(style["rise_offset"]), float(style["fade_out"]))
	tween.tween_callback(func():
		label.text = ""
		label.position = Vector2.ZERO
		if primary:
			combat_primary_priority = -1
		else:
			combat_secondary_priority = -1
	)
	if primary:
		combat_primary_tween = tween
		combat_primary_priority = priority
	else:
		combat_secondary_tween = tween
		combat_secondary_priority = priority

func _show_kill_confirm():
	kill_confirm_label.visible = true
	kill_confirm_label.text = "KILL +100"
	kill_confirm_label.scale = Vector2(0.84, 0.84)
	kill_confirm_label.modulate = Color(0.98, 0.14, 0.1, 0.0)
	kill_confirm_label.offset_top = 12.0
	kill_confirm_label.offset_bottom = 34.0
	if kill_confirm_tween:
		kill_confirm_tween.kill()
	kill_confirm_tween = create_tween()
	kill_confirm_tween.tween_property(kill_confirm_label, "modulate:a", 1.0, 0.06)
	kill_confirm_tween.parallel().tween_property(kill_confirm_label, "scale", Vector2(1.0, 1.0), 0.08)
	kill_confirm_tween.tween_interval(0.18)
	kill_confirm_tween.tween_property(kill_confirm_label, "offset_top", 2.0, 0.16)
	kill_confirm_tween.parallel().tween_property(kill_confirm_label, "offset_bottom", 24.0, 0.16)
	kill_confirm_tween.parallel().tween_property(kill_confirm_label, "modulate:a", 0.0, 0.16)
	kill_confirm_tween.tween_callback(func():
		kill_confirm_label.visible = false
		kill_confirm_label.offset_top = 12.0
		kill_confirm_label.offset_bottom = 34.0
	)

func _get_combat_text_style(message: String, base_color: Color) -> Dictionary:
	var upper_message: String = message.to_upper()
	var style: Dictionary = {
		"color": base_color,
		"start_scale": Vector2(0.86, 0.86),
		"end_scale": Vector2(1.0, 1.0),
		"fade_in": 0.08,
		"settle_time": 0.1,
		"hold_time": 0.55,
		"fade_out": 0.22,
		"rise_offset": -12.0
	}

	if upper_message.contains("HEADSHOT"):
		style["color"] = Color(1.0, 0.72, 0.3, 1.0)
		style["start_scale"] = Vector2(0.94, 0.94)
		style["end_scale"] = Vector2(1.08, 1.08)
		style["hold_time"] = 0.62
		style["rise_offset"] = -18.0
	elif upper_message.contains("ELIMINATION") or upper_message.contains("DOUBLE KILL") or upper_message.contains("TRIPLE KILL") or upper_message.contains("MULTI KILL"):
		style["color"] = Color(1.0, 0.22, 0.16, 1.0)
		style["start_scale"] = Vector2(0.96, 0.96)
		style["end_scale"] = Vector2(1.12, 1.12)
		style["hold_time"] = 0.66
		style["rise_offset"] = -16.0
	elif upper_message.contains("RELOADED") or upper_message.contains("WAVE CLEAR"):
		style["color"] = Color(0.82, 1.0, 0.86, 1.0) if upper_message.contains("RELOADED") else Color(1.0, 0.3, 0.24, 1.0)
		style["start_scale"] = Vector2(0.9, 0.9)
		style["end_scale"] = Vector2(1.04, 1.04)
		style["hold_time"] = 0.58
	elif upper_message.contains("INCOMING"):
		style["color"] = Color(1.0, 0.26, 0.24, 1.0)
		style["start_scale"] = Vector2(0.92, 0.92)
		style["end_scale"] = Vector2(1.04, 1.04)
		style["hold_time"] = 0.4
		style["fade_out"] = 0.18

	return style

func _get_combat_text_priority(message: String) -> int:
	var upper_message: String = message.to_upper()
	if upper_message.contains("TRIPLE KILL") or upper_message.contains("MULTI KILL"):
		return 100
	if upper_message.contains("DOUBLE KILL") or upper_message.contains("ELIMINATION"):
		return 90
	if upper_message.contains("HEADSHOT"):
		return 85
	if upper_message.contains("WAVE CLEAR"):
		return 80
	if upper_message.contains("INCOMING"):
		return 75
	if upper_message.contains("RELOADED"):
		return 45
	return 20

func _show_start_hints():
	start_hint_label.visible = true
	start_hint_label.modulate = Color(1.0, 1.0, 1.0, 0.0)
	start_hint_label.scale = Vector2(0.96, 0.96)
	var tween: Tween = create_tween()
	tween.tween_property(start_hint_label, "modulate:a", 1.0, 0.22)
	tween.parallel().tween_property(start_hint_label, "scale", Vector2(1.0, 1.0), 0.22)
	tween.tween_interval(3.4)
	tween.tween_property(start_hint_label, "modulate:a", 0.0, 0.28)
	tween.tween_callback(func(): start_hint_label.visible = false)

func _setup_handbook_overlay():
	if handbook_book != null:
		return
	handbook_book = HANDBOOK_SCENE.instantiate() as Control
	if handbook_book == null:
		return
	handbook_book.visible = false
	handbook_book.process_mode = Node.PROCESS_MODE_WHEN_PAUSED
	handbook_book.scale = Vector2(0.82, 0.82)
	handbook_book.position = Vector2(120.0, 40.0)
	add_child(handbook_book)
	_apply_handbook_theme()

func _close_handbook_overlay():
	if handbook_book != null and handbook_book.has_method("close_book"):
		handbook_book.call("close_book")
	_restore_pause_menu_after_handbook()
	handbook_opened_from_pause = false

func _restore_pause_menu_after_handbook():
	pause_dimmer.visible = true
	pause_dimmer.modulate.a = 1.0
	pause_panel.visible = true
	pause_panel.modulate.a = 1.0
	pause_panel.scale = Vector2.ONE

func _apply_handbook_theme():
	if handbook_book == null:
		return

	var frame: Control = handbook_book.get_node_or_null("BookFrame") as Control
	var tabs_bg: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ChapterTabsBg") as Control
	var top_bar: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/TopBar") as Control
	var left_column: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/LeftColumn") as Control
	var right_column: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn") as Control
	var title_ribbon: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/TitleRibbon") as Control
	var body_panel: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/ContentSplit/BodyPanel") as Control
	var portrait_panel: Control = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/RightColumn/RightMargin/RightVBox/ContentSplit/PortraitPanel") as Control

	_tint_panel_style(frame, Color(0.015, 0.015, 0.018, 0.99), Color(0.52, 0.08, 0.08, 0.55))
	_tint_panel_style(tabs_bg, Color(0.03, 0.03, 0.035, 0.975), Color(0.44, 0.08, 0.08, 0.4))
	_tint_panel_style(top_bar, Color(0.02, 0.02, 0.024, 0.98), Color(0.46, 0.08, 0.08, 0.36))
	_tint_panel_style(left_column, Color(0.035, 0.035, 0.04, 0.975), Color(0.34, 0.07, 0.07, 0.3))
	_tint_panel_style(right_column, Color(0.02, 0.02, 0.024, 0.99), Color(0.42, 0.08, 0.08, 0.34))
	_tint_panel_style(title_ribbon, Color(0.22, 0.03, 0.03, 0.96), Color(0.68, 0.12, 0.12, 0.52))
	_tint_panel_style(body_panel, Color(0.028, 0.028, 0.032, 0.99), Color(0.34, 0.07, 0.07, 0.26))
	_tint_panel_style(portrait_panel, Color(0.04, 0.04, 0.045, 0.99), Color(0.34, 0.07, 0.07, 0.24))

	var labels: Array = handbook_book.find_children("*", "Label", true, false)
	for label_node in labels:
		var label: Label = label_node as Label
		if label == null:
			continue
		label.modulate = Color(0.92, 0.93, 0.95, 1.0)

	var rich_labels: Array = handbook_book.find_children("*", "RichTextLabel", true, false)
	for rich_label_node in rich_labels:
		var rich_label: RichTextLabel = rich_label_node as RichTextLabel
		if rich_label == null:
			continue
		rich_label.modulate = Color(0.88, 0.9, 0.93, 1.0)

	var buttons: Array = handbook_book.find_children("*", "Button", true, false)
	for button_node in buttons:
		var button: Button = button_node as Button
		if button == null:
			continue
		button.modulate = Color(0.94, 0.95, 0.97, 1.0)

	var tree: Tree = handbook_book.get_node_or_null("BookFrame/OuterMargin/RootVBox/ContentRow/LeftColumn/LeftMargin/LeftVBox/EntryTree") as Tree
	if tree != null:
		tree.modulate = Color(0.9, 0.92, 0.95, 1.0)
		var list_panel := StyleBoxFlat.new()
		list_panel.bg_color = Color(0.028, 0.028, 0.032, 0.99)
		list_panel.border_width_left = 1
		list_panel.border_width_top = 1
		list_panel.border_width_right = 1
		list_panel.border_width_bottom = 1
		list_panel.border_color = Color(0.42, 0.08, 0.08, 0.34)
		list_panel.corner_radius_top_left = 5
		list_panel.corner_radius_top_right = 5
		list_panel.corner_radius_bottom_left = 5
		list_panel.corner_radius_bottom_right = 5
		tree.add_theme_stylebox_override("panel", list_panel)
		tree.add_theme_color_override("font_color", Color(0.9, 0.92, 0.95, 1.0))
		tree.add_theme_color_override("font_selected_color", Color(1.0, 0.94, 0.94, 1.0))
		tree.add_theme_color_override("font_hovered_color", Color(0.98, 0.78, 0.78, 1.0))
		tree.add_theme_color_override("guide_color", Color(0.42, 0.08, 0.08, 0.28))
		tree.add_theme_color_override("title_button_color", Color(0.88, 0.9, 0.93, 1.0))

func _tint_panel_style(control: Control, bg_color: Color, border_color: Color):
	if control == null:
		return
	var style: StyleBoxFlat = control.get("theme_override_styles/panel") as StyleBoxFlat
	if style == null:
		style = control.get_theme_stylebox("panel") as StyleBoxFlat
	if style == null:
		return
	var duplicate_style: StyleBoxFlat = style.duplicate() as StyleBoxFlat
	if duplicate_style == null:
		return
	duplicate_style.bg_color = bg_color
	duplicate_style.border_color = border_color
	control.set("theme_override_styles/panel", duplicate_style)

func _start_ammo_warning():
	if ammo_warning_tween and ammo_warning_tween.is_running():
		return
	ammo_warning_tween = create_tween()
	ammo_warning_tween.set_loops()
	ammo_warning_tween.tween_property(ammo_label, "scale", Vector2(1.1, 1.1), 0.14)
	ammo_warning_tween.parallel().tween_property(ammo_state_label, "modulate:a", 0.45, 0.14)
	ammo_warning_tween.parallel().tween_property(ammo_state_label, "scale", Vector2(1.06, 1.06), 0.14)
	ammo_warning_tween.tween_property(ammo_label, "scale", Vector2(1.0, 1.0), 0.16)
	ammo_warning_tween.parallel().tween_property(ammo_state_label, "modulate:a", 1.0, 0.16)
	ammo_warning_tween.parallel().tween_property(ammo_state_label, "scale", Vector2(1.0, 1.0), 0.16)

func _stop_ammo_warning():
	if ammo_warning_tween:
		ammo_warning_tween.kill()
	ammo_label.scale = Vector2(1.0, 1.0)
	ammo_state_label.modulate.a = 1.0
	ammo_state_label.scale = Vector2(1.0, 1.0)

func _set_crosshair_state(state: String):
	match state:
		"move":
			crosshair_base_color = Color(0.9, 0.94, 1.0, 0.88)
			crosshair_dot_base_color = Color(0.95, 0.97, 1.0, 0.88)
			crosshair_scale_target = Vector2(1.03, 1.03)
		"warning":
			crosshair_base_color = Color(1.0, 0.78, 0.3, 0.94)
			crosshair_dot_base_color = Color(1.0, 0.82, 0.36, 1.0)
			crosshair_scale_target = Vector2(1.02, 1.02)
		"empty":
			crosshair_base_color = Color(1.0, 0.26, 0.22, 0.96)
			crosshair_dot_base_color = Color(1.0, 0.26, 0.22, 1.0)
			crosshair_scale_target = Vector2(1.04, 1.04)
			crosshair_extra_spread = maxf(crosshair_extra_spread, 1.6)
		"reload":
			crosshair_base_color = Color(1.0, 0.82, 0.42, 0.94)
			crosshair_dot_base_color = Color(1.0, 0.88, 0.56, 1.0)
			crosshair_scale_target = Vector2(0.94, 0.94)
		"hit":
			crosshair_flash_color = Color(1.0, 0.28, 0.28, 1.0)
			crosshair_dot_flash_color = Color(1.0, 0.28, 0.28, 1.0)
			crosshair_scale_target = Vector2(1.08, 1.08)
			crosshair_extra_spread = maxf(crosshair_extra_spread, 0.65)
		"kill":
			crosshair_flash_color = Color(1.0, 0.12, 0.1, 1.0)
			crosshair_dot_flash_color = Color(1.0, 0.14, 0.12, 1.0)
			crosshair_scale_target = Vector2(1.12, 1.12)
			crosshair_extra_spread = maxf(crosshair_extra_spread, 1.0)
		_:
			crosshair_base_color = Color(0.95, 0.97, 1.0, 0.92)
			crosshair_dot_base_color = Color(0.95, 0.97, 1.0, 1.0)
			crosshair_scale_target = Vector2.ONE

func _update_crosshair_colors(delta: float):
	crosshair_flash_color = crosshair_flash_color.lerp(crosshair_base_color, clampf(delta * 9.0, 0.0, 1.0))
	crosshair_dot_flash_color = crosshair_dot_flash_color.lerp(crosshair_dot_base_color, clampf(delta * 9.0, 0.0, 1.0))
	for segment in [crosshair_left, crosshair_right, crosshair_top, crosshair_bottom]:
		segment.color = crosshair_flash_color
	crosshair_dot.color = crosshair_dot_flash_color

func _resolve_game_over_stats(stats: Dictionary) -> Dictionary:
	var resolved: Dictionary = stats.duplicate(true)
	var player: Node = get_tree().get_first_node_in_group("player")

	if not resolved.has("wave") or int(resolved.get("wave", 0)) <= 0:
		resolved["wave"] = _get_current_wave_number()
	if not resolved.has("kills"):
		resolved["kills"] = _get_session_elimination_count()
	if not resolved.has("headshots"):
		resolved["headshots"] = _get_node_int(player, "headshots")
	if not resolved.has("accuracy"):
		resolved["accuracy"] = _get_player_accuracy(player)
	if not resolved.has("time_seconds") or int(resolved.get("time_seconds", 0)) <= 0:
		resolved["time_seconds"] = _get_session_time_seconds()

	return resolved

func _get_current_wave_number() -> int:
	if wave_label == null:
		return 0
	var digits: String = ""
	for character in wave_label.text:
		if character >= "0" and character <= "9":
			digits += character
	if digits.is_empty():
		return 0
	return int(digits)

func _get_node_int(node: Node, property_name: String) -> int:
	if node == null or not is_instance_valid(node):
		return 0
	var value: Variant = node.get(property_name)
	if value == null:
		return 0
	return int(value)

func _get_player_accuracy(player: Node) -> float:
	if player == null or not is_instance_valid(player):
		return 0.0
	if player.has_method("get_accuracy"):
		return float(player.call("get_accuracy"))

	var shots_fired: int = _get_node_int(player, "shots_fired")
	if shots_fired <= 0:
		return 0.0
	var shots_hit: int = _get_node_int(player, "shots_hit")
	return float(shots_hit) / float(shots_fired)

func _get_session_time_seconds() -> int:
	if session_start_msec <= 0:
		return 0
	return maxi(0, int((Time.get_ticks_msec() - session_start_msec) / 1000))

func _update_pause_menu_content():
	var live_stats: Dictionary = _resolve_game_over_stats({})
	var wave: int = int(live_stats.get("wave", 0))
	var kills: int = int(live_stats.get("kills", 0))
	var headshots: int = int(live_stats.get("headshots", 0))
	var accuracy: float = float(live_stats.get("accuracy", 0.0)) * 100.0
	var total_seconds: int = int(live_stats.get("time_seconds", 0))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60

	pause_summary_label.text = "WAVE %02d PAUSED\n%d HOSTILES ELIMINATED" % [wave, kills]
	pause_controls_label.text = "CONTROLS\nMOVE  WASD\nFIRE  LMB\nRELOAD  R\nSWAP  1 / 2 / WHEEL\nPAUSE  ESC"
	pause_settings_label.text = "SESSION SNAPSHOT\nHEADSHOTS  %d\nACCURACY   %.0f%%\nSURVIVAL   %02d:%02d" % [headshots, accuracy, minutes, seconds]

func _update_adaptive_hud(delta: float):
	var target_threat: float = clampf(maxf(recent_threat_time / 1.5, low_health_strength), 0.0, 1.0)
	adaptive_threat_level = lerpf(adaptive_threat_level, target_threat, clampf(delta * 3.4, 0.0, 1.0))
	_apply_adaptive_hud_presence()

func _apply_adaptive_hud_presence():
	var threat_level: float = adaptive_threat_level
	var wave_alpha: float = lerpf(0.42, 1.0, threat_level)
	var weapon_alpha: float = lerpf(0.5, 1.0, threat_level)
	var ammo_alpha: float = lerpf(0.56, 1.0, threat_level)
	var reserve_alpha: float = lerpf(0.4, 0.96, threat_level)
	var crosshair_alpha: float = lerpf(0.6, 1.0, threat_level)

	wave_panel.modulate.a = wave_alpha
	weapon_panel.modulate.a = weapon_alpha
	ammo_label.modulate.a = ammo_alpha
	ammo_state_label.modulate.a = maxf(ammo_state_label.modulate.a, ammo_alpha)
	reserve_label.modulate.a = reserve_alpha
	crosshair_root.modulate.a = crosshair_alpha
	wave_panel.scale = Vector2.ONE * lerpf(0.97, 1.0, threat_level)
	weapon_panel.scale = Vector2.ONE * lerpf(0.975, 1.0, threat_level)

func _update_session_milestones():
	var session_kills: int = _get_session_elimination_count()
	if session_kills < 10:
		return
	var milestone_step: int = int(session_kills / 10) * 10
	if milestone_step <= milestone_kills_announced:
		return
	milestone_kills_announced = milestone_step
	show_combat_text("%d KILLS" % milestone_step, Color(1.0, 0.86, 0.32, 1.0))
	show_status("MILESTONE %d" % milestone_step, Color(1.0, 0.86, 0.32, 1.0), 0.4)

func _update_elimination_tracking(wave: int, living_zombies: int, remaining_to_spawn: int):
	var current_wave_total: int = _get_current_wave_total_count()
	if wave != tracked_wave_index:
		if tracked_wave_index > 0:
			tracked_total_eliminations += tracked_wave_total
		tracked_wave_index = wave
		tracked_wave_total = current_wave_total
		tracked_wave_eliminations = 0
	else:
		tracked_wave_total = maxi(tracked_wave_total, current_wave_total)

	var spawned_current_wave: int = max(0, tracked_wave_total - remaining_to_spawn)
	tracked_wave_eliminations = max(0, spawned_current_wave - living_zombies)

func _get_current_wave_total_count() -> int:
	var game_manager: Node = get_node_or_null("../GameManager")
	if game_manager == null or not is_instance_valid(game_manager):
		return 0
	if not game_manager.has_method("get_runtime_state"):
		return 0

	var runtime_state: Dictionary = game_manager.call("get_runtime_state")
	var current_wave_plan: Dictionary = runtime_state.get("current_wave_plan", {})
	return int(current_wave_plan.get("total_count", 0))

func _get_session_elimination_count() -> int:
	return tracked_total_eliminations + tracked_wave_eliminations

func _format_game_over_summary(stats: Dictionary) -> String:
	var wave: int = int(stats.get("wave", 0))
	var kills: int = int(stats.get("kills", 0))
	return "WAVE %02d REACHED\n%d HOSTILES ELIMINATED" % [wave, kills]

func _format_game_over_stats(stats: Dictionary) -> String:
	var wave: int = int(stats.get("wave", 0))
	var kills: int = int(stats.get("kills", 0))
	var headshots: int = int(stats.get("headshots", 0))
	var accuracy: float = float(stats.get("accuracy", 0.0)) * 100.0
	var total_seconds: int = int(stats.get("time_seconds", 0))
	var minutes: int = total_seconds / 60
	var seconds: int = total_seconds % 60
	return "SESSION REPORT\nWAVE REACHED  %02d\nKILLS         %d\nHEADSHOTS     %d\nACCURACY      %.0f%%\nSURVIVAL      %02d:%02d" % [wave, kills, headshots, accuracy, minutes, seconds]
