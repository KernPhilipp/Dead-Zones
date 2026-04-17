extends Control

const GAME_SCENE := "res://scenes/main.tscn"
const BG_COLOR := Color(0.07, 0.07, 0.08, 1.0)
const ACCENT_COLOR := Color(0.8, 0.15, 0.15, 1.0)
const TEXT_COLOR := Color(0.95, 0.93, 0.88, 1.0)
const DIM_COLOR := Color(0.55, 0.53, 0.50, 1.0)
const DEFAULT_SERVER_URL := "ws://localhost:9080"

@onready var _net: Node = get_node("/root/NetworkManager")
@onready var _lobby: Node = get_node("/root/LobbyManager")

var _view: String = "main"  # main | hosting | joining

var _lbl_title: Label
var _lbl_status: Label
var _lbl_room_code: Label
var _lbl_players: Label
var _btn_host: Button
var _btn_join: Button
var _btn_solo: Button
var _btn_start: Button
var _btn_ready: Button
var _btn_back: Button
var _input_url: LineEdit
var _input_name: LineEdit
var _panel_lobby: VBoxContainer
var _panel_main: VBoxContainer

func _ready():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_build_ui()
	_connect_signals()
	_show_main()

func _build_ui():
	var bg := ColorRect.new()
	bg.color = BG_COLOR
	bg.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(bg)

	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	add_child(center)

	var outer := VBoxContainer.new()
	outer.custom_minimum_size = Vector2(460, 0)
	outer.add_theme_constant_override("separation", 20)
	center.add_child(outer)

	_lbl_title = _make_label("DEAD ZONES", 36, TEXT_COLOR)
	_lbl_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	outer.add_child(_lbl_title)

	_lbl_status = _make_label("", 14, DIM_COLOR)
	_lbl_status.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_lbl_status.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	outer.add_child(_lbl_status)

	var name_row := HBoxContainer.new()
	name_row.add_theme_constant_override("separation", 8)
	outer.add_child(name_row)
	var name_lbl := _make_label("Name:", 14, DIM_COLOR)
	name_lbl.custom_minimum_size.x = 60
	name_row.add_child(name_lbl)
	_input_name = LineEdit.new()
	_input_name.placeholder_text = "Spielername"
	_input_name.text = "Player"
	_input_name.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_row.add_child(_input_name)

	_panel_main = VBoxContainer.new()
	_panel_main.add_theme_constant_override("separation", 12)
	outer.add_child(_panel_main)
	_btn_host = _make_button("Spiel hosten")
	_panel_main.add_child(_btn_host)
	_btn_join = _make_button("Spiel beitreten")
	_panel_main.add_child(_btn_join)
	_btn_solo = _make_button("Solo spielen")
	_panel_main.add_child(_btn_solo)

	_panel_lobby = VBoxContainer.new()
	_panel_lobby.add_theme_constant_override("separation", 12)
	_panel_lobby.visible = false
	outer.add_child(_panel_lobby)

	var url_row := HBoxContainer.new()
	url_row.add_theme_constant_override("separation", 8)
	_panel_lobby.add_child(url_row)
	var url_lbl := _make_label("Server-URL:", 14, DIM_COLOR)
	url_lbl.custom_minimum_size.x = 90
	url_row.add_child(url_lbl)
	_input_url = LineEdit.new()
	_input_url.placeholder_text = DEFAULT_SERVER_URL
	_input_url.text = DEFAULT_SERVER_URL
	_input_url.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	url_row.add_child(_input_url)

	_lbl_room_code = _make_label("", 22, ACCENT_COLOR)
	_lbl_room_code.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_panel_lobby.add_child(_lbl_room_code)

	_lbl_players = _make_label("Spieler:", 14, TEXT_COLOR)
	_lbl_players.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_panel_lobby.add_child(_lbl_players)

	var btn_connect := _make_button("Verbinden")
	btn_connect.pressed.connect(_on_connect_button_pressed)
	_panel_lobby.add_child(btn_connect)

	_btn_ready = _make_button("Bereit")
	_panel_lobby.add_child(_btn_ready)
	_btn_start = _make_button("Spiel starten")
	_btn_start.visible = false
	_panel_lobby.add_child(_btn_start)
	_btn_back = _make_button("Zurück")
	_panel_lobby.add_child(_btn_back)

