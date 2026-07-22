extends Node3D

@onready var camera = $CameraRig/Camera3D
@onready var grid_map = $GridMap
@onready var tile_list = $CanvasLayer/Toolbar/ScrollContainer/TileList
var mesh_library : MeshLibrary

var selected_tile = ""

var current_layer := 0

@onready var ghost_tile: MeshInstance3D = $GhostTile
var selected_tile_id := -1

@onready var delete_ghost: MeshInstance3D = $DeleteGhostTile

@onready var create_button = $CanvasLayer/Toolbar/ScrollContainer/TileList/CreateButton
@onready var delete_button = $CanvasLayer/Toolbar/ScrollContainer/TileList/DeleteButton

enum Tool {
	PLACE,
	DELETE
}

var current_tool = Tool.PLACE

func _ready():

	mesh_library = grid_map.mesh_library

	create_button.pressed.connect(_on_place_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)

	create_tile_buttons()

	ghost_tile.visible = false
	delete_ghost.visible = false
	

func _on_place_button_pressed():

	current_tool = Tool.PLACE

	delete_ghost.visible = false
	if selected_tile_id != -1:
		ghost_tile.visible = true

	print("Tool: Place")

func _on_delete_button_pressed():

	current_tool = Tool.DELETE

	ghost_tile.visible = false
	delete_ghost.visible = true

	print("Tool: Delete")

func create_tile_buttons():

	for id in mesh_library.get_item_list():

		var button = Button.new()

		button.alignment = HORIZONTAL_ALIGNMENT_LEFT

		button.text = mesh_library.get_item_name(id)

		button.pressed.connect(_on_tile_selected.bind(id))

		tile_list.add_child(button)

		var preview_path: String = "res://assets/previews/" + button.text + ".png"

		if ResourceLoader.exists(preview_path):
			button.icon = load(preview_path)

func _on_tile_selected(id:int):

	selected_tile_id = id

	selected_tile = mesh_library.get_item_name(id)

	print("Selected:", mesh_library.get_item_name(id))

	update_ghost_mesh()

func update_ghost_mesh():

	if selected_tile_id == -1:
		ghost_tile.visible = false
		return


	var mesh = mesh_library.get_item_mesh(selected_tile_id)

	ghost_tile.mesh = mesh

	ghost_tile.visible = true

func _process(delta):

	if current_tool == Tool.PLACE:

		if selected_tile_id != -1:
			update_ghost_position()


	elif current_tool == Tool.DELETE:

		update_delete_preview()

func update_ghost_position():

	var mouse = get_viewport().get_mouse_position()

	var ray_origin = camera.project_ray_origin(mouse)

	var ray_direction = camera.project_ray_normal(mouse)


	var plane = Plane(
		Vector3.UP,
		0
	)


	var hit = plane.intersects_ray(
		ray_origin,
		ray_direction
	)


	if hit == null:
		return


	var cell = get_placement_cell()

	if cell.y < 0:
		cell.y = 0
	ghost_tile.position = grid_map.map_to_local(cell)

func _unhandled_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			match current_tool:

				Tool.PLACE:
					place_tile()

				Tool.DELETE:
					remove_tile()


func place_tile():

	if selected_tile_id == -1:
		return


	var cell = grid_map.local_to_map(
		grid_map.to_local(ghost_tile.position)
	)

	grid_map.set_cell_item(
		cell,
		selected_tile_id
	)

	print("Placed:", cell)

func get_placement_cell() -> Vector3i:

	var mouse = get_viewport().get_mouse_position()

	var ray_origin = camera.project_ray_origin(mouse)
	var ray_direction = camera.project_ray_normal(mouse)

	var plane = Plane(Vector3.UP, 0)

	var hit = plane.intersects_ray(
		ray_origin,
		ray_direction
	)

	if hit == null:
		return Vector3i(-999,-999,-999)


	var cell = grid_map.local_to_map(
		grid_map.to_local(hit)
	)


	# Move upwards until we find an empty cell
	while grid_map.get_cell_item(cell) != -1:
		cell.y += 1


	return cell

func remove_tile():

	var cell = get_mouse_cell()


	if cell == Vector3i(-999,-999,-999):
		return


	var tile_id = grid_map.get_cell_item(cell)


	if tile_id == -1:
		print("No tile here")
		return


	grid_map.set_cell_item(
		cell,
		-1
	)


	print("Removed tile at:", cell)

func get_mouse_cell() -> Vector3i:

	var mouse = get_viewport().get_mouse_position()

	var ray_origin = camera.project_ray_origin(mouse)
	var ray_direction = camera.project_ray_normal(mouse)


	var plane = Plane(
		Vector3.UP,
		0
	)


	var hit = plane.intersects_ray(
		ray_origin,
		ray_direction
	)


	if hit == null:
		return Vector3i(-999,-999,-999)


	return grid_map.local_to_map(
		grid_map.to_local(hit)
	)
	
func update_delete_preview():

	var cell = get_mouse_cell()


	if cell == Vector3i(-999,-999,-999):
		delete_ghost.visible = false
		return


	var tile_id = grid_map.get_cell_item(cell)


	if tile_id == -1:
		delete_ghost.visible = false
		return


	var mesh = grid_map.mesh_library.get_item_mesh(tile_id)

	delete_ghost.mesh = mesh

	delete_ghost.position = grid_map.map_to_local(cell)

	delete_ghost.visible = true
	
	
