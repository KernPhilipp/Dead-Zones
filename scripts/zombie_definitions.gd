extends RefCounted
class_name ZombieDefinitions

enum Species {
	WALKER,
	TUMBLER,
	BRUTE,
	TWINK,
	BUFFED,
	CRAWLER,
	GRANNY,
	HIDDER,
	SPRINTER,
	SKINNER,
	BOMB,
	FEEDER,
	CRY_BABY,
	PANICO,
	SKULLY
}

enum ZombieClass {
	COMMON,
	FERAL,
	ARMORED
}

enum DeathClass {
	KRANKHEIT,
	UEBERNATUERLICH,
	GEWALT,
	CHEMISCH,
	NATUR,
	UNFALL,
	VERWESUNG,
	STRAHLUNG
}

enum DeathSubtype {
	ALKOHOLISIERT,
	INFIZIERT,
	KREBSINFIZIERT,
	PARASSITIERT,
	PILZINFIZIERT,
	SEUCHENVERSEUCHT,
	RADIOAKTIV_MUTIERT,
	GEISTLICH,
	VERFLUCHT,
	DAEMONISCH_BESESSEN,
	MILITAERISCH,
	VERBRANNT,
	ERHAENGT,
	VERBLUTET,
	HINGERICHTET,
	GEFOLTERT,
	ERSTOCHEN,
	ERSCHOSSEN,
	VERGIFTET,
	CHEMISCH_VERSEUCHT,
	SAEUREVERAETZT,
	ERFROREN,
	ERTRUNKEN,
	BLITZSCHLAG_OPFER,
	TIERANGRIFF_OPFER,
	STARK_VERLETZT,
	ZERSTUECKELT,
	ELEKTRISIERT,
	MUMIFIZIERT,
	VERWEST,
	FRISCH_VERSTORBEN,
	ATOMVERSEUCHT,
	ERSCHLAGEN
}

enum DeathRarity {
	GEWOEHNLICH,
	UNGEWOEHNLICH,
	SELTEN,
	EPISCH,
	LEGENDAER
}

enum Rank {
	ALPHA,
	BETA,
	GAMMA,
	DELTA,
	EPSILON
}

enum HandbookCategory {
	GEWOEHNLICH,
	HEAVY,
	FAST,
	AMBUSH,
	SPECIAL
}

const VISUAL_VARIANTS_DEFAULT: Array[String] = ["male", "female"]

const DEFAULT_SPECIES: int = Species.WALKER
const DEFAULT_CLASS: int = ZombieClass.COMMON
const DEFAULT_RANK: int = Rank.GAMMA
const DEFAULT_MORT_GRADE: int = 6
const MORT_GRADE_MIN: int = 0
const MORT_GRADE_MAX: int = 10
const MORT_GRADE_NEUTRAL: int = 6
const DEFAULT_VISUAL_VARIANT: String = "male"
const DEFAULT_DEATH_CLASS: int = DeathClass.VERWESUNG
const DEFAULT_DEATH_SUBTYPE: int = DeathSubtype.FRISCH_VERSTORBEN

const SPECIES_ORDER: Array[int] = [
	Species.WALKER,
	Species.TUMBLER,
	Species.BRUTE,
	Species.TWINK,
	Species.BUFFED,
	Species.CRAWLER,
	Species.GRANNY,
	Species.HIDDER,
	Species.SPRINTER,
	Species.SKINNER,
	Species.BOMB,
	Species.FEEDER,
	Species.CRY_BABY,
	Species.PANICO,
	Species.SKULLY
]

const DEATH_CLASS_ORDER: Array[int] = [
	DeathClass.KRANKHEIT,
	DeathClass.UEBERNATUERLICH,
	DeathClass.GEWALT,
	DeathClass.CHEMISCH,
	DeathClass.NATUR,
	DeathClass.UNFALL,
	DeathClass.VERWESUNG,
	DeathClass.STRAHLUNG
]

const DEATH_SUBTYPE_ORDER: Array[int] = [
	DeathSubtype.ALKOHOLISIERT,
	DeathSubtype.INFIZIERT,
	DeathSubtype.KREBSINFIZIERT,
	DeathSubtype.PARASSITIERT,
	DeathSubtype.PILZINFIZIERT,
	DeathSubtype.SEUCHENVERSEUCHT,
	DeathSubtype.RADIOAKTIV_MUTIERT,
	DeathSubtype.GEISTLICH,
	DeathSubtype.VERFLUCHT,
	DeathSubtype.DAEMONISCH_BESESSEN,
	DeathSubtype.MILITAERISCH,
	DeathSubtype.VERBRANNT,
	DeathSubtype.ERHAENGT,
	DeathSubtype.VERBLUTET,
	DeathSubtype.HINGERICHTET,
	DeathSubtype.GEFOLTERT,
	DeathSubtype.ERSTOCHEN,
	DeathSubtype.ERSCHOSSEN,
	DeathSubtype.ERSCHLAGEN,
	DeathSubtype.VERGIFTET,
	DeathSubtype.CHEMISCH_VERSEUCHT,
	DeathSubtype.SAEUREVERAETZT,
	DeathSubtype.ERFROREN,
	DeathSubtype.ERTRUNKEN,
	DeathSubtype.BLITZSCHLAG_OPFER,
	DeathSubtype.TIERANGRIFF_OPFER,
	DeathSubtype.STARK_VERLETZT,
	DeathSubtype.ZERSTUECKELT,
	DeathSubtype.ELEKTRISIERT,
	DeathSubtype.MUMIFIZIERT,
	DeathSubtype.VERWEST,
	DeathSubtype.FRISCH_VERSTORBEN,
	DeathSubtype.ATOMVERSEUCHT
]

