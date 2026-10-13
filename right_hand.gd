extends Hand

# The right hand is the manipulation hand. The ray and the pointer come from hand.gd;
# here we only decide what the trigger does:
#  - pressing the trigger while pointing at the button clicks it,
#  - pressing the trigger while pointing at a pickable object grabs it (Go-Go):
#    while the trigger is held, the object stays on the ray at the same depth,
#    and the joystick moves it along the ray (up = further, down = closer).
# Its RayCast3D only hits layer 3 (interactable: the button and the cube).

# Speed (in m/s) at which the joystick moves a grabbed object along the ray.
@export var depth_speed := 2.0
# Closest and farthest distance (in m) between the hand and a grabbed object.
@export var min_depth := 0.3
@export var max_depth := 10.0
# Joystick values smaller than this are ignored (a stick is never perfectly centred).
@export var joystick_deadzone := 0.2

# The grabbed object, its distance along the ray, and its offset from the point
# where the ray hit it (in the ray's own axes, so the object does not jump when grabbed).
var grabbed: Node3D = null
var grab_depth := 0.0
var grab_offset := Vector3.ZERO


func _process(delta):
	# Move the grabbed object first, so the ray and pointer (in super) see its new position.
	if is_instance_valid(grabbed):
		move_grabbed(delta)
	super(delta)  # hand.gd: update the ray and the pointer


func on_trigger_clicked():
	ray.force_raycast_update()
	var collider = ray.get_collider()
	if collider == null:
		return
	# Check what the collider is before using it: only buttons have a "clicked" signal.
	if collider.is_in_group("button") and collider.has_signal("clicked"):
		collider.clicked.emit()
	elif collider.is_in_group("pickable"):
		grab(collider, ray.get_collision_point())


func on_trigger_released():
	release()


func grab(object: Node3D, hit_point: Vector3):
	grabbed = object
	grab_depth = ray.global_position.distance_to(hit_point)
	grab_offset = ray.global_basis.inverse() * (object.global_position - hit_point)


func release():
	# The object simply stays where it is (it is an Area3D, gravity does not move it).
	grabbed = null


func move_grabbed(delta):
	# Joystick up (y > 0) pushes the object away, joystick down brings it closer.
	var joystick := get_vector2("primary")
	if absf(joystick.y) > joystick_deadzone:
		grab_depth = clampf(grab_depth + joystick.y * depth_speed * delta, min_depth, max_depth)

	# Keep the object on the ray, at grab_depth from the hand.
	var direction := (ray.global_basis * ray.target_position).normalized()
	var point_on_ray := ray.global_position + direction * grab_depth
	grabbed.global_position = point_on_ray + ray.global_basis * grab_offset
