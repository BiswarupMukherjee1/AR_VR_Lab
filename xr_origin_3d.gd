extends Node3D

# Emitted when a mob touches the player.
signal hit

var xr_interface: XRInterface
var is_dead = false

@onready var body = $Body
@onready var right_hand = $RightHand


func _ready():
	xr_interface = XRServer.find_interface("OpenXR")
	if xr_interface and xr_interface.is_initialized():
		print("OpenXR initialized successfully")

		# Turn off v-sync!
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)

		# Change our main viewport to output to the HMD
		get_viewport().use_xr = true
	else:
		print("OpenXR not initialized, please check if your headset is connected")
		# No headset: simulate one with the mouse and keyboard (XR Input Simulator addon).
		print("Connecting XRSimulator")
		var xr_simulator_scene = load("res://addons/xr-simulator/XRSimulator.tscn")
		var xr_simulator = xr_simulator_scene.instantiate()
		add_child(xr_simulator)

	body.body_entered.connect(_on_body_body_entered)
	right_hand.button_pressed.connect(_on_right_hand_button_pressed)


func _on_body_body_entered(other):
	if is_dead:
		return
	if other.is_in_group("mob"):
		die()


func die():
	# We do NOT delete this node: it also holds the camera, and the game would freeze.
	is_dead = true
	hit.emit()


func _on_right_hand_button_pressed(action_name: String):
	# Once the player is dead (the MobTimer is stopped), the trigger restarts the game.
	if is_dead and action_name == "trigger_click":
		get_tree().call_deferred("reload_current_scene")
