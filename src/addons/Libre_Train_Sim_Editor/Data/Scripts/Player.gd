extends Spatial

################################################################################
## To Content-Creators: DO NOT EDIT THIS SCRIPT!! This Script will be overwritten by the game.
## For your own scripting please use the attached Node "SpecificScripting"
################################################################################

################################################################################
## Interesting Variables for addOn Creators, which could be read out, (or set).
var soll_command = -1 # The input by the player. (0: Nothing, 1: Full acceleration, -1: Full Break). |soll_command| should be lesser than 1.
export (float) var acceleration # Unit: m/(s*s) 
export (float) var brakeAcceleration # Unit: m/(s*s)
export (float) var friction # (-> Speed = Speed - Speed * fritction (*delta) )
export (float) var length # Train length. # Used in Train Stations for example
export (float) var speedLimit # Maximum Speed, the train can drive. (Unit: km/h)

enum ControlType {
	COMBINED = 0,  # Arrow Keys (Combined Control)
	SEPARATE = 1   # WASD (Separate Brake and Speed)
}
export (int, "Combined", "Separate") var control_type = ControlType.COMBINED
export (bool) var electric = true
var pantograph = false   ## Please just use this variable, if to check, if pantograph is up or down. true: up
var pantographUp = false ## is true, if pantograph is rising.
var engine = false ## Describes wether the engine of the train is running or not.
var voltage = 0 # If this value = 0, the train wont drive unless you press ingame "B". If voltage is "up", then its at 15 by default. Unit (kV)
export (float) var pantographTime = 5
var speed = 0 # Initiats the speed. (Unit: m/s) ## You can convert it with var kmhSpeed = Math.speed2kmh(speed)
onready var currentSpeedLimit = speedLimit # Unit: km/h # holds the current speedlimit
var hardOverSpeeding = false # If Speed > speedlimit + 10 this is set to true
var command = -1 # If Command is < 0 the train will brake, if command > 0 the train will accelerate. Set by the player with Arrow Keys.
var technicalSoll = 0 # Soll Command. This variable describes the "aim" of command
var blockedAcceleration = false ## If true, then acceleration is blocked. e.g.  brakes, dooors, engine,....
var accRoll = 0 # describes the user input, (0 to 1)
var brakeRoll = -1 # describes the user input (0 to -1)
var currentAcceleration = 0 # Current Acceleration in m/(s*s) (Can also be neagtive) - JJust from brakes and engines
var currentRealAcceleration = 0
var time = [23,59,59] ## actual time. Indexes: [0]: Hour, [1]: Minute, [2]: Second
var enforcedBreaking = false 
var overrunRedSignal = false
## set by the world scneario manager. Holds the timetable. PLEASE DO NOT EDIT THIS TIMETABLE! The passed variable displays, if the train was already there. (true/false)
var stations = {"nodeName" : [], "stationName" : [], "arrivalTime" : [], "departureTime" : [], "haltTime" : [], "stopType" : [], "waitingPersons" : [], "leavingPersons" : [], "passed" : [], "arrivalAnnouncePath" : [], "departureAnnouncePath" : [], "approachAnnouncePath" : []} 
## StopType: 0: Dont halt at this station, 1: Halt at this station, 2: Beginning Station, 3: End Station

var reverser = ReverserState.NEUTRAL

## For current Station:
var currentStationName = "" # If we are in a station, this variable stores the current station name
var whole_train_in_station = false # true if speed = 0, and the train is fully in the station
var isInStation = false # true if the train speed = 0, the train is fully in the station, and doors were opened. - Until depart Message
var realArrivalTime = time # Time is set if train successfully arrived
var stationLength = 0 # stores the stationlength
var stationHaltTime = 0 # stores the minimal halt time from station 
var arrivalTime = time # stores the arrival time. (from the timetable)
var depatureTime = time # stores the departure time. (from the timetable)
var platform_side = PlatformSide.NONE

export var doors = true 
export var doorsClosingTime = 7
var doorRight = false # If Door is Open, then its true
var doorLeft = false
var doorsClosing = false

export var brakingSpeed = 0.3
export var brakeReleaseSpeed = 0.2
export var accelerationSpeed = 0.2
export var accerationReleaseSpeed = 0.5

export var sifaEnabled = true
var sifa = false # If this is true, the player has to press the sifa key (Space)

export (String) var description = ""
export (String) var author = ""
export (String) var releaseDate = ""
export (String) var screenshotPath = ""

## 0: Free View 1: Cabin View, 2: Outer View
enum CameraState {
	FREE_VIEW = 0,
	CABIN_VIEW = 1,
	OUTER_VIEW = 2
}
var camera_state = CameraState.CABIN_VIEW

var camera_mid_point = Vector3(0,2,0)
var cameraY = 90
var cameraX = 0

var mouseSensitivity = 10

var camera_distance = 20
var has_camera_distance_changed = false
const CAMERA_DISTANCE_MIN = 5
const CAMERA_DISTANCE_MAX = 200

var ref_fov = 42.7 # reference FOV for camera movement multiplier
var camera_fov = 42.7 # current FOV
var camera_fov_soll = 42.7 # FOV user wants
const CAMERA_FOV_MIN = 20
const CAMERA_FOV_MAX = 60

var soundMode = 0 # 0: Interior, 1: Outer   ## Not currently used


export (Array, NodePath) var wagons 
export var wagonDistance = 0.5 ## Distance between the wagons
var wagonsVisible = false
var wagonsI = [] # Over this the wagons can be accessed

var automaticDriving = false # Autopilot
var sollSpeed = 0 ## Unit: km/h
var sollSpeedTolerance = 4 # Unit km/h
var sollSpeedEnabled = false ## Automatic Speed handlement

var nextSignal = null ## Type: Node (object)
var distanceToNextSignal = 0
var nextSpeedLimitNode = null ## Type: Node (object)
var distanceToNextSpeedLimit = 0

var ai = false # It will be set by the scenario manger from world node. -> Every train which is not controlled by player has this value = true.
var despawnRail = "" ## If the AI Train reaches this Rail, he will despawn.
var rendering = true
var despawning = false
var initialSpeed = -1 ## Set by the scenario manager form the world node. Only works for ai. When == -1, it will be ignored

var frontLight = false
var insideLight = false

var last_driven_signal = null ## In here the reference of the last driven signal is saved

## For Sound:
var currentRailRadius = 0

export (float) var soundIsolation = -8

## callable functions:
# send_message()
# show_textbox_message(string)
################################################################################


var world # Node Reference to the world node.

export var cameraFactor = 1 ## The Factor, how much the camaere moves at acceleration and braking
export var camera_shaking_factor = 1.0 ## The Factor how much the camera moves at high speeds
var startPosition # on rail, given by scenario manager in world node
var forward = true # does the train drive at the rail direction, or against it? 
var debug  ## used for driving fast at the track, if true. Set by world node. Set only for Player Train
var route # String conataining all importand Railnames for e.g. switches. Set by the scenario manager of the world
var distance_on_rail = 0  # It is the current position on the rail.
var distance_on_route = 0 # Current position on the whole route
var currentRail # Node Reference to the current Rail on which we are driving.
var route_index = 0 # Index of the baked route Array.
var next_signal_index = 0 # Index of NEXT signal on baked route signal array
var startRail # Rail, on which the train is starting. Set by the scenario manger of the world

# Reference delta at 60fps
const refDelta = 0.0167 # 1.0 / 60



onready var cameraNode = $Camera
var cameraZeroTransform # Saves the camera position at the beginning. The Camera Position will be changed, when the train is accelerating, or braking

