extends CharacterBody3D

# Minimum speed of the mob in meters per second.
# (10 in Squash the Creeps: far too fast to hit with a bat in VR.)
@export var min_speed = 3
# Maximum speed of the mob in meters per second.
# (18 in Squash the Creeps.)
@export var max_speed = 6
# The mob is deleted when it gets this far from the center of the arena.
@export var max_distance = 40.0

# Emitted when the bat hits the mob
signal squashed

func _physics_process(_delta):
	move_and_slide()
	# In Squash the Creeps, mobs were deleted when they left the screen.
	# In VR the player can turn their head, so a mob would disappear as soon as
	# the player looks away. Instead, we delete mobs that left the arena.
	if position.length() > max_distance:
		queue_free()

# This function will be called from the Main scene.
func initialize(start_position, player_position):
	# We position the mob by placing it at start_position
	# and rotate it towards player_position, so it looks at the player.
	look_at_from_position(start_position, player_position, Vector3.UP)
	# Rotate this mob randomly within range of -5 and +5 degrees.
	# In VR the player faces one direction and does not move, so the mobs
	# must come at them almost head-on (it was -45/+45 in Squash the Creeps).
	rotate_y(randf_range(-PI / 36, PI / 36))

	# We calculate a random speed (integer)
	var random_speed = randi_range(min_speed, max_speed)
	# We calculate a forward velocity that represents the speed.
	velocity = Vector3.FORWARD * random_speed
	# We then rotate the velocity vector based on the mob's Y rotation
	# in order to move in the direction the mob is looking.
	velocity = velocity.rotated(Vector3.UP, rotation.y)

func squash():
	squashed.emit()
	queue_free() # Destroy this node
