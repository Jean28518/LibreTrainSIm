tool
extends MultiMeshInstance

export (String) var description = ""
export (String) var attached_rail
export (float) var on_rail_position
export (float) var length

export (String) var objectPath = ""
export var materialPaths = []
export (int) var sides = 0#0: No Side, 1: Left, 2: Right 4: Both
export (float) var spawnRate = 1
export (float) var rows
export (float) var distanceLength = 10
export (float) var distanceRows
export (float) var shift
export (float) var height
export (float) var rotationObjects = 0
export (bool) var randomLocation
export (float) var randomLocationFactor = 0.3
export (bool) var randomRotation
export (bool) var randomScale
export (float) var randomScaleFactor = 0.2
export (bool) var placeLast = false
export (bool) var applySlopeRotation = false

export (int) var randomSeed = 0

export (bool) var wholeRail

var material_updated = false


onready var world = find_parent("World")
var rail_node
var updated = false

func get_data():
	var d = {}
	d.description = description
	d.attached_rail = attached_rail
	d.on_rail_position = on_rail_position
	d.length = length
	d.objectPath = objectPath
	d.materialPaths = materialPaths.duplicate()
	d.sides = sides
	d.spawnRate = spawnRate
	d.rows = rows
	d.distanceLength = distanceLength
	d.distanceRows = distanceRows
	d.shift = shift
	d.height = height
	d.randomLocation = randomLocation
	d.randomLocationFactor = randomLocationFactor
	d.randomRotation = randomRotation
	d.randomScale = randomScale
	d.randomScaleFactor = randomScaleFactor
	d.wholeRail = wholeRail
#	d.meshSet = meshSet
#	d.multimesh = multimesh.duplicate()
	d.rotationObjects = rotationObjects
	d.placeLast = placeLast
	d.applySlopeRotation = applySlopeRotation
	d.randomSeed = randomSeed
	return d


func set_data(d):
	description = d.description
	attached_rail = d.attached_rail
	on_rail_position = d.on_rail_position
	length = d.length
	objectPath = d.objectPath
	materialPaths = d.materialPaths
	sides = d.sides
	spawnRate = d.spawnRate
	rows = d.rows
	distanceLength = d.distanceLength
	distanceRows = d.distanceRows
	shift = d.shift
	height = d.height
	randomLocation = d.randomLocation
	randomLocationFactor = d.randomLocationFactor
	randomRotation = d.randomRotation
	randomScale = d.randomScale
	randomScaleFactor = d.randomScaleFactor
	wholeRail = d.wholeRail
#	meshSet = d.meshSet
#	multimesh = d.multimesh
	rotationObjects = d.rotationObjects
	placeLast = d.placeLast
	randomSeed = d.get("randomSeed", 0)
	if d.has("applySlopeRotation"):
		applySlopeRotation = d.applySlopeRotation


func attach_to_rail(_rail_node):
	rail_node = _rail_node
	rail_node.trackObjects.append(self)

func unattach_from_rail():
	if rail_node == null:
		return
	rail_node.trackObjects.erase(self)

func _exit_tree():
	unattach_from_rail()

func update(_rail_node, res_cache = {}):
#	print("Loading Rail Attachment..")
	attach_to_rail(_rail_node)
	self.set_multimesh(self.multimesh.duplicate(false))
	if wholeRail:
		on_rail_position = 0
		length = rail_node.length

	translation = rail_node.get_pos_at_RailDistance(on_rail_position)
	var mesh_res
	if not res_cache.has(objectPath):
		if not ResourceLoader.exists(objectPath):
			printerr("Resource "+ objectPath + " not found! Skipping loading track bject "+ name + " ...")
			return
		res_cache[objectPath] = load(objectPath)
	mesh_res = res_cache[objectPath]
#	mesh_res = load(objectPath)

	multimesh.mesh = load(objectPath).duplicate()

	# This was sometimes out of bounds!!
	#for x in range(materialPaths.size()):
	# FIX:

	var count = min(multimesh.mesh.get_surface_count(), materialPaths.size())
	for x in range(count):
		if materialPaths[x] != "":
			var material_path = materialPaths[x]
			var material_res
			if not res_cache.has(material_path):
				if not ResourceLoader.exists(material_path):
					continue
				res_cache[material_path] = load(material_path)
			multimesh.mesh.surface_set_material(x, res_cache[material_path])

	var straightCount = int(length / distanceLength)
	if placeLast:
		straightCount += 1

	self.multimesh.instance_count = 0
	multimesh.visible_instance_count = 0
	if sides == 0:
		self.multimesh.instance_count = 0
	if sides == 1 or sides == 2:
		self.multimesh.instance_count = int(straightCount * rows)
	if sides == 3:
		self.multimesh.instance_count = int(straightCount * rows)*2
	var idx = 0
	var railpos = on_rail_position
	seed(randomSeed)
	for a in range(straightCount):
		for b in range(rows):
			if sides == 1 or sides == 3: ## Left Side
				if rand_range(0,1) < spawnRate:
					var position = rail_node.get_shifted_pos_at_RailDistance(railpos, -(shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot = rail_node.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail_node.get_heightRot(railpos)
					var scale = Vector3(1,1,1)
					if randomScale:
						var scaleval = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
			if sides == 2 or sides == 3: ## Right Side
				if rand_range(0,1) < spawnRate:
					var position = rail_node.get_shifted_pos_at_RailDistance(railpos, (shift+(b)*distanceRows)) - self.translation + Vector3(0,height,0)
					if randomLocation:
						var shiftx = rand_range(-distanceLength * randomLocationFactor, distanceLength * randomLocationFactor)
						var shiftz = rand_range(-distanceRows * randomLocationFactor, distanceRows * randomLocationFactor)
						position += Vector3(shiftx, 0, shiftz)
					var rot = rail_node.get_deg_at_RailDistance(railpos)
					if randomRotation:
						rot = rand_range(0,360)
					else:
						rot += rotationObjects
					var slopeRot = 0
					if applySlopeRotation:
						slopeRot = rail_node.get_heightRot(railpos)
					var scale = Vector3(1,1,1)
					if randomScale:
						var scaleval = rand_range(1 - randomScaleFactor, 1 + randomScaleFactor)
						scale = Vector3(scaleval, scaleval, scaleval)
					self.multimesh.set_instance_transform(idx, Transform(Basis.rotated(Vector3(0,0,1), deg2rad(slopeRot)).rotated(Vector3(0,1,0), deg2rad(rot)).scaled(scale), position))
					idx += 1
		railpos += distanceLength
		self.multimesh.visible_instance_count = idx


func newSeed():
	randomize()
	randomSeed = rand_range(-1000000,1000000)
