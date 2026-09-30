extends XRController3D
class_name Hand

# Name of the action (see the "OpenXR Action Map" tab) that grabs objects.
@export var grab_action: StringName = &"grip_click"
# Extra rotation (in degrees) applied to a grabbed object, relative to the hand.
# The hands follow the OpenXR "grip" pose, whose -Z axis goes through the fist,
# from the little finger to the thumb. The bat is modelled along +Y, so rotating
# it by -90 degrees around X makes it come out of the fist like a real bat.
# If the bat feels tilted in the headset, tune this value.
@export var grab_rotation_degrees := Vector3(-90, 0, 0)

var area: Area3D
# The object currently held by this hand (the root node of the pickable), if any.
var picked: Node3D = null


func _ready():
	area = $Area3D
	button_pressed.connect(_on_button_pressed)
	button_released.connect(_on_button_released)


func _on_button_pressed(action_name: String):
	if action_name == grab_action:
		grab()


func _on_button_released(action_name: String):
	if action_name == grab_action:
		drop()


func grab():
	if picked != null:
		return
	# Look for a pickable that currently touches this hand.
	for other in area.get_overlapping_areas():
		if other.is_in_group("pickable"):
			# The Area3D is the Handle, the object to move is its parent.
			var object = other.get_parent()
			# If the other hand is holding it, take it from that hand.
			var previous_holder = object.get_parent()
			if previous_holder is Hand:
				previous_holder.picked = null
			# Make the object a child of the hand so it follows every movement.
			object.reparent(self)
			object.transform = Transform3D(
				Basis.from_euler(grab_rotation_degrees * (PI / 180.0)), Vector3.ZERO)
			picked = object
			return


func drop():
	if picked == null:
		return
	# Put the object back in the main scene, exactly where it currently is.
	picked.reparent(get_tree().current_scene)
	picked = null
