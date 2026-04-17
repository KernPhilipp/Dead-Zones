extends RefCounted
class_name ZombieDeathVisuals

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

const VISUAL_MODE_NONE := "none"
const VISUAL_MODE_PARTICLE := "particle"
const VISUAL_MODE_ATTACHMENT_MODEL := "attachment_model"
const VISUAL_MODE_MESH_OVERLAY := "mesh_overlay"

const DEFAULT_PROFILE: Dictionary = {
	"visual_mode": VISUAL_MODE_PARTICLE,
	"display_color": Color(0.48, 0.58, 0.62, 1.0),
	"secondary_color": Color(0.32, 0.38, 0.42, 0.0),
	"intensity": 0.28,
	"spawn_anchor": "torso",
	"anchor_offset": Vector3(0.0, 0.08, 0.0),
	"particle_profile_id": "death_hint_soft",
	"future_attachment_model_id": "",
	"handbook_preview_color": Color(0.48, 0.58, 0.62, 1.0),
	"note": "Dezente Todesart-Andeutung als austauschbarer Placeholder."
}

const SUBTYPE_VISUAL_DATA: Dictionary = {
	ZombieDefinitions.DeathSubtype.ALKOHOLISIERT: {
		"display_color": Color(0.63, 0.65, 0.27, 1.0),
		"secondary_color": Color(0.45, 0.43, 0.2, 0.0)
	},
	ZombieDefinitions.DeathSubtype.INFIZIERT: {
		"display_color": Color(0.34, 0.68, 0.26, 1.0),
		"secondary_color": Color(0.19, 0.44, 0.16, 0.0)
	},
	ZombieDefinitions.DeathSubtype.KREBSINFIZIERT: {
		"display_color": Color(0.47, 0.57, 0.43, 1.0),
		"secondary_color": Color(0.31, 0.39, 0.3, 0.0)
	},
	ZombieDefinitions.DeathSubtype.PARASSITIERT: {
		"display_color": Color(0.62, 0.72, 0.22, 1.0),
		"secondary_color": Color(0.43, 0.5, 0.15, 0.0),
		"intensity": 0.3
	},
	ZombieDefinitions.DeathSubtype.PILZINFIZIERT: {
		"display_color": Color(0.32, 0.8, 0.36, 1.0),
		"secondary_color": Color(0.19, 0.53, 0.23, 0.0),
		"intensity": 0.33
	},
	ZombieDefinitions.DeathSubtype.SEUCHENVERSEUCHT: {
		"display_color": Color(0.43, 0.58, 0.31, 1.0),
		"secondary_color": Color(0.37, 0.27, 0.44, 0.0),
		"intensity": 0.34
	},
	ZombieDefinitions.DeathSubtype.RADIOAKTIV_MUTIERT: {
		"display_color": Color(0.28, 0.86, 0.56, 1.0),
		"secondary_color": Color(0.16, 0.59, 0.42, 0.0),
		"intensity": 0.42
	},

	ZombieDefinitions.DeathSubtype.GEISTLICH: {
		"display_color": Color(0.85, 0.81, 0.62, 1.0),
		"secondary_color": Color(0.68, 0.63, 0.48, 0.0),
		"spawn_anchor": "head",
		"anchor_offset": Vector3(0.0, 0.16, 0.0),
		"intensity": 0.24
	},
	ZombieDefinitions.DeathSubtype.VERFLUCHT: {
		"display_color": Color(0.5, 0.28, 0.74, 1.0),
		"secondary_color": Color(0.33, 0.19, 0.49, 0.0),
		"intensity": 0.36
	},
	ZombieDefinitions.DeathSubtype.DAEMONISCH_BESESSEN: {
		"display_color": Color(0.66, 0.24, 0.5, 1.0),
		"secondary_color": Color(0.52, 0.17, 0.21, 0.0),
		"intensity": 0.4
	},

	ZombieDefinitions.DeathSubtype.MILITAERISCH: {
		"display_color": Color(0.58, 0.26, 0.22, 1.0),
		"secondary_color": Color(0.42, 0.19, 0.16, 0.0),
		"intensity": 0.28
	},
	ZombieDefinitions.DeathSubtype.VERBRANNT: {
		"display_color": Color(0.88, 0.42, 0.17, 1.0),
		"secondary_color": Color(0.68, 0.23, 0.11, 0.0),
		"intensity": 0.37
	},
	ZombieDefinitions.DeathSubtype.ERHAENGT: {
		"display_color": Color(0.48, 0.42, 0.55, 1.0),
		"secondary_color": Color(0.34, 0.31, 0.4, 0.0),
		"spawn_anchor": "head",
		"anchor_offset": Vector3(0.0, 0.14, 0.0),
		"intensity": 0.25
	},
	ZombieDefinitions.DeathSubtype.VERBLUTET: {
		"display_color": Color(0.66, 0.17, 0.15, 1.0),
		"secondary_color": Color(0.45, 0.12, 0.11, 0.0),
		"intensity": 0.32
	},
	ZombieDefinitions.DeathSubtype.HINGERICHTET: {
		"display_color": Color(0.61, 0.19, 0.18, 1.0),
		"secondary_color": Color(0.42, 0.13, 0.12, 0.0),
		"intensity": 0.29
	},
	ZombieDefinitions.DeathSubtype.GEFOLTERT: {
		"display_color": Color(0.56, 0.2, 0.13, 1.0),
		"secondary_color": Color(0.4, 0.15, 0.1, 0.0),
		"intensity": 0.31
	},
	ZombieDefinitions.DeathSubtype.ERSTOCHEN: {
		"display_color": Color(0.72, 0.14, 0.14, 1.0),
		"secondary_color": Color(0.49, 0.1, 0.1, 0.0),
		"intensity": 0.31
	},
	ZombieDefinitions.DeathSubtype.ERSCHOSSEN: {
		"display_color": Color(0.54, 0.29, 0.31, 1.0),
		"secondary_color": Color(0.39, 0.2, 0.21, 0.0),
		"intensity": 0.29
	},
	ZombieDefinitions.DeathSubtype.ERSCHLAGEN: {
		"display_color": Color(0.53, 0.25, 0.2, 1.0),
		"secondary_color": Color(0.38, 0.18, 0.15, 0.0),
		"intensity": 0.27
	},

	ZombieDefinitions.DeathSubtype.VERGIFTET: {
		"display_color": Color(0.4, 0.78, 0.2, 1.0),
		"secondary_color": Color(0.24, 0.51, 0.12, 0.0),
		"intensity": 0.34
	},
	ZombieDefinitions.DeathSubtype.CHEMISCH_VERSEUCHT: {
		"display_color": Color(0.66, 0.79, 0.21, 1.0),
		"secondary_color": Color(0.46, 0.58, 0.14, 0.0),
		"intensity": 0.36
	},
	ZombieDefinitions.DeathSubtype.SAEUREVERAETZT: {
		"display_color": Color(0.8, 0.9, 0.22, 1.0),
		"secondary_color": Color(0.55, 0.68, 0.14, 0.0),
		"intensity": 0.38
	},

	ZombieDefinitions.DeathSubtype.ERFROREN: {
		"display_color": Color(0.44, 0.72, 0.9, 1.0),
		"secondary_color": Color(0.27, 0.51, 0.69, 0.0),
		"intensity": 0.29
	},
	ZombieDefinitions.DeathSubtype.ERTRUNKEN: {
		"display_color": Color(0.29, 0.67, 0.78, 1.0),
		"secondary_color": Color(0.19, 0.47, 0.56, 0.0),
		"intensity": 0.3
	},
	ZombieDefinitions.DeathSubtype.BLITZSCHLAG_OPFER: {
		"display_color": Color(0.56, 0.84, 0.98, 1.0),
		"secondary_color": Color(0.88, 0.83, 0.33, 0.0),
		"intensity": 0.38
	},
	ZombieDefinitions.DeathSubtype.TIERANGRIFF_OPFER: {
		"display_color": Color(0.58, 0.3, 0.23, 1.0),
		"secondary_color": Color(0.4, 0.21, 0.16, 0.0),
		"intensity": 0.27
	},

	ZombieDefinitions.DeathSubtype.STARK_VERLETZT: {
		"display_color": Color(0.66, 0.35, 0.3, 1.0),
		"secondary_color": Color(0.47, 0.24, 0.21, 0.0),
		"intensity": 0.26
	},
	ZombieDefinitions.DeathSubtype.ZERSTUECKELT: {
		"display_color": Color(0.48, 0.2, 0.17, 1.0),
		"secondary_color": Color(0.34, 0.14, 0.12, 0.0),
		"intensity": 0.28
	},
	ZombieDefinitions.DeathSubtype.ELEKTRISIERT: {
		"display_color": Color(0.43, 0.85, 0.95, 1.0),
		"secondary_color": Color(0.25, 0.63, 0.75, 0.0),
		"intensity": 0.37
	},

	ZombieDefinitions.DeathSubtype.MUMIFIZIERT: {
		"display_color": Color(0.78, 0.65, 0.35, 1.0),
		"secondary_color": Color(0.57, 0.47, 0.23, 0.0),
		"intensity": 0.25
	},
	ZombieDefinitions.DeathSubtype.VERWEST: {
		"display_color": Color(0.43, 0.48, 0.25, 1.0),
		"secondary_color": Color(0.31, 0.34, 0.18, 0.0),
		"intensity": 0.25
	},
	ZombieDefinitions.DeathSubtype.FRISCH_VERSTORBEN: {
		"display_color": Color(0.61, 0.67, 0.76, 1.0),
		"secondary_color": Color(0.44, 0.48, 0.57, 0.0),
		"intensity": 0.22
	},

	ZombieDefinitions.DeathSubtype.ATOMVERSEUCHT: {
		"display_color": Color(0.36, 0.96, 0.41, 1.0),
		"secondary_color": Color(0.18, 0.75, 0.62, 0.0),
		"intensity": 0.45
	}
}

