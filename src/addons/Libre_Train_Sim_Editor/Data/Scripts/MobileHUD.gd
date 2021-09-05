extends Control

var COMMAND_STEP = 0.2

onready var world = find_parent("World")
var player


func _ready():
	player = world.get_node("Players/Player")


func _process(delta):
	$Pantograph.visible = not player.pantograph
	$Engine.visible = not player.engine

	var window_size_y = float(ProjectSettings.get_setting("display/window/size/height"))
	# var window_size_y = OS.window_size.y ## If we will change the resolution, than this line could be better

	var progress_bar_soll_position = ((soll_command-1)*(-0.5)) * window_size_y
	$ProgressBar.rect_position.y = Root.clampViaTime(progress_bar_soll_position, $ProgressBar.rect_position.y, delta*5.0)

	if player.automaticDriving:
		soll_command = 0
	$ColorRect.visible = not player.automaticDriving
	$ProgressBar.visible = not player.automaticDriving

	if player.pantographUp and not player.pantograph:
		$Pantograph.modulate = Color(1,1,1,0.5)


	if soll_command > -0.1 and soll_command < 0.1:
		$ProgressBar.modulate = Color(1, 1, 1, 1)
	elif soll_command < 0:
		$ProgressBar.modulate = Color(1, 0.6, 0.1, 1)
	else:
		$ProgressBar.modulate = Color(0.2, 0.7, 0.2, 1)


	var player_speed_zero = player.speed == 0
	var other_buttons_visible = not player.automaticDriving

	$Up.visible = other_buttons_visible
	$Down.visible = other_buttons_visible
	$DoorLeft.visible = other_buttons_visible and player_speed_zero
	$DoorClose.visible = other_buttons_visible and player_speed_zero
	$DoorRight.visible = other_buttons_visible and player_speed_zero


func update_player_control():
	player.soll_command = soll_command

var soll_command = -1
func _on_Up_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	soll_command += COMMAND_STEP
	if soll_command > 1.0:
		soll_command = 1.0
	update_player_control()

func _on_Down_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	soll_command -= COMMAND_STEP
	if soll_command < -1.0:
		soll_command = -1.0
	update_player_control()


func _on_Pantograph_pressed():
	if not player.pantographUp:
		jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
		player.rise_pantograph()


func _on_Engine_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.startEngine()


func _on_DoorLeft_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.open_left_doors()


func _on_DoorClose_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.close_doors()


func _on_DoorRight_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.open_right_doors()


func _on_Camera_pressed():
	if player.cameraState == 1:
		player.switch_to_outer_view()
	else:
		player.switch_to_cabin_view()



func _on_Autopilot_pressed():
	jAudioManager.play_game_sound("res://Resources/Basic/Sounds/click.ogg")
	player.toggle_automatic_driving()


func _on_Lights_pressed():
	player.toggle_front_light()
	player.toggle_cabin_light()



func _on_Horn_pressed():
	player.horn()
