tool
extends Node

# Get Next Position from a point on a circle after a specific Distance.
#Used for Building Rails, and driving on rail.
## Circle:
func getNextPos(radius, pos, worldRot, distance):#  Vector3 position, float worldRot, float distance):
	# Straigt
	if radius == 0:
		return pos + Vector3(cos(deg2rad(worldRot))*distance, 0, -sin(deg2rad(worldRot))*distance) ##!!!!
	# Curve
	var extend = radius * 2.0 * PI
	var degree = distance / extend * 360    + worldRot
	return degreeToCoordinate(radius, pos, degree, worldRot)

# Calculate aut from radius of circle, the rotation of the object, and a specific Distande the next rotation of the object.
#Used for Building Rails, and driving on rail.
func getNextDeg(radius, worldRot, distance):
	# Straight:
	if radius == 0:
		return worldRot
	# Curve:
	var extend = radius * 2.0 * PI
	return distance / extend * 360    + worldRot


# Calculates from the radius of the circle, the position and rotation from the object the middlepoint of the circle.
# Whith that the Function returns in the end the position after for example 2 degrees on "driving" on the rail.
# only used sed by getNextPos()
func degreeToCoordinate(radius, pos, degree, worldRot):
	degree = float(degree)
	var mittelpunkt = pos - Vector3(sin(deg2rad(worldRot)) * radius,0,cos(deg2rad(worldRot)) * radius)
	var a = cos(deg2rad(degree)) * radius
	var b = sin(deg2rad(degree)) * radius
	return mittelpunkt + Vector3(b, 0, a)

## converts m/s to km/h
func speedToKmH(speed):
	return speed*3.6

func kmHToSpeed(speed):
	return speed/3.6

func normDeg(degree):
	while degree > 360.0:
		degree -= 360.0
	while degree < 0:
		degree += 360.0
	return degree

# returns the distance in degrees between the 2 rotations, also in degrees
# the SMALLER of the 2 possible angles is chosen!
# examples:
# angle_dist_deg(45, -45) = 90
# angle_dist_deg(-45, 45) = 90
# angle_dist_deg(0, 170) = 170
func angle_distance_deg(rot1, rot2) -> float:
	var normed1 = normDeg(rot1)
	var normed2 = normDeg(rot2)
	return 180.0 - abs(abs(normed1 - normed2) - 180.0)


func sort_signals(signalTable, forward = true): # Gets A Dict like {"name": [], "position" : []}, returns the array of the signal
	var signalT = signalTable.duplicate(true)
	var exportT = []
	for a in range(0, signalT["name"].size()):
		var minimum = 0
		for i in range(0, signalT["name"].size()):
			if signalT["position"][i] < signalT["position"][minimum]:
				minimum = i
		exportT.append(signalT["name"][minimum])
		signalT["name"].remove(minimum)
		signalT["position"].remove(minimum)
	if forward:
		return exportT
	else:
		exportT.invert()
		return exportT


func time2String(time):
	var hour = String(time[0])
	var minute = String(time[1])
	var second = String(time[2])
	if hour.length() == 1:
		hour = "0" + hour
	if minute.length() == 1:
		minute = "0" + minute
	if second.length() == 1:
		second = "0" + second
	return (hour + ":" + minute +":" + second)


func distance2String(distance):
	if distance > 10000:
		return String(int(distance/1000)) + " km"
	if distance > 1000:
		return String(int(distance/100)/10.0) + " km"
	if distance > 100:
		return String((int(distance/100))*100) + " m"
	else:
		return String((int(distance-10)/10)*10) + " m"

