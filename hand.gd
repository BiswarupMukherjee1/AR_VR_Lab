extends XRController3D
class_name Hand

# Code shared by both hands. Each hand has its own script (left_hand.gd,
# right_hand.gd) that extends this one with "extends Hand".

var area: Area3D

func _ready():
	area = $Area3D
