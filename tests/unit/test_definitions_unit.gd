extends RefCounted

const TestCase = preload("res://tests/core/test_case.gd")
const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDataValidator = preload("res://scripts/debug/zombie_data_validator.gd")
const ZombieDeathVisuals = preload("res://scripts/zombie_death_visuals.gd")

func run(_seed: int = 1337) -> Dictionary:
	var tc := TestCase.new("unit.definitions")

	var validator: ZombieDataValidator = ZombieDataValidator.new()
	var validation: Dictionary = validator.validate_all()
	tc.assert_true(bool(validation.get("ok", false)), "validator_ok")
	if not bool(validation.get("ok", false)):
		for err in validation.get("errors", []):
			tc.add_note("validator_error:%s" % String(err))

	tc.assert_eq(ZombieDefinitions.SPECIES_ORDER.size(), 15, "species_count")
	tc.assert_eq(ZombieDefinitions.DEATH_CLASS_ORDER.size(), 8, "death_class_count")
	tc.assert_true(ZombieDefinitions.DEATH_SUBTYPE_ORDER.size() >= 33, "death_subtype_count_min")

	for subtype_id in ZombieDefinitions.DEATH_SUBTYPE_ORDER:
		var profile: Dictionary = ZombieDeathVisuals.get_visual_profile(int(subtype_id))
		tc.assert_true(profile.has("display_color_hex"), "subtype_has_color_hex:%s" % str(subtype_id))
		tc.assert_in_range(float(profile.get("intensity", 0.0)), 0.08, 1.0, "subtype_intensity_range:%s" % str(subtype_id))

	return tc.to_dict()
