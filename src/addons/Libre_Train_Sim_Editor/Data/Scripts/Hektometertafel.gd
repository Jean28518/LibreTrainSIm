extends Spatial

export(int) var distance = 0 setget set_distance


func _enter_tree() -> void:
	$Hektometertafel.get_surface_material(1).albedo_texture = $Viewport.get_texture()


func set_distance(distance_in_m):
	if not is_inside_tree():
		return	

	distance = distance_in_m
	var km = int(distance_in_m / 1000)
	var m = int((distance_in_m - km*1000) / 100)
	$Viewport/Control/VBoxContainer/km.text = str(km)
	$Viewport/Control/VBoxContainer/m.text = str(m)