static func get_visual_profile(death_subtype_id: int) -> Dictionary:
	var merged: Dictionary = DEFAULT_PROFILE.duplicate(true)
	if SUBTYPE_VISUAL_DATA.has(death_subtype_id):
		merged = _merge_dict_recursive(merged, SUBTYPE_VISUAL_DATA[death_subtype_id])

	var display_color: Color = merged.get("display_color", Color(0.48, 0.58, 0.62, 1.0))
	var secondary_color: Color = merged.get("secondary_color", Color(0.32, 0.38, 0.42, 0.0))
	var preview_color: Color = merged.get("handbook_preview_color", display_color)
	var visual_mode: String = String(merged.get("visual_mode", VISUAL_MODE_NONE))

	merged["display_color"] = display_color
	merged["secondary_color"] = secondary_color
	merged["handbook_preview_color"] = preview_color
	merged["display_color_hex"] = _color_to_hex(display_color)
	merged["secondary_color_hex"] = _color_to_hex(secondary_color)
	merged["handbook_preview_color_hex"] = _color_to_hex(preview_color)
	merged["visual_mode"] = visual_mode
	merged["intensity"] = clampf(float(merged.get("intensity", 0.28)), 0.08, 1.0)
	merged["is_placeholder"] = true
	merged["subtype_id"] = death_subtype_id
	return merged

static func is_mode_supported_now(visual_mode: String) -> bool:
	return visual_mode == VISUAL_MODE_NONE or visual_mode == VISUAL_MODE_PARTICLE

static func _color_to_hex(color_value: Color) -> String:
	return "#" + color_value.to_html(false)

static func _merge_dict_recursive(base_cfg: Dictionary, override_cfg: Dictionary) -> Dictionary:
	var merged: Dictionary = base_cfg.duplicate(true)
	for key in override_cfg.keys():
		var value = override_cfg[key]
		if merged.has(key) and merged[key] is Dictionary and value is Dictionary:
			merged[key] = _merge_dict_recursive(merged[key], value)
		else:
			merged[key] = value
	return merged