const SPECIES_APPEARANCE_DATA: Dictionary = {
	Species.WALKER: "Klassischer Standardzombie mit neutralem, durchschnittlichem Koerperbau.",
	Species.TUMBLER: "Klassischer, leicht taumelnder Zombie mit unsicherer Haltung.",
	Species.BRUTE: "Massig und uebergewichtig, gebaut wie ein schwerer Tank.",
	Species.TWINK: "Schlank, geringe Muskelmasse, eher kleiner und agiler Koerper.",
	Species.BUFFED: "Sehr gross und stark muskuloes, klar bodybuilder-aehnliche Silhouette.",
	Species.CRAWLER: "Nur Oberkoerper und Kopf sichtbar; Beine und Unterkoerper bleiben unter der Erde.",
	Species.GRANNY: "Alt wirkend mit weissen Haaren, schrullige Gestalt; optional spaeter auch baertig denkbar.",
	Species.HIDDER: "Gebueckt, schmutzig und bevorzugt Schatten sowie Deckung.",
	Species.SPRINTER: "Drahtig, nervoes, staendig zuckend und schlank gebaut.",
	Species.SKINNER: "Hautlos, rot und sehnig mit klar sichtbarer Muskulatur.",
	Species.BOMB: "Aufgeblaehter Koerper mit instabilem, druckvollem Eindruck.",
	Species.FEEDER: "Klein und mutiert, hungriger Aasfresser-Eindruck.",
	Species.CRY_BABY: "Weinend, jammernd und apathisch in Haltung und Mimik.",
	Species.PANICO: "Narrhaft und hysterisch, wirkt jederzeit nervoes-instabil.",
	Species.SKULLY: "Skelettartig mit nur wenigen verbliebenen Hautstuecken."
}

const SPECIES_IMAGE_PATH_DATA: Dictionary = {
	Species.WALKER: "res://assets/handbook/species/walker.svg",
	Species.TUMBLER: "res://assets/handbook/species/tumbler.svg",
	Species.BRUTE: "res://assets/handbook/species/brute.svg",
	Species.TWINK: "res://assets/handbook/species/twink.svg",
	Species.BUFFED: "res://assets/handbook/species/buffed.svg",
	Species.CRAWLER: "res://assets/handbook/species/crawler.svg",
	Species.GRANNY: "res://assets/handbook/species/granny.svg",
	Species.HIDDER: "res://assets/handbook/species/hidder.svg",
	Species.SPRINTER: "res://assets/handbook/species/sprinter.svg",
	Species.SKINNER: "res://assets/handbook/species/skinner.svg",
	Species.BOMB: "res://assets/handbook/species/bomb.svg",
	Species.FEEDER: "res://assets/handbook/species/feeder.svg",
	Species.CRY_BABY: "res://assets/handbook/species/cry_baby.svg",
	Species.PANICO: "res://assets/handbook/species/panico.svg",
	Species.SKULLY: "res://assets/handbook/species/skully.svg"
}

const HANDBOOK_CATEGORY_DATA: Dictionary = {
	HandbookCategory.GEWOEHNLICH: {
		"id": "gewoehnlich",
		"display_name": "Gewoehnlich",
		"description": "Allgemeine Standardgegner ohne Sonderrolle."
	},
	HandbookCategory.HEAVY: {
		"id": "heavy",
		"display_name": "Heavy",
		"description": "Robuste Druckmacher mit hoher Belastbarkeit."
	},
	HandbookCategory.FAST: {
		"id": "fast",
		"display_name": "Fast",
		"description": "Schnelle, fragile oder hektische Zieltypen."
	},
	HandbookCategory.AMBUSH: {
		"id": "ambush",
		"display_name": "Ambush",
		"description": "Versteck- oder Ueberraschungstypen."
	},
	HandbookCategory.SPECIAL: {
		"id": "special",
		"display_name": "Special",
		"description": "Sondermechaniken mit eigener Prioritaet."
	}
}

const DEATH_RARITY_DATA: Dictionary = {
	DeathRarity.GEWOEHNLICH: {
		"id": "gewoehnlich",
		"display_name": "Gewoehnlich",
		"description": "Hauefig beobachtete Todesart."
	},
	DeathRarity.UNGEWOEHNLICH: {
		"id": "ungewoehnlich",
		"display_name": "Ungewoehnlich",
		"description": "Seltener als Alltagstypen, aber regelmaessig auffindbar."
	},
	DeathRarity.SELTEN: {
		"id": "selten",
		"display_name": "Selten",
		"description": "Ungewoehnliche Fundlage mit klarer Spezialsignatur."
	},
	DeathRarity.EPISCH: {
		"id": "episch",
		"display_name": "Episch",
		"description": "Sehr seltene und markante Todesart."
	},
	DeathRarity.LEGENDAER: {
		"id": "legendaer",
		"display_name": "Legendaer",
		"description": "Extrem seltene Ausnahmeerscheinung."
	}
}

const DEATH_CLASS_DATA: Dictionary = {
	DeathClass.KRANKHEIT: {
		"id": "krankheit",
		"display_name": "Krankheit",
		"description": "Tod durch Krankheit, Infektion, Parasiten oder Seuchen."
	},
	DeathClass.UEBERNATUERLICH: {
		"id": "uebernatuerlich",
		"display_name": "Uebernatuerlich",
		"description": "Tod mit verfluchten, spirituellen oder daemonischen Merkmalen."
	},
	DeathClass.GEWALT: {
		"id": "gewalt",
		"display_name": "Gewalt",
		"description": "Tod durch Kampf, Hinrichtung oder gezielte Fremdeinwirkung."
	},
	DeathClass.CHEMISCH: {
		"id": "chemisch",
		"display_name": "Chemisch",
		"description": "Tod durch Toxine, Chemikalien oder starke Veretzung."
	},
	DeathClass.NATUR: {
		"id": "natur",
		"display_name": "Natur",
		"description": "Tod durch Umweltbedingungen oder Naturereignisse."
	},
	DeathClass.UNFALL: {
		"id": "unfall",
		"display_name": "Unfall",
		"description": "Tod durch technische oder physische Unfallereignisse."
	},
	DeathClass.VERWESUNG: {
		"id": "verwesung",
		"display_name": "Verwesung",
		"description": "Todeseinordnung nach Verfallszustand des Koerpers."
	},
	DeathClass.STRAHLUNG: {
		"id": "strahlung",
		"display_name": "Strahlung",
		"description": "Tod durch atomare oder extreme radioaktive Katastrophen."
	}
}

