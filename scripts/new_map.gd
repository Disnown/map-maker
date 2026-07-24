extends Node3D


# =========================
# REFERENCES
# =========================

@onready var camera = $CameraRig/Camera3D
@onready var grid_map = $GridMap
@onready var tile_list = $CanvasLayer/Toolbar/ScrollContainer/TileList

@onready var ghost_tile: MeshInstance3D = $GhostTile
@onready var delete_ghost: MeshInstance3D = $DeleteGhostTile

@onready var create_button = $CanvasLayer/MenuOptions/ButtonList/CreateButton
@onready var delete_button = $CanvasLayer/MenuOptions/ButtonList/DeleteButton
@onready var load_button = $CanvasLayer/MenuOptions/ButtonList/ImportButton
@onready var export_button = $CanvasLayer/MenuOptions/ButtonList/ExportButton

# =========================
# VARIABLES
# =========================

var mesh_library : MeshLibrary

var selected_tile_id := -1
var selected_tile = ""

var current_rotation := 0

var undo_stack:Array = []
var redo_stack:Array = []

# =========================
# ENUMS
# =========================

enum Tool {
	PLACE,
	DELETE
}

var current_tool = Tool.PLACE

# =========================
# STARTUP
# =========================

func _ready():

	mesh_library = grid_map.mesh_library

	create_button.pressed.connect(_on_place_button_pressed)
	delete_button.pressed.connect(_on_delete_button_pressed)

	create_tile_buttons()

	ghost_tile.visible = false
	delete_ghost.visible = false

	$ExportDialog.hide()
	$ImportDialog.hide()

# =========================
# TOOL SWITCHING
# =========================

func _on_place_button_pressed():

	current_tool = Tool.PLACE

	delete_ghost.visible = false
	if selected_tile_id != -1:
		ghost_tile.visible = true

func _on_delete_button_pressed():

	current_tool = Tool.DELETE

	ghost_tile.visible = false
	delete_ghost.visible = true

# =========================
# TILE PALETTE
# =========================

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

# =========================
# GHOST TILE
# =========================

func update_ghost_mesh():

	if selected_tile_id == -1:
		ghost_tile.visible = false
		return

	var mesh = mesh_library.get_item_mesh(selected_tile_id)

	ghost_tile.mesh = mesh

	ghost_tile.visible = true

	update_ghost_rotation()

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

func update_ghost_rotation():

	ghost_tile.rotation_degrees.y = current_rotation * 90

# =========================
# INPUT
# =========================

func _unhandled_input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:

			match current_tool:

				Tool.PLACE:
					place_tile()

				Tool.DELETE:
					remove_tile()

	if event is InputEventKey and event.pressed:

		if event.keycode == KEY_R:

			current_rotation = (current_rotation + 1) % 4

			print("Rotation:", current_rotation)

			update_ghost_rotation()

		if event.ctrl_pressed:

			if event.keycode == KEY_Z:
				undo()

			if event.keycode == KEY_Y:
				redo()

			if event.keycode == KEY_S:
				_on_export_button_pressed()

			if event.keycode == KEY_L:
				_on_import_button_pressed()

# =========================
# PROCESS
# =========================

func _process(delta):

	if current_tool == Tool.PLACE:

		if selected_tile_id != -1:
			update_ghost_position()

	elif current_tool == Tool.DELETE:

		update_delete_preview()

# =========================
# PLACING
# =========================

func place_tile():

	if selected_tile_id == -1:
		return

	var cell = grid_map.local_to_map(
		grid_map.to_local(ghost_tile.position)
	)

	var old_tile = grid_map.get_cell_item(cell)

	var old_rotation = 0

	if old_tile != -1:
		old_rotation = grid_map.get_cell_item_orientation(cell)

	var new_rotation = get_grid_rotation()

	grid_map.set_cell_item(
		cell,
		selected_tile_id,
		get_grid_rotation()
	)

	save_action(
		cell,
		old_tile,
		old_rotation,
		selected_tile_id,
		new_rotation
	)

# =========================
# DELETING
# =========================

