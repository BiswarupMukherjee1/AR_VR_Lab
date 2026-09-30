extends Node3D

# The bat is made of two Area3D nodes:
# - Handle: what the hands grab (it is in the "pickable" group).
# - Body: the part that hits things. It only detects the "enemies" layer.


func _ready():
	$Body.body_entered.connect(_on_body_body_entered)


func _on_body_body_entered(body):
	# Same idea as the player jumping on a mob in Squash the Creeps.
	if body.is_in_group("mob"):
		body.squash()
