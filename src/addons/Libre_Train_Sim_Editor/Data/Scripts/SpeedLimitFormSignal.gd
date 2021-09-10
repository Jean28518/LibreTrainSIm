tool
extends Spatial

export (int) var speed_limit = 0 setget set_speed_limit

func set_speed_limit(val):
	if not is_inside_tree():
		return
	
	speed_limit = val
	$Viewport/Node2D/Label.text = str(int(val/10))

func _enter_tree():
	$Mesh.get_surface_material(2).albedo_texture = $Viewport.get_texture()
