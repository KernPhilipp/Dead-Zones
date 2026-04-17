extends RefCounted
class_name ZombieMortVisuals

const ZombieDefinitions = preload("res://scripts/zombie_definitions.gd")

const MORT_DARKNESS_CURVE: Dictionary = {
	0: 0.00,
	1: 0.04,
	2: 0.08,
	3: 0.12,
	4: 0.17,
	5: 0.22,
	6: 0.28,
	7: 0.36,
	8: 0.45,
	9: 0.55,
	10: 0.65
}

static func get_visual_profile(mort_grade: int) -> Dictionary:
	var grade: int = ZombieDefinitions.clamp_mort_grade(mort_grade)
	var darkness: float = get_darkness_for_grade(grade)
	return {
		"mort_grade": grade,
		"darkness": darkness,
		"brightness_mult": 1.0 - darkness,
		"saturation_shift": 0.0,
		"tier_label": get_visual_tier_label(grade)
	}

static func get_darkness_for_grade(mort_grade: int) -> float:
	var grade: int = ZombieDefinitions.clamp_mort_grade(mort_grade)
	if MORT_DARKNESS_CURVE.has(grade):
		return clampf(float(MORT_DARKNESS_CURVE[grade]), 0.0, 0.9)

	var lower_grade: int = 0
	var upper_grade: int = 10
	for grade_key in MORT_DARKNESS_CURVE.keys():
		var key_grade: int = int(grade_key)
		if key_grade <= grade and key_grade >= lower_grade:
			lower_grade = key_grade
		if key_grade >= grade and key_grade <= upper_grade:
			upper_grade = key_grade

	var lower_val: float = float(MORT_DARKNESS_CURVE.get(lower_grade, 0.0))
	var upper_val: float = float(MORT_DARKNESS_CURVE.get(upper_grade, lower_val))
	if lower_grade == upper_grade:
		return clampf(lower_val, 0.0, 0.9)

	var alpha: float = float(grade - lower_grade) / float(upper_grade - lower_grade)
	return clampf(lerpf(lower_val, upper_val, alpha), 0.0, 0.9)

static func apply_to_color(base_color: Color, profile: Dictionary, strength_mult: float = 1.0) -> Color:
	var darkness: float = clampf(float(profile.get("darkness", 0.0)) * maxf(0.0, strength_mult), 0.0, 0.9)
	var color_out: Color = base_color.lerp(Color.BLACK, darkness)
	color_out.a = base_color.a
	return color_out

static func get_visual_tier_label(mort_grade: int) -> String:
	var grade: int = ZombieDefinitions.clamp_mort_grade(mort_grade)
	if grade <= 2:
		return "hell / frisch"
	if grade <= 5:
		return "leicht verdunkelt"
	if grade <= 7:
		return "deutlich verdunkelt"
	if grade <= 8:
		return "stark verdunkelt"
	return "sehr dunkel / stark verwest"

