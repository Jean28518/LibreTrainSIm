extends Spatial

onready var signal_logic = get_parent()
onready var world = find_parent("World")


func _ready():
	# force the signal to be a combined signal
	signal_logic.signal_type = signal_logic.SignalType.COMBINED
	# initialize signal
	update_status(signal_logic)


func update_status(instance):
	match instance.status:
		SignalStatus.RED: hp0()
		SignalStatus.GREEN: hp1()
		SignalStatus.OFF: off()
	
	if instance.signal_after_node != null:
		match instance.signal_after_node.status:
			SignalStatus.RED: vr0()
			SignalStatus.GREEN: vr1()
			SignalStatus.OFF: off()


func hp0():
	$Red1.visible = true
	$Red2.visible = true
	$OrangeHp.visible = false
	$GreenHp.visible = false

func hp1():
	$Red1.visible = false
	$Red2.visible = false
	$OrangeHp.visible = signal_logic.speed > 0 and signal_logic.speed <= 60 # Hp2
	$GreenHp.visible = true

func vr0():
	$OrangeVo1.visible = true
	$OrangeVo2.visible = true
	$GreenVo1.visible = false
	$GreenVo2.visible = false

func vr1():
	#Vr2
	if signal_logic.signal_after_node.speed > 0 and signal_logic.signal_after_node.speed <= 60:
		$OrangeVo1.visible = true
		$OrangeVo2.visible = false
		$GreenVo1.visible = false
		$GreenVo2.visible = true
	else:
		$OrangeVo1.visible = false
		$OrangeVo2.visible = false
		$GreenVo1.visible = true
		$GreenVo2.visible = true

func off():
	$Red1.visible = false
	$Red2.visible = false
	$OrangeHp.visible = false
	$OrangeVo1.visible = false
	$OrangeVo2.visible = false
	$GreenHp.visible = false
	$GreenVo1.visible = false
	$GreenVo2.visible = false

func update_speed(new_speed):
	update_status(signal_logic)

func update_warn_speed(new_speed):
	update_status(signal_logic)
