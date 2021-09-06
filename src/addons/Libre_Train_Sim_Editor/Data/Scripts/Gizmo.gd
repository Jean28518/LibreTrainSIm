extends Spatial


var x_active = false
var y_active = false
var z_active = false

var x_rot_active = false


var mouseMotion = Vector2(0,0)
func _input(event):
	if event is InputEventMouseMotion:
		mouseMotion = mouseMotion + event.relative

	if event is InputEventMouseButton and event.pressed == true:
		mouseMotion = Vector2(0,0)

	if event is InputEventMouseButton:
		if event.pressed == false:
			x_active = false
			y_active = false
			z_active = false
			x_rot_active = false
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _process(delta):
	rotation_degrees.y = - get_parent().rotation_degrees.y

	var screen_size = get_viewport().size

	if Input.is_mouse_button_pressed(BUTTON_LEFT) and (x_active or y_active or z_active or x_rot_active):
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		if x_active:
			get_parent().translation.x += mouseMotion.x * 0.01
		if y_active:
			get_parent().translation.y -= mouseMotion.y * 0.01
		if z_active:
			get_parent().translation.z += mouseMotion.x * 0.01

		if x_rot_active:
			get_parent().rotation_degrees.y += mouseMotion.x * 0.1

		mouseMotion = Vector2(0,0)



func _on_xaxis_mouse_entered():
	x_active = true

func _on_xaxis_mouse_exited():
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		x_active = false


func _on_yaxis_mouse_entered():
	y_active = true


func _on_yaxis_mouse_exited():
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		y_active = false


func _on_zaxis_mouse_entered():
	z_active = true


func _on_zaxis_mouse_exited():
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		z_active = false


func _on_x_rot_mouse_entered():
	x_rot_active = true


func _on_x_rot_mouse_exited():
	if not Input.is_mouse_button_pressed(BUTTON_LEFT):
		x_rot_active = false