func ready(): ## Called by World!
	
	pause_mode = Node.PAUSE_MODE_PROCESS
	$Camera.pause_mode = Node.PAUSE_MODE_PROCESS
	
	# capture mouse
	# TODO: input mapping to release mouse for interaction?
	# FIXME: mouse is visible in Grey Train, but not in Red Train, why?
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	if not ai:
		cameraZeroTransform = cameraNode.transform
		cameraX = -$Camera.rotation_degrees.x
		cameraY = $Camera.rotation_degrees.y
		$Camera.current = true
	world = get_parent().get_parent()
	
	route = route.split(" ")
	bake_route()
	
	generate_hectometer_boards()
	
	
	if Root.EasyMode or ai:
		pantograph = true
		control_type = ControlType.COMBINED
		sifaEnabled = false
		reverser = ReverserState.FORWARD

	if not doors:
		doorLeft = false
		doorRight = false
		doorsClosing = false
	
	if not electric:
		pantograph = true
		voltage = 15
	
	if sifaEnabled:
		$Sound/SiFa.play()
	
	## Get driving handled
	## Set the Train at the beginning of the rail, and after that set the distance on the Rail forward, which is standing in var startPosition
	distance_on_rail = startPosition
	currentRail = world.get_node("Rails/"+startRail)
	if currentRail == null:
		printerr("Can't find Rail. Check the route of the Train "+ self.name)
		return
	if forward:
		distance_on_route = startPosition
	else:
		distance_on_route = currentRail.length - startPosition

	## Set Train to Route:
	if forward:
		self.transform = currentRail.get_transform_at_rail_distance(distance_on_rail)
	else:
		self.transform = currentRail.get_transform_at_rail_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))
	if debug and not ai: 
		command = 0
		soll_command = 0
	
	## get chunks handled:
	if not ai:
		world.activeChunk = world.pos2Chunk(self.translation) 
	
	spawnWagons()
	
	## Prepare Signals:
	if not ai:
		set_signalWarnLimits()
		set_signalAfters()

		
		
	if ai:
		soundMode = 1
		wagonsVisible = true
		automaticDriving = true
		$Cabin.queue_free()
		$Camera.queue_free()
		$HUD.queue_free()
		camera_state = CameraState.CABIN_VIEW # Not for the camera, for the components who want to see, if the player sees the train from the inside or outside. AI is seen from outside whole time ;)
		insideLight = true
		frontLight = true
	
	print("Train " + name + " spawned sucessfully at " + currentRail.name)


func init_map():
	$HUD.init_map()


func generate_hectometer_boards():
	var total_route_dist = 0
	for length in baked_route_railLength:
		total_route_dist += length
	var hektometer_prefab = preload("res://Resources/Basic/Objects/Hektometertafel.tscn")
	for i in range(0,total_route_dist+1,200):
		var inst = hektometer_prefab.instance()
		world.get_node("TrackObjects").add_child(inst)
		inst.set_distance(i)
		inst.transform = get_transform_at_route_distance(i)


func get_transform_at_route_distance(distance):
	var dist = baked_route_railLength[0]
	var index = 0
	while distance > dist:
		dist += baked_route_railLength[index]
		index += 1
	dist -= baked_route_railLength[index]
	var rail = world.get_node("Rails").get_node(baked_route[index])
	return rail.get_transform_at_rail_distance(distance - dist)


var initialSwitchCheck = false
var processLongDelta = 0.5 # Definition of Period, every which seconds the function is called.
func processLong(delta): ## All functions in it are called every (processLongDelta * 1 second).
	updateNextSignal(delta)
	updateNextSpeedLimit(delta)
	updateNextStation(delta)
	checkDespawn()
	checkSpeedLimit(delta)
	check_for_next_station(delta)
	check_for_player_help(delta)
	get_time()
	checkFreeLastSignal(delta)
	fixObsoleteStations()
	checkVisibility(delta)
	if automaticDriving:
		autopilot(delta)
	if name == "npc3":
		print(currentRail.name)
		print(distance_on_rail)
		
	if not initialSwitchCheck:
		updateSwitchOnNextChange()
		initialSwitchCheck = true


var processLongTimer = 0
func _process(delta):
	if get_tree().paused and not Root.ingame_pause:
		return
		
	if world == null:
		return
	
	if not ai:
		handleCamera(delta)
	
	if get_tree().paused:
		return
	
	processLongTimer += delta
	if processLongTimer > processLongDelta:
		processLong(processLongTimer)
		processLongTimer = 0
	
	if Root.EasyMode and not ai:
		if Input.is_action_just_pressed("autopilot"):
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
			toggle_automatic_driving()
	
	if sollSpeedEnabled:
		handleSollSpeed(delta)
	
	getCommand(delta)
	
	getSpeed(delta)
	
	if speed != 0:
		drive(delta)
	
	if despawning: 
		queue_free()
	
	if electric:
		check_pantograph(delta)
	
	if not debug and not ai:
		check_security()
	
	if doors:
		check_doors(delta)
	
	check_signals()
	
	check_station(delta)
	
	if sifaEnabled:
		check_sifa(delta)
	
	handle_input()
	
	currentRailRadius = currentRail.radius
	
	if not ai:
		updateTrainAudioBus()
	
	handleEngine()
	
	check_overdriving_a_switch()


func _unhandled_key_input(event):
	if Input.is_action_just_pressed("debug") and not ai:
		debug = !debug
		if debug:
			send_message("DEBUG_MODE_ENABLED")
			force_close_doors()
			force_pantograph_up()
			startEngine()
			overrunRedSignal = false
			enforcedBreaking = false
			command = 0
			soll_command = 0
			
		else:
			overrunRedSignal = false
			enforcedBreaking = false
			command = 0
			soll_command = 0
			send_message("DEBUG_MODE_DISABLED")


func handleEngine():
	if not pantograph:
		engine = false
	if not ai and Input.is_action_just_pressed("engine"):
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if not engine:
			startEngine()
		else:
			stopEngine()
	
func startEngine():
	if pantograph:
		engine = true
		
func stopEngine():
	engine = false
	
func get_time():
	time = world.time

func _input(event):
	if ai:
		return
	if get_tree().paused and not Root.ingame_pause:
		return
	if event is InputEventMouseMotion:
		mouseMotion = mouseMotion + event.relative
	
	if Input.is_action_just_pressed("acc+") and reverser == ReverserState.NEUTRAL:
		send_message("HINT_REVERSER_NEUTRAL", ["reverser+", "reverser-"])
	
	if event.is_pressed():
		# zoom in
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_UP) and not $HUD.is_full_map_visible():
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov + 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance += camera_distance*0.2
				has_camera_distance_changed = true
			# call the zoom function
		# zoom out
		if Input.is_mouse_button_pressed(BUTTON_WHEEL_DOWN) and not $HUD.is_full_map_visible():
			if camera_state == CameraState.CABIN_VIEW:
				camera_fov_soll = camera_fov - 5
			elif camera_state == CameraState.OUTER_VIEW:
				camera_distance -= camera_distance*0.2
				has_camera_distance_changed = true
			# call the zoom function
		
		camera_fov_soll = clamp(camera_fov_soll, CAMERA_FOV_MIN, CAMERA_FOV_MAX)
		camera_distance = clamp(camera_distance, CAMERA_DISTANCE_MIN, CAMERA_DISTANCE_MAX)

