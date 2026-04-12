extends RefCounted
class_name ItemInventory

const ItemDefinitions = preload("res://scripts/player/item_definitions.gd")

var counts: Dictionary = {}
var selected_item_id: String = "medkit"
var max_slots: int = 6

func _init() -> void:
	for item_id in ItemDefinitions.get_item_ids():
		counts[item_id] = 0

func get_count(item_id: String) -> int:
	return int(counts.get(item_id, 0))

func get_item_count(item_id: String) -> int:
	return get_count(item_id)

func can_add_item(item_id: String, amount: int = 1) -> bool:
	if not ItemDefinitions.has_item(item_id):
		return false
	var item_data: Dictionary = ItemDefinitions.get_item_data(item_id)
	item_data["item_id"] = item_id
	return has_space_for(item_data, amount)

func has_space_for(item_data: Dictionary, amount: int) -> bool:
	var item_id: String = String(item_data.get("item_id", ""))
	if item_id.is_empty() or not ItemDefinitions.has_item(item_id):
		return false
	var max_stack: int = maxi(int(item_data.get("max_stack", 0)), 0)
	if max_stack <= 0:
		return false
	var target_amount: int = maxi(amount, 0)
	if target_amount <= 0:
		return true
	var current_count: int = get_count(item_id)
	if current_count + target_amount > max_stack:
		return false
	if current_count > 0:
		return true
	return _get_used_slot_count() < max_slots

func add_item(item_id: String, amount: int) -> int:
	if not ItemDefinitions.has_item(item_id):
		return 0
	var item_data: Dictionary = ItemDefinitions.get_item_data(item_id)
	item_data["item_id"] = item_id
	if not has_space_for(item_data, amount):
		return 0
	var max_stack: int = int(item_data.get("max_stack", 0))
	var current_count: int = get_count(item_id)
	var added_amount: int = mini(max_stack - current_count, maxi(amount, 0))
	if added_amount <= 0:
		return 0
	counts[item_id] = current_count + added_amount
	if selected_item_id.is_empty():
		selected_item_id = item_id
	return added_amount

func consume_item(item_id: String, amount: int = 1) -> bool:
	return remove_item(item_id, amount)

func remove_item(item_id: String, amount: int) -> bool:
	var current_count: int = get_count(item_id)
	if current_count < amount or amount <= 0:
		return false
	counts[item_id] = current_count - amount
	return true

func cycle_selection(step: int, unlocked_item_ids: Array[String]) -> String:
	var selectable_ids: Array[String] = _build_selectable_ids(unlocked_item_ids)
	if selectable_ids.is_empty():
		selected_item_id = ""
		return selected_item_id
	if not selectable_ids.has(selected_item_id):
		selected_item_id = selectable_ids[0]
		return selected_item_id
	var current_index: int = selectable_ids.find(selected_item_id)
	selected_item_id = selectable_ids[posmod(current_index + step, selectable_ids.size())]
	return selected_item_id

func ensure_selected_item(unlocked_item_ids: Array[String]) -> String:
	var selectable_ids: Array[String] = _build_selectable_ids(unlocked_item_ids)
	if selectable_ids.is_empty():
		selected_item_id = ""
	elif not selectable_ids.has(selected_item_id):
		selected_item_id = selectable_ids[0]
	return selected_item_id

func get_selected_item_id() -> String:
	return selected_item_id

func build_state(unlocked_item_ids: Array[String]) -> Dictionary:
	var selected_id: String = ensure_selected_item(unlocked_item_ids)
	return {
		"counts": counts.duplicate(true),
		"selected_item_id": selected_id,
		"selected_item_display": ItemDefinitions.get_display_name(selected_id) if not selected_id.is_empty() else "-",
		"ordered_items": ItemDefinitions.get_item_ids(),
		"unlocked_items": unlocked_item_ids.duplicate(),
	}

func _build_selectable_ids(unlocked_item_ids: Array[String]) -> Array[String]:
	var selectable_ids: Array[String] = []
	for item_id in ItemDefinitions.get_item_ids():
		if unlocked_item_ids.has(item_id):
			selectable_ids.append(item_id)
	return selectable_ids

func _get_used_slot_count() -> int:
	var used_slots: int = 0
	for item_id in counts.keys():
		if int(counts[item_id]) > 0:
			used_slots += 1
	return used_slots
