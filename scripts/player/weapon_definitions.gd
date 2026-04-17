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
		"pellet_count": 1,
		"pellet_spread_multiplier": 1.0,
		"headshot_multiplier": 2.0,
		"buy_cost": 350,
		"ammo_pickup_amount": 24,
		"ammo_refill_cost": 80,
		"unlock_kills": 0,
		"upgrade_tier_1": {
			"display_name": "Pistol+",
			"damage": 42,
			"mag_size": 16,
			"reserve_start": 64,
			"base_spread": 0.14,
			"recoil_pitch": 0.3,
			"recoil_yaw_random": 0.08,
			"recoil_recovery_speed": 18.0,
			"bloom_per_shot": 0.03,
			"max_bloom": 0.18,
			"ammo_pickup_amount": 28,
			"ammo_refill_cost": 95,
			"upgrade_cost": 600,
		},
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
		"pellet_count": 1,
		"pellet_spread_multiplier": 1.0,
		"headshot_multiplier": 2.0,
		"buy_cost": 650,
		"ammo_pickup_amount": 45,
		"ammo_refill_cost": 130,
		"unlock_kills": 0,
		"upgrade_tier_1": {
			"display_name": "Rifle+",
			"damage": 28,
			"mag_size": 40,
			"reserve_start": 160,
			"base_spread": 0.26,
			"recoil_pitch": 0.65,
			"recoil_yaw_random": 0.26,
			"recoil_recovery_speed": 10.5,
			"bloom_per_shot": 0.095,
			"max_bloom": 0.92,
			"ammo_pickup_amount": 54,
			"ammo_refill_cost": 150,
			"upgrade_cost": 900,
		},
	},
	"shotgun": {
		"display_name": "Shotgun",
		"mag_size": 8,
		"reserve_start": 32,
		"damage": 16,
		"fire_rate": 0.82,
		"reload_time": 1.45,
		"is_automatic": false,
		"base_spread": 0.22,
		"movement_spread_multiplier": 1.5,
		"recoil_pitch": 1.38,
		"recoil_yaw_random": 0.25,
		"recoil_recovery_speed": 8.5,
		"sprint_fire_penalty": 0.55,
		"bloom_per_shot": 0.2,
		"bloom_decay_speed": 0.65,
		"max_bloom": 0.95,
		"pellet_count": 7,
		"pellet_spread_multiplier": 1.35,
		"headshot_multiplier": 1.8,
		"buy_cost": 900,
		"ammo_pickup_amount": 12,
		"ammo_refill_cost": 160,
		"unlock_kills": 40,
		"upgrade_tier_1": {
			"display_name": "Shotgun+",
			"damage": 18,
			"mag_size": 10,
			"reserve_start": 40,
			"base_spread": 0.18,
			"recoil_pitch": 1.16,
			"recoil_yaw_random": 0.18,
			"recoil_recovery_speed": 9.4,
			"bloom_per_shot": 0.16,
			"max_bloom": 0.8,
			"pellet_count": 8,
			"ammo_pickup_amount": 14,
			"ammo_refill_cost": 180,
			"upgrade_cost": 1100,
		},
	},
}

static func has_weapon(weapon_id: String) -> bool:
	return WEAPONS.has(weapon_id)

static func get_weapon_ids() -> Array[String]:
	return ORDER.duplicate()

static func get_weapon_data(weapon_id: String, upgrade_tier: int = 0) -> Dictionary:
	var resolved_id: String = weapon_id if has_weapon(weapon_id) else "pistol"
	var result: Dictionary = Dictionary(WEAPONS[resolved_id]).duplicate(true)
	var resolved_tier: int = clampi(upgrade_tier, 0, get_max_upgrade_tier(resolved_id))
	for tier in range(1, resolved_tier + 1):
		var tier_key: String = "upgrade_tier_%d" % tier
		if not result.has(tier_key):
			continue
		var tier_data: Dictionary = Dictionary(result[tier_key]).duplicate(true)
		for field in tier_data.keys():
			result[field] = tier_data[field]
	result["weapon_id"] = resolved_id
	result["upgrade_tier"] = resolved_tier
	return result

static func get_display_name(weapon_id: String, upgrade_tier: int = 0) -> String:
	return String(get_weapon_data(weapon_id, upgrade_tier).get("display_name", weapon_id.capitalize()))

static func get_unlock_threshold(weapon_id: String) -> int:
	return int(get_weapon_data(weapon_id).get("unlock_kills", 0))

static func get_max_upgrade_tier(weapon_id: String) -> int:
	var resolved_id: String = weapon_id if has_weapon(weapon_id) else "pistol"
	var tier: int = 0
	while Dictionary(WEAPONS[resolved_id]).has("upgrade_tier_%d" % (tier + 1)):
		tier += 1
	return tier

static func get_upgrade_cost(weapon_id: String, upgrade_tier: int = 1) -> int:
	var resolved_id: String = weapon_id if has_weapon(weapon_id) else "pistol"
	var tier_key: String = "upgrade_tier_%d" % upgrade_tier
	var tier_data: Dictionary = Dictionary(WEAPONS[resolved_id].get(tier_key, {}))
	return int(tier_data.get("upgrade_cost", 0))

static func create_runtime_state(weapon_id: String) -> Dictionary:
	var weapon_data: Dictionary = get_weapon_data(weapon_id, 0)
	return {
		"weapon_id": weapon_id if has_weapon(weapon_id) else "pistol",
		"upgrade_tier": 0,
		"ammo_in_mag": int(weapon_data.get("mag_size", 0)),
		"reserve_ammo": int(weapon_data.get("reserve_start", 0)),
	}
