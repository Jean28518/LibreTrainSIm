class_name Station
extends RailLogic

var personsNode: Node

export (int) var stationLength: int


export (PlatformSide.TypeHint) var platform_side: int = PlatformSide.NONE
export (bool) var personSystem: bool = true
export (float) var platformHeight: float = 1.2
export (float) var platformStart: float = 2.5
export (float) var platformEnd: float = 4.5

export (String) var attached_rail: String
export (float) var on_rail_position: float
export var forward: bool = true

var waitingPersonCount: int = 5
var attachedPersons: Array = []


func _get_type() -> String:
	return RailLogicTypes.STATION


var rail: Spatial
func _ready():
	if Engine.is_editor_hint():
		if get_parent().name == "Signals":
			return
		if get_parent().is_in_group("Rail"):
			attached_rail = get_parent().name
		var signals = world.get_node("Signals")
		get_parent().remove_child(self)
		signals.add_child(self)
		set_to_rail()
	if not Engine.is_editor_hint() and not Root.Editor:
		$MeshInstance.queue_free()
		set_to_rail()
		personSystem = personSystem and jSettings.get_persons() and not Root.mobile_version


func _process(_delta: float) -> void:
	if rail == null:
		set_to_rail()

	if not Engine.editor_hint and not Root.Editor:
		if personSystem:
			handlePersons()


func set_to_rail() -> void:
	assert(is_inside_tree())
	assert(not not world)

	if world.has_node("Rails/"+attached_rail) and attached_rail != "":
		rail = get_parent().get_parent().get_node("Rails/"+attached_rail)
		rail.register_signal(self.name, on_rail_position)
		self.transform = rail.get_global_transform_at_rail_distance(on_rail_position)
		if not forward:
			rotation_degrees.y += 180
	else:
		queue_free()

func spawnPersonsAtBeginning() -> void:
	if not personSystem:
		return
	if platform_side == PlatformSide.NONE:
		return
	while(rail.visible and attachedPersons.size() < waitingPersonCount):
		spawnRandomPerson()


func set_waiting_persons(count: int) -> void:
	waitingPersonCount = count
	spawnPersonsAtBeginning()


func handlePersons() -> void:
	if platform_side == PlatformSide.NONE:
		return
	if rail == null:
		return

	if rail.visible and attachedPersons.size() < waitingPersonCount:
		spawnRandomPerson()


func spawnRandomPerson() -> void:
	randomize()
	var person: PackedScene = preload("res://Data/Modules/Person.tscn")
	var personVI: PackedScene = world.personVisualInstances[int(rand_range(0, world.personVisualInstances.size()))]
	var personI: Spatial = person.instance()
	personI.add_child(personVI.instance())
	personI.attachedStation = self
	personI.transform = getRandomTransformAtPlatform()
	personsNode.add_child(personI)
	personI.owner = world
	attachedPersons.append(personI)


func getRandomTransformAtPlatform() -> Transform:
	if forward:
		var randRailDistance = int(rand_range(on_rail_position, on_rail_position+stationLength))
		if platform_side == PlatformSide.LEFT:
			return Transform(Basis(Vector3(0,deg2rad(rail.get_deg_at_RailDistance(randRailDistance)), 0)),  rail.get_shifted_pos_at_RailDistance(randRailDistance, rand_range(-platformStart, -platformEnd)) + Vector3(0, platformHeight, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform(Basis(Vector3(0,deg2rad(rail.get_deg_at_RailDistance(randRailDistance)+180.0), 0)) , rail.get_shifted_pos_at_RailDistance(randRailDistance, rand_range(platformStart, platformEnd)) + Vector3(0, platformHeight, 0))
	else:
		var randRailDistance = int(rand_range(on_rail_position, on_rail_position-stationLength))
		if platform_side == PlatformSide.LEFT:
			return Transform(Basis(Vector3(0,deg2rad(rail.get_deg_at_RailDistance(randRailDistance)+180.0), 0)), rail.get_shifted_pos_at_RailDistance(randRailDistance, rand_range(platformStart, platformEnd)) + Vector3(0, platformHeight, 0))
		if platform_side == PlatformSide.RIGHT:
			return Transform(Basis(Vector3(0,deg2rad(rail.get_deg_at_RailDistance(randRailDistance)), 0)) , rail.get_shifted_pos_at_RailDistance(randRailDistance, rand_range(-platformStart, -platformEnd)) + Vector3(0, platformHeight, 0))
	return Transform()


func setDoorPositions(doors: Array, doorsWagon: Array) -> void: ## Called by the train
	if doors.size() == 0:
		return
	for person in attachedPersons:
		person.clear_destinations()
		var nearestDoorIndex = 0
		for i in range(doors.size()):
			if doors[i].global_transform.origin.distance_to(person.translation) <  doors[nearestDoorIndex].global_transform.origin.distance_to(person.translation):
				nearestDoorIndex = i
		person.destinationPos.append(doors[nearestDoorIndex].global_transform.origin)
		person.transitionToWagon = true
		person.assignedDoor = doors[nearestDoorIndex]
		person.attachedWagon = doorsWagon[nearestDoorIndex]


func deregisterPerson(personToDelete: Spatial) -> void:
	if attachedPersons.has(personToDelete):
		attachedPersons.erase(personToDelete)
		waitingPersonCount -= 1


func registerPerson(personNode: Spatial) -> void:
	attachedPersons.append(personNode)
	personNode.get_parent().remove_child(personNode)
	personsNode.add_child(personNode)
	personNode.owner = world
	personNode.destinationPos.append(getRandomTransformAtPlatform().origin)
