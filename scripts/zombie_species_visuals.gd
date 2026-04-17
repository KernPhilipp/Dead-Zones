extends RefCounted
class_name ZombieSpeciesVisuals

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

const DEFAULT_REFERENCE_ROOT := "res://assets/handbook/species/"

const SPECIES_VISUAL_CONFIG: Dictionary = {
	ZombieDefinitions.Species.WALKER: {
		"template_id": "walker_reference",
		"template_note": "Neutraler Referenzkoerper ohne Spezialsilhouette.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "walker.svg",
		"silhouette_tags": ["neutral", "baseline", "average"],
		"palette": {
			"torso": Color(0.21, 0.47, 0.16, 1.0),
			"head": Color(0.26, 0.56, 0.19, 1.0),
			"arm_l": Color(0.2, 0.45, 0.16, 1.0),
			"arm_r": Color(0.2, 0.45, 0.16, 1.0),
			"leg_l": Color(0.16, 0.38, 0.13, 1.0),
			"leg_r": Color(0.16, 0.38, 0.13, 1.0),
			"weapon": Color(0.18, 0.18, 0.19, 1.0)
		}
	},
	ZombieDefinitions.Species.TUMBLER: {
		"template_id": "tumbler_unstable",
		"template_note": "Walker-Template mit sichtbarer Schieflage.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "tumbler.svg",
		"silhouette_tags": ["unstable", "leaning", "stagger"],
		"model_root_offset": Vector3(0.0, -0.02, 0.0),
		"model_root_rotation_deg": Vector3(2.0, 0.0, -5.0),
		"part_offset": {
			"head": Vector3(-0.05, -0.03, 0.0),
			"arm_l": Vector3(-0.04, -0.04, 0.02),
			"arm_r": Vector3(0.06, 0.02, -0.02),
			"leg_l": Vector3(-0.03, -0.03, 0.0),
			"leg_r": Vector3(0.04, 0.01, 0.0)
		},
		"part_rotation_deg": {
			"head": Vector3(0.0, 0.0, -8.0),
			"arm_l": Vector3(5.0, 0.0, -10.0),
			"arm_r": Vector3(-3.0, 0.0, 7.0),
			"leg_l": Vector3(0.0, 0.0, -4.0),
			"leg_r": Vector3(0.0, 0.0, 6.0)
		},
		"palette": {
			"torso": Color(0.28, 0.45, 0.2, 1.0),
			"head": Color(0.33, 0.52, 0.24, 1.0),
			"arm_l": Color(0.24, 0.42, 0.19, 1.0),
			"arm_r": Color(0.24, 0.42, 0.19, 1.0),
			"leg_l": Color(0.2, 0.35, 0.15, 1.0),
			"leg_r": Color(0.2, 0.35, 0.15, 1.0)
		}
	},
	ZombieDefinitions.Species.BRUTE: {
		"template_id": "brute_tank",
		"template_note": "Breit, gedrungen, hohe Masse. Kein grosser Laeufer.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "brute.svg",
		"silhouette_tags": ["tank", "wide", "compact", "heavy"],
		"model_root_offset": Vector3(0.0, -0.08, 0.0),
		"part_scale": {
			"torso": Vector3(1.72, 1.15, 1.45),
			"head": Vector3(1.08, 1.08, 1.08),
			"arm_l": Vector3(1.48, 1.2, 1.48),
			"arm_r": Vector3(1.48, 1.2, 1.48),
			"leg_l": Vector3(1.35, 0.9, 1.35),
			"leg_r": Vector3(1.35, 0.9, 1.35)
		},
		"part_offset": {
			"head": Vector3(0.0, -0.03, 0.0),
			"arm_l": Vector3(-0.19, -0.04, 0.0),
			"arm_r": Vector3(0.19, -0.04, 0.0),
			"leg_l": Vector3(-0.12, -0.09, 0.0),
			"leg_r": Vector3(0.12, -0.09, 0.0)
		},
		"body_collision": {
			"radius_mult": 1.65,
			"height_mult": 0.84,
			"y_offset": -0.08
		},
		"hitbox_scale": {
			"head": Vector3(1.14, 1.14, 1.14),
			"torso": Vector3(1.7, 1.2, 1.48),
			"arm_l": Vector3(1.45, 1.15, 1.45),
			"arm_r": Vector3(1.45, 1.15, 1.45),
			"leg_l": Vector3(1.3, 0.9, 1.3),
			"leg_r": Vector3(1.3, 0.9, 1.3)
		},
		"palette": {
			"torso": Color(0.39, 0.32, 0.17, 1.0),
			"head": Color(0.44, 0.37, 0.2, 1.0),
			"arm_l": Color(0.34, 0.28, 0.14, 1.0),
			"arm_r": Color(0.34, 0.28, 0.14, 1.0),
			"leg_l": Color(0.27, 0.22, 0.11, 1.0),
			"leg_r": Color(0.27, 0.22, 0.11, 1.0)
		}
	},
	ZombieDefinitions.Species.TWINK: {
		"template_id": "twink_fragile",
		"template_note": "Schmal und klein als fragiler Fast-Typ.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "twink.svg",
		"silhouette_tags": ["slim", "small", "fragile"],
		"model_root_offset": Vector3(0.0, -0.03, 0.0),
		"part_scale": {
			"torso": Vector3(0.72, 0.86, 0.72),
			"head": Vector3(0.82, 0.82, 0.82),
			"arm_l": Vector3(0.62, 0.95, 0.62),
			"arm_r": Vector3(0.62, 0.95, 0.62),
			"leg_l": Vector3(0.68, 0.95, 0.68),
			"leg_r": Vector3(0.68, 0.95, 0.68)
		},
		"part_offset": {
			"arm_l": Vector3(0.06, 0.0, 0.0),
			"arm_r": Vector3(-0.06, 0.0, 0.0),
			"leg_l": Vector3(0.04, -0.04, 0.0),
			"leg_r": Vector3(-0.04, -0.04, 0.0)
		},
		"body_collision": {
			"radius_mult": 0.72,
			"height_mult": 0.83,
			"y_offset": -0.1
		},
		"hitbox_scale": {
			"head": Vector3(0.82, 0.82, 0.82),
			"torso": Vector3(0.72, 0.86, 0.72),
			"arm_l": Vector3(0.64, 0.95, 0.64),
			"arm_r": Vector3(0.64, 0.95, 0.64),
			"leg_l": Vector3(0.7, 0.94, 0.7),
			"leg_r": Vector3(0.7, 0.94, 0.7)
		},
		"palette": {
			"torso": Color(0.22, 0.4, 0.29, 1.0),
			"head": Color(0.27, 0.5, 0.36, 1.0),
			"arm_l": Color(0.2, 0.35, 0.26, 1.0),
			"arm_r": Color(0.2, 0.35, 0.26, 1.0),
			"leg_l": Color(0.17, 0.29, 0.22, 1.0),
			"leg_r": Color(0.17, 0.29, 0.22, 1.0)
		}
	},
	ZombieDefinitions.Species.BUFFED: {
		"template_id": "buffed_bodybuilder",
		"template_note": "Gross und muskuloes, klar anders als Brute.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "buffed.svg",
		"silhouette_tags": ["tall", "muscular", "dominant"],
		"model_root_offset": Vector3(0.0, 0.08, 0.0),
		"part_scale": {
			"torso": Vector3(1.34, 1.42, 1.18),
			"head": Vector3(1.02, 1.02, 1.02),
			"arm_l": Vector3(1.58, 1.35, 1.58),
			"arm_r": Vector3(1.58, 1.35, 1.58),
			"leg_l": Vector3(1.2, 1.28, 1.2),
			"leg_r": Vector3(1.2, 1.28, 1.2)
		},
		"part_offset": {
			"arm_l": Vector3(-0.22, 0.06, 0.0),
			"arm_r": Vector3(0.22, 0.06, 0.0),
			"leg_l": Vector3(-0.08, 0.03, 0.0),
			"leg_r": Vector3(0.08, 0.03, 0.0),
			"head": Vector3(0.0, 0.06, 0.0)
		},
		"body_collision": {
			"radius_mult": 1.2,
			"height_mult": 1.22,
			"y_offset": 0.14
		},
		"hitbox_scale": {
			"torso": Vector3(1.35, 1.42, 1.2),
			"arm_l": Vector3(1.55, 1.3, 1.55),
			"arm_r": Vector3(1.55, 1.3, 1.55),
			"leg_l": Vector3(1.2, 1.25, 1.2),
			"leg_r": Vector3(1.2, 1.25, 1.2),
			"head": Vector3(1.02, 1.02, 1.02)
		},
		"palette": {
			"torso": Color(0.33, 0.2, 0.14, 1.0),
			"head": Color(0.4, 0.24, 0.17, 1.0),
			"arm_l": Color(0.38, 0.22, 0.15, 1.0),
			"arm_r": Color(0.38, 0.22, 0.15, 1.0),
			"leg_l": Color(0.28, 0.16, 0.12, 1.0),
			"leg_r": Color(0.28, 0.16, 0.12, 1.0)
		}
	},
	ZombieDefinitions.Species.CRAWLER: {
		"template_id": "crawler_ground",
		"template_note": "Bodennaher Sonderfall mit stark reduziertem Beinprofil.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "crawler.svg",
		"silhouette_tags": ["low_profile", "grounded", "swarm"],
		"model_root_offset": Vector3(0.0, -0.42, 0.0),
		"model_root_rotation_deg": Vector3(38.0, 0.0, 0.0),
		"part_scale": {
			"torso": Vector3(1.15, 0.72, 1.25),
			"head": Vector3(0.96, 0.96, 0.96),
			"arm_l": Vector3(1.05, 1.25, 1.05),
			"arm_r": Vector3(1.05, 1.25, 1.05),
			"leg_l": Vector3(0.08, 0.08, 0.08),
			"leg_r": Vector3(0.08, 0.08, 0.08)
		},
		"part_offset": {
			"torso": Vector3(0.0, -0.28, 0.06),
			"head": Vector3(0.0, -0.42, 0.1),
			"arm_l": Vector3(-0.18, -0.44, 0.12),
			"arm_r": Vector3(0.18, -0.44, 0.12),
			"leg_l": Vector3(0.0, -0.58, -0.08),
			"leg_r": Vector3(0.0, -0.58, -0.08)
		},
		"part_rotation_deg": {
			"arm_l": Vector3(20.0, 0.0, -15.0),
			"arm_r": Vector3(20.0, 0.0, 15.0),
			"head": Vector3(-12.0, 0.0, 0.0)
		},
		"weapon_socket_offset": Vector3(0.0, -0.45, 0.2),
		"held_item_scale": Vector3(0.0, 0.0, 0.0),
		"body_collision": {
			"radius_mult": 1.36,
			"height_mult": 0.45,
			"y_offset": -0.42
		},
		"hitbox_scale": {
			"head": Vector3(0.86, 0.86, 0.86),
			"torso": Vector3(1.2, 0.58, 1.2),
			"arm_l": Vector3(1.08, 1.1, 1.08),
			"arm_r": Vector3(1.08, 1.1, 1.08),
			"leg_l": Vector3(0.12, 0.12, 0.12),
			"leg_r": Vector3(0.12, 0.12, 0.12)
		},
		"hitbox_offset": {
			"head": Vector3(0.0, -0.42, 0.12),
			"torso": Vector3(0.0, -0.35, 0.08),
			"arm_l": Vector3(-0.18, -0.44, 0.1),
			"arm_r": Vector3(0.18, -0.44, 0.1),
			"leg_l": Vector3(0.0, -0.58, -0.08),
			"leg_r": Vector3(0.0, -0.58, -0.08)
		},
		"palette": {
			"torso": Color(0.25, 0.22, 0.15, 1.0),
			"head": Color(0.3, 0.27, 0.18, 1.0),
			"arm_l": Color(0.26, 0.24, 0.16, 1.0),
			"arm_r": Color(0.26, 0.24, 0.16, 1.0),
			"leg_l": Color(0.1, 0.1, 0.1, 1.0),
			"leg_r": Color(0.1, 0.1, 0.1, 1.0)
		}
	},
	ZombieDefinitions.Species.GRANNY: {
		"template_id": "granny_hunched",
		"template_note": "Aeltere, gebueckte Haltung mit schwaecherem Profil.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "granny.svg",
		"silhouette_tags": ["old", "hunched", "frail"],
		"model_root_offset": Vector3(0.0, -0.08, 0.0),
		"model_root_rotation_deg": Vector3(18.0, 0.0, 2.0),
		"part_scale": {
			"torso": Vector3(0.86, 0.9, 0.84),
			"head": Vector3(0.94, 0.94, 0.94),
			"arm_l": Vector3(0.72, 0.98, 0.72),
			"arm_r": Vector3(0.72, 0.98, 0.72),
			"leg_l": Vector3(0.8, 0.9, 0.8),
			"leg_r": Vector3(0.8, 0.9, 0.8)
		},
		"part_offset": {
			"head": Vector3(0.0, -0.14, 0.08),
			"arm_l": Vector3(-0.05, -0.12, 0.05),
			"arm_r": Vector3(0.05, -0.12, 0.05),
			"leg_l": Vector3(0.0, -0.08, 0.04),
			"leg_r": Vector3(0.0, -0.08, 0.04)
		},
		"body_collision": {
			"radius_mult": 0.86,
			"height_mult": 0.88,
			"y_offset": -0.12
		},
		"palette": {
			"torso": Color(0.45, 0.44, 0.38, 1.0),
			"head": Color(0.63, 0.62, 0.57, 1.0),
			"arm_l": Color(0.44, 0.42, 0.36, 1.0),
			"arm_r": Color(0.44, 0.42, 0.36, 1.0),
			"leg_l": Color(0.35, 0.34, 0.3, 1.0),
			"leg_r": Color(0.35, 0.34, 0.3, 1.0)
		}
	},
	ZombieDefinitions.Species.HIDDER: {
		"template_id": "hidder_crouched",
		"template_note": "Niedriges Ambush-Profil fuer Deckung und Schatten.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "hidder.svg",
		"silhouette_tags": ["ambush", "crouched", "hidden"],
		"model_root_offset": Vector3(0.0, -0.28, 0.0),
		"model_root_rotation_deg": Vector3(26.0, 0.0, 0.0),
		"part_scale": {
			"torso": Vector3(0.9, 0.75, 0.95),
			"head": Vector3(0.88, 0.88, 0.88),
			"arm_l": Vector3(0.84, 0.9, 0.84),
			"arm_r": Vector3(0.84, 0.9, 0.84),
			"leg_l": Vector3(0.85, 0.62, 0.85),
			"leg_r": Vector3(0.85, 0.62, 0.85)
		},
		"part_offset": {
			"head": Vector3(0.0, -0.22, 0.08),
			"arm_l": Vector3(-0.07, -0.22, 0.08),
			"arm_r": Vector3(0.07, -0.22, 0.08),
			"leg_l": Vector3(-0.04, -0.3, 0.06),
			"leg_r": Vector3(0.04, -0.3, 0.06)
		},
		"body_collision": {
			"radius_mult": 1.0,
			"height_mult": 0.62,
			"y_offset": -0.28
		},
		"hitbox_offset": {
			"head": Vector3(0.0, -0.22, 0.08),
			"torso": Vector3(0.0, -0.2, 0.05),
			"arm_l": Vector3(-0.07, -0.22, 0.08),
			"arm_r": Vector3(0.07, -0.22, 0.08),
			"leg_l": Vector3(-0.04, -0.3, 0.06),
			"leg_r": Vector3(0.04, -0.3, 0.06)
		},
		"palette": {
			"torso": Color(0.13, 0.18, 0.12, 1.0),
			"head": Color(0.2, 0.24, 0.16, 1.0),
			"arm_l": Color(0.12, 0.16, 0.1, 1.0),
			"arm_r": Color(0.12, 0.16, 0.1, 1.0),
			"leg_l": Color(0.1, 0.13, 0.08, 1.0),
			"leg_r": Color(0.1, 0.13, 0.08, 1.0)
		}
	},
	ZombieDefinitions.Species.SPRINTER: {
		"template_id": "sprinter_wiry",
		"template_note": "Drahtiger, langgliedriger Speed-Typ.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "sprinter.svg",
		"silhouette_tags": ["fast", "wiry", "long_limb"],
		"model_root_offset": Vector3(0.0, 0.04, 0.0),
		"model_root_rotation_deg": Vector3(6.0, 0.0, 0.0),
		"part_scale": {
			"torso": Vector3(0.82, 0.92, 0.78),
			"head": Vector3(0.83, 0.83, 0.83),
			"arm_l": Vector3(0.62, 1.28, 0.62),
			"arm_r": Vector3(0.62, 1.28, 0.62),
			"leg_l": Vector3(0.68, 1.28, 0.68),
			"leg_r": Vector3(0.68, 1.28, 0.68)
		},
		"part_offset": {
			"head": Vector3(0.0, 0.02, 0.0),
			"arm_l": Vector3(-0.03, 0.06, 0.02),
			"arm_r": Vector3(0.03, 0.06, 0.02),
			"leg_l": Vector3(-0.03, 0.08, 0.02),
			"leg_r": Vector3(0.03, 0.08, 0.02)
		},
		"body_collision": {
			"radius_mult": 0.78,
			"height_mult": 1.1,
			"y_offset": 0.05
		},
		"palette": {
			"torso": Color(0.2, 0.32, 0.36, 1.0),
			"head": Color(0.26, 0.4, 0.45, 1.0),
			"arm_l": Color(0.16, 0.27, 0.31, 1.0),
			"arm_r": Color(0.16, 0.27, 0.31, 1.0),
			"leg_l": Color(0.14, 0.24, 0.27, 1.0),
			"leg_r": Color(0.14, 0.24, 0.27, 1.0)
		}
	},
	ZombieDefinitions.Species.SKINNER: {
		"template_id": "skinner_sinewy",
		"template_note": "Sehniges Profil mit sichtbarer roher Formsprache.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "skinner.svg",
		"silhouette_tags": ["sinewy", "raw", "taut"],
		"model_root_offset": Vector3(0.0, 0.02, 0.0),
		"model_root_rotation_deg": Vector3(8.0, 0.0, 0.0),
		"part_scale": {
			"torso": Vector3(0.92, 1.08, 0.86),
			"head": Vector3(0.86, 0.86, 0.86),
			"arm_l": Vector3(0.74, 1.2, 0.74),
			"arm_r": Vector3(0.74, 1.2, 0.74),
			"leg_l": Vector3(0.82, 1.1, 0.82),
			"leg_r": Vector3(0.82, 1.1, 0.82)
		},
		"body_collision": {
			"radius_mult": 0.9,
			"height_mult": 1.02,
			"y_offset": 0.0
		},
		"palette": {
			"torso": Color(0.58, 0.16, 0.14, 1.0),
			"head": Color(0.68, 0.2, 0.18, 1.0),
			"arm_l": Color(0.63, 0.18, 0.16, 1.0),
			"arm_r": Color(0.63, 0.18, 0.16, 1.0),
			"leg_l": Color(0.5, 0.14, 0.13, 1.0),
			"leg_r": Color(0.5, 0.14, 0.13, 1.0)
		}
	},
	ZombieDefinitions.Species.BOMB: {
		"template_id": "bomb_bloated",
		"template_note": "Aufgeblaehte Kernmasse mit instabilem Eindruck.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "bomb.svg",
		"silhouette_tags": ["bloated", "volatile", "burst_risk"],
		"part_scale": {
			"torso": Vector3(1.65, 1.58, 1.52),
			"head": Vector3(0.9, 0.9, 0.9),
			"arm_l": Vector3(0.82, 0.9, 0.82),
			"arm_r": Vector3(0.82, 0.9, 0.82),
			"leg_l": Vector3(0.92, 0.86, 0.92),
			"leg_r": Vector3(0.92, 0.86, 0.92)
		},
		"part_offset": {
			"head": Vector3(0.0, 0.08, 0.03),
			"arm_l": Vector3(-0.22, -0.04, 0.0),
			"arm_r": Vector3(0.22, -0.04, 0.0),
			"leg_l": Vector3(-0.06, -0.12, 0.0),
			"leg_r": Vector3(0.06, -0.12, 0.0)
		},
		"body_collision": {
			"radius_mult": 1.54,
			"height_mult": 0.9,
			"y_offset": -0.04
		},
		"hitbox_scale": {
			"torso": Vector3(1.6, 1.45, 1.5),
			"head": Vector3(0.9, 0.9, 0.9)
		},
		"palette": {
			"torso": Color(0.5, 0.41, 0.18, 1.0),
			"head": Color(0.64, 0.52, 0.25, 1.0),
			"arm_l": Color(0.4, 0.33, 0.15, 1.0),
			"arm_r": Color(0.4, 0.33, 0.15, 1.0),
			"leg_l": Color(0.34, 0.28, 0.13, 1.0),
			"leg_r": Color(0.34, 0.28, 0.13, 1.0)
		}
	},
	ZombieDefinitions.Species.FEEDER: {
		"template_id": "feeder_mutant",
		"template_note": "Klein, gedrueckt und mutiert statt humanoid neutral.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "feeder.svg",
		"silhouette_tags": ["small", "mutated", "corpse_feeder"],
		"model_root_offset": Vector3(0.0, -0.24, 0.0),
		"model_root_rotation_deg": Vector3(22.0, 0.0, -4.0),
		"part_scale": {
			"torso": Vector3(0.74, 0.72, 0.92),
			"head": Vector3(0.72, 0.72, 0.72),
			"arm_l": Vector3(0.8, 0.96, 0.8),
			"arm_r": Vector3(0.8, 0.96, 0.8),
			"leg_l": Vector3(0.62, 0.56, 0.62),
			"leg_r": Vector3(0.62, 0.56, 0.62)
		},
		"part_offset": {
			"head": Vector3(0.0, -0.25, 0.1),
			"arm_l": Vector3(-0.05, -0.28, 0.1),
			"arm_r": Vector3(0.05, -0.28, 0.1),
			"leg_l": Vector3(-0.03, -0.34, 0.06),
			"leg_r": Vector3(0.03, -0.34, 0.06)
		},
		"body_collision": {
			"radius_mult": 0.8,
			"height_mult": 0.6,
			"y_offset": -0.25
		},
		"palette": {
			"torso": Color(0.33, 0.27, 0.18, 1.0),
			"head": Color(0.4, 0.32, 0.2, 1.0),
			"arm_l": Color(0.3, 0.24, 0.15, 1.0),
			"arm_r": Color(0.3, 0.24, 0.15, 1.0),
			"leg_l": Color(0.24, 0.2, 0.13, 1.0),
			"leg_r": Color(0.24, 0.2, 0.13, 1.0)
		}
	},
	ZombieDefinitions.Species.CRY_BABY: {
		"template_id": "cry_baby_collapsed",
		"template_note": "Apathische, eingefallene Haltung mit geringer Praesenz.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "cry_baby.svg",
		"silhouette_tags": ["weak", "collapsed", "passive"],
		"model_root_offset": Vector3(0.0, -0.14, 0.0),
		"model_root_rotation_deg": Vector3(14.0, 0.0, 0.0),
		"part_scale": {
			"torso": Vector3(0.78, 0.82, 0.76),
			"head": Vector3(0.82, 0.82, 0.82),
			"arm_l": Vector3(0.68, 0.86, 0.68),
			"arm_r": Vector3(0.68, 0.86, 0.68),
			"leg_l": Vector3(0.72, 0.74, 0.72),
			"leg_r": Vector3(0.72, 0.74, 0.72)
		},
		"part_offset": {
			"head": Vector3(0.0, -0.16, 0.06),
			"arm_l": Vector3(-0.02, -0.16, 0.05),
			"arm_r": Vector3(0.02, -0.16, 0.05),
			"leg_l": Vector3(0.0, -0.18, 0.03),
			"leg_r": Vector3(0.0, -0.18, 0.03)
		},
		"body_collision": {
			"radius_mult": 0.82,
			"height_mult": 0.7,
			"y_offset": -0.18
		},
		"palette": {
			"torso": Color(0.38, 0.39, 0.45, 1.0),
			"head": Color(0.5, 0.52, 0.6, 1.0),
			"arm_l": Color(0.34, 0.35, 0.41, 1.0),
			"arm_r": Color(0.34, 0.35, 0.41, 1.0),
			"leg_l": Color(0.28, 0.3, 0.35, 1.0),
			"leg_r": Color(0.28, 0.3, 0.35, 1.0)
		}
	},
	ZombieDefinitions.Species.PANICO: {
		"template_id": "panico_chaotic",
		"template_note": "Sprinter-verwandt, aber asymmetrisch und nervoes-chaotisch.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "panico.svg",
		"silhouette_tags": ["chaotic", "unstable", "hysteric"],
		"model_root_offset": Vector3(0.0, -0.02, 0.0),
		"model_root_rotation_deg": Vector3(10.0, 0.0, 8.0),
		"part_scale": {
			"torso": Vector3(0.86, 0.94, 0.84),
			"head": Vector3(0.8, 0.8, 0.8),
			"arm_l": Vector3(0.55, 1.15, 0.55),
			"arm_r": Vector3(0.72, 1.05, 0.72),
			"leg_l": Vector3(0.65, 1.12, 0.65),
			"leg_r": Vector3(0.8, 0.9, 0.8)
		},
		"part_offset": {
			"head": Vector3(0.03, 0.02, 0.02),
			"arm_l": Vector3(-0.08, 0.04, 0.06),
			"arm_r": Vector3(0.06, 0.01, -0.03),
			"leg_l": Vector3(-0.04, 0.05, 0.04),
			"leg_r": Vector3(0.06, -0.02, -0.02)
		},
		"part_rotation_deg": {
			"head": Vector3(0.0, 0.0, 11.0),
			"arm_l": Vector3(12.0, 0.0, -14.0),
			"arm_r": Vector3(-6.0, 0.0, 12.0),
			"leg_l": Vector3(5.0, 0.0, -6.0),
			"leg_r": Vector3(-8.0, 0.0, 7.0)
		},
		"body_collision": {
			"radius_mult": 0.82,
			"height_mult": 0.96,
			"y_offset": -0.04
		},
		"palette": {
			"torso": Color(0.33, 0.2, 0.35, 1.0),
			"head": Color(0.45, 0.27, 0.46, 1.0),
			"arm_l": Color(0.31, 0.19, 0.33, 1.0),
			"arm_r": Color(0.31, 0.19, 0.33, 1.0),
			"leg_l": Color(0.24, 0.15, 0.26, 1.0),
			"leg_r": Color(0.24, 0.15, 0.26, 1.0)
		}
	},
	ZombieDefinitions.Species.SKULLY: {
		"template_id": "skully_bone",
		"template_note": "Extrem ausgemergelte Knochen-Silhouette.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "skully.svg",
		"silhouette_tags": ["skeletal", "bone", "very_thin"],
		"model_root_offset": Vector3(0.0, 0.02, 0.0),
		"part_scale": {
			"torso": Vector3(0.58, 0.92, 0.52),
			"head": Vector3(0.72, 0.72, 0.72),
			"arm_l": Vector3(0.4, 1.12, 0.4),
			"arm_r": Vector3(0.4, 1.12, 0.4),
			"leg_l": Vector3(0.46, 1.22, 0.46),
			"leg_r": Vector3(0.46, 1.22, 0.46)
		},
		"part_offset": {
			"arm_l": Vector3(0.05, 0.04, 0.0),
			"arm_r": Vector3(-0.05, 0.04, 0.0),
			"leg_l": Vector3(0.04, 0.06, 0.0),
			"leg_r": Vector3(-0.04, 0.06, 0.0)
		},
		"body_collision": {
			"radius_mult": 0.62,
			"height_mult": 1.04,
			"y_offset": 0.02
		},
		"hitbox_scale": {
			"head": Vector3(0.75, 0.75, 0.75),
			"torso": Vector3(0.62, 0.9, 0.6),
			"arm_l": Vector3(0.45, 1.08, 0.45),
			"arm_r": Vector3(0.45, 1.08, 0.45),
			"leg_l": Vector3(0.5, 1.16, 0.5),
			"leg_r": Vector3(0.5, 1.16, 0.5)
		},
		"palette": {
			"torso": Color(0.78, 0.76, 0.68, 1.0),
			"head": Color(0.84, 0.82, 0.74, 1.0),
			"arm_l": Color(0.72, 0.7, 0.63, 1.0),
			"arm_r": Color(0.72, 0.7, 0.63, 1.0),
			"leg_l": Color(0.66, 0.63, 0.57, 1.0),
			"leg_r": Color(0.66, 0.63, 0.57, 1.0),
			"weapon": Color(0.17, 0.2, 0.22, 1.0)
		}
	}
}