func remove_tile():

	var cell = get_mouse_cell()

	if cell == Vector3i(-999,-999,-999):
		return

	var tile_id = grid_map.get_cell_item(cell)

	if tile_id == -1:
		print("No tile here")
		return

	var old_tile = grid_map.get_cell_item(cell)
	var old_rotation = grid_map.get_cell_item_orientation(cell)

	grid_map.set_cell_item(
		cell,
		-1
	)

	save_action(
	cell,
	tile_id,
	old_rotation,
	-1,
	0
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

# =========================
# GRID / RAYCAST
# =========================

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
	

# =========================
# ROTATION
# =========================

func get_grid_rotation() -> int:

	var basis = Basis()

	basis = basis.rotated(
		Vector3.UP,
		deg_to_rad(current_rotation * 90)
	)

	return grid_map.get_orthogonal_index_from_basis(basis)

# =========================
# SAVE / EXPORT
# =========================

func _on_export_button_pressed():

	$ExportDialog.current_file = "new_map.json"
	$ExportDialog.popup_centered_ratio()

func export_map(map_tag:String) -> Dictionary:

	var data = {
		"mapTag": "new_map",
		"tiles": []
	}


	var used_cells = grid_map.get_used_cells()

	for cell in used_cells:

		var tile_id = grid_map.get_cell_item(cell)

		if tile_id == -1:
			continue

		var tile_name = grid_map.mesh_library.get_item_name(tile_id)

		var tile_data = {
			"name": tile_name,
			"cell": {
				"x": cell.x,
				"y": cell.y,
				"z": cell.z
			},
			"rotation": grid_map.get_cell_item_orientation(cell)
		}

		data["tiles"].append(tile_data)

	return data


func _on_export_dialog_file_selected(path):

	var map_tag = path.get_file().get_basename()

	var map_data = export_map(map_tag)

	var json_string = JSON.stringify(
		map_data,
		"\t"
	)

	var file = FileAccess.open(
		path,
		FileAccess.WRITE
	)

	file.store_string(json_string)

	file.close()

	print("Saved:", path)

# =========================
# LOAD / IMPORT
# =========================

func _on_import_button_pressed() -> void:
	$ImportDialog.popup_centered_ratio()

func _on_load_dialog_file_selected(path: String) -> void:
	load_map(path)

func load_map(path:String):

	var file = FileAccess.open(
		path,
		FileAccess.READ
	)

	var json_text = file.get_as_text()

	file.close()

	var map_data = JSON.parse_string(json_text)


	if map_data == null:
		print("Invalid JSON")
		return

	clear_map()

	build_map(map_data)

	print("Map loaded:", path)

func clear_map():

	for cell in grid_map.get_used_cells():

		grid_map.set_cell_item(
			cell,
			-1
		)

func build_map(data):

	for tile in data["tiles"]:

		var cell_data = tile["cell"]

		var cell = Vector3i(
			cell_data["x"],
			cell_data["y"],
			cell_data["z"]
		)

		var tile_name = tile["name"]

		var tile_id = mesh_library.find_item_by_name(tile_name)

		if tile_id == -1:
			print("Missing tile:", tile_name)
			continue

		var rotation = 0

		if tile.has("rotation"):
			rotation = tile["rotation"]

		grid_map.set_cell_item(
			cell,
			tile_id,
			rotation
		)

# =========================
# UNDO / REDO
# =========================

func save_action(
	cell:Vector3i,
	old_tile:int,
	old_rotation:int,
	new_tile:int,
	new_rotation:int
):

	var action = {
		"cell": cell,

		"old_tile": old_tile,
		"old_rotation": old_rotation,

		"new_tile": new_tile,
		"new_rotation": new_rotation
	}

	undo_stack.append(action)

	redo_stack.clear()

func undo():

	if undo_stack.is_empty():
		return

	var action = undo_stack.pop_back()

	grid_map.set_cell_item(
		action.cell,
		action.old_tile,
		action.old_rotation
	)

	redo_stack.append(action)

func redo():

	if redo_stack.is_empty():
		return

	var action = redo_stack.pop_back()

	grid_map.set_cell_item(
		action.cell,
		action.new_tile,
		action.new_rotation
	)

	undo_stack.append(action)
