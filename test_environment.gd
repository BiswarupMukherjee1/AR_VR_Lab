extends Node3D

var cube_game

func _ready() -> void:
	cube_game = load("res://cube_game.tscn").instantiate()

func _on_start_button_clicked() -> void:
	$StartButton.queue_free()
	add_child(cube_game)
	cube_game.position.z = -8
