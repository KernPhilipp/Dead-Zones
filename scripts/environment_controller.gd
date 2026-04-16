extends Node3D

const WEATHER_CLEAR := 0
const WEATHER_CLOUDY := 1
const WEATHER_FOGGY := 2
const WEATHER_RAIN := 3
const WEATHER_STORM := 4

const WEATHER_PROFILES := {
	WEATHER_CLEAR: {
		"sky_shadow": 0.26,
		"fog_density": 0.01,
		"rain_amount": 0.0,
		"light_multiplier": 1.08,
		"ambient_multiplier": 1.08,
		"storminess": 0.04,
		"blood_tint": 0.22,
		"toxic_tint": 0.38,
		"purple_tint": 0.24,
		"void_depth": 0.55
	},
	WEATHER_CLOUDY: {
		"sky_shadow": 0.45,
		"fog_density": 0.015,
		"rain_amount": 0.0,
		"light_multiplier": 1.08,
		"ambient_multiplier": 1.08,
		"storminess": 0.08,
		"blood_tint": 0.3,
		"toxic_tint": 0.46,
		"purple_tint": 0.36,
		"void_depth": 0.66
	},
	WEATHER_FOGGY: {
		"sky_shadow": 0.52,
		"fog_density": 0.022,
		"rain_amount": 0.0,
		"light_multiplier": 1.06,
		"ambient_multiplier": 1.08,
		"storminess": 0.12,
		"blood_tint": 0.36,
		"toxic_tint": 0.72,
		"purple_tint": 0.58,
		"void_depth": 0.8
	},
	WEATHER_RAIN: {
		"sky_shadow": 0.7,
		"fog_density": 0.019,
		"rain_amount": 0.86,
		"light_multiplier": 1.0,
		"ambient_multiplier": 1.04,
		"storminess": 0.48,
		"blood_tint": 0.48,
		"toxic_tint": 0.58,
		"purple_tint": 0.52,
		"void_depth": 0.88
	},
	WEATHER_STORM: {
		"sky_shadow": 0.95,
		"fog_density": 0.024,
		"rain_amount": 1.0,
		"light_multiplier": 0.94,
		"ambient_multiplier": 0.98,
		"storminess": 1.0,
		"blood_tint": 0.68,
		"toxic_tint": 0.86,
		"purple_tint": 0.78,
		"void_depth": 1.0
	}
}

const WEATHER_WEIGHTS := {
	WEATHER_CLEAR: 0.18,
	WEATHER_CLOUDY: 0.28,
	WEATHER_FOGGY: 0.2,
	WEATHER_RAIN: 0.22,
	WEATHER_STORM: 0.12
}

@export var cycle_duration_seconds: float = 420.0
@export_range(0.0, 1.0, 0.001) var start_time_of_day: float = 0.68
@export var weather_hold_duration: Vector2 = Vector2(16.0, 28.0)
@export var weather_transition_duration: float = 9.5
@export var rain_follow_target_path: NodePath
@export var rain_follow_height: float = 26.0
@export var rain_area_size: Vector2 = Vector2(28.0, 28.0)

var sun: DirectionalLight3D
var world_environment: WorldEnvironment
var environment: Environment
var follow_target: Node3D
var rain_particles: GPUParticles3D
var rain_material: ParticleProcessMaterial
var lightning_light: OmniLight3D

var rng := RandomNumberGenerator.new()
var time_of_day: float = 0.0
var current_weather: int = WEATHER_CLEAR
var target_weather: int = WEATHER_CLEAR
var weather_blend: float = 1.0
var weather_hold_timer: float = 0.0
var lightning_timer: float = 0.0
var lightning_flash_duration: float = 0.0
var lightning_flash_remaining: float = 0.0
var lightning_peak_energy: float = 0.0
var lightning_flash_color: Color = Color(0.9, 0.96, 1.0, 1.0)
var current_weather_audio_event: String = ""

