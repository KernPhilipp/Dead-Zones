extends CanvasLayer

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton

func _ready():
	game_over_panel.visible = false
	restart_button.pressed.connect(_on_restart)

func update_health(value: int):
	health_label.text = "HP: " + str(value)

func update_ammo(current: int, max_val: int):
	ammo_label.text = "Ammo: " + str(current) + "/" + str(max_val)

func show_game_over():
	game_over_panel.visible = true

func _on_restart():
	get_tree().paused = false
	get_tree().reload_current_scene()
