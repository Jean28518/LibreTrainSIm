extends Viewport

const LINE_POINT_INTERVAL = 15 # 1 line point for every 15 meters of track

onready var train_world = find_parent("World")
onready var camera = $Camera2D

onready var signal_green = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/GreenSignalArrow.svg")
onready var signal_red = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/RedSignalArrow.svg")
onready var signal_orange = preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/OrangeSignalArrow.svg")

var follow_player = true
var overlay = false

var active_route_rect = Rect2(2e31, 2e31, 0, 0)

var chunk_origin = Vector2()


func _ready():
	render_target_update_mode = Viewport.UPDATE_ALWAYS
	yield(get_tree(), "idle_frame")
	init_map()


func init_map():
	if train_world == null:
		print("RAILMAP: Could not find world! Despawning!")
		queue_free()

	train_world.connect("bchunk_updated_world_transform", self, "_on_chunk_world_transform_update")

	var rails = train_world.get_node("Rails").get_children()
	for rail in rails:
		create_line2d_from_rail(rail)

	var signals = train_world.get_node("Signals").get_children()
	for signal_i in signals:
		if signal_i.type == "Signal":
			create_signal(signal_i)
		elif signal_i.type == "Station":
			create_station(signal_i)

	close_map()
	camera.current = true


func open_full_map():
	set_process(true)
	set_process_unhandled_input(true)

	self.size = OS.window_size
	overlay = false

	$RouteLines.show()
	$RailLines.show()
	$Signals.show()

	follow_player = true
	$Camera2D.zoom = Vector2(0.1, 0.1)
	$Camera2D.rotation = 0

	update_active_lines_width(1.435)
	$PlayerPolygon.scale = Vector2(1,1)


func open_overlay_map():
	set_process(true)
	set_process_input(false)

	var os_size = OS.window_size
	self.size = Vector2(os_size.x*0.33,os_size.y)

	overlay = true
	follow_player = false

	$Signals.hide()
	$RailLines.hide()
	$RouteLines.show()

	var zoomx
	var zoomy
	if active_route_rect.size.x > active_route_rect.size.y:
		camera.rotation = 90
		zoomx = active_route_rect.size.x / self.size.y
		zoomy = active_route_rect.size.y / self.size.x
	else:
		camera.rotation = 0
		zoomx = active_route_rect.size.x / self.size.x
		zoomy = active_route_rect.size.y / self.size.y

	var zoom = max(zoomx, zoomy)*1.2 # 120% to make sure labels are not cut off
	$Camera2D.zoom = Vector2(zoom, zoom)  # mazda :^)
	$Camera2D.position = active_route_rect.position + (active_route_rect.size/2)

	update_active_lines_width(1.435 * zoom)
	$PlayerPolygon.scale = 4*Vector2(zoom, zoom)


func close_map():
	set_process(false)
	set_process_unhandled_input(false)


var mouse_motion = Vector2(0,0)
func _unhandled_input(event: InputEvent) -> void:
	if event.is_action("zoom_in"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*0.8, 0.01, 2.5)
		zoom.y = clamp(zoom.y*0.8, 0.01, 2.5)
		$Camera2D.zoom = zoom
		get_tree().set_input_as_handled()

	if event.is_action("zoom_out"):
		var zoom = $Camera2D.zoom
		zoom.x = clamp(zoom.x*1.25, 0.01, 3)
		zoom.y = clamp(zoom.y*1.25, 0.01, 3)
		$Camera2D.zoom = zoom
		get_tree().set_input_as_handled()

	if not overlay:
		if event.is_action_pressed("map_center_player"):
			follow_player = true
			get_tree().set_input_as_handled()
		if event is InputEventMouseButton:
			if event.button_index == BUTTON_MIDDLE:
				follow_player = false
				get_tree().set_input_as_handled()
		if event is InputEventMouseMotion and Input.is_mouse_button_pressed(BUTTON_MIDDLE):
			mouse_motion -= event.relative
			get_tree().set_input_as_handled()


func _process(delta: float) -> void:
	var player_pos = train_world.player.translation
	var player_pos_2d = Vector2(player_pos.x, player_pos.z)

	# subtracting chunk origin is necessary!
	$PlayerPolygon.position = player_pos_2d - chunk_origin
	$PlayerPolygon.rotation = -train_world.player.rotation.y

	if follow_player == true:
		camera.position = $PlayerPolygon.position
		camera.rotation_degrees = $PlayerPolygon.rotation_degrees + 90
	else:
		var movement = mouse_motion * $Camera2D.zoom.x * 0.5
		camera.position += movement.rotated(camera.rotation)
		mouse_motion = Vector2(0,0)

	update_labels()


