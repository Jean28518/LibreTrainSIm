extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")
onready var anim_fsm = $AnimationTree.get("parameters/playback")

func _ready():
	# force the signal to be a pre-signal
	signal_logic.signal_type = signal_logic.SignalType.PRESIGNAL
	update_status(signal_logic)

# this is a MAIN signal, it CANNOT be orange!
func update_status(instance):
	match instance.status:
		SignalStatus.ORANGE: orange()
		SignalStatus.GREEN: green()

func green():
	if signal_logic.warn_speed > 0:
		anim_fsm.travel("Vr2")  # Langsamfahrt erwarten
	else:
		anim_fsm.travel("Vr1")  # Fahrt erwarten

func orange():
	anim_fsm.travel("Vr0")  # Halt erwarten

func update_speed(new_speed):
	pass

func update_warn_speed(new_speed):
	update_status(signal_logic)