const DEATH_SUBTYPE_DATA: Dictionary = {
	DeathSubtype.ALKOHOLISIERT: {
		"id": "alkoholisiert",
		"display_name": "alkoholisiert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "An Alkoholmissbrauch oder Leberzirrhose gestorben."
	},
	DeathSubtype.INFIZIERT: {
		"id": "infiziert",
		"display_name": "infiziert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "An einer Krankheit oder Infektion gestorben."
	},
	DeathSubtype.KREBSINFIZIERT: {
		"id": "krebsinfiziert",
		"display_name": "krebsinfiziert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "An Krebs gestorben."
	},
	DeathSubtype.PARASSITIERT: {
		"id": "parassitiert",
		"display_name": "parassitiert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.SELTEN,
		"description": "Durch Parasiten befallen und daran gestorben."
	},
	DeathSubtype.PILZINFIZIERT: {
		"id": "pilzinfiziert",
		"display_name": "pilzinfiziert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Durch Pilzbefall oder Sporen gestorben."
	},
	DeathSubtype.SEUCHENVERSEUCHT: {
		"id": "seuchenverseucht",
		"display_name": "seuchenverseucht",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.SELTEN,
		"description": "Opfer einer schweren Epidemie."
	},
	DeathSubtype.RADIOAKTIV_MUTIERT: {
		"id": "radioaktiv_mutiert",
		"display_name": "radioaktiv mutiert",
		"death_class": DeathClass.KRANKHEIT,
		"rarity": DeathRarity.EPISCH,
		"description": "Durch starke Strahlung mutiert."
	},
	DeathSubtype.GEISTLICH: {
		"id": "geistlich",
		"display_name": "geistlich",
		"death_class": DeathClass.UEBERNATUERLICH,
		"rarity": DeathRarity.SELTEN,
		"description": "Priester oder religioese Person, fuer die Kirche gestorben."
	},
	DeathSubtype.VERFLUCHT: {
		"id": "verflucht",
		"display_name": "verflucht",
		"death_class": DeathClass.UEBERNATUERLICH,
		"rarity": DeathRarity.EPISCH,
		"description": "Durch einen Fluch gestorben."
	},
	DeathSubtype.DAEMONISCH_BESESSEN: {
		"id": "daemonisch_besessen",
		"display_name": "daemonisch besessen",
		"death_class": DeathClass.UEBERNATUERLICH,
		"rarity": DeathRarity.LEGENDAER,
		"description": "Von dunkler Macht uebernommen."
	},
	DeathSubtype.MILITAERISCH: {
		"id": "militaerisch",
		"display_name": "militaerisch",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Verstorbener Soldat."
	},
	DeathSubtype.VERBRANNT: {
		"id": "verbrannt",
		"display_name": "verbrannt",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Im Feuer oder durch Verbrennung gestorben."
	},
	DeathSubtype.ERHAENGT: {
		"id": "erhaengt",
		"display_name": "erhaengt",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Durch Erhaengen getoetet."
	},
	DeathSubtype.VERBLUTET: {
		"id": "verblutet",
		"display_name": "verblutet",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Durch starken Blutverlust gestorben."
	},
	DeathSubtype.HINGERICHTET: {
		"id": "hingerichtet",
		"display_name": "hingerichtet",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.SELTEN,
		"description": "Gezielte Toetung durch Urteil oder Exekution."
	},
	DeathSubtype.GEFOLTERT: {
		"id": "gefoltert",
		"display_name": "gefoltert",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.SELTEN,
		"description": "Vor dem Tod schwer misshandelt."
	},
	DeathSubtype.ERSTOCHEN: {
		"id": "erstochen",
		"display_name": "erstochen",
		"death_class": DeathClass.GEWALT,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Durch Stichwaffe getoetet."
	},
		DeathSubtype.ERSCHOSSEN: {
			"id": "erschossen",
			"display_name": "erschossen",
			"death_class": DeathClass.GEWALT,
			"rarity": DeathRarity.UNGEWOEHNLICH,
			"description": "Durch Schusswaffe getoetet."
		},
		DeathSubtype.ERSCHLAGEN: {
			"id": "erschlagen",
			"display_name": "erschlagen",
			"death_class": DeathClass.GEWALT,
			"rarity": DeathRarity.SELTEN,
			"description": "Durch stumpfe Gewalteinwirkung erschlagen."
		},
		DeathSubtype.VERGIFTET: {
			"id": "vergiftet",
			"display_name": "vergiftet",
			"death_class": DeathClass.CHEMISCH,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Durch Gift gestorben."
	},
	DeathSubtype.CHEMISCH_VERSEUCHT: {
		"id": "chemisch_verseucht",
		"display_name": "chemisch verseucht",
		"death_class": DeathClass.CHEMISCH,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Durch Chemieunfall oder toxische Stoffe gestorben."
	},
	DeathSubtype.SAEUREVERAETZT: {
		"id": "saeureveraetzt",
		"display_name": "saeureveraetzt",
		"death_class": DeathClass.CHEMISCH,
		"rarity": DeathRarity.SELTEN,
		"description": "Durch Saeure getoetet."
	},
	DeathSubtype.ERFROREN: {
		"id": "erfroren",
		"display_name": "erfroren",
		"death_class": DeathClass.NATUR,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "In extremer Kaelte gestorben."
	},
	DeathSubtype.ERTRUNKEN: {
		"id": "ertrunken",
		"display_name": "ertrunken",
		"death_class": DeathClass.NATUR,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Im Wasser gestorben."
	},
	DeathSubtype.BLITZSCHLAG_OPFER: {
		"id": "blitzschlag_opfer",
		"display_name": "Blitzschlag-Opfer",
		"death_class": DeathClass.NATUR,
		"rarity": DeathRarity.SELTEN,
		"description": "Durch Blitzschlag getoetet."
	},
	DeathSubtype.TIERANGRIFF_OPFER: {
		"id": "tierangriff_opfer",
		"display_name": "Tierangriff-Opfer",
		"death_class": DeathClass.NATUR,
		"rarity": DeathRarity.SELTEN,
		"description": "Von Tieren getoetet oder schwer verletzt."
	},
	DeathSubtype.STARK_VERLETZT: {
		"id": "stark_verletzt",
		"display_name": "stark verletzt",
		"death_class": DeathClass.UNFALL,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Schwer verletztes Autounfall-Opfer."
	},
	DeathSubtype.ZERSTUECKELT: {
		"id": "zerstueckelt",
		"display_name": "zerstueckelt",
		"death_class": DeathClass.UNFALL,
		"rarity": DeathRarity.SELTEN,
		"description": "Flugunfall-Opfer oder massiv zerfetzter Koerper."
	},
	DeathSubtype.ELEKTRISIERT: {
		"id": "elektrisiert",
		"display_name": "elektrisiert",
		"death_class": DeathClass.UNFALL,
		"rarity": DeathRarity.UNGEWOEHNLICH,
		"description": "Durch Stromschlag gestorben."
	},
	DeathSubtype.MUMIFIZIERT: {
		"id": "mumifiziert",
		"display_name": "mumifiziert",
		"death_class": DeathClass.VERWESUNG,
		"rarity": DeathRarity.EPISCH,
		"description": "Stark ausgetrockneter, uralter Leichnam."
	},
	DeathSubtype.VERWEST: {
		"id": "verwest",
		"display_name": "verwest",
		"death_class": DeathClass.VERWESUNG,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Lange tot, stark zerfallen."
	},
	DeathSubtype.FRISCH_VERSTORBEN: {
		"id": "frisch_verstorben",
		"display_name": "frisch verstorben",
		"death_class": DeathClass.VERWESUNG,
		"rarity": DeathRarity.GEWOEHNLICH,
		"description": "Erst kuerzlich gestorben."
	},
	DeathSubtype.ATOMVERSEUCHT: {
		"id": "atomverseucht",
		"display_name": "atomverseucht",
		"death_class": DeathClass.STRAHLUNG,
		"rarity": DeathRarity.LEGENDAER,
		"description": "Opfer einer Atombombe oder radioaktiven Katastrophe."
	}
}

