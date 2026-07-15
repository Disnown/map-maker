extends Node3D

@onready var camera: Camera3D = $Camera3D

@export var move_speed := 10.0
@export var fast_speed := 25.0

@export var rotate_sensitivity := 0.25

@export var zoom_speed := 1.0
@export var min_zoom := 3.0
@export var max_zoom := 25.0

var rotating := false


func _process(delta):

	var direction := Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z

	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z

	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x

	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x

	direction.y = 0

	if direction != Vector3.ZERO:

		direction = direction.normalized()

		var speed = move_speed

		if Input.is_key_pressed(KEY_SHIFT):
			speed = fast_speed

		position += direction * speed * delta


func _input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_RIGHT:

			rotating = event.pressed

			if rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

		elif event.button_index == MOUSE_BUTTON_WHEEL_UP and event.pressed:

			camera.position.z -= zoom_speed
			camera.position.y -= zoom_speed

			_clamp_zoom()

		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN and event.pressed:

			camera.position.z += zoom_speed
			camera.position.y += zoom_speed

			_clamp_zoom()

	elif event is InputEventMouseMotion and rotating:

		rotation.y -= deg_to_rad(event.relative.x * rotate_sensitivity)

		rotation.x -= deg_to_rad(event.relative.y * rotate_sensitivity)

		rotation.x = clamp(rotation.x, deg_to_rad(-50), deg_to_rad(80))


func _clamp_zoom():

	camera.position.y = clamp(camera.position.y, min_zoom, max_zoom)
	camera.position.z = clamp(camera.position.z, min_zoom, max_zoom)
