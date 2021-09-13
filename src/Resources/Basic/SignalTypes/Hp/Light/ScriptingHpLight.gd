extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")


func _ready():
	# force the signal to be a main signal
	signal_logic.signal_type = signal_logic.SignalType.MAIN
	# initialize signal
	update_status(signal_logic)


# main signal CANNOT be orange!
func update_status(instance):
	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()
		SignalStatus.OFF: off()


# if the signal is not "STOP", but shows a speed limit, show Hp2
func green():
	$Red1.visible = false
	$Red2.visible = false
	$Green.visible = true
	$Orange.visible = signal_logic.speed > 0 and signal_logic.speed <= 60

func red():
	$Red1.visible = true
	$Red2.visible = true
	$Orange.visible = false
	$Green.visible = false

func off():
	$Red1.visible = false
	$Red2.visible = false
	$Orange.visible = false
	$Green.visible = false



func update_speed(new_speed):
	update_status(signal_logic)


func update_warn_speed(new_speed):
	pass
