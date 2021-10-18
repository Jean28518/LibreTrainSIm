extends PanelContainer


var currentTrack := ""
var currentTrain := ""
var currentScenario := ""
var screenshot_texture: Texture


func show() -> void:
	update_track_list()
	.show()


func update_track_list():
	$Play/Selection/Tracks/Tracks.clear()
	for track in ContentLoader.foundTracks:
		$Play/Selection/Tracks/Tracks.add_item(track.get_file().get_basename())

func update_train_list():
	$Play/Selection/Trains/Trains.clear()
	for train in ContentLoader.foundTrains:
		$Play/Selection/Trains/Trains.add_item(train.get_file().get_basename())


func _on_Back_pressed() -> void:
	hide()


func _on_Play_pressed():
	if currentScenario == "" or currentTrack == "" or currentTrain == "": return
	var index = $Play/Selection/Tracks/Tracks.get_selected_items()[0]
	Root.currentScenario = currentScenario
	Root.currentTrain = currentTrain
	Root.EasyMode = $Play/Info/Info/EasyMode.pressed
	hide()

	## Load
	var track_name = ContentLoader.foundTracks[index].get_basename().get_file()
	var save_path = ContentLoader.foundTracks[index].get_basename() + "-scenarios.cfg"

	var loadScenePath = ContentLoader.foundTracks[index]
	LoadingScreen.load_world(loadScenePath, currentScenario, currentTrain, screenshot_texture)


func _on_Tracks_item_selected(index: int) -> void:
	currentTrack = ContentLoader.foundTracks[index]
	Root.checkAndLoadTranslationsForTrack(currentTrack.get_file().get_basename())
	currentScenario = ""
	var save_path = ContentLoader.foundTracks[index].get_basename() + "-scenarios.cfg"
	$jSaveModule.set_save_path(save_path)

	var wData = $jSaveModule.get_value("world_config", null)
	if wData == null:
		Logger.err("No scenarios found.", save_path)
		$Play/Info/Description.text = tr("MENU_NO_SCENARIO_FOUND")
		$Play/Selection/Scenarios.hide()
		return
	$Play/Info/Description.text = tr(wData["TrackDesciption"])
	$Play/Info/Info/Author.text = " "+ tr("MENU_AUTHOR") + ": " + wData["Author"] + " "
	$Play/Info/Info/ReleaseDate.text = " "+ tr("MENU_RELEASE") + ": " + String(wData["ReleaseDate"][1]) + " " + String(wData["ReleaseDate"][2]) + " "
	var track_name = currentTrack.get_basename().get_file()
	Logger.vlog(track_name)
	$Play/Info/Screenshot.texture = _make_image("res://Worlds/"+track_name + "/screenshot.png")


	$Play/Selection/Scenarios.show()
	$Play/Selection/Scenarios/Scenarios.clear()
	$Play/Selection/Trains.hide()
	$Play/Info/Info/EasyMode.hide()
	var scenarios = $jSaveModule.get_value("scenario_list", [])
	for scenario in scenarios:
		# FIXME: remove mobile version hack and replace with resource based loading
		if Root.mobile_version and (scenario == "The Basics" or scenario == "Advanced Train Driving"):
			continue
		if not Root.mobile_version and scenario == "The Basics - Mobile Version":
			continue
		$Play/Selection/Scenarios/Scenarios.add_item(scenario)


func _on_Scenarios_item_selected(index: int) -> void:
	currentScenario = $Play/Selection/Scenarios/Scenarios.get_item_text(index)
	var save_path = ContentLoader.foundTracks[$Play/Selection/Tracks/Tracks.get_selected_items()[0]].get_basename() + "-scenarios.cfg"
	var sData = $jSaveModule.get_value("scenario_data")
	$Play/Info/Description.text = tr(sData[currentScenario]["Description"])
	$Play/Info/Info/Duration.text = "%s: %s min" % [tr("MENU_DURATION"), sData[currentScenario]["Duration"]]
	$Play/Selection/Trains.show()
	$Play/Info/Info/EasyMode.hide()
	update_train_list()

	# Search and preselect train from scenario:
	$Play/Selection/Trains/Trains.unselect_all()
	var preferredTrain = sData[currentScenario]["Trains"].get("Player", {}).get("PreferredTrain", "")
	if preferredTrain != "":
		for i in range(ContentLoader.foundTrains.size()):
			if ContentLoader.foundTrains[i].find(preferredTrain) != -1:
				$Play/Selection/Trains/Trains.select(i)
				_on_Trains_item_selected(i)


func _on_Trains_item_selected(index: int) -> void:
	currentTrain = ContentLoader.foundTrains[index]
	Root.checkAndLoadTranslationsForTrain(currentTrain.get_base_dir())
	# FIXME: this should not happen in the menu. The trains can get huge, so we should
	# add a resource holding information about the trains
	var train = load(currentTrain).instance()
	Logger.vlog("Current Train: "+currentTrain)
	$Play/Info/Description.text = tr(train.description)
	$Play/Info/Info/ReleaseDate.text = tr("MENU_RELEASE")+": "+ train.releaseDate
	$Play/Info/Info/Author.text = tr("MENU_AUTHOR")+": "+ train.author
	$Play/Info/Screenshot.texture = _make_image(train.screenshotPath)
	var electric = tr("YES")
	if not train.electric:
		electric = tr("NO")
	$Play/Info/Info/Duration.text = tr("MENU_ELECTRIC")+ ": " + electric
	if not Root.mobile_version:
		$Play/Info/Info/EasyMode.show()
	else:
		$Play/Info/Info/EasyMode.pressed = true
	train.queue_free()


func _make_image(path: String) -> Texture:
	var dir := Directory.new()
	dir.open("res://")
	if dir.file_exists(path):
		screenshot_texture = load(path)
		# FIXME: Fails, because image is not imported as resource. That needs to change
		# but I don't want to bloat this PR even more, so it will be done in a subsequent
		# PR. Ping HaSa1002, if this message made its way into 0.9
	else:
		var img := Image.new()
		img.create(1, 1, false, Image.FORMAT_RGB8)
		img.fill(Color.black)
		screenshot_texture = ImageTexture.new()
		screenshot_texture.create_from_image(img)
	return screenshot_texture
