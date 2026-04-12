extends RefCounted
class_name ItemInventory

const ItemDefinitions = preload("res://scripts/player/item_definitions.gd")

var counts: Dictionary = {}
var selected_item_id: String = "medkit"

func _init() -> void:
	for item_id in ItemDefinitions.get_item_ids():
		counts[item_id] = 0

func get_count(item_id: String) -> int:
	return int(counts.get(item_id, 0))

func can_add_item(item_id: String, amount: int = 1) -> bool:
	if not ItemDefinitions.has_item(item_id):
		return false
	var item_data: Dictionary = ItemDefinitions.get_item_data(item_id)
	return get_count(item_id) + maxi(amount, 0) <= int(item_data.get("max_stack", 0))

func add_item(item_id: String, amount: int) -> int:
	if not ItemDefinitions.has_item(item_id):
		return 0
	var item_data: Dictionary = ItemDefinitions.get_item_data(item_id)
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
