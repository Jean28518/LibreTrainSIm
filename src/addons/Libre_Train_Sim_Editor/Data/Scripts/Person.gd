extends Spatial

export (float) var walkingSpeed = 1.5

var attachedStation = null
var attachedWagon = null
var attachedSeat = null
var assignedDoor = null
var destinationIsSeat = false

var transitionToWagon = false
var transitionToStation = false

var status = 0
#0 Walking To Position
#1: Sitting

var destinationPos = []

var stopping = false # Used, if for example doors where closed to early

func _ready():
	walkingSpeed = rand_range(walkingSpeed, walkingSpeed+0.3)

func _process(delta):
	if not get_tree().paused:
		handleWalk(delta)

var leave_wagon_timer = 0
func handleWalk(delta):

	# If Doors where closed to early, and the person is at the station..
	if transitionToWagon == true and not (attachedWagon.lastDoorRight or attachedWagon.lastDoorLeft):
		if attachedWagon.player.currentStationNode != attachedStation:
			transitionToWagon = false
			destinationPos.clear()
		else:
			stopping = true
			if $VisualInstance/AnimationPlayer.current_animation != "Standing":
				$VisualInstance/AnimationPlayer.play("Standing")
	else:
		stopping = false


	if destinationPos.size() == 0:
		if transitionToWagon:
			attachedStation.deregisterPerson(self)
			attachedStation = null
			transitionToWagon = false
			attachedWagon.registerPerson(self, assignedDoor)
			assignedDoor = null
		if transitionToStation and (attachedWagon.lastDoorRight or attachedWagon.lastDoorLeft):
			leave_wagon_timer += delta
			if leave_wagon_timer > 1.8:
				leave_wagon_timer = 0
				transitionToStation = false
				leave_current_wagon()
		if destinationIsSeat and translation.distance_to(attachedSeat.translation) < 0.1:
			destinationIsSeat = false
			rotation_degrees.y = attachedSeat.rotation_degrees.y + 90

			## Animation Sitting
			$VisualInstance/AnimationPlayer.play("Sitting")
		elif !$VisualInstance/AnimationPlayer.is_playing() and attachedSeat == null:
			$VisualInstance/AnimationPlayer.play("Standing")

		return

	if !$VisualInstance/AnimationPlayer.is_playing():
		$VisualInstance/AnimationPlayer.play("Walking")

	if translation.distance_to(destinationPos[0]) < 0.1:
		destinationPos.pop_front()
		return
	else:
		if not stopping:
			translation = translation.move_toward(destinationPos[0], delta*walkingSpeed)
			var vector_delta = destinationPos[0] - translation
#			rotation_degrees.y = rad2deg(translation.angle_to(destinationPos[0]))
			if vector_delta.z != 0:
				if vector_delta.z > 0:
					rotation_degrees.y = rad2deg(atan(vector_delta.x/vector_delta.z))
				else:
					rotation_degrees.y = rad2deg(atan(vector_delta.x/vector_delta.z))+180

func leave_current_wagon():
	destinationPos.append(assignedDoor.to_global(Vector3(0,0,0)))
	translation = to_global(Vector3(0,0,0))
	attachedWagon.deregisterPerson(self)
	attachedStation.registerPerson(self)
	transitionToStation = false
	attachedWagon = null
	assignedDoor = null

func deSpawn():
	if attachedStation:
		attachedStation.deregisterPerson(self)
	if attachedWagon:
		attachedWagon.deregisterPerson(self)

	queue_free()

func clear_destinations():
	destinationPos.clear()