func update_labels():
	for node in $Stations.get_children():
		node.rotation_degrees = camera.rotation_degrees# - 30
		if overlay:
			node.scale = camera.zoom * 0.25
		else:
			node.scale = camera.zoom.clamped(1)*0.25


func update_active_lines_width(width):
	for line in $RouteLines.get_children():
		line.width = width


func create_station(signal_instance):
	var index = train_world.player.stations["nodeName"].find(signal_instance.name)
	if index < 0:
		print("Station Name not found: ", signal_instance.name, "! Probably not a stop in the current scenario!")
		return

	var node = Node2D.new()
	node.rotation_degrees = -30
	#node.scale = Vector2(0.1, 0.1)
	node.position = Vector2(signal_instance.translation.x, signal_instance.translation.z)
	node.name = signal_instance.name
	$Stations.add_child(node)
	node.owner = $Stations

	var label = $LabelPrototype.duplicate()
	node.add_child(label)
	label.owner = node
	label.show()
	label.rect_position.y = -140
	label.text = train_world.player.stations["stationName"][index]


func create_signal(signal_instance):
	var sprite = Sprite.new()
	sprite.position = Vector2(signal_instance.translation.x, signal_instance.translation.z)
	sprite.scale = Vector2(0.1, 0.1)
	sprite.rotation_degrees = -signal_instance.rotation_degrees.y + 90
	sprite.name = signal_instance.name
	$Signals.add_child(sprite)
	sprite.owner = $Signals
	signal_instance.connect("status_changed", self, "_on_signal_changed")
	_on_signal_changed(signal_instance) # call once to init


func _on_signal_changed(signal_instance):
	var sprite: Sprite = $Signals.get_node(signal_instance.name)
	match signal_instance.status:
		SignalStatus.RED: sprite.texture = signal_red
		SignalStatus.ORANGE: sprite.texture = signal_orange
		SignalStatus.GREEN: sprite.texture = signal_green


func _on_chunk_world_transform_update(deltaTranslation):
	print("RAIL MAP: UPDATING WORLD ORIGIN")
	chunk_origin += Vector2(deltaTranslation.x, deltaTranslation.z)


func create_line2d_from_rail(rail):
	var line = Line2D.new()

	# Note: we do not need a "map scale"
	# the rails are probably 100s of meters long, so that would make a very
	# large map, but! line points are measured in pixels. No problem! :)
	var points = build_rail(rail)
	line.points = points
	line.width = 1.435
	line.antialiased = true
	line.name = rail.name

	if train_world.player.baked_route.has(rail.name):
		line.default_color = Color("9eea18")
		$RouteLines.add_child(line)
		line.owner = $RouteLines
		find_max_coords(points)
	else:
		line.default_color = Color("4b86ff")
		$RailLines.add_child(line)
		line.owner = $RailLines


func find_max_coords(points):
	var min_x = 2e31
	var max_x = -2e31
	var min_y = 2e31
	var max_y = -2e31

	for p in points:
		max_x = max(max_x, p.x)
		min_x = min(min_x, p.x)
		max_y = max(max_y, p.y)
		min_y = min(min_y, p.y)

	var rect_max_x = active_route_rect.position.x + active_route_rect.size.x
	var rect_max_y = active_route_rect.position.y + active_route_rect.size.y

	if min_x < active_route_rect.position.x:
		active_route_rect.position.x = min_x
	if min_y < active_route_rect.position.y:
		active_route_rect.position.y = min_y
	if max_x > rect_max_x:
		active_route_rect.size.x = max_x - active_route_rect.position.x
	if max_y > rect_max_y:
		active_route_rect.size.y = max_y - active_route_rect.position.y

func build_rail(rail) -> Array:
	var points = []

	var length
	if rail.parRail != null:
		length = rail.parRail.length
	else:
		length = rail.length

	# detailed rail for curves
	if rail.radius != 0:
		var point_count = int(length / LINE_POINT_INTERVAL) + 1
		# add point count many points along track
		for i in range(0,point_count):
			var rail_transform = rail.get_global_transform_at_rail_distance(i*LINE_POINT_INTERVAL)
			points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		# add end point
		var rail_transform = rail.get_global_transform_at_rail_distance(rail.length)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
	# only 2 points for straight rails
	else:
		# Start Point
		var rail_transform = rail.get_global_transform_at_rail_distance(0)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))
		# End Point
		rail_transform = rail.get_global_transform_at_rail_distance(rail.length)
		points.append(Vector2(rail_transform.origin.x, rail_transform.origin.z))

	return points