func _ready():
	rng.randomize()
	time_of_day = wrapf(start_time_of_day, 0.0, 1.0)
	sun = _resolve_sun()
	world_environment = _resolve_world_environment()
	environment = world_environment.environment
	if environment == null:
		environment = Environment.new()
		world_environment.environment = environment
	_configure_environment_defaults()
	follow_target = get_node_or_null(rain_follow_target_path) as Node3D
	if follow_target == null:
		follow_target = get_tree().get_first_node_in_group("player") as Node3D
	_create_weather_effects()
	current_weather = WEATHER_CLOUDY
	target_weather = current_weather
	weather_blend = 1.0
	_reset_weather_hold_timer()
	lightning_timer = rng.randf_range(0.8, 2.0)
	_apply_environment()
	AudioManager.play_music("music_ambient")
	AudioManager.play_loop("ambience_base", "ambience_base_wind")
	_sync_weather_audio()

func _process(delta: float):
	if cycle_duration_seconds > 0.0:
		time_of_day = wrapf(time_of_day + (delta / cycle_duration_seconds), 0.0, 1.0)
	_update_weather_state(delta)
	_update_lightning(delta)
	_update_effect_positions()
	_apply_environment()
	_sync_weather_audio()

func _resolve_sun() -> DirectionalLight3D:
	var sibling_sun := get_parent().get_node_or_null("DirectionalLight3D") as DirectionalLight3D
	if sibling_sun != null:
		return sibling_sun
	var fallback_sun := DirectionalLight3D.new()
	fallback_sun.name = "DirectionalLight3D"
	get_parent().add_child.call_deferred(fallback_sun)
	push_warning("EnvironmentController: DirectionalLight3D not found, created fallback light.")
	return fallback_sun

func _resolve_world_environment() -> WorldEnvironment:
	var sibling_environment := get_parent().get_node_or_null("WorldEnvironment") as WorldEnvironment
	if sibling_environment != null:
		return sibling_environment
	var fallback_environment := WorldEnvironment.new()
	fallback_environment.name = "WorldEnvironment"
	get_parent().add_child.call_deferred(fallback_environment)
	push_warning("EnvironmentController: WorldEnvironment not found, created fallback environment.")
	return fallback_environment

func _configure_environment_defaults():
	environment.background_mode = Environment.BG_COLOR
	environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.ambient_light_sky_contribution = 0.0
	environment.ambient_light_energy = 0.62
	environment.ambient_light_color = Color(0.3, 0.31, 0.33, 1.0)
	environment.fog_enabled = true
	environment.fog_density = 0.012
	environment.fog_aerial_perspective = 0.28
	environment.fog_sky_affect = 0.62
	environment.fog_light_color = Color(0.24, 0.34, 0.3, 1.0)
	environment.fog_light_energy = 0.76
	sun.shadow_enabled = true
	sun.light_energy = 1.16

func _create_weather_effects():
	rain_particles = GPUParticles3D.new()
	rain_particles.name = "RainParticles"
	rain_particles.amount = 1600
	rain_particles.lifetime = 0.95
	rain_particles.preprocess = 0.15
	rain_particles.local_coords = false
	rain_particles.emitting = false
	rain_particles.draw_pass_1 = _build_rain_mesh()
	rain_particles.visibility_aabb = AABB(
		Vector3(-rain_area_size.x, -42.0, -rain_area_size.y),
		Vector3(rain_area_size.x * 2.0, 84.0, rain_area_size.y * 2.0)
	)
	rain_particles.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	rain_material = ParticleProcessMaterial.new()
	rain_material.direction = Vector3(0.08, -1.0, 0.02)
	rain_material.spread = 1.2
	rain_material.gravity = Vector3(0.0, -52.0, 0.0)
	rain_material.initial_velocity_min = 34.0
	rain_material.initial_velocity_max = 42.0
	rain_material.scale_min = 0.45
	rain_material.scale_max = 0.72
	rain_material.color = Color(0.8, 0.87, 0.95, 0.55)
	rain_material.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	rain_material.emission_box_extents = Vector3(rain_area_size.x, 1.0, rain_area_size.y)
	rain_particles.process_material = rain_material
	add_child(rain_particles)

	lightning_light = OmniLight3D.new()
	lightning_light.name = "LightningLight"
	lightning_light.light_color = Color(0.9, 0.96, 1.0, 1.0)
	lightning_light.light_energy = 0.0
	lightning_light.omni_range = 42.0
	lightning_light.shadow_enabled = false
	add_child(lightning_light)

