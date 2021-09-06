extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
export (float) var length = 17.5

export (bool) var cabinMode = false

var baked_route
var baked_route_direction
var routeIndex = 0
var forward
var currentRail
var distanceOnRail = 0
var distance = 0
var speed = 0

var leftDoors = []
var rightDoors = []

var seats = [] # In here the Seats Refernces are safed
var seatsOccupancy = [] # In here the Persons are safed, they are currently sitting on the seats. Index equal to index of seats

var passengerPathNodes = []

var distanceToPlayer = -1

export var pantographEnabled = false


var player
var world

var attachedPersons = []

var initialSet = false
# Called when the node enters the scene tree for the first time.
func _ready():
	pause_mode = Node.PAUSE_MODE_PROCESS
	if cabinMode:
		length = 4
		return
	registerDoors()
	registerPassengerPathNodes()
	registerSeats()

	$MeshInstance.show()

	var personsNode = Spatial.new()
	personsNode.name = "Persons"
	add_child(personsNode)
	personsNode.owner = self

	initialize_outside_announcement_player()
	pass # Replace with function body.

var initialSwitchCheck = false
# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if get_tree().paused:
		if player != null and not cabinMode:
			visible = player.wagonsVisible
		return

	if player == null or player.despawning:
		queue_free()
		return

	if not initialSwitchCheck:
		updateSwitchOnNextChange()
		initialSwitchCheck = true

	speed = player.speed

	if cabinMode:
		drive(delta)
		return


	if get_parent().name != "Players": return
	if distanceToPlayer == -1:
		distanceToPlayer = abs(player.distanceOnRail - distanceOnRail)
	visible = player.wagonsVisible
	if speed != 0 or not initialSet:
		drive(delta)
		initialSet = true
	check_doors()

	if pantographEnabled:
		check_pantograph()

	if not visible: return
	if forward:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
	else:
		self.transform = currentRail.get_transform_at_rail_distance(distanceOnRail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))

	if has_node("InsideLight"):
		$InsideLight.visible = player.insideLight





func drive(delta):
	if currentRail  == player.currentRail:
		if player.forward:
			distanceOnRail = player.distanceOnRail - distanceToPlayer
			distance = player.distance - distanceToPlayer
			if distanceOnRail > currentRail.length:
				change_to_next_rail()
		else:
			distanceOnRail = player.distanceOnRail + distanceToPlayer
			distance = player.distance + distanceToPlayer
			if distanceOnRail < 0:
				change_to_next_rail()


	else:
		## Real Driving - Only used, if wagon isn't at the same rail as his player.
		var drivenDistance
		if forward:
			drivenDistance = speed * delta
			distanceOnRail += drivenDistance
			distance += drivenDistance
			if distanceOnRail > currentRail.length:
				change_to_next_rail()
		else:
			drivenDistance = speed * delta
			distanceOnRail -= drivenDistance
			distance += drivenDistance
			if distanceOnRail < 0:
				change_to_next_rail()

func change_to_next_rail():
	if forward:
		distanceOnRail -= currentRail.length
	routeIndex += 1
	currentRail =  world.get_node("Rails").get_node(baked_route[routeIndex])
	forward = baked_route_direction[routeIndex]
	updateSwitchOnNextChange()
	if not forward:
		distanceOnRail += currentRail.length

var lastDoorRight = false
var lastDoorLeft = false
var lastDoorsClosing = false
func check_doors():
	if player.doorRight and not lastDoorRight:
		$DoorRight.play("open")
	if player.doorRight and not lastDoorsClosing and player.doorsClosing:
		$DoorRight.play_backwards("open")
	if player.doorLeft and not lastDoorLeft:
		$DoorLeft.play("open")
	if player.doorLeft and not lastDoorsClosing and player.doorsClosing:
		$DoorLeft.play_backwards("open")


	lastDoorRight = player.doorRight
	lastDoorLeft = player.doorLeft
	lastDoorsClosing = player.doorsClosing