func getCommand(delta):
	if control_type == ControlType.COMBINED and not automaticDriving:
		if Input.is_action_pressed("acc+"):
			soll_command += 0.7 * delta
		if Input.is_action_pressed("acc-"):
			soll_command -= 0.7 * delta
		if soll_command >= 1:
			soll_command = 1
		if soll_command <= -1:
			soll_command = -1
		if Input.is_action_pressed("brake-"):
			soll_command = 0
		if Input.is_action_pressed("brake+"):
			soll_command = 1
		if soll_command > 1: soll_command = 1
		if soll_command < -1: soll_command = -1
		
	elif control_type == ControlType.SEPARATE and not automaticDriving:
		if Input.is_action_pressed("acc+"):
			accRoll += 0.7 * delta
		if Input.is_action_pressed("acc-"):
			accRoll -= 0.7 * delta
		if accRoll > 1: accRoll = 1
		if accRoll < 0: accRoll = 0
		if Input.is_action_pressed("brake+"):
			brakeRoll -= 0.7 * delta
		if Input.is_action_pressed("brake-"):
			brakeRoll += 0.7 * delta
		if brakeRoll > 0: brakeRoll = 0
		if brakeRoll < -1: brakeRoll = -1
		
		soll_command = accRoll
		if brakeRoll != 0: soll_command = brakeRoll
		
	if soll_command == 0 or Root.EasyMode or ai and not enforcedBreaking:
		blockedAcceleration = false
	if command < 0 and not Root.EasyMode and not ai:
		blockedAcceleration = true
	if (doorRight or doorLeft):
		blockedAcceleration = true
	if reverser == ReverserState.NEUTRAL:
		blockedAcceleration = true
		
	technicalSoll = soll_command
	
	if technicalSoll > 0 and blockedAcceleration:
		technicalSoll = 0
	
	if enforcedBreaking and not debug:
		technicalSoll = -1
	
	
	var missing_value = (technicalSoll-command)
	if missing_value == 0: return
	if command > 0:
		if missing_value > 0:
			missing_value = accelerationSpeed
		if missing_value < 0:
			missing_value = -accerationReleaseSpeed
	if command < 0:
		if missing_value > 0:
			missing_value = brakeReleaseSpeed
		if missing_value < 0:
			missing_value = -brakingSpeed
	command = command + missing_value*delta
	if ((technicalSoll-command) > 0 and missing_value < 0) or ((technicalSoll-command) < 0 and missing_value > 0):
		command = technicalSoll

	
	
func getSpeed(delta):
	if initialSpeed != -1 and not enforcedBreaking and command > 0 and ai:
		speed = initialSpeed
		initialSpeed = -1
		return
	var lastspeed = speed
	## Slope:
	var currentSlope = currentRail.get_heightRot(distance_on_rail)
	if not forward:
		currentSlope = -currentSlope
	if reverser == ReverserState.REVERSE:
		currentSlope = -currentSlope
	var slopeAcceleration = -currentSlope/10
	speed += slopeAcceleration *delta
	
	var sollAcceleration
	if command < 0:
		## Brake:
		sollAcceleration = brakeAcceleration * command
		if speed < 0:
			sollAcceleration = -sollAcceleration
	else:
		sollAcceleration = acceleration * command
	
	currentAcceleration = sollAcceleration
	speed += sollAcceleration * delta
	
	speed -= speed *friction * delta
	
	if abs(speed) < 0.2 and command < 0 and abs(sollAcceleration) > abs(slopeAcceleration):
		speed = 0
	
#	if speed < 0:
#		speed = 0
	if Math.speedToKmH(speed) > speedLimit:
		speed = Math.kmHToSpeed(speedLimit)
	if delta != 0:
		currentRealAcceleration = (speed - lastspeed) * 1/delta
	if debug:
		speed = max(0, 200*command)

func drive(delta):
	var driven_distance = speed * delta
	if reverser == ReverserState.REVERSE:
		driven_distance = -driven_distance
	distance_on_route += driven_distance

	if not forward:
		driven_distance = -driven_distance
	distance_on_rail += driven_distance

	if distance_on_rail > currentRail.length or distance_on_rail < 0:
		change_to_next_rail()
	
	if not rendering: return
	if forward:
		self.transform = currentRail.get_transform_at_rail_distance(distance_on_rail)
	else:
		self.transform = currentRail.get_transform_at_rail_distance(distance_on_rail)
		rotate_object_local(Vector3(0,1,0), deg2rad(180))

func change_to_next_rail():
	var old_radius = currentRail.radius
	if forward:
		old_radius = -old_radius
	
	if forward and (reverser == ReverserState.FORWARD):
		distance_on_rail -= currentRail.length
	if not forward and (reverser == ReverserState.REVERSE):
		distance_on_rail -= currentRail.length

	if not ai:
		print("Player: Changing Rail...")

	if reverser == ReverserState.REVERSE:
		route_index -= 1
	else:
		route_index += 1

	if baked_route.size() == route_index:
		print(name + ": Route no more rail found, despawning me...")
		despawn()
		return

	currentRail =  world.get_node("Rails").get_node(baked_route[route_index])
	forward = baked_route_direction[route_index]

	var new_radius = currentRail.radius
	if forward:
		new_radius = -new_radius
	
	if not forward and (reverser == ReverserState.FORWARD):
		distance_on_rail += currentRail.length
	if forward and (reverser == ReverserState.REVERSE):
		distance_on_rail += currentRail.length
		
	
	# Get radius difference:
	if old_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead. 
		old_radius = 1000000000
	if new_radius == 0: # prevent diviging through Zero, and take a very very big curve radius instead. 
		new_radius = 1000000000
	var radius_difference_factor = abs(1/new_radius - 1/old_radius)*2000
	
	print(new_radius)
	print(old_radius)
	
	print (radius_difference_factor)
	curve_shaking_factor = radius_difference_factor * Math.speedToKmH(speed) / 100.0 * camera_shaking_factor



	
var mouseMotion = Vector2()
var mouseWheel

func remove_free_camera():
	if world.has_node("FreeCamera"):
		world.get_node("FreeCamera").queue_free()
		

func switch_to_cabin_view():
	#Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	camera_state = CameraState.CABIN_VIEW
	wagonsVisible = false
	cameraNode.transform = cameraZeroTransform
	cameraX = -cameraNode.rotation_degrees.x
	cameraY = cameraNode.rotation_degrees.y
	$Camera.fov = camera_fov # reset to first person FOV (zoom)
	$Cabin.show()
	remove_free_camera()
	$Camera.current = true

func switch_to_outer_view():
	wagonsVisible = true
	camera_state = CameraState.OUTER_VIEW
	has_camera_distance_changed = true # FIX for camera not properly setting itself until 1st input
	$Camera.fov = ref_fov # reset to reference FOV, zooming works different in this view
	$Cabin.hide()
	remove_free_camera()
	$Camera.current = true