func _connect_signals():
	_btn_host.pressed.connect(_on_host_pressed)
	_btn_join.pressed.connect(_on_join_pressed)
	_btn_solo.pressed.connect(_on_solo_pressed)
	_btn_ready.pressed.connect(_on_ready_pressed)
	_btn_start.pressed.connect(_on_start_pressed)
	_btn_back.pressed.connect(_on_back_pressed)

	_net.connected_to_server.connect(_on_connected_to_server)
	_net.connection_failed.connect(_on_connection_failed)
	_net.server_disconnected.connect(_on_server_disconnected)
	_lobby.lobby_updated.connect(_on_lobby_updated)
	_lobby.game_starting.connect(_on_game_starting)

func _show_main():
	_view = "main"
	_panel_main.visible = true
	_panel_lobby.visible = false
	_input_url.visible = false
	_lbl_status.text = ""

func _show_hosting():
	_view = "hosting"
	_panel_main.visible = false
	_panel_lobby.visible = true
	_input_url.visible = false
	_btn_start.visible = true
	_btn_ready.visible = false
	_lbl_room_code.text = "Raumcode: %s" % _lobby.room_code
	_lbl_status.text = "Warte auf Mitspieler…"

func _show_joining():
	_view = "joining"
	_panel_main.visible = false
	_panel_lobby.visible = true
	_input_url.visible = true
	_btn_start.visible = false
	_btn_ready.visible = true
	_lbl_room_code.text = ""
	_lbl_status.text = "Verbinden…"

func _on_host_pressed():
	var player_name := _input_name.text.strip_edges()
	if player_name.is_empty():
		player_name = "Host"
	_lobby.host_lobby(player_name)
	var err: Error = _net.host_game()
	if err != OK:
		_lbl_status.text = "Fehler beim Starten des Servers: %s" % error_string(err)
		return
	var code: String = _lobby.generate_room_code()
	print("Lobby room code: %s" % code)
	_show_hosting()
	_on_lobby_updated(_lobby.players)

func _on_join_pressed():
	_show_joining()

func _on_solo_pressed():
	get_tree().change_scene_to_file(GAME_SCENE)

func _on_ready_pressed():
	var is_ready: bool = _btn_ready.text == "Bereit"
	_lobby.send_ready(is_ready)
	_btn_ready.text = "Nicht bereit" if is_ready else "Bereit"

func _on_start_pressed():
	_lobby.start_game()

func _on_back_pressed():
	_net.disconnect_all()
	_lobby.players.clear()
	_show_main()

func _on_connect_button_pressed():
	var player_name := _input_name.text.strip_edges()
	if player_name.is_empty():
		player_name = "Player"
	_lobby.join_lobby(player_name)
	var url := _input_url.text.strip_edges()
	if url.is_empty():
		url = DEFAULT_SERVER_URL
	var err: Error = _net.join_game(url)
	if err != OK:
		_lbl_status.text = "Verbindungsfehler: %s" % error_string(err)

func _on_connected_to_server():
	_lbl_status.text = "Verbunden! Warte auf Lobby…"
	_lobby.on_connected_to_server()

func _on_connection_failed():
	_lbl_status.text = "Verbindung fehlgeschlagen."

func _on_server_disconnected():
	_lbl_status.text = "Verbindung zum Server verloren."
	_show_main()

func _on_lobby_updated(lobby_players: Dictionary):
	var lines: PackedStringArray = []
	for pid in lobby_players:
		var p: Dictionary = lobby_players[pid]
		var ready_tag := " ✓" if p.get("ready", false) else ""
		lines.append("• %s%s" % [p.get("name", "?"), ready_tag])
	_lbl_players.text = "Spieler (%d/4):\n%s" % [lobby_players.size(), "\n".join(lines)]

	if _view == "hosting":
		_btn_start.disabled = lobby_players.size() < 1

func _on_game_starting():
	get_tree().change_scene_to_file(GAME_SCENE)

func _process(_delta: float):
	if _view == "joining" and _input_url.visible:
		pass

func _make_label(text: String, size: int, color: Color) -> Label:
	var lbl := Label.new()
	lbl.text = text
	lbl.add_theme_font_size_override("font_size", size)
	lbl.add_theme_color_override("font_color", color)
	return lbl

func _make_button(text: String) -> Button:
	var btn := Button.new()
	btn.text = text
	btn.custom_minimum_size = Vector2(0, 42)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	return btn