var lastPantograph = false
var lastPantographUp = false
func check_pantograph():
	if not self.has_node("Pantograph"): return
	if not lastPantographUp and player.pantographUp:
		print("Started Pantograph Animation")
		$Pantograph/AnimationPlayer.play("Up")
	if lastPantograph and not player.pantograph:
		$Pantograph/AnimationPlayer.play_backwards("Up")
	lastPantograph = player.pantograph
	lastPantographUp = player.pantographUp


## This function is very very basic.. It only checks, if the "end" of the current Rail, or the "beginning" of the next rail is a switch. Otherwise it sets nextSwitchRail to null..
#var nextSwitchRail = null
#var nextSwitchOnBeginning = false
#func findNextSwitch():
#	if forward and currentRail.isSwitchPart[1] != "":
#		nextSwitchRail = currentRail
#		nextSwitchOnBeginning = false
#		return
#	elif not forward and currentRail.isSwitchPart[0] != "":
#		nextSwitchRail = currentRail
#		nextSwitchOnBeginning = true
#		return
#
#	if baked_route.size() > routeIndex+1:
#		var nextRail = baked_route[routeIndex+1]
#		var nextForward = baked_route_direction[routeIndex+1]
#		if nextForward and nextRail.isSwitchPart[0] != "":
#			nextSwitchRail = nextRail
#			nextSwitchOnBeginning = true
#			return
#		elif not nextForward and nextRail.isSwitchPart[1] != "":
#			nextSwitchRail = nextRail
#			nextSwitchOnBeginning = true
#			return
#
#	nextSwitchRail = null



func registerDoors():
	for child in get_children():
		if child.is_in_group("PassengerDoor"):
			if child.translation[2] > 0:
				child.translation += Vector3(0,0,0.5)
				rightDoors.append(child)
			else:
				child.translation -= Vector3(0,0,0.5)
				leftDoors.append(child)

func registerPerson(person, door):
	var seatIndex = getRandomFreeSeatIndex()
	if seatIndex == -1:
		person.queue_free()
		return
	attachedPersons.append(person)
	person.get_parent().remove_child(person)
	$Persons.add_child(person)
	person.owner = self
	person.translation = door.translation

	var passengerRoutePath = getPathFromTo(door, seats[seatIndex])
	if passengerRoutePath == null:
		printerr("Some seats of "+ name + " are not reachable from every door!!")
		return
#	print(passengerRoutePath)
	person.destinationPos = passengerRoutePath
	person.destinationIsSeat = true
	person.attachedSeat = seats[seatIndex]
	seatsOccupancy[seatIndex] = person



func getRandomFreeSeatIndex():
	if attachedPersons.size()+1 > seats.size():
		return -1
	while (true):
		var randIndex = int(rand_range(0, seats.size()))
		if seatsOccupancy[randIndex] == null:
			return randIndex


func getPathFromTo(start, destination):
	var passengerRoutePath = [] ## Array of Vector3
	var realStartNode = start
#	print(start.get_groups())
	if start.is_in_group("PassengerDoor") or start.is_in_group("PassengerSeat"):
		 # find the connected passengerNode
		for passengerPathNode in passengerPathNodes:
			for connection in passengerPathNode.connections:
#				print(connection + "  " + start.name)
				if connection == start.name:
					passengerRoutePath.append(passengerPathNode.translation)
#					print("Equals!")
					realStartNode = passengerPathNode
#					print(realStartNode.name)

	if not realStartNode.is_in_group("PassengerPathNode"):
#		printerr("At " + name + " " + start.name + " is not connected to a passengerPathNode!")
		return null

	var restOfpassengerRoutePath = getPathFromToHelper(realStartNode, destination, [])
	if restOfpassengerRoutePath == null:
		return null
	for routePathPosition in restOfpassengerRoutePath:
		passengerRoutePath.append(routePathPosition)
	return passengerRoutePath

func getPathFromToHelper(start, destination, visitedNodes): ## Recursion, Simple Pathfinding, Start  has to be a PassengerPathNode.
#	print("Recursion: " + start.name + " " + destination.name + " " + String(visitedNodes))
	for connection in start.connections:
		var connectionN = get_node(connection)
		if connectionN == destination:
			return [connectionN.translation]
		if connectionN.is_in_group("PassengerPathNode"):
			if visitedNodes.has(connectionN):
				continue
			visitedNodes.append(connectionN)
			var passengerRoutePath = getPathFromToHelper(connectionN, destination, visitedNodes)
			if  passengerRoutePath != null:
				passengerRoutePath.push_front(connectionN.translation)
				return passengerRoutePath
	return null


