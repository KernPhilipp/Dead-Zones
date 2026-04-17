extends Node3D

@export var weather_min_duration: float = 10.0
@export var weather_max_duration: float = 18.0
@export var lightning_min_interval: float = 0.7
@export var lightning_max_interval: float = 2.2
@export var rain_follow_lerp: float = 4.0
@export var rain_height: float = 24.0

enum WeatherState { CLEAR, RAIN, STORM }

var lightning_timer: Timer
var weather_timer: Timer
var player: Node3D
var sun_light: DirectionalLight3D
var lightning_flash: OmniLight3D
var rain: GPUParticles3D
var world_environment: WorldEnvironment
var rain_process_material: ParticleProcessMaterial
var current_state: WeatherState = WeatherState.RAIN
var target_rain_amount: float = 0.0
var target_fog_density: float = 0.005
var target_light_energy: float = 1.0
var target_ambient_energy: float = 0.58
var target_bg_color: Color = Color(0.42, 0.47, 0.53, 1.0)
var base_light_energy: float = 1.0

func _ready():
	player = get_tree().get_first_node_in_group("player") as Node3D
	sun_light = get_node_or_null("../MoonLight") as DirectionalLight3D
	if sun_light == null:
		sun_light = get_node_or_null("../DirectionalLight3D") as DirectionalLight3D
	lightning_flash = get_node_or_null("../LightningFlash") as OmniLight3D
	world_environment = get_node_or_null("../WorldEnvironment") as WorldEnvironment
	rain = get_node_or_null("../Weather/Rain") as GPUParticles3D
	if rain != null:
		rain_process_material = rain.process_material as ParticleProcessMaterial
	if sun_light != null:
		base_light_energy = sun_light.light_energy
	if lightning_flash != null:
		lightning_flash.visible = false

	lightning_timer = Timer.new()
	lightning_timer.one_shot = true
	lightning_timer.timeout.connect(_trigger_lightning)
	add_child(lightning_timer)

	weather_timer = Timer.new()
	weather_timer.one_shot = true
	weather_timer.timeout.connect(_advance_weather)
	add_child(weather_timer)

	_set_weather_state(WeatherState.STORM if randf() > 0.45 else WeatherState.RAIN)
	_schedule_next_weather()

func _process(delta: float):
	if player != null and rain != null:
		var target_origin: Vector3 = player.global_position
		target_origin.y = rain_height
		rain.global_position = rain.global_position.lerp(target_origin, clampf(delta * rain_follow_lerp, 0.0, 1.0))
		rain.amount_ratio = lerpf(rain.amount_ratio, target_rain_amount, clampf(delta * 1.2, 0.0, 1.0))

	if sun_light != null:
		sun_light.light_energy = lerpf(sun_light.light_energy, target_light_energy, clampf(delta * 1.5, 0.0, 1.0))

	if world_environment != null:
		var environment: Environment = world_environment.environment
		if environment != null:
			environment.fog_density = lerpf(environment.fog_density, target_fog_density, clampf(delta * 1.2, 0.0, 1.0))
			environment.ambient_light_energy = lerpf(environment.ambient_light_energy, target_ambient_energy, clampf(delta * 1.2, 0.0, 1.0))
			environment.background_color = environment.background_color.lerp(target_bg_color, clampf(delta * 1.0, 0.0, 1.0))

	if rain_process_material != null:
		match current_state:
			WeatherState.CLEAR:
				rain_process_material.direction = rain_process_material.direction.lerp(Vector3(0.06, -1.0, 0.03), clampf(delta * 1.5, 0.0, 1.0))
			WeatherState.RAIN:
				rain_process_material.direction = rain_process_material.direction.lerp(Vector3(0.34, -1.0, 0.14), clampf(delta * 1.5, 0.0, 1.0))
			WeatherState.STORM:
				rain_process_material.direction = rain_process_material.direction.lerp(Vector3(0.72, -1.0, 0.30), clampf(delta * 1.5, 0.0, 1.0))

func _schedule_next_weather():
	weather_timer.start(randf_range(weather_min_duration, weather_max_duration))

func _schedule_next_lightning():
	if lightning_timer == null:
		return
	lightning_timer.start(randf_range(lightning_min_interval, lightning_max_interval))

func _advance_weather():
	match current_state:
		WeatherState.CLEAR:
			_set_weather_state(WeatherState.RAIN)
		WeatherState.RAIN:
			_set_weather_state(WeatherState.STORM if randf() > 0.25 else WeatherState.CLEAR)
		WeatherState.STORM:
			_set_weather_state(WeatherState.RAIN if randf() > 0.2 else WeatherState.CLEAR)
	_schedule_next_weather()

func _set_weather_state(next_state: WeatherState):
	current_state = next_state
	var environment: Environment = world_environment.environment if world_environment != null else null

	match current_state:
		WeatherState.CLEAR:
			target_rain_amount = 0.0
			target_fog_density = 0.007
			target_light_energy = 1.08
			target_ambient_energy = 0.58
			target_bg_color = Color(0.42, 0.47, 0.53, 1.0)
			if environment != null:
				environment.fog_light_color = Color(0.54, 0.58, 0.64, 1.0)
			if lightning_timer != null:
				lightning_timer.stop()
			if lightning_flash != null:
				lightning_flash.visible = false
		WeatherState.RAIN:
			target_rain_amount = 0.9
			target_fog_density = 0.013
			target_light_energy = 0.92
			target_ambient_energy = 0.50
			target_bg_color = Color(0.33, 0.38, 0.43, 1.0)
			if environment != null:
				environment.fog_light_color = Color(0.46, 0.50, 0.56, 1.0)
			if lightning_timer != null:
				lightning_timer.stop()
			if lightning_flash != null:
				lightning_flash.visible = false
		WeatherState.STORM:
			target_rain_amount = 1.0
			target_fog_density = 0.018
			target_light_energy = 0.72
			target_ambient_energy = 0.42
			target_bg_color = Color(0.24, 0.28, 0.33, 1.0)
			if environment != null:
				environment.fog_light_color = Color(0.36, 0.40, 0.47, 1.0)
			_schedule_next_lightning()

func _trigger_lightning():
	if lightning_flash == null or sun_light == null or current_state != WeatherState.STORM:
		return

	await _flash_lightning(randf_range(6.2, 8.4), randf_range(0.5, 0.9), 0.07)

	var extra_flashes: int = randi_range(1, 3)
	if extra_flashes >= 1:
		await get_tree().create_timer(randf_range(0.04, 0.11)).timeout
		await _flash_lightning(randf_range(4.8, 7.1), randf_range(0.32, 0.65), randf_range(0.04, 0.08))
	if extra_flashes >= 2:
		await get_tree().create_timer(randf_range(0.04, 0.11)).timeout
		await _flash_lightning(randf_range(4.4, 6.4), randf_range(0.28, 0.58), randf_range(0.04, 0.08))
	if extra_flashes >= 3:
		await get_tree().create_timer(randf_range(0.04, 0.11)).timeout
		await _flash_lightning(randf_range(4.0, 5.8), randf_range(0.24, 0.50), randf_range(0.04, 0.08))

	if current_state == WeatherState.STORM:
		_schedule_next_lightning()

func _flash_lightning(flash_energy: float, light_boost: float, duration: float):
	lightning_flash.visible = true
	lightning_flash.light_energy = flash_energy
	sun_light.light_energy = base_light_energy + light_boost
	await get_tree().create_timer(duration).timeout
	lightning_flash.visible = false
	sun_light.light_energy = target_light_energy
