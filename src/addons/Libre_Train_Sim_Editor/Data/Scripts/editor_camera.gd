class_name EditorCamera
extends CameraBase


export var mouse_sensitivity: float = 0.003
export var normal_speed: float = 1
export var fast_speed: float = 3
export var pan_move_sensitivity: float = 0.25


var velocity := Vector3.ZERO
var is_moving_first_person := false
var is_panning := false


# TODO: F to focus on selected object
# TODO: Fix Pan speed depending on distance to ground or zoom
#	needs object picking
func _unhandled_input(event: InputEvent) -> void:
	var mm := event as InputEventMouseMotion
	if mm != null and is_moving_first_person:
		_rotate_local(mm.relative * mouse_sensitivity)
	elif mm != null and is_panning:
		if get_parent() == orbit_rotation_helper and (mm.shift || mm.alt || mm.control):
			_remove_orbit()
		if mm.alt:
			_pan_local(mm.relative * pan_move_sensitivity)
		elif mm.shift:
			_pan_global(mm.relative * pan_move_sensitivity)
		elif mm.control:
			_zoom(-mm.relative.y * pan_move_sensitivity)
		else:
			_rotate_orbit(mm.relative * mouse_sensitivity)

	var mb := event as InputEventMouseButton
	if mb != null and mb.button_index == BUTTON_RIGHT:
		if mb.pressed and !is_moving_first_person:
			_capture_mouse()
		elif !mb.pressed and is_moving_first_person:
			_free_mouse()
		is_moving_first_person = mb.pressed
	elif mb != null and mb.button_index == BUTTON_MIDDLE:
		if mb.pressed and !is_panning:
			_capture_mouse()
			if mb.shift:
				_prepare_orbit()
		elif !mb.pressed and is_panning:
			_free_mouse()
			if get_parent() == orbit_rotation_helper:
				_remove_orbit()
		is_panning = mb.pressed
	elif mb != null and mb.button_index == BUTTON_WHEEL_DOWN:
		_zoom(10 * max(mb.factor, 1))
	elif mb != null and mb.button_index == BUTTON_WHEEL_UP:
		_zoom(-10 * max(mb.factor, 1))


func _physics_process(_delta: float) -> void:
	if !is_moving_first_person:
		return
	var direction = Vector3(\
		Input.get_action_strength("right") - Input.get_action_strength("left"), \
		Input.get_action_strength("up") - Input.get_action_strength("down"), \
		Input.get_action_strength("backward") - Input.get_action_strength("forward")\
		).normalized()

	direction *= fast_speed if Input.is_action_pressed("shift") else normal_speed
	direction = lerp(velocity, direction, 0.3)
	velocity = direction
	translate_object_local(direction)

