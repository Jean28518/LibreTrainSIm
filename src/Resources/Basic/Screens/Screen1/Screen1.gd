extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"

export (float) var SpeedPointerRotationAt100
export (float) var SollSpeedPointerRotationAt100
var SpeedPointerZero
var SpeedPerKmH
var SollSpeedPointerZero
var SollSpeedPerKmH

onready var world = find_parent("World")


export (float) var CommandPointerRotationAt100
export (float) var blinkingTime = 0.8
var CommandPointerZero
var CommandPerPercent

var syncronizingScreen = false
# Called when the node enters the scene tree for the first time.
func _ready():
	if not  world.globalDict.has("Screen1.BlinkingStatus"):
		syncronizingScreen = true
		world.globalDict["Screen1.BlinkingStatus"] = false

	SpeedPointerZero = $SpeedPointer.rotation_degrees
	SpeedPerKmH = (SpeedPointerRotationAt100-SpeedPointerZero)/100.0

	SollSpeedPointerZero = $SpeedLimitPointer.rotation_degrees
	SollSpeedPerKmH = (SollSpeedPointerRotationAt100 - SollSpeedPointerZero)/100.0

	CommandPointerZero = $CommandPointer.rotation_degrees
	CommandPerPercent = (CommandPointerRotationAt100-CommandPointerZero)/100.0
	#print("DISPLAY: " + String(SpeedPerKmH) + " " + String(SpeedPointerZero) + " " + String(SpeedPointerRotationAt100))
	pass # Replace with function body.

var SollCommandPointer = 0
var SollSpeedLimitPointer = 0
var blinkingTimer = 0
var blinkStatus = false
func _process(delta):
	$CommandPointer.rotation_degrees = (SollCommandPointer - $CommandPointer.rotation_degrees)*delta*4.0 + $CommandPointer.rotation_degrees
	$SpeedLimitPointer.rotation_degrees = (SollSpeedLimitPointer - $SpeedLimitPointer.rotation_degrees)*delta*4.0 + $SpeedLimitPointer.rotation_degrees
	if syncronizingScreen:
		blinkingTimer += delta
		if blinkingTimer > blinkingTime:
			blinkStatus = !blinkStatus
			world.globalDict["Screen1.BlinkingStatus"] = blinkStatus
			blinkingTimer = 0

	blinkStatus = world.globalDict["Screen1.BlinkingStatus"]



var lastAutoPilot = false
func update_display(speed, command, doorLeft, doorRight, doorsClosing, enforcedBreaking, sifa, autopilot, speedLimit, engine):
	## Tachos:
	$SpeedPointer.rotation_degrees = SpeedPointerZero+SpeedPerKmH*speed
	SollCommandPointer = CommandPointerZero+CommandPerPercent*command*100
	SollSpeedLimitPointer = SollSpeedPointerZero+SollSpeedPerKmH*speedLimit


	$Speed.text = String(int(speed))
	$Time.text = Math.time2String(world.time)

	## Engine:
	$Engine.visible = !engine

	## Enforced Breaking
	if enforcedBreaking:
		$EnforcedBraking.visible = blinkStatus
	else:
		$EnforcedBraking.visible = false

	## Sifa:
	$Sifa.visible = sifa

	## Doors:
	if doorsClosing:
		$Doors.visible = blinkStatus
	else:
		$Doors.visible = true
	$Doors/Right.visible = doorRight
	$Doors/Left.visible = doorLeft
	$Doors/Door.visible = doorLeft or doorRight

#	if not lastAutoPilot and autopilot:
#		$AnimationPlayerAutoPilot.play("autopilot")
	$Autopilot.visible = autopilot and blinkStatus
#	lastAutoPilot = autopilot