const SPECIES_DATA: Dictionary = {
	Species.WALKER: {
		"id": "walker",
		"display_name": "Walker",
		"handbook_category": HandbookCategory.GEWOEHNLICH,
		"handbook_short": "Neutraler Referenztyp.",
		"functional_profile": "Ausgewogene Standardwerte ohne Speziallogik.",
		"threat_profile": "Basisbedrohung.",
		"base_speed": 3.0,
		"base_health": 80.0,
		"base_damage": 12.0,
		"base_attack_cooldown": 1.0,
		"base_scale": 1.0,
		"turn_agility": 1.0,
		"movement_jitter": 0.1,
		"pain_resistance": 0.25,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Baseline fuer Balancing."
	},
	Species.TUMBLER: {
		"id": "tumbler",
		"display_name": "Tumbler",
		"handbook_category": HandbookCategory.GEWOEHNLICH,
		"handbook_short": "Leicht taumelnder Standardzombie.",
		"functional_profile": "Langsam, stabil, kein Spezialverhalten.",
		"threat_profile": "Konstante Nahkampfdrohung.",
		"base_speed": 2.7,
		"base_health": 84.0,
		"base_damage": 11.0,
		"base_attack_cooldown": 1.08,
		"base_scale": 1.0,
		"turn_agility": 0.9,
		"movement_jitter": 0.14,
		"pain_resistance": 0.25,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Taumeln wird ueber Jitter + moderate Wendigkeit angedeutet."
	},
	Species.BRUTE: {
		"id": "brute",
		"display_name": "Brute",
		"handbook_category": HandbookCategory.HEAVY,
		"handbook_short": "Massiger Tank-Zombie.",
		"functional_profile": "Sehr viel Leben, langsam, hoher Nahkampfschaden.",
		"threat_profile": "Frontdruck, schwer schnell auszuschalten.",
		"base_speed": 1.9,
		"base_health": 152.0,
		"base_damage": 22.0,
		"base_attack_cooldown": 1.25,
		"base_scale": 1.12,
		"turn_agility": 0.55,
		"movement_jitter": 0.03,
		"pain_resistance": 0.35,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Niedrige Wendigkeit erzwingt stumpfere Laufwege."
	},
	Species.TWINK: {
		"id": "twink",
		"display_name": "Twink",
		"handbook_category": HandbookCategory.FAST,
		"handbook_short": "Schlank, klein, fragil.",
		"functional_profile": "Wenig Leben, schneller als Standardtypen.",
		"threat_profile": "Mobil, aber schnell eliminiert.",
		"base_speed": 3.85,
		"base_health": 56.0,
		"base_damage": 9.0,
		"base_attack_cooldown": 0.9,
		"base_scale": 0.9,
		"turn_agility": 1.25,
		"movement_jitter": 0.12,
		"pain_resistance": 0.2,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Kleiner Skalierungsfaktor reduziert Zielprofil."
	},
	Species.BUFFED: {
		"id": "buffed",
		"display_name": "Buffed",
		"handbook_category": HandbookCategory.HEAVY,
		"handbook_short": "Gross und muskuloes.",
		"functional_profile": "Hohe HP, hoher Schaden, aber schlechte Wendigkeit.",
		"threat_profile": "Aggressiver Bruiser mit unpraezisem Lauf.",
		"base_speed": 3.25,
		"base_health": 170.0,
		"base_damage": 24.0,
		"base_attack_cooldown": 1.02,
		"base_scale": 1.2,
		"turn_agility": 0.4,
		"movement_jitter": 0.22,
		"pain_resistance": 0.45,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Sehr geringe Turn-Agility soll Kollisionen beguenstigen."
	},
	Species.CRAWLER: {
		"id": "crawler",
		"display_name": "Crawler",
		"handbook_category": HandbookCategory.AMBUSH,
		"handbook_short": "Niedriger Schwarmtyp.",
		"functional_profile": "Wenig HP, kleines Profil, Arm-basiertes Vorwaertsdruecken.",
		"threat_profile": "In Gruppen gefaehrlicher als solo.",
		"base_speed": 2.95,
		"base_health": 48.0,
		"base_damage": 7.0,
		"base_attack_cooldown": 1.15,
		"base_scale": 0.62,
		"turn_agility": 1.0,
		"movement_jitter": 0.09,
		"pain_resistance": 0.15,
		"behavior_mode": "low_crawl",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Niedrige Pose als Platzhalter fuer spaetere Modelle."
	},
	Species.GRANNY: {
		"id": "granny",
		"display_name": "Granny",
		"handbook_category": HandbookCategory.GEWOEHNLICH,
		"handbook_short": "Langsam gehender Alterstyp.",
		"functional_profile": "Niedrige Geschwindigkeit, stabile Grundwerte, Weapon-Hook vorbereitet.",
		"threat_profile": "Konstant, weniger mobil.",
		"base_speed": 2.3,
		"base_health": 76.0,
		"base_damage": 10.0,
		"base_attack_cooldown": 1.08,
		"base_scale": 0.95,
		"turn_agility": 0.82,
		"movement_jitter": 0.08,
		"pain_resistance": 0.3,
		"behavior_mode": "default",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Schnittstelle fuer spaeteres Weapon-Handling vorhanden."
	},
	Species.HIDDER: {
		"id": "hidder",
		"display_name": "Hidder",
		"handbook_category": HandbookCategory.AMBUSH,
		"handbook_short": "Deckungssucher mit Prioritaetslogik.",
		"functional_profile": "Hindernis > Zombie > Bodenmodus, hoher Schaden mit langem Cooldown.",
		"threat_profile": "Ueberraschungsangriffe statt Dauerdruck.",
		"base_speed": 2.65,
		"base_health": 70.0,
		"base_damage": 18.0,
		"base_attack_cooldown": 1.45,
		"base_scale": 0.92,
		"turn_agility": 1.0,
		"movement_jitter": 0.06,
		"pain_resistance": 0.25,
		"behavior_mode": "cover_ambush",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Bodenmodus deaktiviert aktiven Schaden."
	},
	Species.SPRINTER: {
		"id": "sprinter",
		"display_name": "Sprinter",
		"handbook_category": HandbookCategory.FAST,
		"handbook_short": "Sehr schneller, fragiler Rush-Typ.",
		"functional_profile": "Extrem schnell, wenig HP, instabilere Bewegungsbahn.",
		"threat_profile": "Kurze Time-to-Contact.",
		"base_speed": 5.25,
		"base_health": 40.0,
		"base_damage": 13.0,
		"base_attack_cooldown": 0.75,
		"base_scale": 0.88,
		"turn_agility": 1.5,
		"movement_jitter": 0.3,
		"pain_resistance": 0.1,
		"behavior_mode": "panic_fast",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Hohe Geschwindigkeit bei fragiler Defensive."
	},
	Species.SKINNER: {
		"id": "skinner",
		"display_name": "Skinner",
		"handbook_category": HandbookCategory.FAST,
		"handbook_short": "Schnell und schmerzresistent.",
		"functional_profile": "Mittlere HP, schnell, starke Resistenz gegen Stagger.",
		"threat_profile": "Bleibt trotz Treffern eher auf Kurs.",
		"base_speed": 4.2,
		"base_health": 86.0,
		"base_damage": 12.0,
		"base_attack_cooldown": 0.9,
		"base_scale": 1.0,
		"turn_agility": 1.25,
		"movement_jitter": 0.18,
		"pain_resistance": 0.86,
		"behavior_mode": "relentless",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Reduzierte Hurt-Unterbrechung."
	},
	Species.BOMB: {
		"id": "bomb",
		"display_name": "Bomb",
		"handbook_category": HandbookCategory.SPECIAL,
		"handbook_short": "Platzt beim Tod.",
		"functional_profile": "Wenig HP, schnell, on-death Explosionsereignis.",
		"threat_profile": "Gefahr im Nahbereich beim Kill.",
		"base_speed": 4.1,
		"base_health": 34.0,
		"base_damage": 6.0,
		"base_attack_cooldown": 1.3,
		"base_scale": 1.02,
		"turn_agility": 1.1,
		"movement_jitter": 0.15,
		"pain_resistance": 0.1,
		"behavior_mode": "bomber",
		"death_behavior": "explode",
		"explosion_radius": 3.1,
		"explosion_damage": 24.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Explosionsradius und -schaden sind datengetrieben."
	},
	Species.FEEDER: {
		"id": "feeder",
		"display_name": "Feeder",
		"handbook_category": HandbookCategory.SPECIAL,
		"handbook_short": "Sucht bevorzugt Leichen.",
		"functional_profile": "Corpse-Prioritaet vor Spieler bis Trigger.",
		"threat_profile": "Wird nach Trigger aggressiv.",
		"base_speed": 2.55,
		"base_health": 68.0,
		"base_damage": 11.0,
		"base_attack_cooldown": 1.1,
		"base_scale": 0.84,
		"turn_agility": 1.0,
		"movement_jitter": 0.1,
		"pain_resistance": 0.28,
		"behavior_mode": "corpse_feeder",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Aggro-Trigger via Naehe oder Treffer."
	},
	Species.CRY_BABY: {
		"id": "cry_baby",
		"display_name": "Cry Baby",
		"handbook_category": HandbookCategory.SPECIAL,
		"handbook_short": "Passiv bis Trigger.",
		"functional_profile": "Traege Startphase, danach normal aggressiv.",
		"threat_profile": "Niedrige Fruehbedrohung, spaeter wechselnd.",
		"base_speed": 2.0,
		"base_health": 52.0,
		"base_damage": 9.0,
		"base_attack_cooldown": 1.2,
		"base_scale": 0.94,
		"turn_agility": 0.9,
		"movement_jitter": 0.05,
		"pain_resistance": 0.2,
		"behavior_mode": "passive_trigger",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Triggerwechsel ohne separate Animationspipeline."
	},
	Species.PANICO: {
		"id": "panico",
		"display_name": "Panico",
		"handbook_category": HandbookCategory.FAST,
		"handbook_short": "Hektisch-unsteter Speed-Typ.",
		"functional_profile": "Sehr schnell, geringe HP, instabile Laufbahn.",
		"threat_profile": "Sprunghaftes Attack-Tempo.",
		"base_speed": 4.85,
		"base_health": 45.0,
		"base_damage": 12.0,
		"base_attack_cooldown": 0.82,
		"base_scale": 0.9,
		"turn_agility": 1.45,
		"movement_jitter": 0.38,
		"pain_resistance": 0.12,
		"behavior_mode": "panic_fast",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": false,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Instabilitaet ueber hoeheren Jitter modelliert."
	},
	Species.SKULLY: {
		"id": "skully",
		"display_name": "Skully",
		"handbook_category": HandbookCategory.SPECIAL,
		"handbook_short": "Ranged-affiner Skeletttyp.",
		"functional_profile": "Melee bleibt aktiv, Ranged-Hook vorbereitet/eingebaut.",
		"threat_profile": "Kann Distanzdruck aufbauen.",
		"base_speed": 3.05,
		"base_health": 90.0,
		"base_damage": 12.0,
		"base_attack_cooldown": 1.0,
		"base_scale": 1.03,
		"turn_agility": 1.12,
		"movement_jitter": 0.08,
		"pain_resistance": 0.45,
		"behavior_mode": "ranged_hook",
		"death_behavior": "collapse",
		"explosion_radius": 0.0,
		"explosion_damage": 0.0,
		"weapon_affinity_melee": true,
		"weapon_affinity_ranged": true,
		"allowed_visual_variants": VISUAL_VARIANTS_DEFAULT,
		"notes": "Spaetere echte Fernkampfwaffen koennen andocken."
	}
}

