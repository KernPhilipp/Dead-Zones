extends RefCounted
class_name ItemDefinitions

const ORDER: Array[String] = ["medkit", "armor_plate", "grenade"]

const ITEMS := {
	"medkit": {
		"display_name": "Medkit",
		"max_stack": 3,
		"effect_type": "heal",
		"effect_value": 35,
		"buy_cost": 90,
		"unlock_kills": 0,
	},
	"armor_plate": {
		"display_name": "Armor Plate",
		"max_stack": 4,
		"effect_type": "armor",
		"effect_value": 35,
		"buy_cost": 125,
		"unlock_kills": 75,
	},
	"grenade": {
		"display_name": "Grenade",
		"max_stack": 3,
		"effect_type": "grenade",
		"effect_value": 1,
		"buy_cost": 175,
		"unlock_kills": 120,
	},
}

static func has_item(item_id: String) -> bool:
	return ITEMS.has(item_id)

static func get_item_ids() -> Array[String]:
	return ORDER.duplicate()

static func get_item_data(item_id: String) -> Dictionary:
	var resolved_id: String = item_id if has_item(item_id) else "medkit"
	return Dictionary(ITEMS[resolved_id]).duplicate(true)

static func get_display_name(item_id: String) -> String:
	return String(get_item_data(item_id).get("display_name", item_id.capitalize()))

static func get_unlock_threshold(item_id: String) -> int:
	return int(get_item_data(item_id).get("unlock_kills", 0))