func handleCamera(delta):
	if Input.is_action_just_pressed("Cabin View"):
		switch_to_cabin_view()
	if Input.is_action_just_pressed("Outer View"):
		switch_to_outer_view()
	if Input.is_action_just_pressed("FreeCamera"):
		$Cabin.hide()
		wagonsVisible = true
		camera_state = CameraState.FREE_VIEW
		get_node("Camera").current = false
		var cam = load("res://addons/Libre_Train_Sim_Editor/Data/Modules/FreeCamera.tscn").instance()
		cam.current = true
		world.add_child(cam)
		cam.owner = world
		cam.transform = transform.translated(camera_mid_point)
	
	var playerCameras = get_tree().get_nodes_in_group("PlayerCameras")
	for i in range(3, 9):
		if Input.is_action_just_pressed("player_camera_" + str(i)) and playerCameras.size() >= i - 2:
			wagonsVisible = true
			camera_state = i
			playerCameras[i -3].current = true
			$Cabin.hide()
			remove_free_camera()

	if camera_state == CameraState.CABIN_VIEW:
		## Camera x Position
		var sollCameraPosition_x = cameraZeroTransform.origin.x + (currentRealAcceleration/20.0 * -cameraFactor * reverser)
		if speed == 0 or debug:
			sollCameraPosition_x = cameraZeroTransform.origin.x
		var missingCameraPosition_x = cameraNode.translation.x - sollCameraPosition_x
		var soll_camera_translation = cameraNode.translation
		soll_camera_translation.x -= missingCameraPosition_x * delta
		
		## Handle Camera Shaking:
		soll_camera_translation += get_camera_shaking(delta)
		cameraNode.translation = soll_camera_translation
		
		# FIXME: in the first frame, delta == 0, why?
		if mouseMotion.length() > 0 and delta > 0:
			var motionFactor = (refDelta / delta * refDelta) * mouseSensitivity * (camera_fov / ref_fov)
			cameraY += -mouseMotion.x * motionFactor
			cameraX += +mouseMotion.y * motionFactor
			cameraX = clamp(cameraX, -85, 85)
			cameraNode.rotation_degrees.y = cameraY
			cameraNode.rotation_degrees.x = -cameraX
			mouseMotion = Vector2(0,0)
		
		if abs(camera_fov - camera_fov_soll) > 1:
			camera_fov += sign(camera_fov_soll-camera_fov)
			cameraNode.fov = camera_fov
		
	elif camera_state == CameraState.OUTER_VIEW:
		if mouseMotion.length() > 0 or has_camera_distance_changed:
			var motionFactor = (refDelta / delta * refDelta) * mouseSensitivity
			cameraY += -mouseMotion.x * motionFactor
			cameraX += +mouseMotion.y * motionFactor
			cameraX = clamp(cameraX, -85, 85)
			var cameraVector = Vector3(camera_distance, 0, 0)
			cameraVector = cameraVector.rotated(Vector3(0,0,1), deg2rad(cameraX)).rotated(Vector3(0,1,0), deg2rad(cameraY))
			cameraNode.translation = cameraVector + camera_mid_point
			cameraNode.rotation_degrees.y = cameraY + 90
			cameraNode.rotation_degrees.x = -cameraX
			mouseMotion = Vector2(0,0)
			has_camera_distance_changed = false
		

## Signals:
func check_signals():
	if reverser == ReverserState.REVERSE:
		# search through signals BACKWARDS, since we are driving BACKWARDS
		var search_array = baked_route_signal_names.slice(0, next_signal_index-1)
		search_array.invert()
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] > distance_on_route:
				next_signal_index -= 1 # order is important
				handle_signal(signal_name)
			else: break
	else:
		var search_array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
		for signal_name in search_array:
			if baked_route_signal_positions[signal_name] < distance_on_route:
				next_signal_index += 1
				handle_signal(signal_name)
			else: break

func find_previous_speed_limit():
	# reset to max speed limit, in case no previous signal is found
	var return_value = speedLimit
	var search_array = get_all_previous_signals_of_types(["Signal", "Speed"])
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance.speed != -1:
			return_value = signal_instance.speed
			break
	return return_value

func handle_signal(signal_name):
	nextSignal = null
	nextSpeedLimitNode = null
	var signal_passed = world.get_node("Signals/"+signal_name)
	if signal_passed.forward != forward: return

	print(name + ": SIGNAL: " + signal_passed.name)

	if signal_passed.type == "Signal": ## Signal
		if reverser == ReverserState.FORWARD:
			if signal_passed.speed != -1:
				currentSpeedLimit = signal_passed.speed
			if signal_passed.warn_speed != -1: 
				pass
			if signal_passed.status == SignalStatus.RED:
				send_message("YOU_OVERRUN_RED_SIGNAL")
				overrunRedSignal = true
			else:
				free_signal_after_driven_train_length(last_driven_signal)
			signal_passed.set_status(SignalStatus.RED)
			last_driven_signal = signal_passed
		else:
			if signal_passed.speed != -1:
				currentSpeedLimit = find_previous_speed_limit()
			signal_passed.set_status(SignalStatus.GREEN)  # turn green, we are no longer in the block!
			# reset last signal, and turn it RED
			var prev = get_all_previous_signals_of_types(["Signal"])
			if prev.size() > 0:
				last_driven_signal = world.get_node("Signals/"+prev[0])
				last_driven_signal.set_status(SignalStatus.RED)
	
	elif signal_passed.type == "Station": ## Station
		if not stations["nodeName"].has(signal_passed.name):
			print(name + ": Station not found in repository, ingoring station. Maybe you are at the wrong track, or the nodename in the station table of the player is incorrect...")
			return
		current_station_index = stations["nodeName"].find(signal_passed.name)
		match stations["stopType"][current_station_index]:
			0:
				stations["passed"][current_station_index] = true
			1:
				is_last_station = false
				is_first_station = false
			2:
				is_last_station = false
				is_first_station = true
			3:
				is_last_station = true
				is_first_station = false
		currentStationName = stations["stationName"][current_station_index]
		isInStation = false
		platform_side = signal_passed.platform_side
		stationHaltTime = stations["haltTime"][current_station_index]
		stationLength = signal_passed.stationLength
		distanceOnStationBeginning = distance_on_route
		arrivalTime = stations["arrivalTime"][current_station_index]
		depatureTime = stations["departureTime"][current_station_index]
		doorOpenMessageSentTimer = 0
		doorOpenMessageSent = false
		currentStationNode = signal_passed
		if not is_first_station:
			for wagonI in wagonsI:
				wagonI.sendPersonsToDoor(platform_side, stations["leavingPersons"][current_station_index]/100.0)
		
	elif signal_passed.type == "Speed":
		if reverser == ReverserState.REVERSE:
			currentSpeedLimit = find_previous_speed_limit()
		else:
			currentSpeedLimit = signal_passed.speed
	elif signal_passed.type == "WarnSpeed":
		print(name + ": Next Speed Limit: "+String(signal_passed.warn_speed))
	elif signal_passed.type == "ContactPoint":
		signal_passed.activateContactPoint(name)
	pass




