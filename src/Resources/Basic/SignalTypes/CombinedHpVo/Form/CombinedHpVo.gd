extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")
onready var hp_anim_fsm = $Hp/AnimationTree.get("parameters/playback")
onready var vo_anim_fsm = $Vo/AnimationTree.get("parameters/playback")

func _ready():
	# force the signal to be a combined signal
	signal_logic.signal_type = signal_logic.SignalType.COMBINED
	if signal_logic.signal_after == "":
		$Vo.queue_free()
	update_status(signal_logic)

func update_status(instance):
	if instance.status == SignalStatus.RED:
		hp_anim_fsm.travel("Hp0")  # Halt
	else:
		if instance.speed > 0:
			hp_anim_fsm.travel("Hp2")  # Langsamfahrt
		else:
			hp_anim_fsm.travel("Hp1")  # Fahrt
	
	if instance.signal_after_node != null:
		if instance.signal_after_node.status == SignalStatus.RED:
			vo_anim_fsm.travel("Vr0")  # Halt erwarten
		else:
			if instance.signal_after_node.speed > 0:
				vo_anim_fsm.travel("Vr2")  # Langsamfahrt erwarten
			else:
				vo_anim_fsm.travel("Vr1")  # Fahrt erwarten

func update_speed(new_speed):
	update_status(signal_logic)

# main signals do not react to the next signal at all
func update_warn_speed(new_speed):
	update_status(signal_logic)
