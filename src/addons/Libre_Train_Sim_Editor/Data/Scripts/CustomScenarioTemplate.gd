extends Node

var scenario = Root.currentScenario
onready var world = find_parent("World")
var step = 0
var message = ""
var player

################################################################################
func _process(delta):
	internal_stuff(delta)

	if scenario == "ExactNameOfTheScenario":
		scenario1()

func scenario1():
	match step:
		0:
			message = "Welcome! Please rise up the pantograph by pressing b"  ## In Beginning of every step, you should define next message.
			if player.pantograph: # condition, if step 0 is done
				next_step() # move on to next step
		1:
			message = "Great! To close the Doors, press 'o'.\n\nWhith 'i' you can open the left one,\nwith 'p' you open the right door."
			if  not (player.doorRight or player.doorLeft):
				next_step()
		2:
			message = "Last message of custom scenario. Thanks for playing!"


################################################################################
# Call this function, if the condition of the current step is fulfilled.
func next_step():
	step += 1
	message_sent = false
	send_message_timer = 0


# Don't mind this function. It shouldn't be interesting for you.
var send_message_timer = 0
var message_sent = false
func internal_stuff(delta):
	if world == null:
		world = find_parent("World")
	if player == null:
		player = world.get_node("Players/Player")
	send_message_timer += delta
	if not message_sent and send_message_timer > 1:
		message_sent = true
		player.show_textbox_message(message)
