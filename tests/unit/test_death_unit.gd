extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDeathVisuals = preload("res://scripts/zombie_death_visuals.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("unit.death")
	var valid_modes: Dictionary = {
		ZombieDeathVisuals.VISUAL_MODE_NONE: true,
		ZombieDeathVisuals.VISUAL_MODE_PARTICLE: true,
		ZombieDeathVisuals.VISUAL_MODE_ATTACHMENT_MODEL: true,
		ZombieDeathVisuals.VISUAL_MODE_MESH_OVERLAY: true
	}

	for subtype_id in ZombieDefinitions.DEATH_SUBTYPE_ORDER:
		var subtype_data: Dictionary = ZombieDefinitions.get_death_subtype_data(int(subtype_id))
		var subtype_name: String = String(subtype_data.get("id", str(subtype_id)))
		var death_class_id: int = int(subtype_data.get("death_class", -1))
		tc.assert_true(ZombieDefinitions.DEATH_CLASS_DATA.has(death_class_id), "death_class_exists:%s" % subtype_name)
		tc.assert_true(ZombieDefinitions.DEATH_RARITY_DATA.has(int(subtype_data.get("rarity", -1))), "death_rarity_exists:%s" % subtype_name)
		tc.assert_true(String(subtype_data.get("description", "")).length() > 2, "death_description_exists:%s" % subtype_name)

		var visual_profile: Dictionary = ZombieDeathVisuals.get_visual_profile(int(subtype_id))
		var mode: String = String(visual_profile.get("visual_mode", ""))
		tc.assert_true(valid_modes.has(mode), "death_visual_mode_valid:%s=%s" % [subtype_name, mode])
		tc.assert_true(String(visual_profile.get("display_color_hex", "")).begins_with("#"), "death_visual_color_hex:%s" % subtype_name)

	var atom_subtype: Dictionary = ZombieDefinitions.get_death_subtype_data(ZombieDefinitions.DeathSubtype.ATOMVERSEUCHT)
	tc.assert_eq(int(atom_subtype.get("death_class", -1)), ZombieDefinitions.DeathClass.STRAHLUNG, "atomverseucht_in_strahlung")

	return tc.to_dict()
