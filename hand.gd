extends XRController3D
class_name Hand

# Code shared by both hands: the ray (RayCast3D + red cylinder), the pointer,
# and the trigger. Each hand has its own script (left_hand.gd, right_hand.gd)
# that extends this one with "extends Hand", and decides what the trigger does
# by overriding on_trigger_clicked() and on_trigger_released().
#
# Each hand needs, in xr_origin_3d.tscn:
#   Area3D, RayCast3D, and RayCast3D/RayVisual (a Node3D holding the red cylinder).
# What a ray can hit is set on its RayCast3D (Collision Mask), not here.

# The red sphere shown where the ray hits something.
const POINTER_SCENE = preload("res://pointer.tscn")

var area: Area3D
var ray: RayCast3D
# Parent of the red cylinder. Scaling it along z sets the length of the visible ray.
var ray_visual: Node3D
var pointer: Node3D

var trigger_touched := false
var trigger_pressed := false


func _ready():
	area = $Area3D
	ray = $RayCast3D
	ray_visual = $RayCast3D/RayVisual
	ray_visual.visible = false

	pointer = POINTER_SCENE.instantiate()
	# top_level: the pointer is placed in world coordinates, it does not follow the hand.
	pointer.top_level = true
	pointer.visible = false
	add_child(pointer)

	button_pressed.connect(_on_button_pressed)
	button_released.connect(_on_button_released)


func _on_button_pressed(action_name: String):
	if action_name == "trigger_touch":
		trigger_touched = true
	elif action_name == "trigger_click":
		trigger_pressed = true
		on_trigger_clicked()
	update_ray_visibility()


func _on_button_released(action_name: String):
	if action_name == "trigger_touch":
		trigger_touched = false
	elif action_name == "trigger_click":
		trigger_pressed = false
		on_trigger_released()
	update_ray_visibility()


# What the trigger does. Empty here: each hand overrides these two functions.
func on_trigger_clicked():
	pass


func on_trigger_released():
	pass


func update_ray_visibility():
	# On the Quest, pressing the trigger always means touching it too. The simulator
	# sends trigger_click without trigger_touch, so a press also shows the ray.
	ray_visual.visible = trigger_touched or trigger_pressed


func _process(_delta):
	update_ray_and_pointer()


func update_ray_and_pointer():
	# Recompute the ray now, with the hand's position of this frame.
	ray.force_raycast_update()
	var collider = ray.get_collider()

	# The visible ray stops where it hits something, otherwise it has its full length.
	var length := ray.target_position.length()
	if collider != null:
		length = ray.global_position.distance_to(ray.get_collision_point())
	ray_visual.scale.z = maxf(length, 0.01)  # a scale of 0 would break the transform

	# The pointer is shown only if the ray is visible AND has a collider.
	pointer.visible = ray_visual.visible and collider != null
	if pointer.visible:
		pointer.global_position = ray.get_collision_point()