## For Station:
var GOODWILL_DISTANCE = 10 # distance the player can overdrive a station, or it's train end isn't in the station.
var is_last_station = false # if this is the last station on the route
var is_first_station = true # if this is the first station (where the player spawns)
var stationTimer = 0
var distanceOnStationBeginning = 0 # distance of the station begin on route
var doorOpenMessageSentTimer = 0
var doorOpenMessageSent = false
var currentStationNode 
var current_station_index = 0
func check_station(delta):
	if currentStationName == "":
		return

	var distance_in_station = distance_on_route - distanceOnStationBeginning

	# handle code independent of speed
	# whole train drove further than distance is long (except first station)
	# if part of train is still within station, this will not trigger (allow player to back into station again)
	if distance_in_station > stationLength+length+GOODWILL_DISTANCE and not is_first_station:
		# if train was already stopped at station, it departed early
		if isInStation:
			send_message("YOU_DEPARTED_EARLIER")
		# if it hadn't stopped yet, it missed the station
		else:
			send_message("YOU_MISSED_A_STATION")
		# finally, leave the station
		leave_current_station()
		return

	# handle cases when speed > 0:
	if speed != 0:
		whole_train_in_station = true
		if isInStation and not (doorLeft or doorRight):
			send_message("YOU_DEPARTED_EARLIER")
			leave_current_station()
		return

	# handle speed == 0:
	# train not fully in station
	if not isInStation and whole_train_in_station and not is_first_station:
		if distance_in_station+GOODWILL_DISTANCE < length:
			whole_train_in_station = false
			send_message("END_OF_YOUR_TRAIN_NOT_IN_STATION")
		if distance_in_station > stationLength+GOODWILL_DISTANCE:
			whole_train_in_station = false
			send_message("FRONT_OF_YOUR_TRAIN_NOT_IN_STATION", ["reverser+", "reverser-"])
	
	# train in station but doors closed
	if not isInStation and whole_train_in_station and not (doorLeft or doorRight):
		doorOpenMessageSentTimer += delta
		if doorOpenMessageSentTimer > 5 and not doorOpenMessageSent:
			send_message("HINT_OPEN_DOORS", ["doorLeft", "doorRight"])
			doorOpenMessageSent = true
	
	# train just now fully in station and doors opened, or first station 
	if (not isInStation and whole_train_in_station and (doorLeft or doorRight or platform_side == PlatformSide.NONE)) or (is_first_station and not isInStation):
		isInStation = true
		stationTimer = 0
		realArrivalTime = time
		
		# send a "you are x minutes late" message if player is late
		var lateMessage = ". "
		if not is_first_station:
			var secondsLater = -arrivalTime[2] + realArrivalTime[2] + (-arrivalTime[1] + realArrivalTime[1])*60 + (-arrivalTime[0] + realArrivalTime[0])*3600
			if secondsLater < 60:
				lateMessage = ""
			elif secondsLater < 120:
				lateMessage += tr("YOU_ARE_LATE_1") + " %d %s" % [int(secondsLater/60), tr("YOU_ARE_LATE_2_ONE_MINUTE")]
			else:
				lateMessage += tr("YOU_ARE_LATE_1") + " %d %s" % [int(secondsLater/60), tr("YOU_ARE_LATE_2")]
		
		# send "welcome to station" message
		if is_first_station:
			currentStationNode.set_waiting_persons(stations["waitingPersons"][0]/100.0 * world.default_persons_at_station)
			jEssentials.call_delayed(1.2, self, "send_message", [tr("WELCOME_TO") + " " + currentStationName])
		else:
			send_message(tr("WELCOME_TO") + " " + currentStationName + lateMessage)
		
		# play station announcement
		if camera_state != CameraState.CABIN_VIEW:
			for wagon in wagonsI:
				jTools.call_delayed(1, wagon, "play_outside_announcement", [stations["arrivalAnnouncePath"][current_station_index]])
		elif not ai:
			jTools.call_delayed(1, jAudioManager, "play_game_sound", [stations["arrivalAnnouncePath"][current_station_index]])
		
		# send door position, so persons can get in
		if not is_last_station:
			sendDoorPositionsToCurrentStation()
	
	# train waited long enough in station
	elif isInStation and stationTimer > stationHaltTime:
		# scenario finished if last station
		if is_last_station:
			send_message("SCENARIO_FINISHED")
			stations["passed"][stations["stationName"].find(currentStationName)] = true
			currentStationName = ""
			nextStation = ""
			isInStation = false
			nextStationNode = null
			currentStationNode = null
			update_waiting_persons_on_next_station()
			return
		# else, send "you can depart" message once the time is up
		elif depatureTime[0] <= time[0] and depatureTime[1] <= time[1] and depatureTime[2] <= time[2]:
			nextStation = null
			send_message("YOU_CAN_DEPART")
			stations["passed"][stations["stationName"].find(currentStationName)] = true
			if camera_state != CameraState.CABIN_VIEW:
				for wagon in wagonsI:
					wagon.play_outside_announcement(stations["departureAnnouncePath"][current_station_index])
			elif not ai:
				jAudioManager.play_game_sound(stations["departureAnnouncePath"][current_station_index])
			leave_current_station()

	stationTimer += delta


func leave_current_station():
	stations["passed"][stations["stationName"].find(currentStationName)] = true
	currentStationName = ""
	nextStation = ""
	isInStation = false
	nextStationNode = null
	currentStationNode = null
	update_waiting_persons_on_next_station()


func update_waiting_persons_on_next_station():
	var station_nodes = get_all_upcoming_signals_of_types(["Station"])
	if station_nodes.size() != 0:
		var station_node = world.get_node("Signals/"+station_nodes[0])
		var index = stations["nodeName"].find(station_node.name)
		station_node.set_waiting_persons(stations["waitingPersons"][index]/100.0 * world.default_persons_at_station)


## Pantograph
var pantographTimer = 0
func force_pantograph_up():
	pantograph = true
	pantographUp = true

func rise_pantograph():
	if not pantograph:
		pantographUp = true
		pantographTimer = 0

func check_pantograph(delta):
	if Input.is_action_just_pressed("pantograph") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		pantographUp = !pantographUp
		pantographTimer = 0
	if pantograph != pantographUp:
		pantographTimer+= delta
		if pantograph:
			pantograph = false
		if pantographTimer > pantographTime:
			pantograph = pantographUp
	if pantograph:
		voltage = voltage + (20-voltage)*delta*2.0
	else:
		voltage = voltage + (0-voltage)*delta*2.0


var checkSpeedLimitTimer = 0
func checkSpeedLimit(delta):
	hardOverSpeeding = Math.speedToKmH(speed) > currentSpeedLimit + 10
	if Math.speedToKmH(speed) > currentSpeedLimit + 5 and checkSpeedLimitTimer > 5:
		checkSpeedLimitTimer = 0
		send_message(tr("YOU_ARE_DRIVING_TO_FAST") + " " +  String(currentSpeedLimit))
	checkSpeedLimitTimer += delta


func send_message(string : String, actions := []):
	if not ai:
		print("Sending Message: " + tr(string) % actions )
		$HUD.send_message(string, actions)

## Doors:
var doorsClosingTimer = 0
func open_left_doors():
	if not doorLeft and speed == 0 and not doorsClosing:
		if not $Sound/DoorsOpen.playing: 
			$Sound/DoorsOpen.play()
		doorLeft = true
		
func open_right_doors():
	if not doorRight and speed == 0 and not doorsClosing:
		if not $Sound/DoorsOpen.playing: 
			$Sound/DoorsOpen.play()
		doorRight = true

func close_doors():
	if not doorsClosing and (doorLeft or doorRight):
		doorsClosing = true
		$Sound/DoorsClose.play()
		
func force_close_doors():
	doorsClosing = true
	doorsClosingTimer = doorsClosingTime - 0.1

func check_doors(delta):
	if Input.is_action_just_pressed("doorClose") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		close_doors()
	if Input.is_action_just_pressed("doorLeft") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if doorLeft:
			close_doors()
		else:
			open_left_doors()
	if Input.is_action_just_pressed("doorRight") and not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		if doorRight:
			close_doors()
		else:
			open_right_doors()
	
	if doorsClosing:
		doorsClosingTimer += delta
	
	if doorsClosingTimer > doorsClosingTime:
		doorsClosing = false
		doorRight = false
		doorLeft = false
		doorsClosingTimer = 0
		
	
## BAKING
func sort_signals_by_distance(a, b):
	if a["distance"] < b["distance"]:
		return true
	return false
	
