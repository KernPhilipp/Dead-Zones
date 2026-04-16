extends RefCounted
class_name ZombieHandbookData

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")
const ZombieDeathEffects = preload("res://scripts/zombie_death_effects.gd")

const HANDBOOK_CATEGORY_ORDER: Array[int] = [
	ZombieDefinitions.HandbookCategory.GEWOEHNLICH,
	ZombieDefinitions.HandbookCategory.HEAVY,
	ZombieDefinitions.HandbookCategory.FAST,
	ZombieDefinitions.HandbookCategory.AMBUSH,
	ZombieDefinitions.HandbookCategory.SPECIAL
]

const GAMEPLAY_CLASS_ORDER: Array[int] = [
	ZombieDefinitions.ZombieClass.COMMON,
	ZombieDefinitions.ZombieClass.FERAL,
	ZombieDefinitions.ZombieClass.ARMORED
]

const RANK_ORDER: Array[int] = [
	ZombieDefinitions.Rank.ALPHA,
	ZombieDefinitions.Rank.BETA,
	ZombieDefinitions.Rank.GAMMA,
	ZombieDefinitions.Rank.DELTA,
	ZombieDefinitions.Rank.EPSILON
]

const DEATH_RARITY_ORDER: Array[int] = [
	ZombieDefinitions.DeathRarity.GEWOEHNLICH,
	ZombieDefinitions.DeathRarity.UNGEWOEHNLICH,
	ZombieDefinitions.DeathRarity.SELTEN,
	ZombieDefinitions.DeathRarity.EPISCH,
	ZombieDefinitions.DeathRarity.LEGENDAER
]

static func get_species_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var order: int = 1
	for species_id in ZombieDefinitions.get_species_order():
		var species_cfg: Dictionary = ZombieDefinitions.get_species_data(species_id)
		var category_cfg: Dictionary = ZombieDefinitions.get_handbook_category_data(int(species_cfg["handbook_category"]))
		entries.append({
			"order": order,
			"species_id": int(species_id),
			"internal_id": String(species_cfg["id"]),
			"name": String(species_cfg["display_name"]),
			"handbook_category_id": String(category_cfg["id"]),
			"handbook_category_name": String(category_cfg["display_name"]),
			"appearance_description": ZombieDefinitions.get_species_appearance_description(int(species_id)),
			"handbook_image": ZombieDefinitions.get_species_handbook_image(int(species_id)),
			"short_description": String(species_cfg["handbook_short"]),
			"functional_profile": String(species_cfg["functional_profile"]),
			"threat_profile": String(species_cfg["threat_profile"]),
			"notes": String(species_cfg["notes"])
		})
		order += 1
	return entries

static func get_handbook_categories() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for category_id in HANDBOOK_CATEGORY_ORDER:
		var category_cfg: Dictionary = ZombieDefinitions.get_handbook_category_data(category_id)
		entries.append({
			"category_id": String(category_cfg["id"]),
			"name": String(category_cfg["display_name"]),
			"description": String(category_cfg["description"]),
			"note": "Nur Handbuch-Sortierung, keine Gameplay-Klasse."
		})
	return entries

static func get_gameplay_class_glossary() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for gameplay_class in GAMEPLAY_CLASS_ORDER:
		var class_cfg: Dictionary = ZombieDefinitions.get_class_data(gameplay_class)
		entries.append({
			"id": String(class_cfg["id"]),
			"name": String(class_cfg["display_name"]),
			"description": "GameplayClass-Modifikator. Strikt getrennt von DeathClass."
		})
	return entries

static func get_class_glossary() -> Array[Dictionary]:
	return get_gameplay_class_glossary()

