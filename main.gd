extends Node

@export var mob_scene: PackedScene

@onready var xr_origin = $XROrigin3D
@onready var score_label = $ScoreLabel3D
@onready var restart_button = $RestartButton


func _ready():
	xr_origin.hit.connect(_on_player_hit)
	restart_button.pressed.connect(_on_restart_button_pressed)


func _on_mob_timer_timeout():
	# Create a new instance of the Mob scene.
	var mob = mob_scene.instantiate()

	# Choose a random location on the SpawnPath.
	# We store the reference to the SpawnLocation node.
	var mob_spawn_location = get_node("SpawnPath/SpawnLocation")
	# And give it a random offset.
	mob_spawn_location.progress_ratio = randf()

	var player_position = xr_origin.position
	mob.initialize(mob_spawn_location.position, player_position)

	# Spawn the mob by adding it to the Main scene.
	add_child(mob)

	# We connect the mob to the score label to update the score upon squashing one.
	mob.squashed.connect(score_label._on_mob_squashed)


func _on_player_hit():
	$MobTimer.stop()
	# Show the restart button in front of the player.
	restart_button.appear_in_front_of($XROrigin3D/XRCamera3D)


func _on_restart_button_pressed():
	# This restarts the current scene. We are inside a physics callback (a hand
	# touched the button), so the reload is deferred to the end of the frame.
	get_tree().call_deferred("reload_current_scene")
