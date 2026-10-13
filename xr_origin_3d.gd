extends Node3D

var xr_interface: XRInterface

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
		# The simulator only works when running from the editor, never on the Quest.
		print("Connecting XRSimulator")
		var xr_simulator_scene = load("res://addons/xr-simulator/XRSimulator.tscn")
		var xr_simulator = xr_simulator_scene.instantiate()
		add_child(xr_simulator)
