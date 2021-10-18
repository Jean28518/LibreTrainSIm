extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"


# Called when the node enters the scene tree for the first time.
func _ready():
	$Table/Arrival/Label.text = " " + TranslationServer.translate("ARRIVAL:") + " "
	$Table/Departure/Label.text = " " + TranslationServer.translate("DEPARTURE:") + " "
	$Table/Station/Label.text = " " + TranslationServer.translate("STATION:") + " "
	pass # Replace with function body.

func update_display(arrivals, departures, stationNames, stopTypes, passed, isInStation):
	$CurrentStation.visible = isInStation
	var arrString = ""
	var depString = ""
	var staString = ""
	for i in range (0, stationNames.size()):
		if passed[i]: continue

		if stopTypes[i] == 0 or stopTypes[i] == 2:
			arrString += "\n"
		else:
			arrString += Math.time2String(arrivals[i]) + "\n"

		if stopTypes[i] == 3:
			depString += "\n"
		else:
			depString += Math.time2String(departures[i]) + "\n"

		staString += stationNames[i] + "\n"

	$Table/Arrival/Label2.text = arrString
	$Table/Departure/Label2.text = depString
	$Table/Station/Label2.text = staString

# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