const CLASS_DATA: Dictionary = {
	ZombieClass.COMMON: {
		"id": "common",
		"display_name": "Common",
		"speed_mult": 1.0,
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"attack_cooldown_mult": 1.0
	},
	ZombieClass.FERAL: {
		"id": "feral",
		"display_name": "Feral",
		"speed_mult": 1.08,
		"health_mult": 0.9,
		"damage_mult": 1.0,
		"attack_cooldown_mult": 0.92
	},
	ZombieClass.ARMORED: {
		"id": "armored",
		"display_name": "Armored",
		"speed_mult": 0.9,
		"health_mult": 1.2,
		"damage_mult": 1.1,
		"attack_cooldown_mult": 1.08
	}
}

const RANK_DATA: Dictionary = {
	Rank.ALPHA: {
		"id": "alpha",
		"display_name": "Alpha",
		"rank_power": 4,
		"scale_mult": 1.55,
		"health_mult": 2.2,
		"damage_mult": 1.85,
		"speed_mult": 0.75,
		"threat_mult": 2.5,
		"visual_intensity": "extrem",
		"spawn_interval_factor": 1.8,
		"speed_cap": 2.6,
		"attack_cooldown_mult": 1.08,
		"role": "Extrem seltener Endboss-Rang mit maximaler Praesenz."
	},
	Rank.BETA: {
		"id": "beta",
		"display_name": "Beta",
		"rank_power": 3,
		"scale_mult": 1.3,
		"health_mult": 1.65,
		"damage_mult": 1.45,
		"speed_mult": 0.88,
		"threat_mult": 1.7,
		"visual_intensity": "hoch",
		"spawn_interval_factor": 1.35,
		"speed_cap": 2.95,
		"attack_cooldown_mult": 1.04,
		"role": "Hochrangiger Elitetyp mit hoher Gefahr und geringerer Mobilitaet."
	},
	Rank.GAMMA: {
		"id": "gamma",
		"display_name": "Gamma",
		"rank_power": 2,
		"scale_mult": 1.15,
		"health_mult": 1.3,
		"damage_mult": 1.2,
		"speed_mult": 0.94,
		"threat_mult": 1.3,
		"visual_intensity": "erhoeht",
		"spawn_interval_factor": 1.15,
		"speed_cap": 3.25,
		"attack_cooldown_mult": 1.02,
		"role": "Mittlerer Hochrang mit spuerbarer Robustheit."
	},
	Rank.DELTA: {
		"id": "delta",
		"display_name": "Delta",
		"rank_power": 1,
		"scale_mult": 1.0,
		"health_mult": 1.0,
		"damage_mult": 1.0,
		"speed_mult": 1.0,
		"threat_mult": 1.0,
		"visual_intensity": "normal",
		"spawn_interval_factor": 1.0,
		"speed_cap": 3.55,
		"attack_cooldown_mult": 1.0,
		"role": "Stabiler Standardrang fuer mittlere Bedrohung."
	},
	Rank.EPSILON: {
		"id": "epsilon",
		"display_name": "Epsilon",
		"rank_power": 0,
		"scale_mult": 0.9,
		"health_mult": 0.75,
		"damage_mult": 0.8,
		"speed_mult": 1.08,
		"threat_mult": 0.8,
		"visual_intensity": "niedrig",
		"spawn_interval_factor": 0.9,
		"speed_cap": 4.35,
		"attack_cooldown_mult": 0.96,
		"role": "Haeufigster Basisrang fuer fruehe Wellen."
	}
}