var baked_route ## Route, which will be generated at start of the game.
var baked_route_direction
var baked_route_railLength
var baked_route_signal_names = [] # sorted array of all signal names along the route
var baked_route_signal_positions = {} # dictionary of all signal positions along the route (key = signal name)
func bake_route(): ## Generate the whole route for the train.
	baked_route = []
	baked_route_direction = [forward]
	
	baked_route.append(startRail)
	var currentR = world.get_node("Rails").get_node(baked_route[0]) ## imagine: current rail, which the train will drive later
	baked_route_railLength = [currentR.length]
	var currentpos
	var currentrot
	var currentF = forward
	if currentF: ## Forward
		currentpos = currentR.endpos
		currentrot = currentR.endrot
	else: ## Backward
		currentpos = currentR.startpos
		currentrot = currentR.startrot - 180.0

	var sum_route_length = 0

	var rail_signals = currentR.attachedSignals
	rail_signals.sort_custom(self, "sort_signals_by_distance")
	if not currentF: 
		rail_signals.invert()
	for signal_dict in rail_signals:
		var signal_instance = world.get_node("Signals/"+signal_dict["name"])
		if signal_instance.forward != currentF: 
			continue
		var position_on_route = sum_route_length
		if currentF: 
			position_on_route += signal_dict["distance"]
		else: 
			position_on_route += currentR.length - signal_dict["distance"]
		baked_route_signal_names.append(signal_dict["name"])
		baked_route_signal_positions[signal_dict["name"]] = position_on_route
	sum_route_length += currentR.length

	while(true): ## Find next Rail
		var possibleRails = []
		for rail in world.get_node("Rails").get_children(): ## Get Rails, which are in the near of the endposition of current rail:
			# Could be useful for debugging:
#			if rail.name == "HarrasPConnector" and currentR.name == "HarrasP":
#				print("########")
#				print(currentpos)
#				print(rail.startpos)
#				print(rail.endpos)
#				print(currentrot)
#				print(rail.startrot)
#				print(rail.endrot)
#				print(currentpos.distance_to(rail.endpos))
#				print(Math.angle_distance_deg(currentrot, rail.endrot+180))
			if rail.name != currentR.name and currentpos.distance_to(rail.startpos) < 0.2 and Math.angle_distance_deg(currentrot, rail.startrot) < 1:
				possibleRails.append(rail.name)
			elif rail.name != currentR.name and currentpos.distance_to(rail.endpos) < 0.2 and Math.angle_distance_deg(currentrot, rail.endrot+180) < 1:
				possibleRails.append(rail.name)
		
		if possibleRails.size() == 0: ## If no Rail was found
			break
		elif possibleRails.size() == 1: ## If only one Rail is possible to switch
			baked_route.append(possibleRails[0])
		else: ## if more Rails are available:
			var selectedRail = possibleRails[0]
			for rail in possibleRails:
				for routeName in route:
					if routeName == rail:
						selectedRail = rail
						break
			baked_route.append(selectedRail)
		
		
		## Set Rail to "End" of newly added Rail
		currentR = world.get_node("Rails").get_node(baked_route[baked_route.size()-1]) ## Get "current Rail"
		if currentpos.distance_to(currentR.translation) < currentpos.distance_to(currentR.endpos):
			currentF = true
		else:
			currentF = false

		baked_route_direction.append(currentF)
		baked_route_railLength.append(currentR.length)

		# bake signals
		rail_signals = currentR.attachedSignals
		rail_signals.sort_custom(self, "sort_signals_by_distance")
		if not currentF: 
			rail_signals.invert()
		for signal_dict in rail_signals:
			var signal_instance = world.get_node("Signals/"+signal_dict["name"])
			if signal_instance.forward != currentF: 
				continue
			var position_on_route = sum_route_length
			if currentF: 
				position_on_route += signal_dict["distance"]
			else: 
				position_on_route += currentR.length - signal_dict["distance"]
			baked_route_signal_names.append(signal_dict["name"])
			baked_route_signal_positions[signal_dict["name"]] = position_on_route
		sum_route_length += currentR.length

		if currentF: ## Forward
			currentpos = currentR.endpos
			currentrot = currentR.endrot
		else: ## Backward
			currentpos = currentR.startpos
			currentrot = currentR.startrot - 180.0
	print(name + ": Baking Route finished:")
	print(name + ": Baked Route: "+ String(baked_route))
	print(name + ": Baked Route: Direction "+ String(baked_route_direction))
	
	
func show_textbox_message(string):
	$HUD.show_textbox_message(string)
	
func get_all_upcoming_signals_of_types(types : Array): # returns an sorted array with the names of the signals. The first entry is the nearest.
	var return_value = []
	var search_array = baked_route_signal_names.slice(next_signal_index, baked_route_signal_names.size()-1)
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value

func get_all_previous_signals_of_types(types: Array): # returns an sorted array with the names of the signals. The first entry is the nearest.
	var return_value = []
	var search_array = baked_route_signal_names.slice(0, next_signal_index-1)
	search_array.invert()
	for signal_name in search_array:
		var signal_instance = world.get_node("Signals/"+signal_name)
		if signal_instance == null: continue
		if types.has(signal_instance.type):
			return_value.append(signal_name)
	return return_value

func get_distance_to_signal(signal_name):
	return baked_route_signal_positions[signal_name] - distance_on_route

var nextStation = ""
var check_for_next_stationTimer = 0
var stationMessageSent = false
func check_for_next_station(delta):  ## Used for displaying (In 1000m there is ...)
	check_for_next_stationTimer += delta
	if check_for_next_stationTimer < 1: return
	else:
		check_for_next_stationTimer = 0
		if nextStation == "":
			var nextStations = get_all_upcoming_signals_of_types(["Station"])
#			print(name + ": "+String(nextStations))
			if nextStations.size() == 0:
				stationMessageSent = true
				return
			nextStation = nextStations[0]
			stationMessageSent = false
		
		if not stationMessageSent and get_distance_to_signal(nextStation) < 1001 and stations["nodeName"].has(nextStation) and stations["stopType"][stations["nodeName"].find(nextStation)] != 0 and not isInStation:
			var station = world.get_node("Signals").get_node(nextStation)
			stationMessageSent = true
			var distanceS = String(int(get_distance_to_signal(nextStation)/100)*100+100)
			if distanceS == "1000":
				distanceS = "1km"
			else:
				distanceS+= "m"
			send_message(tr("THE_NEXT_STATION_IS_1") + " " + stations["stationName"][stations["nodeName"].find(nextStation)]+ ". " + tr("THE_NEXT_STATION_IS_2")+ " " + distanceS + " " + tr("THE_NEXT_STATION_IS_3"))
			if camera_state != CameraState.OUTER_VIEW and camera_state != CameraState.FREE_VIEW and not ai:
#				print(name + ": Playing Sound.......................................................")
				jTools.call_delayed(10, jAudioManager, "play_game_sound", [stations["approachAnnouncePath"][stations["nodeName"].find(nextStation)]])
#				jAudioManager.play_game_sound(stations["approachAnnouncePath"][current_station_index+1])
		

func check_security():#
	var oldEnforcedBrake = 	enforcedBreaking
	enforcedBreaking = hardOverSpeeding or overrunRedSignal or not engine or sifaTimer > 33 
	if not oldEnforcedBrake and enforcedBreaking and speed > 0 and not ai:
		$Sound/EnforcedBrake.play()

var check_for_player_helpTimer = 0
var check_for_player_helpTimer2 = 0
var check_for_player_helpSent = false
func check_for_player_help(delta):
	if not check_for_player_helpSent and speed == 0:
		check_for_player_helpTimer += delta
		if check_for_player_helpTimer > 8 and not pantographUp and not check_for_player_helpSent:
			if not Root.mobile_version:
				send_message("HINT_F2", ["trainInfoAbove"])
			check_for_player_helpSent = true
		if check_for_player_helpTimer > 15 and command < -0.5 and not check_for_player_helpSent:
			if not Root.mobile_version:
				send_message("HINT_F2", ["trainInfoAbove"])
			check_for_player_helpSent = true
	else:
		check_for_player_helpTimer = 0
	
	check_for_player_helpTimer2 += delta
	if blockedAcceleration and accRoll > 0 and brakeRoll == 0 and not (doorRight or doorLeft) and not overrunRedSignal and check_for_player_helpTimer2 > 10 and not isInStation:
		send_message("HINT_ADVANCED_DRIVING", ["acc-", "acc+"])
		check_for_player_helpTimer2 = 0
		

