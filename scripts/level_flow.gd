extends Node

const LEVEL_SELECT_SCENE_PATH := "res://scenes/menus/level_select.tscn"
const GAMEPLAY_SCENE_PATH := "res://scenes/main.tscn"
const DEFAULT_LEVEL_PATH := "res://scenes/levels/arena/arena_level.tscn"

const LEVELS := [
	{
		"id": "arena",
		"title": "Training Yard",
		"subtitle": "Original survival arena with stations, pickups, and compact lanes.",
		"scene_path": "res://scenes/levels/arena/arena_level.tscn"
	},
	{
		"id": "forest_facility",
		"title": "Forest Facility",
		"subtitle": "Remote woodland compound with long sightlines and facility choke points.",
		"scene_path": "res://scenes/levels/forest_facility/forest_facility_level.tscn"
	}
]

var current_level_path: String = DEFAULT_LEVEL_PATH

func get_level_entries() -> Array[Dictionary]:
	var levels: Array[Dictionary] = []
	for entry in LEVELS:
		levels.append(entry.duplicate(true))
	return levels

func start_level(scene_path: String) -> void:
	current_level_path = _resolve_level_path(scene_path)
	_change_scene(GAMEPLAY_SCENE_PATH)

func restart_current_level() -> void:
	current_level_path = _resolve_level_path(current_level_path)
	_change_scene(GAMEPLAY_SCENE_PATH)

func return_to_level_select() -> void:
	_change_scene(LEVEL_SELECT_SCENE_PATH)

func instantiate_current_level(parent: Node) -> Node:
	if parent == null:
		return null

	for child in parent.get_children():
		child.queue_free()

	var level_path: String = _resolve_level_path(current_level_path)
	var level_scene := load(level_path) as PackedScene
	if level_scene == null:
		push_error("LevelFlow: failed to load level '%s'." % level_path)
		return null

	var level_instance := level_scene.instantiate()
	parent.add_child(level_instance)
	return level_instance

func _change_scene(scene_path: String) -> void:
	var tree: SceneTree = get_tree()
	if tree == null:
		return

	tree.paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if scene_path == LEVEL_SELECT_SCENE_PATH else Input.MOUSE_MODE_CAPTURED
	tree.change_scene_to_file(scene_path)

func _resolve_level_path(scene_path: String) -> String:
	if not scene_path.is_empty() and ResourceLoader.exists(scene_path):
		return scene_path
	return DEFAULT_LEVEL_PATH
