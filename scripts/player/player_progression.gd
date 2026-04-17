extends RefCounted
class_name PlayerProgression

const WeaponDefinitions = preload("res://scripts/player/weapon_definitions.gd")
const ItemDefinitions = preload("res://scripts/player/item_definitions.gd")

const SAVE_PATH: String = "user://dead_zones_player_profile.json"

var profile: Dictionary = {}

func _init() -> void:
	load_profile()

func load_profile() -> void:
	var default_profile: Dictionary = _build_default_profile()
	if not FileAccess.file_exists(SAVE_PATH):
		profile = default_profile
		save_profile()
		return

	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		profile = default_profile
		save_profile()
		return

	var parsed: Variant = JSON.parse_string(file.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		profile = default_profile
		save_profile()
		return

	profile = _sanitize_profile(parsed as Dictionary)
	save_profile()

func save_profile() -> void:
	var file: FileAccess = FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		return
	file.store_string(JSON.stringify(profile))

func get_total_kills() -> int:
	return int(profile.get("total_kills", 0))

func get_total_headshots() -> int:
	return int(profile.get("total_headshots", 0))

func get_unlocked_weapons() -> Array[String]:
	return _build_string_array(profile.get("unlocked_weapons", []))

func get_unlocked_items() -> Array[String]:
	return _build_string_array(profile.get("unlocked_items", []))

func is_weapon_unlocked(weapon_id: String) -> bool:
	return get_unlocked_weapons().has(weapon_id)

func is_item_unlocked(item_id: String) -> bool:
	return get_unlocked_items().has(item_id)

func register_kill(is_headshot: bool) -> Array[Dictionary]:
	profile["total_kills"] = get_total_kills() + 1
	if is_headshot:
		profile["total_headshots"] = get_total_headshots() + 1
	var unlocked_entries: Array[Dictionary] = _apply_unlocks()
	save_profile()
	return unlocked_entries

func _build_default_profile() -> Dictionary:
	return {
		"total_kills": 0,
		"total_headshots": 0,
		"unlocked_weapons": ["pistol", "rifle"],
		"unlocked_items": ["medkit"],
	}

func _sanitize_profile(raw_profile: Dictionary) -> Dictionary:
	var sanitized_profile: Dictionary = _build_default_profile()
	sanitized_profile["total_kills"] = maxi(int(raw_profile.get("total_kills", 0)), 0)
	sanitized_profile["total_headshots"] = maxi(int(raw_profile.get("total_headshots", 0)), 0)

	var unlocked_weapons: Array[String] = []
	for weapon_id in _build_string_array(raw_profile.get("unlocked_weapons", [])):
		if WeaponDefinitions.has_weapon(weapon_id) and not unlocked_weapons.has(weapon_id):
			unlocked_weapons.append(weapon_id)
	for base_weapon in ["pistol", "rifle"]:
		if not unlocked_weapons.has(base_weapon):
			unlocked_weapons.append(base_weapon)
	sanitized_profile["unlocked_weapons"] = unlocked_weapons

	var unlocked_items: Array[String] = []
	for item_id in _build_string_array(raw_profile.get("unlocked_items", [])):
		if ItemDefinitions.has_item(item_id) and not unlocked_items.has(item_id):
			unlocked_items.append(item_id)
	if not unlocked_items.has("medkit"):
		unlocked_items.append("medkit")
	sanitized_profile["unlocked_items"] = unlocked_items
	return sanitized_profile

func _apply_unlocks() -> Array[Dictionary]:
	var unlocked_entries: Array[Dictionary] = []
	var total_kills: int = get_total_kills()
	var unlocked_weapons: Array[String] = get_unlocked_weapons()
	var unlocked_items: Array[String] = get_unlocked_items()

	for weapon_id in WeaponDefinitions.get_weapon_ids():
		if unlocked_weapons.has(weapon_id):
			continue
		if total_kills < WeaponDefinitions.get_unlock_threshold(weapon_id):
			continue
		unlocked_weapons.append(weapon_id)
		unlocked_entries.append({
			"unlock_type": "weapon",
			"unlock_id": weapon_id,
			"display_name": WeaponDefinitions.get_display_name(weapon_id),
		})

	for item_id in ItemDefinitions.get_item_ids():
		if unlocked_items.has(item_id):
			continue
		if total_kills < ItemDefinitions.get_unlock_threshold(item_id):
			continue
		unlocked_items.append(item_id)
		unlocked_entries.append({
			"unlock_type": "item",
			"unlock_id": item_id,
			"display_name": ItemDefinitions.get_display_name(item_id),
		})

	profile["unlocked_weapons"] = unlocked_weapons
	profile["unlocked_items"] = unlocked_items
	return unlocked_entries

func _build_string_array(source: Variant) -> Array[String]:
	var result: Array[String] = []
	if source is Array:
		for entry in source:
			result.append(String(entry))
	return result
