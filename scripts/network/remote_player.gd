extends Node3D

# Lightweight visual representation of a remote player.
# Attach to any Node3D that has been spawned for a remote peer.
# The MultiplayerSynchronizer on the player.tscn replicates position/rotation;
# this script handles the nameplate label above the head.

@export var player_name: String = "Player"

var _nameplate: Label3D = null

func _ready():
	if is_multiplayer_authority():
		# We are the owner of this node — no ghost needed
		return
	_create_nameplate()

func _create_nameplate():
	_nameplate = Label3D.new()
	_nameplate.text = player_name
	_nameplate.pixel_size = 0.005
	_nameplate.position = Vector3(0, 2.2, 0)
	_nameplate.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_nameplate.modulate = Color(0.9, 0.85, 0.75, 1.0)
	add_child(_nameplate)

func set_player_name(new_name: String):
	player_name = new_name
	if _nameplate != null:
		_nameplate.text = new_name