func _build_rain_mesh() -> QuadMesh:
	var mesh := QuadMesh.new()
	mesh.size = Vector2(0.018, 0.62)
	var material := StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.vertex_color_use_as_albedo = true
	material.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	material.cull_mode = BaseMaterial3D.CULL_DISABLED
	material.albedo_color = Color(0.62, 0.86, 0.72, 0.6)
	mesh.material = material
	return mesh

func _update_weather_state(delta: float):
	if current_weather == target_weather:
		weather_hold_timer -= delta
		if weather_hold_timer <= 0.0:
			target_weather = _pick_next_weather()
			weather_blend = 0.0
		return

	weather_blend = minf(weather_blend + (delta / maxf(weather_transition_duration, 0.01)), 1.0)
	if weather_blend >= 1.0:
		current_weather = target_weather
		weather_blend = 1.0
		_reset_weather_hold_timer()

func _update_lightning(delta: float):
	var storminess := _get_weather_value("storminess")
	if storminess < 0.08:
		lightning_flash_remaining = 0.0
		lightning_flash_duration = 0.0
		lightning_peak_energy = 0.0
		lightning_light.light_energy = 0.0
		lightning_timer = rng.randf_range(1.0, 2.4)
		return

	lightning_timer -= delta
	if lightning_flash_remaining <= 0.0 and lightning_timer <= 0.0 and rng.randf() < clampf(storminess * 1.15, 0.0, 1.0):
		_begin_lightning_flash(storminess)

	if lightning_flash_remaining > 0.0:
		lightning_flash_remaining = maxf(lightning_flash_remaining - delta, 0.0)
		var progress := 1.0 - (lightning_flash_remaining / maxf(lightning_flash_duration, 0.01))
		var pulse := sin(progress * PI)
		lightning_light.light_energy = lightning_peak_energy * pulse
	else:
		lightning_light.light_energy = 0.0

func _begin_lightning_flash(storminess: float):
	lightning_flash_duration = rng.randf_range(0.1, 0.22)
	lightning_flash_remaining = lightning_flash_duration
	lightning_peak_energy = rng.randf_range(3.4, 5.8) * lerpf(0.9, 1.35, storminess)
	lightning_timer = rng.randf_range(0.7, 2.1)
	var flash_roll := rng.randf()
	if flash_roll < 0.18:
		lightning_flash_color = Color(1.0, 0.18, 0.12, 1.0)
	elif flash_roll < 0.43:
		lightning_flash_color = Color(0.5, 1.0, 0.62, 1.0)
	else:
		lightning_flash_color = Color(0.9, 0.96, 1.0, 1.0)
	lightning_light.light_color = lightning_flash_color
	if follow_target != null:
		var offset := Vector3(rng.randf_range(-12.0, 12.0), 14.0, rng.randf_range(-12.0, 12.0))
		lightning_light.global_position = follow_target.global_position + offset
	AudioManager.play_sfx(
		"ambience_thunder_near" if rng.randf() < clampf(storminess * 0.65, 0.2, 0.85) else "ambience_thunder_far",
		lightning_light.global_position,
		true
	)

func _update_effect_positions():
	if follow_target == null:
		return
	var target_position := follow_target.global_position
	if rain_particles != null:
		rain_particles.global_position = Vector3(target_position.x, target_position.y + rain_follow_height, target_position.z)
	if lightning_light != null and lightning_flash_remaining <= 0.0:
		lightning_light.global_position = Vector3(target_position.x, target_position.y + rain_follow_height + 4.0, target_position.z)

