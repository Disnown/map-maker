extends Camera3D

@export var move_speed := 10.0
@export var mouse_sensitivity := 0.2

var rotating := false


func _process(delta):

	var direction = Vector3.ZERO

	if Input.is_key_pressed(KEY_W):
		direction -= transform.basis.z

	if Input.is_key_pressed(KEY_S):
		direction += transform.basis.z

	if Input.is_key_pressed(KEY_A):
		direction -= transform.basis.x

	if Input.is_key_pressed(KEY_D):
		direction += transform.basis.x


	direction.y = 0

	if direction.length() > 0:
		position += direction.normalized() * move_speed * delta



func _input(event):

	if event is InputEventMouseButton:

		if event.button_index == MOUSE_BUTTON_RIGHT:
			rotating = event.pressed

			if rotating:
				Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
			else:
				Input.mouse_mode = Input.MOUSE_MODE_VISIBLE



	if event is InputEventMouseMotion and rotating:

		rotation.y -= deg_to_rad(event.relative.x * mouse_sensitivity)

		rotation.x -= deg_to_rad(event.relative.y * mouse_sensitivity)

		rotation.x = clamp(rotation.x, -1.5, -0.2)
