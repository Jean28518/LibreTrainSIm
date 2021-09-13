extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")
onready var anim_fsm = $AnimationTree.get("parameters/playback")

func _ready():
	# force the signal to be a main signal
	signal_logic.signal_type = signal_logic.SignalType.MAIN
	update_status(signal_logic)

# this is a MAIN signal, it CANNOT be orange!
func update_status(instance):
	match instance.status:
		SignalStatus.RED: red()
		SignalStatus.GREEN: green()

func green():
	if signal_logic.speed > 0 and signal_logic.speed <= 60:
		anim_fsm.travel("Hp2") # Langsamfahrt
	else:
		anim_fsm.travel("Hp1") # Fahrt
		pass

func red():
	anim_fsm.travel("Hp0") # Halt


func update_speed(new_speed):
	update_status(signal_logic)

# main signals do not react to the next signal at all
func update_warn_speed(new_speed):
	pass