func _apply_environment():
	var orbit_angle := time_of_day * TAU
	var sun_height_curve := sin(orbit_angle - (PI * 0.5))
	var elevation := lerpf(deg_to_rad(-82.0), deg_to_rad(82.0), (sun_height_curve + 1.0) * 0.5)
	var azimuth := orbit_angle + deg_to_rad(32.0)
	var sun_position := Vector3(
		cos(elevation) * cos(azimuth),
		sin(elevation),
		cos(elevation) * sin(azimuth)
	).normalized()
	var lighting_sun_position := sun_position
	lighting_sun_position.y = maxf(lighting_sun_position.y, 0.38)
	lighting_sun_position = lighting_sun_position.normalized()
	var light_direction := -lighting_sun_position
	sun.transform = Transform3D(Basis.looking_at(light_direction, Vector3.UP), sun.transform.origin)

	var daylight := smoothstep(-0.16, 0.1, sun_position.y)
	var twilight := clampf(1.0 - absf(sun_position.y * 4.0), 0.0, 1.0)
	var sky_shadow := _get_weather_value("sky_shadow")
	var visible_daylight := maxf(daylight, 0.86)
	var fog_density := _get_weather_value("fog_density") + ((1.0 - daylight) * 0.003)
	var ambient_multiplier := _get_weather_value("ambient_multiplier")
	var light_multiplier := _get_weather_value("light_multiplier")
	var rain_amount := _get_weather_value("rain_amount")
	var blood_tint := _get_weather_value("blood_tint")
	var toxic_tint := _get_weather_value("toxic_tint")
	var purple_tint := _get_weather_value("purple_tint")
	var void_depth := _get_weather_value("void_depth")
	var lightning_mix := clampf(lightning_light.light_energy / 5.8, 0.0, 1.0)
	var horror_daylight := maxf(daylight, 0.54)

	var void_black := Color(0.01, 0.012, 0.01, 1.0)
	var dead_night := Color(0.02, 0.035, 0.028, 1.0)
	var toxic_green := Color(0.16, 0.34, 0.18, 1.0)
	var arcane_purple := Color(0.38, 0.14, 0.44, 1.0)
	var blood_red := Color(0.46, 0.04, 0.02, 1.0)
	var sky_color := void_black.lerp(dead_night, horror_daylight)
	sky_color = sky_color.lerp(toxic_green, toxic_tint * 0.48)
	sky_color = sky_color.lerp(arcane_purple, purple_tint * 0.42)
	sky_color = sky_color.lerp(blood_red, maxf(twilight * 0.72, blood_tint * 0.5))
	sky_color = sky_color.lerp(Color(0.0, 0.0, 0.0, 1.0), void_depth * 0.04)
	sky_color = sky_color.lerp(lightning_flash_color, lightning_mix * 0.24)

	var ambient_base := Color(0.14, 0.15, 0.16, 1.0)
	var ambient_toxic := Color(0.16, 0.26, 0.17, 1.0)
	var ambient_purple := Color(0.24, 0.16, 0.28, 1.0)
	var ambient_blood := Color(0.24, 0.11, 0.09, 1.0)
	var ambient_color := ambient_base.lerp(ambient_toxic, toxic_tint * 0.52)
	ambient_color = ambient_color.lerp(ambient_purple, purple_tint * 0.42)
	ambient_color = ambient_color.lerp(ambient_blood, blood_tint * 0.35)
	ambient_color = ambient_color.lerp(sky_color, 0.24)

	var sick_moon := Color(0.28, 0.48, 0.3, 1.0)
	var cursed_purple := Color(0.56, 0.24, 0.68, 1.0)
	var dirty_day := Color(0.46, 0.54, 0.38, 1.0)
	var dusk_sun_color := Color(0.82, 0.14, 0.08, 1.0)
	var sun_color := sick_moon.lerp(dirty_day, horror_daylight)
	sun_color = sun_color.lerp(cursed_purple, purple_tint * 0.36)
	sun_color = sun_color.lerp(dusk_sun_color, maxf(twilight * 0.78, blood_tint * 0.22))
	sun_color = sun_color.lerp(lightning_flash_color, lightning_mix * 0.38)

	environment.background_color = sky_color
	environment.ambient_light_color = ambient_color
	environment.ambient_light_energy = lerpf(0.78, 1.08, visible_daylight) * ambient_multiplier
	environment.fog_enabled = fog_density > 0.001
	environment.fog_density = fog_density
	environment.fog_aerial_perspective = lerpf(0.34, 0.62, rain_amount)
	environment.fog_sky_affect = lerpf(0.62, 0.9, sky_shadow)
	var fog_color := Color(0.16, 0.18, 0.18, 1.0)
	fog_color = fog_color.lerp(Color(0.22, 0.42, 0.24, 1.0), toxic_tint * 0.82)
	fog_color = fog_color.lerp(Color(0.34, 0.18, 0.42, 1.0), purple_tint * 0.8)
	fog_color = fog_color.lerp(Color(0.36, 0.08, 0.06, 1.0), blood_tint * 0.34)
	fog_color = fog_color.lerp(lightning_flash_color, lightning_mix * 0.2)
	environment.fog_light_color = fog_color
	environment.fog_light_energy = lerpf(0.62, 0.82, visible_daylight) + (purple_tint * 0.08) + (lightning_mix * 0.14)

	sun.light_color = sun_color
	sun.light_energy = (lerpf(1.08, 1.72, visible_daylight) * light_multiplier) + (lightning_light.light_energy * 0.24)

	_update_rain_effect(rain_amount)

