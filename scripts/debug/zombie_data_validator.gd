extends RefCounted
class_name ZombieDataValidator

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDeathVisuals = preload("res://scripts/zombie_death_visuals.gd")
const ZombieMortVisuals = preload("res://scripts/zombie_mort_visuals.gd")

func validate_all() -> Dictionary:
	var errors: Array[String] = []
	var warnings: Array[String] = []

	_validate_species(errors)
	_validate_ranks(errors)
	_validate_mort(errors)
	_validate_death_data(errors)
	_validate_jump_profiles(errors, warnings)

	return {
		"ok": errors.is_empty(),
		"errors": errors,
		"warnings": warnings,
		"error_count": errors.size(),
		"warning_count": warnings.size()
	}

func _validate_species(errors: Array[String]):
	var seen_ids: Dictionary = {}
	for species_id in ZombieDefinitions.SPECIES_ORDER:
		var data: Dictionary = ZombieDefinitions.get_species_data(int(species_id))
		var sid: String = String(data.get("id", ""))
		if sid.is_empty():
			errors.append("species_missing_id:%s" % str(species_id))
			continue
		if seen_ids.has(sid):
			errors.append("species_duplicate_id:%s" % sid)
		seen_ids[sid] = true

func _validate_ranks(errors: Array[String]):
	var required_ranks: Array[int] = [
		ZombieDefinitions.Rank.ALPHA,
		ZombieDefinitions.Rank.BETA,
		ZombieDefinitions.Rank.GAMMA,
		ZombieDefinitions.Rank.DELTA,
		ZombieDefinitions.Rank.EPSILON
	]
	for rank_id in required_ranks:
		var data: Dictionary = ZombieDefinitions.get_rank_data(rank_id)
		if not data.has("id"):
			errors.append("rank_missing_id:%s" % str(rank_id))
		if not data.has("rank_power"):
			errors.append("rank_missing_power:%s" % str(rank_id))

func _validate_mort(errors: Array[String]):
	for grade in range(0, 11):
		var darkness: float = ZombieMortVisuals.get_darkness_for_grade(grade)
		if darkness < 0.0 or darkness > 0.9:
			errors.append("mort_darkness_out_of_range:%d=%f" % [grade, darkness])

	var probabilities: Dictionary = ZombieDefinitions.get_mort_grade_probability_table(0, 10)
	var sum_probs: float = 0.0
	for value in probabilities.values():
		sum_probs += float(value)
	if absf(sum_probs - 1.0) > 0.0001:
		errors.append("mort_probability_sum_invalid:%f" % sum_probs)

func _validate_death_data(errors: Array[String]):
	var subtype_id_seen: Dictionary = {}
	for subtype_id in ZombieDefinitions.DEATH_SUBTYPE_ORDER:
		var subtype_data: Dictionary = ZombieDefinitions.get_death_subtype_data(int(subtype_id))
		var sid: String = String(subtype_data.get("id", ""))
		if sid.is_empty():
			errors.append("death_subtype_missing_id:%s" % str(subtype_id))
			continue
		if subtype_id_seen.has(sid):
			errors.append("death_subtype_duplicate_id:%s" % sid)
		subtype_id_seen[sid] = true

		if not subtype_data.has("death_class") or not ZombieDefinitions.DEATH_CLASS_DATA.has(int(subtype_data["death_class"])):
			errors.append("death_subtype_invalid_class:%s" % sid)
		if not subtype_data.has("rarity") or not ZombieDefinitions.DEATH_RARITY_DATA.has(int(subtype_data["rarity"])):
			errors.append("death_subtype_invalid_rarity:%s" % sid)
		if String(subtype_data.get("description", "")).strip_edges().is_empty():
			errors.append("death_subtype_missing_description:%s" % sid)

		var visual_profile: Dictionary = ZombieDeathVisuals.get_visual_profile(int(subtype_id))
		var mode: String = String(visual_profile.get("visual_mode", ZombieDeathVisuals.VISUAL_MODE_NONE))
		if mode != ZombieDeathVisuals.VISUAL_MODE_NONE and mode != ZombieDeathVisuals.VISUAL_MODE_PARTICLE and mode != ZombieDeathVisuals.VISUAL_MODE_ATTACHMENT_MODEL and mode != ZombieDeathVisuals.VISUAL_MODE_MESH_OVERLAY:
			errors.append("death_subtype_invalid_visual_mode:%s=%s" % [sid, mode])

func _validate_jump_profiles(errors: Array[String], warnings: Array[String]):
	for species_id in ZombieDefinitions.SPECIES_ORDER:
		var profile: Dictionary = ZombieDefinitions.get_species_jump_profile(int(species_id))
		if not profile.has("can_jump"):
			errors.append("jump_profile_missing_can_jump:%s" % str(species_id))
		if not profile.has("force_mult"):
			errors.append("jump_profile_missing_force:%s" % str(species_id))
		if float(profile.get("force_mult", 0.0)) < 0.0:
			errors.append("jump_profile_negative_force:%s" % str(species_id))
		if float(profile.get("cooldown_mult", 0.0)) <= 0.0:
			errors.append("jump_profile_invalid_cooldown:%s" % str(species_id))

	var crawler_profile: Dictionary = ZombieDefinitions.get_species_jump_profile(ZombieDefinitions.Species.CRAWLER)
	if bool(crawler_profile.get("can_jump", true)):
		warnings.append("crawler_can_jump_enabled_expected_false")
