extends Spatial

#onready var drivePitchShift = AudioServer.get_bus_effect(2, 0)

export (float) var AccelerationTransitionTime
export (float) var AccelerationTransitionSpeed


var sollAccelerationVolume1 = -50
var sollAccelerationVolume2 = -50

var inSideReduction = -15

onready var player = get_parent()



#func _ready():
#	$Acceleration1.unit_db = -50
#	pass

#func _process(delta):
#	var speed = Math.speedToKmH((get_parent().speed))
#	var command = get_parent().command
#
#	if player.cameraState == 0:
#		inSideReduction = -15
#	else:
#		inSideReduction = 0
#
#
#	handleDrive(speed)
#	handleAcceleration(command, speed, delta)
#
#	sollAccelerationVolume1 = (sollAccelerationVolume1-$Acceleration1.unit_db)*delta+$Acceleration1.unit_db + inSideReduction
#	$Acceleration1.unit_db = sollAccelerationVolume1
#	sollAccelerationVolume2 = (sollAccelerationVolume2-$Acceleration2.unit_db)*delta+$Acceleration2.unit_db + inSideReduction
#	$Acceleration2.unit_db = sollAccelerationVolume2
#	$AccelerationTransition.unit_db = 0 + inSideReduction
#	$Horn.unit_db = 0 + inSideReduction*1.6
#
#
#func handleDrive(speed):
#	$Drive.pitch_scale = 0.5 + speed/100.0
#	$Drive.unit_db = inSideReduction
#
#var lastspeed = 0
#var timerstatus = ""
#
#func handleAcceleration(command, speed, delta):
#	if !$AccelerationTransition.playing:
#		sollAccelerationVolume1 = -50+(command*60) - speed*0.05
#		sollAccelerationVolume2 = sollAccelerationVolume1
#		if not $Acceleration1.playing:
#			sollAccelerationVolume1 = -50
#		if not $Acceleration2.playing:
#			sollAccelerationVolume2 = -50
#
#
#	if lastspeed <= AccelerationTransitionSpeed and speed > AccelerationTransitionSpeed:
#		$AccelerationTransition.play()
#		$Timer.wait_time = AccelerationTransitionTime
#		$Timer.start()
#		sollAccelerationVolume1 = -50
#		sollAccelerationVolume2 = -50
#	if lastspeed > AccelerationTransitionSpeed and speed <= AccelerationTransitionSpeed:
#		$Acceleration2.stop()
#		$Acceleration1.play()
#
#	$AccelerationTransition.unit_db = -50+(command*50)
#	lastspeed = speed
#
#
#
#func _on_Timer_timeout():
#	sollAccelerationVolume1 = 0
#	sollAccelerationVolume2 = 0
#	$Acceleration2.play()
#	$Acceleration1.stop()