static func get_mort_grade_glossary() -> Dictionary:
	var mort_entries: Array[Dictionary] = get_mort_grade_entries()
	return {
		"name": "Mort-Grad",
		"description": "Beschreibt den Zerfallszustand als Gameplay-Layer von 0 (frisch) bis 10 (stark verwest).",
		"neutral_grade": ZombieDefinitions.MORT_GRADE_NEUTRAL,
		"low_mort": "Niedrige Grade (0-2) sind etwas schneller und gefaehrlicher.",
		"high_mort": "Hohe Grade (9-10) sind deutlich traeger und schwaecher.",
		"distribution_note": "Spawn-Gewichtung: raw_weight = 0.5 ^ abs(grade - 6), danach normalisiert auf 100%.",
		"distribution_focus": "Grad 6 ist der haeufigste Standardfall.",
		"tier_notes": [
			"0-2: frisch, reaktionsfaehig, gefaehrlicher",
			"3-5: leicht verwest, aber noch stabil",
			"6: durchschnittlicher Schwerpunkt",
			"7-8: deutlich verwest, schwaecher",
			"9-10: extrem zerfallen, stark gedaempft"
		],
		"entries": mort_entries
	}

static func get_mort_grade_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	var probability_table: Dictionary = ZombieDefinitions.get_mort_grade_probability_table(
		ZombieDefinitions.MORT_GRADE_MIN,
		ZombieDefinitions.MORT_GRADE_MAX
	)
	for grade in range(ZombieDefinitions.MORT_GRADE_MIN, ZombieDefinitions.MORT_GRADE_MAX + 1):
		var modifiers: Dictionary = ZombieDefinitions.get_mort_grade_modifiers(grade)
		var probability: float = float(probability_table.get(grade, 0.0))
		entries.append({
			"grade": grade,
			"probability": probability,
			"probability_percent": probability * 100.0,
			"raw_weight": ZombieDefinitions.get_mort_grade_raw_weight(grade),
			"speed_mult": float(modifiers["speed_mult"]),
			"damage_mult": float(modifiers["damage_mult"]),
			"attack_cooldown_mult": float(modifiers["attack_cooldown_mult"])
		})
	return entries

static func get_rank_glossary() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for rank_id in RANK_ORDER:
		var rank_cfg: Dictionary = ZombieDefinitions.get_rank_data(rank_id)
		entries.append({
			"id": String(rank_cfg["id"]),
			"name": String(rank_cfg.get("display_name", String(rank_cfg["id"]))),
			"rank_power": int(rank_cfg.get("rank_power", 0)),
			"description": String(rank_cfg.get("role", "Hierarchiestufe mit eigenem Profil.")),
			"size_mult": float(rank_cfg.get("scale_mult", 1.0)),
			"health_mult": float(rank_cfg.get("health_mult", 1.0)),
			"damage_mult": float(rank_cfg.get("damage_mult", 1.0)),
			"speed_mult": float(rank_cfg.get("speed_mult", 1.0)),
			"threat_mult": float(rank_cfg.get("threat_mult", 1.0)),
			"visual_intensity": String(rank_cfg.get("visual_intensity", "normal")),
			"spawn_interval_factor": float(rank_cfg.get("spawn_interval_factor", 1.0)),
			"speed_cap": float(rank_cfg.get("speed_cap", 8.0))
		})
	return entries

