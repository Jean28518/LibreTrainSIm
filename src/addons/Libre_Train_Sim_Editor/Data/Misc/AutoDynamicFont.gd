tool
class_name AutoDynamicFont
extends DynamicFont

export var desktop_size := 20
export var mobile_size := 60
export var debug_test_size := false setget set_debug_test_size


func _init():
	adjust_size()


func set_debug_test_size(val: bool):
	debug_test_size = val
	adjust_size()


# set_size is taken
func adjust_size():
	if OS.has_feature("mobile") or (OS.has_feature("editor") and debug_test_size):
		size = mobile_size
	else:
		size = desktop_size
