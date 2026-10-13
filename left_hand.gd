extends Hand

# The left hand is the navigation hand:
#  - joystick up/down: move forward/backward in the direction the camera is facing,
#  - joystick left/right: turn the point of view (by steps if snap_turn is on,
#    continuously if it is off),
#  - while moving, the VectionReductor (vignette) hides the peripheral vision,
#  - trigger: teleport to the point of the ground the ray is pointing at.
# The ray and the pointer come from hand.gd. Its RayCast3D only hits layer 2 (ground).

# Movement speed in m/s, at full joystick.
@export var translation_speed := 2.0
# Continuous turning speed in degrees per second (only used when snap_turn is off).
@export var rotation_speed := 60.0
# Vection reduction for rotation: turn by fixed steps instead of continuously.
@export var snap_turn := true
# Size of one step, in degrees.
@export var snap_angle := 30.0
# Vection reduction for translation: show the vignette while moving.
@export var use_vignette := true
# Joystick values smaller than this are ignored (a stick is never perfectly centred).
@export var joystick_deadzone := 0.2

@onready var origin: XROrigin3D = get_parent()
@onready var camera: XRCamera3D = get_parent().get_node("XRCamera3D")
@onready var vignette: Node3D = get_parent().get_node("XRCamera3D/VectionReductor")

# Snap turn: true after a step, until the joystick goes back to the centre.
# The user must let go of the joystick before turning again.
var snap_done := false


func _process(delta):
	# Move the player first, so the ray and pointer (in super) use the new position.
	navigate(delta)
	super(delta)  # hand.gd: update the ray and the pointer


func navigate(delta):
	# x = left/right (-1..1), y = down/up (-1..1)
	var joystick := get_vector2("primary")
	var moving := false

	# Forward / backward
	if absf(joystick.y) > joystick_deadzone:
		move_forward(joystick.y * translation_speed * delta)
		moving = true

	# Turning (joystick right = turn right = negative angle around the vertical axis)
	if snap_turn:
		if absf(joystick.x) > 0.5 and not snap_done:
			turn(-signf(joystick.x) * deg_to_rad(snap_angle))
			snap_done = true
		elif absf(joystick.x) < joystick_deadzone:
			snap_done = false
	elif absf(joystick.x) > joystick_deadzone:
		turn(-joystick.x * deg_to_rad(rotation_speed) * delta)
		moving = true

	# The vignette is hidden by default, and visible only while moving continuously.
	vignette.visible = use_vignette and moving


func move_forward(distance: float):
	# The direction the camera is facing is -Z of its basis.
	var forward := -camera.global_basis.z
	# Stay on the ground: ignore the up/down part (looking up must not make you fly).
	forward.y = 0.0
	if forward.length() < 0.001:
		return  # looking straight up or down: no horizontal direction
	# To move the player, we move XROrigin3D (the camera and hands follow, they are its children).
	origin.global_position += forward.normalized() * distance


func turn(angle: float):
	# Rotate XROrigin3D around the vertical axis passing through the camera (the
	# player's head), not around the origin's centre: otherwise, if the player is not
	# standing exactly on the origin, turning would also move them sideways.
	var pivot := camera.global_position
	var t := origin.global_transform
	t.origin -= pivot
	t = t.rotated(Vector3.UP, angle)
	t.origin += pivot
	origin.global_transform = t


func on_trigger_clicked():
	ray.force_raycast_update()
	if ray.get_collider() == null:
		return
	# Only teleport onto flat ground (the normal points up), not onto a vertical side.
	if ray.get_collision_normal().y < 0.7:
		return
	teleport(ray.get_collision_point())


func teleport(target: Vector3):
	# Move XROrigin3D so that the player's head ends up right above the target point,
	# and the origin (the floor of the play space) at the height of the target.
	var head := camera.global_position
	origin.global_position += Vector3(target.x - head.x, target.y - origin.global_position.y, target.z - head.z)