func horn():
	if not ai:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	$Sound/Horn.play()

var sifaTimer = 0
func check_sifa(delta):
	if automaticDriving:
		sifaTimer = 0
	sifaTimer += delta
	if speed == 0 or Input.is_action_just_pressed("SiFa"):
		if Input.is_action_just_pressed("SiFa"):
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		sifaTimer = 0
	sifa =  sifaTimer > 25
	$Sound/SiFa.stream_paused = not sifaTimer > 30
		
func set_signalWarnLimits(): # Called in the beginning of the route
	var signals = get_all_upcoming_signals_of_types(["Signal"])
	var speedLimits = get_all_upcoming_signals_of_types(["Speed"])
	for speedLimit in speedLimits:
		signals.append(speedLimit)
	var signalT = {"name" : signals, "position" : []}
	for signalS in signalT["name"]:
		signalT["position"].append(get_distance_to_signal(signalS))
	var sortedSignals = Math.sort_signals(signalT, true)
#	print(signalT)
#	print(sortedSignals)
	var limit = speedLimit
	for i in range(0,sortedSignals.size()):
		var signalN = world.get_node("Signals").get_node(sortedSignals[i])
		if signalN.speed != -1:
			if signalN.speed < limit and i > 0:
				var signalNBefore = world.get_node("Signals").get_node(sortedSignals[i-1])
				if signalNBefore.type == "Signal":
					signalNBefore.warn_speed = signalN.speed
			limit = signalN.speed

func set_signalAfters():
	var signals = get_all_upcoming_signals_of_types(["Signal"])
	for i in range(1,signals.size()):
		var signalN = world.get_node("Signals").get_node(signals[i-1])
		signalN.signal_after = signals[i]
		

func spawnWagons():
	var nextWagonPosition = startPosition
	for wagon in wagons:
		var wagonNode = get_node(wagon)
		var newWagon = wagonNode.duplicate()
		newWagon.show()
		newWagon.baked_route = baked_route
		newWagon.baked_route_direction = baked_route_direction
		newWagon.forward = forward
		newWagon.currentRail = currentRail
		newWagon.distance_on_rail = nextWagonPosition
		newWagon.player = self
		newWagon.world = world
		if forward:
			nextWagonPosition -= wagonNode.length + wagonDistance
		else:
			nextWagonPosition += wagonNode.length + wagonDistance
		get_parent().add_child(newWagon)
		newWagon.owner = self.owner
		wagonsI.append(newWagon)
	
	# Handle Cabin:
	$Cabin.baked_route = baked_route
	$Cabin.baked_route_direction = baked_route_direction
	$Cabin.forward = forward
	$Cabin.currentRail = currentRail
	$Cabin.distance_on_rail = nextWagonPosition
	$Cabin.player = self
	$Cabin.world = world

func toggle_automatic_driving():
	reverser = ReverserState.FORWARD
	automaticDriving = !automaticDriving
	if not automaticDriving:
		sollSpeedEnabled = false
		print("AutomaticDriving disabled")
	else:
		print("AutomaticDriving enabled")

var autoPilotInStation = true

var updateNextSignalTimer = 0
func updateNextSignal(delta):
	if nextSignal == null:
		var upcoming = get_next_signal()
		if upcoming == null:
			return
		nextSignal = world.get_node("Signals/"+upcoming)
		updateNextSignalTimer = 1 ## Force Update Signal
	updateNextSignalTimer += delta
	if updateNextSignalTimer > 0.2:
		distanceToNextSignal = get_distance_to_signal(nextSignal.name)
		updateNextSignalTimer = 0

func get_next_signal():
	var all = get_all_upcoming_signals_of_types(["Signal"])
	if all.size() > 0:
		return all[0]
	return null

var updateNextSpeedLimitTimer = 0
func updateNextSpeedLimit(delta):
	if nextSpeedLimitNode == null:
		nextSpeedLimitNode = get_next_SpeedLimit()
		if nextSpeedLimitNode == null:
			return
		updateNextSpeedLimitTimer = 1 ## Force Update Signal
	updateNextSpeedLimitTimer += delta
	if updateNextSpeedLimitTimer > 0.2:
		distanceToNextSpeedLimit = get_distance_to_signal(nextSpeedLimitNode.name)
		updateNextSpeedLimitTimer = 0

func get_next_SpeedLimit(): #
	var allLimits = get_all_upcoming_signals_of_types(["Speed", "Signal"])
	for limit in allLimits:
		if world.get_node("Signals/" + limit).speed != -1:
			return world.get_node("Signals/" + limit)
			


var nextStationNode = null
var distanceToNextStation = 0
var updateNextStationTimer = 0
func updateNextStation(delta):  ## Used for Autopilot
	if nextStationNode == null:
		var upcoming = get_next_station()
		if upcoming == null:
			return
		nextStationNode = world.get_node("Signals").get_node(upcoming)
		nextStationNode.set_waiting_persons(stations["waitingPersons"][0]/100.0 * world.default_persons_at_station)
	distanceToNextStation = get_distance_to_signal(nextStationNode.name) + nextStationNode.stationLength

func get_next_station():
	var all = get_all_upcoming_signals_of_types(["Station"])
	if all.size() > 0:
		return all[0]
	return null

func autopilot(delta):
	debugLights(self)
	if not pantographUp:
		pantographUp = true
	if not engine:
		startEngine()
	if isInStation:
		sollSpeed = 0
		return
	if (doorLeft or doorRight) and not doorsClosing:
		doorsClosing = true
		$Sound/DoorsClose.play()
		
	
	
	var sollSpeedArr = {}
	
	## Red Signal:
	sollSpeedArr[0] = speedLimit
	if nextSignal != null and nextSignal.status == SignalStatus.RED:
		sollSpeedArr[0] = min(sqrt(15*distanceToNextSignal+20), (distanceToNextSignal+10)/4.0)
		if sollSpeedArr[0] < 10:
			sollSpeedArr[0] = 0
	## Next SpeedLimit
	sollSpeedArr[1] = currentSpeedLimit
	if nextSpeedLimitNode != null and nextSpeedLimitNode.speed != -1:
		sollSpeedArr[1] = nextSpeedLimitNode.speed + (distanceToNextSpeedLimit-50)/((speed+2)/2)
		if (distanceToNextSignal < 50):
			sollSpeedArr[1] = nextSpeedLimitNode.speed
	
	## Next Station:
	sollSpeedArr[2] = speedLimit
	
	if nextStationNode != null:
		if stations["nodeName"].has(nextStationNode.name):

			sollSpeedArr[2] = min(sqrt(15*distanceToNextStation+20), (distanceToNextStation+10)/4.0)
			if sollSpeedArr[2] < 10:
				sollSpeedArr[2] = 0
		else:
			nextStationNode = null

			
	## Open Doors:
	if (currentStationName != "" and speed == 0 and not isInStation and distance_on_route - distanceOnStationBeginning >= length):
		if nextStationNode.platform_side == PlatformSide.LEFT:
			doorLeft = true
			$Sound/DoorsOpen.play()
		elif nextStationNode.platform_side == PlatformSide.RIGHT:
			doorRight = true
			$Sound/DoorsOpen.play()
		elif nextStationNode.platform_side == PlatformSide.BOTH:
			doorLeft = true
			doorRight = true
			$Sound/DoorsOpen.play()
	
	
	sollSpeedArr[3] = currentSpeedLimit
	