static func get_species_order() -> Array[int]:
	return SPECIES_ORDER.duplicate()

static func get_death_class_order() -> Array[int]:
	return DEATH_CLASS_ORDER.duplicate()

static func get_death_subtype_order() -> Array[int]:
	return DEATH_SUBTYPE_ORDER.duplicate()

static func get_species_data(species: int) -> Dictionary:
	if SPECIES_DATA.has(species):
		return SPECIES_DATA[species]
	return SPECIES_DATA[DEFAULT_SPECIES]

static func get_species_appearance_description(species: int) -> String:
	if SPECIES_APPEARANCE_DATA.has(species):
		return String(SPECIES_APPEARANCE_DATA[species])
	return String(SPECIES_APPEARANCE_DATA[DEFAULT_SPECIES])

static func get_species_handbook_image(species: int) -> String:
	if SPECIES_IMAGE_PATH_DATA.has(species):
		return String(SPECIES_IMAGE_PATH_DATA[species])
	return String(SPECIES_IMAGE_PATH_DATA[DEFAULT_SPECIES])

static func get_class_data(zombie_class: int) -> Dictionary:
	if CLASS_DATA.has(zombie_class):
		return CLASS_DATA[zombie_class]
	return CLASS_DATA[DEFAULT_CLASS]

static func get_rank_data(rank: int) -> Dictionary:
	if RANK_DATA.has(rank):
		return RANK_DATA[rank]
	return RANK_DATA[DEFAULT_RANK]

static func get_handbook_category_data(category: int) -> Dictionary:
	if HANDBOOK_CATEGORY_DATA.has(category):
		return HANDBOOK_CATEGORY_DATA[category]
	return HANDBOOK_CATEGORY_DATA[HandbookCategory.GEWOEHNLICH]

static func get_death_class_data(death_class: int) -> Dictionary:
	if DEATH_CLASS_DATA.has(death_class):
		return DEATH_CLASS_DATA[death_class]
	return DEATH_CLASS_DATA[DEFAULT_DEATH_CLASS]

static func get_death_subtype_data(death_subtype: int) -> Dictionary:
	if DEATH_SUBTYPE_DATA.has(death_subtype):
		return DEATH_SUBTYPE_DATA[death_subtype]
	return DEATH_SUBTYPE_DATA[DEFAULT_DEATH_SUBTYPE]

static func get_death_rarity_data(death_rarity: int) -> Dictionary:
	if DEATH_RARITY_DATA.has(death_rarity):
		return DEATH_RARITY_DATA[death_rarity]
	return DEATH_RARITY_DATA[DeathRarity.GEWOEHNLICH]

