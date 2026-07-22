extends Node3D

@onready var camera = $CameraRig/Camera3D
@onready var grid_map = $GridMap
@onready var tile_list = $CanvasLayer/Toolbar/ScrollContainer/TileList
var mesh_library : MeshLibrary

var selected_tile = ""

func _ready():

	mesh_library = grid_map.mesh_library

	create_tile_buttons()

func create_tile_buttons():

	for id in mesh_library.get_item_list():

		var button = Button.new()

		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		button.text = mesh_library.get_item_name(id)

		button.pressed.connect(_on_tile_selected.bind(id))

		tile_list.add_child(button)

		var texture = load("res://assets/previews/" + button.text + ".png")

		button.icon = texture

func _on_tile_selected(id:int):

	selected_tile = mesh_library.get_item_name(id)

	print("Selected:", selected_tile)
