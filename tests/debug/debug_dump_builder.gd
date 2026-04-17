extends RefCounted
class_name DebugDumpBuilder

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const MainWaveProgressionModel = preload("res://scripts/wave/main_wave_progression_model.gd")

func build_debug_dump(seed: int = 1337) -> Dictionary:
	var progression: MainWaveProgressionModel = MainWaveProgressionModel.new()
	var dump: Dictionary = {
		"seed": seed,
		"mort_distribution": ZombieDefinitions.get_mort_grade_probability_table(0, 10),
		"rank_distributions": {},
		"jump_matrix": {}
	}

	for wave in [1, 5, 10, 15, 25, 40]:
		dump["rank_distributions"][str(wave)] = progression.build_distribution(wave)

	var species_samples: Array[int] = [
		ZombieDefinitions.Species.WALKER,
		ZombieDefinitions.Species.BRUTE,
		ZombieDefinitions.Species.SPRINTER,
		ZombieDefinitions.Species.CRAWLER
	]
	var rank_samples: Array[int] = [
		ZombieDefinitions.Rank.EPSILON,
		ZombieDefinitions.Rank.DELTA,
		ZombieDefinitions.Rank.GAMMA,
		ZombieDefinitions.Rank.BETA,
		ZombieDefinitions.Rank.ALPHA
	]

	for species_id in species_samples:
		var species_key: String = String(ZombieDefinitions.get_species_data(species_id).get("id", str(species_id)))
		var per_rank: Dictionary = {}
		for rank_id in rank_samples:
			var rank_key: String = String(ZombieDefinitions.get_rank_data(rank_id).get("id", str(rank_id)))
			per_rank[rank_key] = {
				"mort_0": ZombieDefinitions.build_jump_runtime_profile(species_id, rank_id, 0, {}),
				"mort_6": ZombieDefinitions.build_jump_runtime_profile(species_id, rank_id, 6, {}),
				"mort_10": ZombieDefinitions.build_jump_runtime_profile(species_id, rank_id, 10, {})
			}
		dump["jump_matrix"][species_key] = per_rank

	return dump
