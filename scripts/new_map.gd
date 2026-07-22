extends Node3D

@onready var camera = $CameraRig/Camera3D
@onready var grid_map = $GridMap

var selected_tile = ""

func _ready():
	print("Map Editor Script Loaded")


func _input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			print("Left mouse clicked")