static func build_profile(
	species: int,
	zombie_class: int,
	mort_grade: int,
	rank: int,
	death_class: int = DEFAULT_DEATH_CLASS,
	death_subtype: int = DEFAULT_DEATH_SUBTYPE
) -> Dictionary:
	var resolved_species: int = DEFAULT_SPECIES
	if SPECIES_DATA.has(species):
		resolved_species = species

	var resolved_class: int = DEFAULT_CLASS
	if CLASS_DATA.has(zombie_class):
		resolved_class = zombie_class

	var resolved_rank: int = DEFAULT_RANK
	if RANK_DATA.has(rank):
		resolved_rank = rank

	var species_cfg: Dictionary = SPECIES_DATA[resolved_species]
	var class_cfg: Dictionary = CLASS_DATA[resolved_class]
	var rank_cfg: Dictionary = RANK_DATA[resolved_rank]
	var death_resolution: Dictionary = resolve_death_fields(death_class, death_subtype)
	var resolved_death_class: int = int(death_resolution["death_class"])
	var resolved_death_subtype: int = int(death_resolution["death_subtype"])
	var death_class_cfg: Dictionary = DEATH_CLASS_DATA[resolved_death_class]
	var death_subtype_cfg: Dictionary = DEATH_SUBTYPE_DATA[resolved_death_subtype]
	var death_rarity_cfg: Dictionary = DEATH_RARITY_DATA[int(death_subtype_cfg["rarity"])]
	var resolved_mort_grade: int = clamp_mort_grade(mort_grade)
	var mort_cfg: Dictionary = _build_mort_modifiers(resolved_mort_grade)

	var speed: float = float(species_cfg["base_speed"])
	speed *= float(class_cfg["speed_mult"])
	speed *= float(rank_cfg["speed_mult"])
	speed *= float(mort_cfg["speed_mult"])
	speed = minf(speed, float(rank_cfg.get("speed_cap", 8.0)))
	speed = clampf(speed, 0.25, 8.0)

	var health: float = float(species_cfg["base_health"])
	health *= float(class_cfg["health_mult"])
	health *= float(rank_cfg["health_mult"])
	health *= float(mort_cfg["health_mult"])

	var damage: float = float(species_cfg["base_damage"])
	damage *= float(class_cfg["damage_mult"])
	damage *= float(rank_cfg["damage_mult"])
	damage *= float(mort_cfg["damage_mult"])

	var attack_cooldown: float = float(species_cfg["base_attack_cooldown"])
	attack_cooldown *= float(class_cfg["attack_cooldown_mult"])
	attack_cooldown *= float(rank_cfg["attack_cooldown_mult"])
	attack_cooldown *= float(mort_cfg["attack_cooldown_mult"])
	attack_cooldown = clampf(attack_cooldown, 0.2, 3.0)

	var final_scale: float = float(species_cfg["base_scale"]) * float(rank_cfg["scale_mult"])

	return {
		"species": resolved_species,
		"class": resolved_class,
		"rank": resolved_rank,
		"mort_grade": resolved_mort_grade,
		"death_class": resolved_death_class,
		"death_subtype": resolved_death_subtype,
		"species_id": String(species_cfg["id"]),
		"species_name": String(species_cfg["display_name"]),
		"class_id": String(class_cfg["id"]),
			"class_name": String(class_cfg["display_name"]),
			"rank_id": String(rank_cfg["id"]),
			"rank_name": String(rank_cfg.get("display_name", String(rank_cfg["id"]))),
			"rank_power": int(rank_cfg.get("rank_power", 0)),
			"death_class_id": String(death_class_cfg["id"]),
		"death_class_name": String(death_class_cfg["display_name"]),
		"death_subtype_id": String(death_subtype_cfg["id"]),
		"death_subtype_name": String(death_subtype_cfg["display_name"]),
		"death_subtype_description": String(death_subtype_cfg["description"]),
		"death_rarity": int(death_subtype_cfg["rarity"]),
		"death_rarity_id": String(death_rarity_cfg["id"]),
		"death_rarity_name": String(death_rarity_cfg["display_name"]),
		"speed": speed,
		"health": max(1, int(round(health))),
		"damage": max(1, int(round(damage))),
		"attack_cooldown": attack_cooldown,
		"mort_speed_mult": float(mort_cfg["speed_mult"]),
			"mort_damage_mult": float(mort_cfg["damage_mult"]),
			"mort_attack_cooldown_mult": float(mort_cfg["attack_cooldown_mult"]),
			"rank_threat_mult": float(rank_cfg.get("threat_mult", 1.0)),
			"rank_visual_intensity": String(rank_cfg.get("visual_intensity", "normal")),
			"rank_spawn_interval_factor": float(rank_cfg.get("spawn_interval_factor", 1.0)),
			"rank_speed_cap": float(rank_cfg.get("speed_cap", 8.0)),
			"scale": final_scale,
		"part_health_mult": float(rank_cfg["health_mult"]) * float(mort_cfg["health_mult"]),
		"handbook_category": int(species_cfg["handbook_category"]),
		"handbook_short": String(species_cfg["handbook_short"]),
		"functional_profile": String(species_cfg["functional_profile"]),
		"threat_profile": String(species_cfg["threat_profile"]),
		"behavior_mode": String(species_cfg["behavior_mode"]),
		"turn_agility": float(species_cfg["turn_agility"]),
		"movement_jitter": float(species_cfg["movement_jitter"]),
		"pain_resistance": float(species_cfg["pain_resistance"]),
		"death_behavior": String(species_cfg["death_behavior"]),
		"explosion_radius": float(species_cfg["explosion_radius"]),
		"explosion_damage": float(species_cfg["explosion_damage"]),
		"weapon_affinity_melee": bool(species_cfg["weapon_affinity_melee"]),
		"weapon_affinity_ranged": bool(species_cfg["weapon_affinity_ranged"]),
		"allowed_visual_variants": species_cfg["allowed_visual_variants"],
		"notes": String(species_cfg["notes"])
	}

static func random_profile_ids(rng: RandomNumberGenerator, mort_grade_min: int = MORT_GRADE_MIN, mort_grade_max: int = MORT_GRADE_MAX) -> Dictionary:
	var mort_min: int = clamp_mort_grade(mort_grade_min)
	var mort_max: int = clamp_mort_grade(mort_grade_max)
	if mort_min > mort_max:
		var temp: int = mort_min
		mort_min = mort_max
		mort_max = temp

	var random_species: int = random_species_id(rng)
	var random_death_subtype: int = random_death_subtype_id(rng)
	var random_death_class: int = int(get_death_subtype_data(random_death_subtype)["death_class"])
	return {
		"species": random_species,
		"class": _pick_random_key(CLASS_DATA, DEFAULT_CLASS, rng),
		"rank": _pick_random_key(RANK_DATA, DEFAULT_RANK, rng),
		"mort_grade": random_mort_grade(rng, mort_min, mort_max),
		"death_class": random_death_class,
		"death_subtype": random_death_subtype
	}

static func clamp_mort_grade(mort_grade: int) -> int:
	return clampi(mort_grade, MORT_GRADE_MIN, MORT_GRADE_MAX)

static func get_mort_grade_raw_weight(mort_grade: int) -> float:
	var grade: int = clamp_mort_grade(mort_grade)
	var distance_to_neutral: int = absi(grade - MORT_GRADE_NEUTRAL)
	return pow(0.5, float(distance_to_neutral))

