extends Control

@onready var level_button_one: Button = $MenuCard/MarginContainer/VBoxContainer/LevelOptionOneButton
@onready var level_description_one: Label = $MenuCard/MarginContainer/VBoxContainer/LevelOptionOneDescription
@onready var level_button_two: Button = $MenuCard/MarginContainer/VBoxContainer/LevelOptionTwoButton
@onready var level_description_two: Label = $MenuCard/MarginContainer/VBoxContainer/LevelOptionTwoDescription

func _ready():
	get_tree().paused = false
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	var level_buttons: Array[Button] = [level_button_one, level_button_two]
	var level_descriptions: Array[Label] = [level_description_one, level_description_two]
	var levels: Array[Dictionary] = LevelFlow.get_level_entries()

	for index in range(level_buttons.size()):
		var button: Button = level_buttons[index]
		var description: Label = level_descriptions[index]
		if index >= levels.size():
			button.visible = false
			description.visible = false
			continue

		var level_entry: Dictionary = levels[index]
		var scene_path: String = String(level_entry.get("scene_path", ""))
		button.text = String(level_entry.get("title", "UNKNOWN LEVEL"))
		description.text = String(level_entry.get("subtitle", ""))
		button.pressed.connect(func():
			LevelFlow.start_level(scene_path)
		)
		button.mouse_entered.connect(_on_button_hover)
		button.pressed.connect(_on_button_pressed)

	if not level_buttons.is_empty():
		level_buttons[0].grab_focus()

func _on_button_hover():
	AudioManager.play_ui("ui_button_hover")

func _on_button_pressed():
	AudioManager.play_ui("ui_button_click")