static func get_species_visual_config(species_id: int) -> Dictionary:
	var base_cfg: Dictionary = _base_visual_template()
	var species_cfg: Dictionary = SPECIES_VISUAL_CONFIG.get(species_id, {})
	return _merge_dict_recursive(base_cfg, species_cfg)

static func _base_visual_template() -> Dictionary:
	return {
		"template_id": "default_visual_template",
		"template_note": "Austauschbarer Placeholder-Visual-Layer.",
		"reference_image": DEFAULT_REFERENCE_ROOT + "walker.svg",
		"silhouette_tags": ["placeholder"],
		"model_root_offset": Vector3.ZERO,
		"model_root_rotation_deg": Vector3.ZERO,
		"part_scale": {
			"torso": Vector3.ONE,
			"head": Vector3.ONE,
			"arm_l": Vector3.ONE,
			"arm_r": Vector3.ONE,
			"leg_l": Vector3.ONE,
			"leg_r": Vector3.ONE
		},
		"part_offset": {},
		"part_rotation_deg": {},
		"weapon_socket_offset": Vector3.ZERO,
		"weapon_socket_rotation_deg": Vector3.ZERO,
		"held_item_scale": Vector3.ONE,
		"hitbox_scale": {},
		"hitbox_offset": {},
		"hitbox_rotation_deg": {},
		"body_collision": {
			"radius_mult": 1.0,
			"height_mult": 1.0,
			"y_offset": 0.0
		},
		"palette": {
			"torso": Color(0.2, 0.45, 0.15, 1.0),
			"head": Color(0.2, 0.45, 0.15, 1.0),
			"arm_l": Color(0.2, 0.45, 0.15, 1.0),
			"arm_r": Color(0.2, 0.45, 0.15, 1.0),
			"leg_l": Color(0.2, 0.45, 0.15, 1.0),
			"leg_r": Color(0.2, 0.45, 0.15, 1.0),
			"weapon": Color(0.18, 0.18, 0.19, 1.0)
		}
	}

static func _merge_dict_recursive(base_cfg: Dictionary, override_cfg: Dictionary) -> Dictionary:
	var merged: Dictionary = base_cfg.duplicate(true)
	for key in override_cfg.keys():
		var value = override_cfg[key]
		if merged.has(key) and merged[key] is Dictionary and value is Dictionary:
			merged[key] = _merge_dict_recursive(merged[key], value)
		else:
			merged[key] = value
	return merged
