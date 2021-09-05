class_name TextBox
extends PanelContainer

signal closed


var _previous_mouse_mode


func _unhandled_key_input(event):
	if Input.is_action_just_released("ui_accept"):
		_on_Ok_pressed()


func message(text: String):
	_previous_mouse_mode = Input.get_mouse_mode()
	assert(_previous_mouse_mode != null)
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	$VBoxContainer/Message.text = text
	visible = true
	$VBoxContainer/Ok.grab_focus()


func _on_Ok_pressed():
	visible = false
	Input.set_mouse_mode(_previous_mouse_mode)
	emit_signal("closed")
