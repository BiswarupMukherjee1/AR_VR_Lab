extends Hand

# The right hand is the manipulation hand:
#  - touching the trigger shows a red ray, and a red pointer where the ray hits,
#  - pressing the trigger while pointing at the button clicks it,
#  - pressing the trigger while pointing at a pickable object grabs it (Go-Go):
#    while the trigger is held, the object stays on the ray at the same depth,
#    and the joystick moves it along the ray (up = further, down = closer).

# Speed (in m/s) at which the joystick moves a grabbed object along the ray.
@export var depth_speed := 2.0
# Closest and farthest distance (in m) between the hand and a grabbed object.
@export var min_depth := 0.3
@export var max_depth := 10.0
# Joystick values smaller than this are ignored (a stick is never perfectly centred).
@export var joystick_deadzone := 0.2

# The red sphere shown where the ray hits something.
const POINTER_SCENE = preload("res://pointer.tscn")

@onready var ray: RayCast3D = $RayCast3D
# Parent of the red cylinder. Scaling it along z sets the length of the visible ray.
@onready var ray_visual: Node3D = $RayCast3D/RayVisual

var pointer: Node3D

var trigger_touched := false
var trigger_pressed := false

# The grabbed object, its distance along the ray, and its offset from the point
# where the ray hit it (in the ray's own axes, so the object does not jump when grabbed).
var grabbed: Node3D = null
var grab_depth := 0.0
var grab_offset := Vector3.ZERO


func _ready():
	super()  # runs the _ready() of hand.gd
	pointer = POINTER_SCENE.instantiate()
	# top_level: the pointer is placed in world coordinates, it does not follow the hand.
	pointer.top_level = true
	pointer.visible = false
	add_child(pointer)
	ray_visual.visible = false
	button_pressed.connect(_on_button_pressed)
	button_released.connect(_on_button_released)


func _on_button_pressed(action_name: String):
	if action_name == "trigger_touch":
		trigger_touched = true
	elif action_name == "trigger_click":
		trigger_pressed = true
		click()
	update_ray_visibility()


func _on_button_released(action_name: String):
	if action_name == "trigger_touch":
		trigger_touched = false
	elif action_name == "trigger_click":
		trigger_pressed = false
		release()
	update_ray_visibility()


func update_ray_visibility():
	# On the Quest, pressing the trigger always means touching it too. The simulator
	# sends trigger_click without trigger_touch, so a press also shows the ray.
	ray_visual.visible = trigger_touched or trigger_pressed


func _process(delta):
	if is_instance_valid(grabbed):
		move_grabbed(delta)
	update_ray_and_pointer()


func update_ray_and_pointer():
	# Recompute the ray now, with the hand's position of this frame.
	ray.force_raycast_update()
	var collider = ray.get_collider()

	# The visible ray stops where it hits something, otherwise it is 10 m long.
	var length := ray.target_position.length()
	if collider != null:
		length = ray.global_position.distance_to(ray.get_collision_point())
	ray_visual.scale.z = maxf(length, 0.01)  # a scale of 0 would break the transform

	# The pointer is shown only if the ray is visible AND has a collider.
	pointer.visible = ray_visual.visible and collider != null
	if pointer.visible:
		pointer.global_position = ray.get_collision_point()


func click():
	ray.force_raycast_update()
	var collider = ray.get_collider()
	if collider == null:
		return
	# Check what the collider is before using it: only buttons have a "clicked" signal.
	if collider.is_in_group("button") and collider.has_signal("clicked"):
		collider.clicked.emit()
	elif collider.is_in_group("pickable"):
		grab(collider, ray.get_collision_point())


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
