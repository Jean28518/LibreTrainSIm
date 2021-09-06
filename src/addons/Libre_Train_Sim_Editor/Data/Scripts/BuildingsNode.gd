tool
extends Spatial


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
var updateTimer = 0
func _process(delta):
	if Root.Editor:
		return
	updateTimer += delta
	if updateTimer > 0.5:
		updateTimer = 0
		var world = get_parent()
		for child in get_children():
			if child.get_children().size() != 0 and child.is_class("MeshInstance"):
				for child2 in child.get_children():
					print("Correcting MeshInstance Position in Scene Tree...")
					child.remove_child(child2)
					add_child(child2)
					child2.owner = world
					child2.translation = child.translation + child2.global_transform.origin

	pass
