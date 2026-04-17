extends RefCounted
class_name AudioLibrary

const ROOT := "res://assets/audio"

static var _events_cache: Dictionary = {}

static func get_event(event_id: String) -> Dictionary:
	if _events_cache.is_empty():
		_events_cache = _build_events()
	return Dictionary(_events_cache.get(event_id, {}))

static func has_event(event_id: String) -> bool:
	if _events_cache.is_empty():
		_events_cache = _build_events()
	return _events_cache.has(event_id)

static func _build_events() -> Dictionary:
	return {
		"music_ambient": _entry(
			["%s/music/music.mp3" % ROOT],
			"Music",
			-7.0,
			Vector2(1.0, 1.0),
			true
		),
		"music_wave_start": _entry(
			["%s/music/mus_wave_start_stinger.ogg" % ROOT],
			"Music",
			-3.5,
			Vector2(1.0, 1.0)
		),
		"music_wave_clear": _entry(
			["%s/music/mus_wave_clear_stinger.ogg" % ROOT],
			"Music",
			-3.5,
			Vector2(1.0, 1.0)
		),
		"music_game_over": _entry(
			["%s/music/mus_game_over_stinger.ogg" % ROOT],
			"Music",
			-2.0,
			Vector2(1.0, 1.0)
		),
		"ambience_base_wind": _entry(
			["%s/ambience/amb_base_wind_loop.ogg" % ROOT],
			"Ambience",
			-14.0,
			Vector2(1.0, 1.0),
			true
		),
		"ambience_rain": _entry(
			["%s/ambience/amb_rain_loop.ogg" % ROOT],
			"Ambience",
			-11.0,
			Vector2(1.0, 1.0),
			true
		),
		"ambience_storm": _entry(
			["%s/ambience/amb_storm_loop.ogg" % ROOT],
			"Ambience",
			-9.0,
			Vector2(1.0, 1.0),
			true
		),
		"ambience_thunder_far": _entry(_seq("%s/ambience/amb_thunder_far" % ROOT, 1, 4), "Ambience", -4.0, Vector2(0.97, 1.03), false, true, 70.0),
		"ambience_thunder_near": _entry(_seq("%s/ambience/amb_thunder_near" % ROOT, 1, 3), "Ambience", -1.5, Vector2(0.98, 1.04), false, true, 85.0),
		"weapon_fire_pistol": _entry(["%s/sfx/weapons/pistol/pistol.mp3" % ROOT], "SFX", -3.0, Vector2(3.0, 3.0)),
		"weapon_reload_pistol": _entry(["%s/sfx/weapons/pistol/pistol.mp3" % ROOT], "SFX", -6.0, Vector2(3.0, 3.0)),
		"weapon_empty_pistol": _entry(["%s/sfx/weapons/pistol/pistol.mp3" % ROOT], "SFX", -8.0, Vector2(3.0, 3.0)),
		"weapon_fire_rifle": _entry(["%s/sfx/weapons/rifle/rifle.mp3" % ROOT], "SFX", -4.0, Vector2(3.0, 3.0)),
		"weapon_reload_rifle": _entry(["%s/sfx/weapons/rifle/rifle.mp3" % ROOT], "SFX", -6.5, Vector2(3.0, 3.0)),
		"weapon_empty_rifle": _entry(["%s/sfx/weapons/rifle/rifle.mp3" % ROOT], "SFX", -8.0, Vector2(3.0, 3.0)),
		"weapon_fire_shotgun": _entry(["%s/sfx/weapons/shotgun/shotgun.mp3" % ROOT], "SFX", -2.0, Vector2(3.0, 3.0)),
		"weapon_reload_shotgun": _entry(["%s/sfx/weapons/shotgun/shotgun.mp3" % ROOT], "SFX", -6.0, Vector2(3.0, 3.0)),
		"weapon_empty_shotgun": _entry(["%s/sfx/weapons/shotgun/shotgun.mp3" % ROOT], "SFX", -8.0, Vector2(3.0, 3.0)),
		"player_footstep_concrete": _entry(_seq("%s/sfx/player/plr_footstep_concrete" % ROOT, 1, 6), "SFX", -12.0, Vector2(0.95, 1.06)),
		"player_jump": _entry(["%s/sfx/player/plr_jump_01.ogg" % ROOT], "SFX", -10.0, Vector2(1.0, 1.03)),
		"player_land": _entry(_seq("%s/sfx/player/plr_land" % ROOT, 1, 3), "SFX", -8.5, Vector2(0.98, 1.03)),
		"player_damage": _entry(_seq("%s/sfx/player/plr_damage" % ROOT, 1, 4), "SFX", -5.0, Vector2(0.97, 1.03)),
		"player_medkit_use": _entry(["%s/sfx/player/plr_medkit_use_01.ogg" % ROOT], "SFX", -7.0, Vector2(1.0, 1.02)),
		"player_armor_use": _entry(["%s/sfx/player/plr_armor_use_01.ogg" % ROOT], "SFX", -7.0, Vector2(1.0, 1.02)),
		"player_grenade_throw": _entry(["%s/sfx/player/plr_grenade_throw_01.ogg" % ROOT], "SFX", -6.0, Vector2(1.0, 1.03)),
		"player_weapon_switch": _entry(_seq("%s/sfx/player/plr_weapon_switch" % ROOT, 1, 2), "SFX", -8.5, Vector2(0.98, 1.02)),
		"zombie_spawn": _entry(["%s/sfx/zombie/zombie1.mp3" % ROOT], "SFX", -5.5, Vector2(0.95, 1.05), false, true, 32.0),
		"zombie_idle": _entry(["%s/sfx/zombie/zombie1.mp3" % ROOT], "SFX", -13.0, Vector2(0.93, 1.04), false, true, 36.0),
		"zombie_hurt": _entry(["%s/sfx/zombie/zombie2.mp3" % ROOT], "SFX", -6.5, Vector2(0.95, 1.05), false, true, 32.0),
		"zombie_attack": _entry(["%s/sfx/zombie/zombie1.mp3" % ROOT], "SFX", -5.5, Vector2(0.95, 1.04), false, true, 28.0),
		"zombie_barricade_hit": _entry(["%s/sfx/zombie/zombie2.mp3" % ROOT], "SFX", -4.5, Vector2(0.96, 1.04), false, true, 24.0),
		"zombie_death": _entry(["%s/sfx/zombie/zombie1.mp3" % ROOT, "%s/sfx/zombie/zombie2.mp3" % ROOT], "SFX", -4.5, Vector2(0.95, 1.03), false, true, 30.0, "round_robin"),
		"zombie_explode": _entry(["%s/sfx/zombie/zombie2.mp3" % ROOT], "SFX", -1.5, Vector2(0.98, 1.02), false, true, 46.0),
		"zombie_ranged_attack": _entry(["%s/sfx/zombie/zombie1.mp3" % ROOT], "SFX", -4.5, Vector2(0.98, 1.02), false, true, 36.0),
		"pickup_ammo": _entry(["%s/sfx/interactables/pickup_ammo_01.ogg" % ROOT], "SFX", -6.0, Vector2(1.0, 1.03)),
		"pickup_weapon": _entry(["%s/sfx/interactables/pickup_weapon_01.ogg" % ROOT], "SFX", -5.0, Vector2(1.0, 1.03)),
		"pickup_consumable": _entry(["%s/sfx/interactables/pickup_consumable_01.ogg" % ROOT], "SFX", -6.0, Vector2(1.0, 1.03)),
		"station_purchase_success": _entry(["%s/sfx/interactables/station_purchase_success_01.ogg" % ROOT], "SFX", -5.0, Vector2(1.0, 1.02)),
		"station_purchase_fail": _entry(["%s/sfx/interactables/station_purchase_fail_01.ogg" % ROOT], "SFX", -5.5, Vector2(1.0, 1.02)),
		"station_upgrade_success": _entry(["%s/sfx/interactables/station_upgrade_success_01.ogg" % ROOT], "SFX", -4.5, Vector2(1.0, 1.02)),
		"barricade_repair": _entry(_seq("%s/sfx/interactables/barricade_repair" % ROOT, 1, 3), "SFX", -5.5, Vector2(0.98, 1.04), false, true, 22.0),
		"barricade_break": _entry(_seq("%s/sfx/interactables/barricade_break" % ROOT, 1, 3), "SFX", -4.0, Vector2(0.98, 1.03), false, true, 26.0),
		"ui_hit": _entry(["%s/sfx/ui/ui_hit_01.ogg" % ROOT], "UI", -6.0, Vector2(1.0, 1.02)),
		"ui_kill": _entry(["%s/sfx/ui/ui_kill_01.ogg" % ROOT], "UI", -5.5, Vector2(1.0, 1.02)),
		"ui_headshot": _entry(["%s/sfx/ui/ui_headshot_01.ogg" % ROOT], "UI", -4.5, Vector2(1.0, 1.02)),
		"ui_unlock": _entry(["%s/sfx/ui/ui_unlock_01.ogg" % ROOT], "UI", -4.5, Vector2(1.0, 1.02)),
		"ui_pause_open": _entry(["%s/sfx/ui/ui_pause_open_01.ogg" % ROOT], "UI", -7.0, Vector2(1.0, 1.01)),
		"ui_pause_close": _entry(["%s/sfx/ui/ui_pause_close_01.ogg" % ROOT], "UI", -7.0, Vector2(1.0, 1.01)),
		"ui_button_hover": _entry(["%s/sfx/ui/ui_button_hover_01.ogg" % ROOT], "UI", -11.0, Vector2(1.0, 1.02)),
		"ui_button_click": _entry(["%s/sfx/ui/ui_button_click_01.ogg" % ROOT], "UI", -7.5, Vector2(1.0, 1.02)),
		"ui_handbook_open": _entry(["%s/sfx/ui/ui_handbook_open_01.ogg" % ROOT], "UI", -6.5, Vector2(1.0, 1.02)),
		"ui_handbook_close": _entry(["%s/sfx/ui/ui_handbook_close_01.ogg" % ROOT], "UI", -6.5, Vector2(1.0, 1.02)),
		"ui_error": _entry(["%s/sfx/ui/ui_error_01.ogg" % ROOT], "UI", -6.0, Vector2(1.0, 1.02)),
	}

static func _entry(
	paths: Array[String],
	bus: String,
	volume_db: float,
	pitch_range: Vector2,
	loop: bool = false,
	default_3d: bool = false,
	max_distance: float = 24.0,
	selection_mode: String = "random"
) -> Dictionary:
	return {
		"paths": paths,
		"bus": bus,
		"volume_db": volume_db,
		"pitch_range": pitch_range,
		"loop": loop,
		"default_3d": default_3d,
		"max_distance": max_distance,
		"selection_mode": selection_mode,
	}

static func _seq(prefix: String, from_index: int, to_index: int) -> Array[String]:
	var paths: Array[String] = []
	for variant_index in range(from_index, to_index + 1):
		paths.append("%s_%02d.ogg" % [prefix, variant_index])
	return paths