#	print("0: "+ String(sollSpeedArr[0]))
#	print("1: "+ String(sollSpeedArr[1]))
#	print("2: "+ String(sollSpeedArr[2]))
#	print("3: "+ String(sollSpeedArr[3]))
	sollSpeed = sollSpeedArr.values().min()
	sollSpeedEnabled = true
	

	

	
func handleSollSpeed(delta):
	var speedDifference = sollSpeed - Math.speedToKmH(speed)
	if abs(speedDifference) > 4:
		if speedDifference > 10: 
			soll_command = 1
		elif speedDifference < 10 and speedDifference > 0:
			soll_command = 0.5
		elif speedDifference > -10 and speedDifference < 0:
			soll_command = -0.5
		elif speedDifference < -10:
			soll_command = -1
	elif abs(speedDifference) < 1: 
		soll_command = 0
	if sollSpeed == 0 and abs(speedDifference) < 10:
		soll_command = -0.5

func checkDespawn():
	if ai and currentRail.name == despawnRail:
		despawn()
		
func despawn():
	freeLastSignalBecauseOfDespawn()
	print("Despawning Train: " + name)
	despawning = true

var checkVisibilityTimer = 0
func checkVisibility(delta):
	checkVisibilityTimer += delta
	if checkVisibilityTimer < 1: return
	if ai: 
		var currentChunk = world.pos2Chunk(world.getOriginalPos_bchunk(translation))
		rendering = world.ist_chunks.has(currentChunk)
		self.visible = rendering
		wagonsVisible = rendering
			 

func debugLights(node):
	for child in node.get_children():
		if child.name != "HUD":
			debugLights(child)
	if node.has_meta("energy"):
		node.visible = false
		node.visible = true
		print("Spotlight updated")


		
func toggle_cabin_light():
	if not has_node("CabinLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	insideLight = !insideLight
	$CabinLight.visible = insideLight

func toggle_front_light():
	if not has_node("FrontLight"):
		return
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	frontLight = !frontLight
	$FrontLight.visible = frontLight

var signal_to_free = null
var signal_to_free_distance = 0
func free_signal_after_driven_train_length(signal_instance): # Called, when overdrove the next signal
	signal_to_free = signal_instance
	signal_to_free_distance = distance_on_route

func checkFreeLastSignal(delta): #called by process
	if signal_to_free != null and (distance_on_route - signal_to_free_distance) > length:
		signal_to_free.give_signal_free()
		signal_to_free = null # sucessfully freed, don't do it again :)
		
func freeLastSignalBecauseOfDespawn():
	if  last_driven_signal != null:
		last_driven_signal.give_signal_free()
	
func fixObsoleteStations(): ## Checks, if there are stations in the stations table, wich are not passed, but unreachable. For them it sets them to passed. Thats good for the Screen in the train.
	pass # doesn't work as expected..
#	for i in range(stations.nodeName.size()):
#		var stationNodeName = stations.nodeName[i]
#		var obsolete = true
#		for nextStationsNodeName in get_all_upcoming_signals_of_types(["Station"]):
#			if nextStationsNodeName == stationNodeName:
#					obsolete = false
#					break
#		if obsolete:
#			if not stationNodeName == currentStationName and stations.stopType[i] != 2:
#				stations.passed[i] = true

func updateTrainAudioBus():
	if camera_state == CameraState.FREE_VIEW or camera_state == CameraState.OUTER_VIEW:
		AudioServer.set_bus_volume_db(2,0)
	else:
		AudioServer.set_bus_volume_db(2,soundIsolation)

func sendDoorPositionsToCurrentStation():
	print("Sending Door Postions...")
	var doors = []
	var doorsWagon = []
	for wagon in wagonsI:
		var wagonTransform
		if forward:
			wagonTransform = wagon.currentRail.get_transform_at_rail_distance(wagon.distance_on_rail)
		else:
			var forward_transform = wagon.currentRail.get_transform_at_rail_distance(wagon.distance_on_rail)
			var backward_basis = forward_transform.basis.rotated(Vector3(0,1,0), deg2rad(180)) # Maybe this could break on ascending/descanding rails..
			var backward_transform = Transform(backward_basis, forward_transform.origin)
			wagonTransform = backward_transform
		if (currentStationNode.platform_side == PlatformSide.LEFT):
			for door in wagon.leftDoors:
				door.worldPos = (wagonTransform.translated(door.translation).origin)
				doors.append(door)
				doorsWagon.append(wagon)
		if (currentStationNode.platform_side == PlatformSide.RIGHT):
			for door in wagon.rightDoors:
				door.worldPos = (wagonTransform.translated(door.translation).origin)
				doors.append(door)
				doorsWagon.append(wagon)
	currentStationNode.setDoorPositions(doors, doorsWagon)


var curve_shaking_factor = 0.0
var camera_shaking_time = 0.0
func get_camera_shaking(delta):
	camera_shaking_time += delta
	curve_shaking_factor = Root.clampViaTime(0.0, curve_shaking_factor, delta)
	
	var camera_shaking = Vector3(sin(camera_shaking_time*10.0), cos(camera_shaking_time*7.0), sin(camera_shaking_time*13.0)) / 10000.0
	
	var shaking_factor = Math.speedToKmH(speed) / 100.0 * abs(sin(camera_shaking_time/5)) * camera_shaking_factor
	

#	print(curve_shaking_factor)
	shaking_factor = max(shaking_factor, curve_shaking_factor)
	
	var current_camera_shaking = camera_shaking * shaking_factor
	
	return current_camera_shaking
		
var switch_on_next_change = false
func updateSwitchOnNextChange():
	if forward and currentRail.isSwitchPart[1] != "":
		switch_on_next_change = true
		return
	elif not forward and currentRail.isSwitchPart[0] != "":
		switch_on_next_change = true
		return
	
	if baked_route.size() > route_index+1:
		var nextRail = world.get_node("Rails").get_node(baked_route[route_index+1])
		var nextForward = baked_route_direction[route_index+1]
		if nextForward and nextRail.isSwitchPart[0] != "":
			switch_on_next_change = true
			return
		elif not nextForward and nextRail.isSwitchPart[1] != "":
			switch_on_next_change = true
			return
			
	switch_on_next_change = false

var last_switch_rail = null ## Last Rail, where was overdriven a switch
func check_overdriving_a_switch():
	if not switch_on_next_change:
		return
	
	var camera_translation = 0
	if has_node("Camera"):
		camera_translation = $Camera.translation.x
	if forward:
		if currentRail.length - (distance_on_rail + camera_translation) < 0 and not currentRail == last_switch_rail:
			overdriven_switch()
			last_switch_rail = currentRail
	else:
		if distance_on_rail - camera_translation < 0 and not currentRail == last_switch_rail:
			overdriven_switch()
			last_switch_rail = currentRail


func overdriven_switch():
	pass

func change_reverser(change):
	if speed != 0:
		return

	match reverser:
		ReverserState.FORWARD:
			if change < 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		ReverserState.NEUTRAL:
			jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
			if change > 0: reverser = ReverserState.FORWARD
			else: reverser = ReverserState.REVERSE
		ReverserState.REVERSE:
			if change > 0:
				reverser = ReverserState.NEUTRAL
				jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")


func handle_input():
	if ai:
		return
	if Input.is_action_just_pressed("FrontLight") and not Input.is_key_pressed(KEY_CONTROL):
		toggle_front_light()
		
	if Input.is_action_just_pressed("InsideLight"):
		toggle_cabin_light()
	
	if Input.is_action_just_pressed("Horn"):
		horn()

	if Input.is_action_just_pressed("reverser+"):
		change_reverser(+1)

	if Input.is_action_just_pressed("reverser-"):
		change_reverser(-1)
