extends StaticBody

# Called when the node enters the scene tree for the first time.
func _ready():
	var mesh
	if get_parent().is_in_group("Signal"):
		if get_parent().type == "Signal":
			mesh = get_parent().get_node("VisualInstance").get_node("MeshInstance").mesh
			translation = get_parent().get_node("VisualInstance").get_node("MeshInstance").translation
		else:
			mesh = get_parent().get_node("Mesh").mesh
			transform = get_parent().get_node("Mesh").transform

	if mesh != null:
		$CollisionShape.shape = mesh.create_convex_shape()
