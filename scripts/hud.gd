extends CanvasLayer

@onready var health_label: Label = $HealthLabel
@onready var ammo_label: Label = $AmmoLabel
@onready var game_over_panel: PanelContainer = $GameOverPanel
@onready var restart_button: Button = $GameOverPanel/VBoxContainer/RestartButton
@onready var pause_panel: PanelContainer = $PausePanel
@onready var resume_button: Button = $PausePanel/VBoxContainer/ResumeButton
@onready var handbook_button: Button = $PausePanel/VBoxContainer/HandbookButton
@onready var settings_button: Button = $PausePanel/VBoxContainer/SettingsButton
@onready var quit_button: Button = $PausePanel/VBoxContainer/QuitButton
@onready var settings_hint_label: Label = $PausePanel/VBoxContainer/SettingsHintLabel
@onready var handbook_book: Control = $HandbookBook

var is_game_over: bool = false

func _ready():
	game_over_panel.visible = false
	pause_panel.visible = false
	settings_hint_label.visible = false
	restart_button.pressed.connect(_on_restart)
	resume_button.pressed.connect(_on_resume)
	handbook_button.pressed.connect(_on_handbook)
	settings_button.pressed.connect(_on_settings)
	quit_button.pressed.connect(_on_quit)

func update_health(value: int):
	health_label.text = "HP: " + str(value)

func update_ammo(current: int, max_val: int):
	ammo_label.text = "Ammo: " + str(current) + "/" + str(max_val)

func show_game_over():
	is_game_over = true
	_close_handbook()
	_close_pause_menu()
	game_over_panel.visible = true

func _on_restart():
	is_game_over = false
	_close_handbook()
	get_tree().paused = false
	pause_panel.visible = false
	get_tree().reload_current_scene()

func _unhandled_input(event: InputEvent):
	if is_game_over:
		return

	if event is InputEventKey and event.pressed and not event.echo:
		var key_event := event as InputEventKey
		if _is_handbook_open():
			if key_event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
				_close_handbook()
				get_viewport().set_input_as_handled()
			return

		if key_event.keycode == KEY_B:
			_open_handbook()
			get_viewport().set_input_as_handled()
			return

		if key_event.keycode == KEY_ESCAPE or event.is_action_pressed("ui_cancel"):
			if pause_panel.visible:
				_close_pause_menu()
			else:
				_open_pause_menu()
			get_viewport().set_input_as_handled()

func _open_pause_menu():
	pause_panel.visible = true
	settings_hint_label.visible = false
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func _close_pause_menu():
	_close_handbook()
	pause_panel.visible = false
	settings_hint_label.visible = false
	get_tree().paused = false
	if not is_game_over:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _on_resume():
	_close_pause_menu()

func _on_handbook():
	_open_handbook()

func _on_settings():
	settings_hint_label.visible = true

func _on_quit():
	get_tree().quit()

func _open_handbook():
	if is_game_over:
		return
	_open_pause_menu()
	settings_hint_label.visible = false
	pause_panel.visible = false
	if handbook_book and handbook_book.has_method("open_book"):
		handbook_book.call("open_book")

func _close_handbook():
	if handbook_book and handbook_book.has_method("is_open") and handbook_book.call("is_open"):
		handbook_book.call("close_book")
	if not is_game_over and get_tree().paused:
		pause_panel.visible = true

func _is_handbook_open() -> bool:
	if handbook_book and handbook_book.has_method("is_open"):
		return bool(handbook_book.call("is_open"))
	return false
