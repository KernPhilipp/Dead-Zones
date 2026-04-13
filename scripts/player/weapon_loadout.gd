extends RefCounted
class_name WeaponLoadout

const WeaponDefinitions = preload("res://scripts/player/weapon_definitions.gd")

const SLOT_COUNT: int = 2

var slot_states: Array[Dictionary] = []
var current_slot_index: int = 0

func initialize(initial_weapon_ids: Array[String]) -> void:
	slot_states.clear()
	for slot_index in range(SLOT_COUNT):
		var weapon_id: String = "pistol"
		if slot_index < initial_weapon_ids.size() and WeaponDefinitions.has_weapon(initial_weapon_ids[slot_index]):
			weapon_id = initial_weapon_ids[slot_index]
		slot_states.append(WeaponDefinitions.create_runtime_state(weapon_id))
	current_slot_index = clampi(current_slot_index, 0, max(slot_states.size() - 1, 0))

func get_slot_count() -> int:
	return slot_states.size()

func get_current_slot_index() -> int:
	return current_slot_index

func set_current_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slot_states.size():
		return false
	current_slot_index = slot_index
	return true

func cycle_slots(step: int) -> int:
	if slot_states.is_empty():
		return 0
	current_slot_index = posmod(current_slot_index + step, slot_states.size())
	return current_slot_index

func get_slot_state(slot_index: int) -> Dictionary:
	if slot_index < 0 or slot_index >= slot_states.size():
		return {}
	return slot_states[slot_index]

func get_current_state() -> Dictionary:
	return get_slot_state(current_slot_index)

func get_current_weapon_id() -> String:
	return String(get_current_state().get("weapon_id", "pistol"))

func get_current_weapon_data() -> Dictionary:
	return WeaponDefinitions.get_weapon_data(get_current_weapon_id(), get_current_upgrade_tier())

func get_weapon_id_in_slot(slot_index: int) -> String:
	return String(get_slot_state(slot_index).get("weapon_id", "pistol"))

func get_weapon_data_in_slot(slot_index: int) -> Dictionary:
	return WeaponDefinitions.get_weapon_data(get_weapon_id_in_slot(slot_index), get_upgrade_tier(slot_index))

func get_upgrade_tier(slot_index: int) -> int:
	return int(get_slot_state(slot_index).get("upgrade_tier", 0))

func get_current_upgrade_tier() -> int:
	return get_upgrade_tier(current_slot_index)

func assign_weapon(slot_index: int, weapon_id: String) -> Dictionary:
	if slot_index < 0 or slot_index >= slot_states.size():
		return {}
	var previous_state: Dictionary = get_slot_state(slot_index).duplicate(true)
	slot_states[slot_index] = WeaponDefinitions.create_runtime_state(weapon_id)
	return previous_state

func get_slot_index_by_weapon_id(weapon_id: String) -> int:
	for slot_index in range(slot_states.size()):
		if String(slot_states[slot_index].get("weapon_id", "")) == weapon_id:
			return slot_index
	return -1

func current_ammo_in_mag() -> int:
	return int(get_current_state().get("ammo_in_mag", 0))

func current_reserve_ammo() -> int:
	return int(get_current_state().get("reserve_ammo", 0))

func current_mag_size() -> int:
	return int(get_current_weapon_data().get("mag_size", 0))

func current_is_automatic() -> bool:
	return bool(get_current_weapon_data().get("is_automatic", false))

func consume_current_shot() -> bool:
	var current_state: Dictionary = get_current_state()
	var ammo_in_mag: int = int(current_state.get("ammo_in_mag", 0))
	if ammo_in_mag <= 0:
		return false
	current_state["ammo_in_mag"] = ammo_in_mag - 1
	return true

func can_reload_current() -> bool:
	var ammo_in_mag: int = current_ammo_in_mag()
	var mag_size: int = current_mag_size()
	var reserve_ammo: int = current_reserve_ammo()
	return ammo_in_mag < mag_size and reserve_ammo > 0

func finish_reload_current() -> int:
	if not can_reload_current():
		return 0
	var current_state: Dictionary = get_current_state()
	var mag_size: int = current_mag_size()
	var ammo_in_mag: int = int(current_state.get("ammo_in_mag", 0))
	var reserve_ammo: int = int(current_state.get("reserve_ammo", 0))
	var needed_ammo: int = mag_size - ammo_in_mag
	var reloaded_ammo: int = mini(needed_ammo, reserve_ammo)
	current_state["ammo_in_mag"] = ammo_in_mag + reloaded_ammo
	current_state["reserve_ammo"] = reserve_ammo - reloaded_ammo
	return reloaded_ammo

func can_upgrade_current() -> bool:
	return get_current_upgrade_tier() < WeaponDefinitions.get_max_upgrade_tier(get_current_weapon_id())

func apply_upgrade_to_current() -> bool:
	return apply_upgrade_to_slot(current_slot_index)

func apply_upgrade_to_slot(slot_index: int) -> bool:
	if slot_index < 0 or slot_index >= slot_states.size():
		return false
	var slot_state: Dictionary = get_slot_state(slot_index)
	var weapon_id: String = String(slot_state.get("weapon_id", "pistol"))
	var current_tier: int = int(slot_state.get("upgrade_tier", 0))
	var next_tier: int = current_tier + 1
	if next_tier > WeaponDefinitions.get_max_upgrade_tier(weapon_id):
		return false

	var previous_data: Dictionary = WeaponDefinitions.get_weapon_data(weapon_id, current_tier)
	var upgraded_data: Dictionary = WeaponDefinitions.get_weapon_data(weapon_id, next_tier)
	slot_state["upgrade_tier"] = next_tier

	var current_ammo: int = int(slot_state.get("ammo_in_mag", 0))
	var current_reserve: int = int(slot_state.get("reserve_ammo", 0))
	var mag_bonus: int = max(0, int(upgraded_data.get("mag_size", 0)) - int(previous_data.get("mag_size", 0)))
	var reserve_bonus: int = max(0, int(upgraded_data.get("reserve_start", 0)) - int(previous_data.get("reserve_start", 0)))
	slot_state["ammo_in_mag"] = min(int(upgraded_data.get("mag_size", 0)), current_ammo + mag_bonus)
	slot_state["reserve_ammo"] = current_reserve + reserve_bonus
	return true

func add_reserve_ammo_for_weapon(weapon_id: String, amount: int) -> int:
	var slot_index: int = get_slot_index_by_weapon_id(weapon_id)
	if slot_index == -1:
		return 0
	var slot_state: Dictionary = get_slot_state(slot_index)
	var added_amount: int = maxi(amount, 0)
	slot_state["reserve_ammo"] = int(slot_state.get("reserve_ammo", 0)) + added_amount
	return added_amount

func add_reserve_ammo_to_current(amount: int) -> int:
	return add_reserve_ammo_for_weapon(get_current_weapon_id(), amount)
