extends Node2D

func update_voltage(voltage):
	$Oberspannung.value = voltage

func update_time(time):
	var hour = String(time[0])
	var minute = String(time[1])
	var second = String(time[2])
	if hour.length() == 1:
		hour = "0" + hour
	if minute.length() == 1:
		minute = "0" + minute
	if second.length() == 1:
		second = "0" + second

	$Time.text = hour + ":" + minute +":" + second

func update_command(command):
	$ZK1.value = command
	$ZK2.value = command
	$ZK3.value = command
	$ZK4.value = command
	$ZK5.value = command
	$Oberstrom.value = command * 820
	$ZK6.value = - command
	$ZK7.value = - command
	$ZK8.value = - command
	$ZK9.value = - command
	$ZK10.value = - command