static func get_mort_grade_probability_table(mort_grade_min: int = MORT_GRADE_MIN, mort_grade_max: int = MORT_GRADE_MAX) -> Dictionary:
	var min_grade: int = clamp_mort_grade(mort_grade_min)
	var max_grade: int = clamp_mort_grade(mort_grade_max)
	if min_grade > max_grade:
		var temp: int = min_grade
		min_grade = max_grade
		max_grade = temp

	var raw_sum: float = 0.0
	var raw_weights: Dictionary = {}
	for grade in range(min_grade, max_grade + 1):
		var raw_weight: float = get_mort_grade_raw_weight(grade)
		raw_weights[grade] = raw_weight
		raw_sum += raw_weight

	var probabilities: Dictionary = {}
	if raw_sum <= 0.0:
		probabilities[MORT_GRADE_NEUTRAL] = 1.0
		return probabilities

	for grade in raw_weights.keys():
		probabilities[grade] = float(raw_weights[grade]) / raw_sum
	return probabilities

static func random_mort_grade(rng: RandomNumberGenerator, mort_grade_min: int = MORT_GRADE_MIN, mort_grade_max: int = MORT_GRADE_MAX) -> int:
	var probabilities: Dictionary = get_mort_grade_probability_table(mort_grade_min, mort_grade_max)
	var roll: float = rng.randf()
	var cumulative: float = 0.0
	var grades: Array = probabilities.keys()
	grades.sort()
	for grade_value in grades:
		cumulative += float(probabilities[grade_value])
		if roll <= cumulative:
			return int(grade_value)

	if grades.is_empty():
		return DEFAULT_MORT_GRADE
	return int(grades[grades.size() - 1])

static func get_mort_grade_modifiers(mort_grade: int) -> Dictionary:
	return _build_mort_modifiers(clamp_mort_grade(mort_grade))

static func random_species_id(rng: RandomNumberGenerator) -> int:
	if SPECIES_ORDER.is_empty():
		return DEFAULT_SPECIES
	var index: int = rng.randi_range(0, SPECIES_ORDER.size() - 1)
	return int(SPECIES_ORDER[index])

static func random_class_id(rng: RandomNumberGenerator) -> int:
	return _pick_random_key(CLASS_DATA, DEFAULT_CLASS, rng)

static func random_death_subtype_id(rng: RandomNumberGenerator) -> int:
	if DEATH_SUBTYPE_ORDER.is_empty():
		return DEFAULT_DEATH_SUBTYPE
	var index: int = rng.randi_range(0, DEATH_SUBTYPE_ORDER.size() - 1)
	return int(DEATH_SUBTYPE_ORDER[index])

static func resolve_death_fields(death_class: int, death_subtype: int) -> Dictionary:
	var resolved_subtype: int = DEFAULT_DEATH_SUBTYPE
	if DEATH_SUBTYPE_DATA.has(death_subtype):
		resolved_subtype = death_subtype

	var subtype_cfg: Dictionary = DEATH_SUBTYPE_DATA[resolved_subtype]
	var subtype_class: int = int(subtype_cfg["death_class"])

	var resolved_class: int = subtype_class
	if DEATH_CLASS_DATA.has(death_class):
		resolved_class = death_class

	if resolved_class != subtype_class:
		resolved_subtype = _first_death_subtype_for_class(resolved_class)

	return {
		"death_class": resolved_class,
		"death_subtype": resolved_subtype
	}

static func _first_death_subtype_for_class(death_class: int) -> int:
	for subtype in DEATH_SUBTYPE_ORDER:
		var subtype_cfg: Dictionary = get_death_subtype_data(subtype)
		if int(subtype_cfg["death_class"]) == death_class:
			return int(subtype)
	return DEFAULT_DEATH_SUBTYPE

static func resolve_visual_variant(species: int, allow_female_variants: bool, rng: RandomNumberGenerator) -> String:
	if not allow_female_variants:
		return DEFAULT_VISUAL_VARIANT

	var species_cfg: Dictionary = get_species_data(species)
	var variants: Array = species_cfg.get("allowed_visual_variants", [DEFAULT_VISUAL_VARIANT])
	if variants.is_empty():
		return DEFAULT_VISUAL_VARIANT
	var index: int = rng.randi_range(0, variants.size() - 1)
	return String(variants[index])

static func get_rank_power(rank: int) -> int:
	var rank_cfg: Dictionary = get_rank_data(rank)
	return int(rank_cfg.get("rank_power", 0))

static func get_rank_spawn_interval_factor(rank: int) -> float:
	var rank_cfg: Dictionary = get_rank_data(rank)
	return float(rank_cfg.get("spawn_interval_factor", 1.0))

static func get_rank_speed_cap(rank: int) -> float:
	var rank_cfg: Dictionary = get_rank_data(rank)
	return float(rank_cfg.get("speed_cap", 8.0))

static func _pick_random_key(source: Dictionary, fallback: int, rng: RandomNumberGenerator) -> int:
	if source.is_empty():
		return fallback

	var keys: Array = source.keys()
	var index: int = rng.randi_range(0, keys.size() - 1)
	return int(keys[index])

static func _build_mort_modifiers(mort_grade: int) -> Dictionary:
	var grade: int = clamp_mort_grade(mort_grade)
	var speed_mult: float = 1.0
	var damage_mult: float = 1.0
	var attack_cooldown_mult: float = 1.0
	var health_mult: float = 1.0

	if grade < MORT_GRADE_NEUTRAL:
		var delta_up: int = MORT_GRADE_NEUTRAL - grade
		speed_mult = 1.0 + float(delta_up) * 0.02
		damage_mult = 1.0 + float(delta_up) * 0.015
		attack_cooldown_mult = 1.0 - float(delta_up) * 0.015
	elif grade > MORT_GRADE_NEUTRAL:
		var delta_down: int = grade - MORT_GRADE_NEUTRAL
		speed_mult = 1.0 - float(delta_down) * 0.03
		damage_mult = 1.0 - float(delta_down) * 0.05
		attack_cooldown_mult = 1.0 + float(delta_down) * 0.025

	speed_mult = clampf(speed_mult, 0.82, 1.12)
	damage_mult = clampf(damage_mult, 0.8, 1.09)
	attack_cooldown_mult = clampf(attack_cooldown_mult, 0.9, 1.25)

	return {
		"attack_cooldown_mult": attack_cooldown_mult,
		"speed_mult": speed_mult,
		"health_mult": health_mult,
		"damage_mult": damage_mult
	}