static func get_wave_runtime_glossary() -> Dictionary:
	return {
		"title": "Wellen- und Ebenensystem",
		"summary": "Jede Welle wird zuerst vollstaendig als Plan erzeugt und danach zeitlich abgespielt.",
		"steps": [
			"1) Hauptverteilung pro Welle berechnen und normalisieren",
			"2) Hauptwelle mit BaseWaveSpawnCount ziehen",
			"3) Verdraengte Ranges erkennen und Ebenen persistent aktualisieren",
			"4) Extra-Spawns nur aus Restbudget (maximal base*2 insgesamt) berechnen",
			"5) Vollstaendigen SpawnSchedule erstellen und zeitlich staffeln",
			"6) Waehrend der Welle nur Plan abarbeiten, nicht neu auswuerfeln"
		],
		"defaults": [
			"BaseWaveSpawnCount: 20",
			"MaxTotalSpawnCount: BaseWaveSpawnCount * 2",
			"AliveCap: 12",
			"BaseSpawnIntervalSeconds: 1.2",
			"MinSpawnDistanceFromPlayer: 10.0m",
			"NearZeroThreshold fuer Verdraengung: 1%",
			"Curve-Toggle: F7 (default/tuned, fuer Balancing)",
			"Debug-Overlay: zeigt Wave/Plan/Layer live"
		],
		"notes": [
			"Hohe Ranges sind staerker, auffaelliger und langsamer.",
			"Alpha bleibt Endboss-Niveau und bekommt zusaetzliche Spawn-Luft.",
			"Spawnpunkte werden mapabhaengig gesammelt und vor Distanz zum Player validiert.",
			"Naechste Welle startet nach vollstaendigem Clear."
		]
	}

static func get_death_class_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for death_class_id in ZombieDefinitions.get_death_class_order():
		var class_cfg: Dictionary = ZombieDefinitions.get_death_class_data(death_class_id)
		var subtype_names: Array[String] = []
		for subtype_id in ZombieDefinitions.get_death_subtype_order():
			var subtype_cfg: Dictionary = ZombieDefinitions.get_death_subtype_data(subtype_id)
			if int(subtype_cfg["death_class"]) == death_class_id:
				subtype_names.append(String(subtype_cfg["display_name"]))

		entries.append({
			"id": String(class_cfg["id"]),
			"name": String(class_cfg["display_name"]),
			"description": String(class_cfg["description"]),
			"death_subtypes": subtype_names
		})
	return entries

static func get_death_subtype_entries() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for subtype_id in ZombieDefinitions.get_death_subtype_order():
		var subtype_cfg: Dictionary = ZombieDefinitions.get_death_subtype_data(subtype_id)
		var class_cfg: Dictionary = ZombieDefinitions.get_death_class_data(int(subtype_cfg["death_class"]))
		var rarity_cfg: Dictionary = ZombieDefinitions.get_death_rarity_data(int(subtype_cfg["rarity"]))
		var effect_cfg: Dictionary = ZombieDeathEffects.get_effect_profile(subtype_id)
		entries.append({
			"id": String(subtype_cfg["id"]),
			"name": String(subtype_cfg["display_name"]),
			"death_class_id": String(class_cfg["id"]),
			"death_class_name": String(class_cfg["display_name"]),
			"rarity_id": String(rarity_cfg["id"]),
			"rarity_name": String(rarity_cfg["display_name"]),
			"description": String(subtype_cfg["description"]),
			"runtime_effect": String(effect_cfg["runtime_effect"]),
			"gameplay_followup": String(effect_cfg["gameplay_followup"]),
			"implementation_status_id": String(effect_cfg["implementation_status"]),
			"implementation_status_name": String(effect_cfg["implementation_status_name"]),
			"revenge_bonus": bool(effect_cfg["revenge_bonus"]),
			"danger_hint": String(effect_cfg["danger_hint"]),
			"counter_hint": String(effect_cfg["counter_hint"]),
			"active_hooks": effect_cfg.get("active_hooks", []),
			"planned_hooks": effect_cfg.get("planned_hooks", []),
			"image_path": String(effect_cfg["image_path"]),
			"ai_prompt": String(effect_cfg["ai_prompt"])
		})
	return entries

static func get_death_rarity_glossary() -> Array[Dictionary]:
	var entries: Array[Dictionary] = []
	for rarity_id in DEATH_RARITY_ORDER:
		var rarity_cfg: Dictionary = ZombieDefinitions.get_death_rarity_data(rarity_id)
		entries.append({
			"id": String(rarity_cfg["id"]),
			"name": String(rarity_cfg["display_name"]),
			"description": String(rarity_cfg["description"])
		})
	return entries
