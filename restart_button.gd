extends Node3D

# Emitted when a hand pushes the button.
signal pressed

# Seconds during which the button ignores hands after it appears, so that a hand
# that happens to be there when the player dies does not press it by accident.
@export var arming_delay = 1.0
# Distance (in meters) in front of the player where the button appears.
@export var distance = 1.0

@onready var head = $Head
@onready var press_area = $PressArea

var head_rest_y = 0.0


func _ready():
	head_rest_y = head.position.y
	press_area.area_entered.connect(_on_press_area_area_entered)
	press_area.area_exited.connect(_on_press_area_area_exited)
	disappear()


func disappear():
	visible = false
	# Hiding a node does not stop its collisions, so we also switch detection off.
	press_area.set_deferred("monitoring", false)


func appear_in_front_of(camera: Node3D):
	# Direction the player is looking at, flattened onto the floor.
	var forward = -camera.global_transform.basis.z
	forward.y = 0.0
	if forward.length() < 0.001:
		forward = Vector3.FORWARD
	forward = forward.normalized()

	# Stand on the floor (y = 0), in front of the player, with the sign facing them.
	var camera_position = camera.global_position
	global_transform = Transform3D(
		Basis.looking_at(forward),
		Vector3(camera_position.x, 0.0, camera_position.z) + forward * distance)
	visible = true

	# Only let hands press the button after a short delay.
	await get_tree().create_timer(arming_delay).timeout
	press_area.monitoring = true


func _on_press_area_area_entered(other):
	if other.get_parent() is Hand:
		create_tween().tween_property(head, "position:y", head_rest_y - 0.03, 0.05)
		pressed.emit()


func _on_press_area_area_exited(other):
	if other.get_parent() is Hand:
		create_tween().tween_property(head, "position:y", head_rest_y, 0.1)