func registerPassengerPathNodes():
	for child in get_children():
		if child.is_in_group("PassengerPathNode"):
			passengerPathNodes.append(child)

func registerSeats():
	for child in get_children():
		if child.is_in_group("PassengerSeat"):
			seats.append(child)
			seatsOccupancy.append(null)

var leavingPassengerNodes = []
## Called by the train when arriving
## Randomly picks some to the waggon attached persons, picks randomly a door
## on the given side, sends the routeInformation for that to the persons.
func sendPersonsToDoor(doorDirection, proportion : float = 0.5):
	leavingPassengerNodes.clear()
	 #0: No platform, 1: at left side, 2: at right side, 3: at both sides
	var possibleDoors = []
	if doorDirection == 1 or doorDirection == 3: # Left
		for door in leftDoors:
			possibleDoors.append(door)
	if doorDirection == 2 or doorDirection == 3: # Right
		for door in rightDoors:
			possibleDoors.append(door)


	if possibleDoors.empty():
		print(name + ": No Doors found for doorDirection: " + String(doorDirection) )
		return

	randomize()
	for personNode in $Persons.get_children():
		if rand_range(0, 1) < proportion:
			leavingPassengerNodes.append(personNode)
			var randomDoor = possibleDoors[int(rand_range(0, possibleDoors.size()))]

			var seatIndex = -1
			for i in range(seatsOccupancy.size()):
				if seatsOccupancy[i] == personNode:
					seatIndex = i
					break
			if seatIndex == -1:
				print(name + ": Error: Seat from person" + personNode.name+  " not found!")
				return

			var passengerRoutePath = getPathFromTo(seats[seatIndex], randomDoor)
			if passengerRoutePath == null:
				printerr("Some doors are not reachable from every door! Check your Path configuration")
				return

			# Update position of door. (The Persons should stick inside the train while waiting ;)
			if passengerRoutePath.back().z < 0:
				passengerRoutePath[passengerRoutePath.size()-1].z += 1.3
			else:
				passengerRoutePath[passengerRoutePath.size()-1].z -= 1.3

			personNode.destinationPos = passengerRoutePath # Here maybe .append could be better
			personNode.attachedStation = player.currentStationNode
			personNode.transitionToStation = true
			personNode.assignedDoor = randomDoor
			personNode.attachedSeat = null
			seatsOccupancy[seatIndex] = null
			# Send Person to door
			pass
	pass

func deregisterPerson(personNode):
	if leavingPassengerNodes.has(personNode):
		leavingPassengerNodes.erase(personNode)

var outside_announcement_player
func initialize_outside_announcement_player():
	var audioStreamPlayer = AudioStreamPlayer3D.new()

	audioStreamPlayer.unit_size = 10
	audioStreamPlayer.bus = "Game"
	outside_announcement_player = audioStreamPlayer

	add_child(audioStreamPlayer)

func play_outside_announcement(sound_path : String):
	if sound_path == "":
		return
	if cabinMode:
		return
	var stream = load(sound_path)
	if stream == null:
		return
	stream.loop = false
	if stream != null:
		outside_announcement_player.stream = stream
		outside_announcement_player.play()

var switch_on_next_change = false
func updateSwitchOnNextChange(): ## Exact function also in player.gd. But these are needed: When the player drives over many small rails that could be inaccurate..
	if forward and currentRail.isSwitchPart[1] != "":
		switch_on_next_change = true
		return
	elif not forward and currentRail.isSwitchPart[0] != "":
		switch_on_next_change = true
		return

	if baked_route.size() > routeIndex+1:
		var nextRail = world.get_node("Rails").get_node(baked_route[routeIndex+1])
		var nextForward = baked_route_direction[routeIndex+1]
		if nextForward and nextRail.isSwitchPart[0] != "":
			switch_on_next_change = true
			return
		elif not nextForward and nextRail.isSwitchPart[1] != "":
			switch_on_next_change = true
			return

	switch_on_next_change = false
