extends RefCounted
class_name WeaponDefinitions

const ORDER: Array[String] = ["pistol", "rifle", "shotgun"]

const WEAPONS := {
	"pistol": {
		"display_name": "Pistol",
		"mag_size": 12,
		"reserve_start": 48,
		"damage": 32,
		"fire_rate": 0.26,
		"reload_time": 1.1,
		"is_automatic": false,
		"base_spread": 0.16,
		"movement_spread_multiplier": 1.15,
		"recoil_pitch": 0.38,
		"recoil_yaw_random": 0.12,
		"recoil_recovery_speed": 16.0,
		"sprint_fire_penalty": 0.18,
		"bloom_per_shot": 0.04,
		"bloom_decay_speed": 1.8,
		"max_bloom": 0.22,
		"buy_cost": 350,
		"ammo_pickup_amount": 24,
		"ammo_refill_cost": 80,
		"unlock_kills": 0,
	},
	"rifle": {
		"display_name": "Rifle",
		"mag_size": 32,
		"reserve_start": 128,
		"damage": 23,
		"fire_rate": 0.085,
		"reload_time": 1.25,
		"is_automatic": true,
		"base_spread": 0.34,
		"movement_spread_multiplier": 1.7,
		"recoil_pitch": 0.82,
		"recoil_yaw_random": 0.4,
		"recoil_recovery_speed": 9.0,
		"sprint_fire_penalty": 0.45,
		"bloom_per_shot": 0.12,
		"bloom_decay_speed": 0.8,
		"max_bloom": 1.1,
		"buy_cost": 650,
		"ammo_pickup_amount": 45,
		"ammo_refill_cost": 130,
		"unlock_kills": 0,
	},
	"shotgun": {
		"display_name": "Shotgun",
		"mag_size": 8,
		"reserve_start": 32,
		"damage": 54,
		"fire_rate": 0.82,
		"reload_time": 1.45,
		"is_automatic": false,
		"base_spread": 0.9,
		"movement_spread_multiplier": 1.5,
		"recoil_pitch": 1.38,
		"recoil_yaw_random": 0.25,
		"recoil_recovery_speed": 8.5,
		"sprint_fire_penalty": 0.55,
		"bloom_per_shot": 0.28,
		"bloom_decay_speed": 0.55,
		"max_bloom": 1.45,
		"buy_cost": 900,
		"ammo_pickup_amount": 12,
		"ammo_refill_cost": 160,
		"unlock_kills": 40,
	},
}

static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)

static func get_weapon_ids() -> Array[String]:
	return ORDER.duplicate()

static func get_weapon_data(weapon_id: String) -> Dictionary:
	var resolved_id: String = weapon_id if has_weapon(weapon_id) else "pistol"
	return Dictionary(WEAPONS[resolved_id]).duplicate(true)

static func get_display_name(weapon_id: String) -> String:
	return String(get_weapon_data(weapon_id).get("display_name", weapon_id.capitalize()))

static func get_unlock_threshold(weapon_id: String) -> int:
	return int(get_weapon_data(weapon_id).get("unlock_kills", 0))

static func create_runtime_state(weapon_id: String) -> Dictionary:
	var weapon_data: Dictionary = get_weapon_data(weapon_id)
	return {
		"weapon_id": weapon_id if has_weapon(weapon_id) else "pistol",
		"ammo_in_mag": int(weapon_data.get("mag_size", 0)),
		"reserve_ammo": int(weapon_data.get("reserve_start", 0)),
	}