func _update_rain_effect(rain_amount: float):
	if rain_particles == null or rain_material == null:
		return
	if rain_amount <= 0.05:
		rain_particles.emitting = false
		return

	rain_particles.emitting = true
	rain_particles.amount = int(lerpf(1400.0, 2400.0, rain_amount))
	rain_material.direction = Vector3(lerpf(0.04, 0.18, rain_amount), -1.0, lerpf(0.01, 0.08, rain_amount))
	rain_material.spread = lerpf(0.8, 1.6, rain_amount)
	rain_material.initial_velocity_min = lerpf(34.0, 42.0, rain_amount)
	rain_material.initial_velocity_max = lerpf(42.0, 52.0, rain_amount)
	rain_material.gravity = Vector3(0.0, lerpf(-52.0, -66.0, rain_amount), 0.0)
	rain_material.color = Color(0.58, 0.92, 0.66, lerpf(0.42, 0.82, rain_amount))

func _pick_next_weather() -> int:
	var total_weight := 0.0
	for weather_type in WEATHER_WEIGHTS.keys():
		if weather_type == current_weather:
			continue
		total_weight += float(WEATHER_WEIGHTS[weather_type])

	var roll := rng.randf() * total_weight
	for weather_type in WEATHER_WEIGHTS.keys():
		if weather_type == current_weather:
			continue
		roll -= float(WEATHER_WEIGHTS[weather_type])
		if roll <= 0.0:
			return int(weather_type)
	return WEATHER_CLEAR

func _reset_weather_hold_timer():
	weather_hold_timer = rng.randf_range(weather_hold_duration.x, weather_hold_duration.y)

func _get_weather_value(key: String) -> float:
	var from_profile: Dictionary = WEATHER_PROFILES.get(current_weather, WEATHER_PROFILES[WEATHER_CLEAR])
	var to_profile: Dictionary = WEATHER_PROFILES.get(target_weather, from_profile)
	var blend := 1.0 if current_weather == target_weather else smoothstep(0.0, 1.0, weather_blend)
	return lerpf(float(from_profile.get(key, 0.0)), float(to_profile.get(key, 0.0)), blend)

func get_time_label() -> String:
	var total_minutes := int(roundi(time_of_day * 24.0 * 60.0)) % (24 * 60)
	var hours: int = total_minutes / 60
	var minutes: int = total_minutes % 60
	return "%02d:%02d" % [hours, minutes]

func _sync_weather_audio() -> void:
	var rain_amount: float = _get_weather_value("rain_amount")
	var storminess: float = _get_weather_value("storminess")
	var next_event: String = ""
	if rain_amount > 0.05:
		next_event = "ambience_storm" if storminess >= 0.7 else "ambience_rain"

	if next_event == current_weather_audio_event:
		return

	current_weather_audio_event = next_event
	if current_weather_audio_event.is_empty():
		AudioManager.stop_loop("ambience_weather")
	else:
		AudioManager.play_loop("ambience_weather", current_weather_audio_event)
