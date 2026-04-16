extends RefCounted
class_name MainWaveProgressionModel

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

const MAIN_RANK_ORDER: Array[int] = [
	ZombieDefinitions.Rank.EPSILON,
	ZombieDefinitions.Rank.DELTA,
	ZombieDefinitions.Rank.GAMMA,
	ZombieDefinitions.Rank.BETA,
	ZombieDefinitions.Rank.ALPHA
]

const CURVE_PRESETS: Dictionary = {
	"default": {
		"epsilon_floor": 0.002,
		"epsilon_amp": 1.35,
		"epsilon_decay": 0.22,
		"delta_floor": 0.004,
		"delta_amp": 1.20,
		"delta_mid": 12.5,
		"delta_steep": 3.0,
		"gamma_floor": 0.001,
		"gamma_amp": 0.85,
		"gamma_mid": 17.0,
		"gamma_steep": 3.0,
		"beta_floor": 0.0002,
		"beta_amp": 0.42,
		"beta_mid": 26.0,
		"beta_steep": 3.6,
		"alpha_floor": 0.00002,
		"alpha_amp": 0.08,
		"alpha_mid": 38.0,
		"alpha_steep": 4.8
	},
	"tuned": {
		"epsilon_floor": 0.003,
		"epsilon_amp": 1.30,
		"epsilon_decay": 0.205,
		"delta_floor": 0.005,
		"delta_amp": 1.24,
		"delta_mid": 11.6,
		"delta_steep": 2.8,
		"gamma_floor": 0.0012,
		"gamma_amp": 0.92,
		"gamma_mid": 16.2,
		"gamma_steep": 2.9,
		"beta_floor": 0.00025,
		"beta_amp": 0.46,
		"beta_mid": 24.8,
		"beta_steep": 3.4,
		"alpha_floor": 0.00002,
		"alpha_amp": 0.085,
		"alpha_mid": 36.5,
		"alpha_steep": 4.4
	}
}

func build_distribution(wave_index: int, rank_modifier: RefCounted = null, curve_mode: String = "default") -> Dictionary:
	var w: float = maxf(1.0, float(wave_index))
	var curve_cfg: Dictionary = _get_curve_preset(curve_mode)

	var raw: Dictionary = {
		ZombieDefinitions.Rank.EPSILON: float(curve_cfg["epsilon_floor"]) + float(curve_cfg["epsilon_amp"]) * exp(-float(curve_cfg["epsilon_decay"]) * (w - 1.0)),
		ZombieDefinitions.Rank.DELTA: float(curve_cfg["delta_floor"]) + float(curve_cfg["delta_amp"]) * _sigmoid((w - float(curve_cfg["delta_mid"])) / float(curve_cfg["delta_steep"])),
		ZombieDefinitions.Rank.GAMMA: float(curve_cfg["gamma_floor"]) + float(curve_cfg["gamma_amp"]) * _sigmoid((w - float(curve_cfg["gamma_mid"])) / float(curve_cfg["gamma_steep"])),
		ZombieDefinitions.Rank.BETA: float(curve_cfg["beta_floor"]) + float(curve_cfg["beta_amp"]) * _sigmoid((w - float(curve_cfg["beta_mid"])) / float(curve_cfg["beta_steep"])),
		ZombieDefinitions.Rank.ALPHA: float(curve_cfg["alpha_floor"]) + float(curve_cfg["alpha_amp"]) * _sigmoid((w - float(curve_cfg["alpha_mid"])) / float(curve_cfg["alpha_steep"]))
	}

	var raw_sum: float = 0.0
	for rank_id in MAIN_RANK_ORDER:
		var value: float = float(raw[rank_id])
		if rank_modifier != null and rank_modifier.has_method("get_rank_weight_multiplier"):
			value *= maxf(0.0, float(rank_modifier.call("get_rank_weight_multiplier", rank_id, wave_index)))
		value = maxf(0.0, value)
		raw[rank_id] = value
		raw_sum += value

	var distribution: Dictionary = {}
	if raw_sum <= 0.0:
		distribution[ZombieDefinitions.Rank.DELTA] = 1.0
		return distribution

	for rank_id in MAIN_RANK_ORDER:
		distribution[rank_id] = float(raw[rank_id]) / raw_sum
	return distribution

func get_displaced_ranks(
	distribution: Dictionary,
	near_zero_threshold: float,
	wave_index: int,
	rank_modifier: RefCounted = null,
	curve_mode: String = "default"
) -> Array[int]:
	var threshold: float = clampf(near_zero_threshold, 0.0001, 1.0)
	if wave_index <= 1:
		return []

	var previous_distribution: Dictionary = build_distribution(wave_index - 1, rank_modifier, curve_mode)
	var displaced: Array[int] = []
	for rank_id in MAIN_RANK_ORDER:
		var probability: float = float(distribution.get(rank_id, 0.0))
		var previous_probability: float = float(previous_distribution.get(rank_id, 0.0))
		var trending_down: bool = probability <= previous_probability
		if probability < threshold and trending_down:
			displaced.append(rank_id)

	displaced.sort_custom(func(a: int, b: int) -> bool:
		return ZombieDefinitions.get_rank_power(a) > ZombieDefinitions.get_rank_power(b)
	)
	return displaced

func _sigmoid(value: float) -> float:
	return 1.0 / (1.0 + exp(-value))

func _get_curve_preset(curve_mode: String) -> Dictionary:
	var key: String = curve_mode.to_lower()
	if CURVE_PRESETS.has(key):
		return CURVE_PRESETS[key]
	return CURVE_PRESETS["default"]
