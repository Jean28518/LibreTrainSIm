tool
extends Control


export var version = ""
var mobile_version := false setget update_project_for_mobile
var save_path := OS.get_executable_path().get_base_dir()+"config.cfg"


func _ready():
	if Engine.is_editor_hint():
		return
	update_config()
	$Version.text = "Version: " + String(version)
	var openTimes = jSaveManager.get_value("open_times", 0)
	openTimes += 1
	jSaveManager.save_value("open_times", openTimes)
	var feedbackPressed = jSaveManager.get_value("feedback_pressed", false)
	if openTimes > 3 and not feedbackPressed and not mobile_version:
		$FeedBack/VBoxContainer/RichTextLabel.text = TranslationServer.translate("MENU_FEEDBACK_QUESTION")
		$FeedBack.popup()
	$MusicPlayer.play(0)

	mobile_version = Root.mobile_version
	if mobile_version:
		set_menu_to_mobile()

	if Root.start_menu_in_play_menu:
		Root.start_menu_in_play_menu = false
		$FeedBack.hide()
		_on_PlayFront_pressed()


func set_menu_to_mobile():
	$Front/VBoxContainer.hide()
	$Front/VBoxContainerAndoid.show()
	$Play/Buttons/Play.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Buttons/Back.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Tracks/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Tracks/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Scenarios/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Scenarios/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Trains/Label.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))
	$Play/Selection/Trains/ItemList.add_font_override("font", preload("res://addons/Libre_Train_Sim_Editor/Data/Misc/FontMenu.tres"))


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	if Engine.is_editor_hint():
		return
	load_scene(delta)
	updateBottmLabels()


var foundTracks = []
var foundContentPacks = []
var foundTrains = []

var currentTrack = ""
var currentTrain = ""
var currentScenario = ""

func _on_Quit_pressed():
	get_tree().quit()


func updateBottmLabels():
	$Label_Music.visible = jSaveManager.get_setting("musicVolume", 0.0) != 0.0
	$Version.visible = $Front.visible

func _on_BackPlay_pressed():
	$Play.hide()
	$MenuBackground.hide()
	$Front.show()
	$Version.show()




func _on_PlayFront_pressed():
	update_track_list()
	$Play.show()
	$MenuBackground.show()
	$Front.hide()
	$Version.hide()

func _on_Content_pressed():
	update_content()
	$Front.hide()
	$MenuBackground.show()
	$Content.show()

func _on_SettingsFront_pressed():
#	$Front.hide()
	jSettings.open_window()
#	$MenuBackground.show()
#	$Settings.show()


func update_config():
	## Get All .pck files:
	foundContentPacks = []
	if OS.has_feature("standalone"):
		foundContentPacks.append_array(jEssentials.crawl_directory_for(OS.get_executable_path().get_base_dir(), "pck"))
		foundContentPacks.append_array(jEssentials.crawl_directory_for("user://addons/", "pck"))
	else:
		print("Skipping pack loading in editor build, because of https://github.com/godotengine/godot/issues/16798")
	print("Found Content Packs: %s" % [foundContentPacks])

	for contentPack in foundContentPacks:
		if ProjectSettings.load_resource_pack(contentPack, false):
			print("Loading Content Pack %s successfully finished" % contentPack)

	## Get all Tracks:
	var foundFiles = {"Array": []}
	Root.crawlDirectory("res://Worlds",foundFiles,"tscn")
	foundTracks = foundFiles["Array"].duplicate(true)

	## Get all Trains
	foundFiles = {"Array": []}
	Root.crawlDirectory("res://Trains",foundFiles,"tscn")
	foundTrains = foundFiles["Array"].duplicate(true)


func update_track_list():
	$Play/Selection/Tracks/ItemList.clear()
	for track in foundTracks:
		$Play/Selection/Tracks/ItemList.add_item(track.get_file().get_basename())

func update_train_list():
	$Play/Selection/Trains/ItemList.clear()
	for train in foundTrains:
		$Play/Selection/Trains/ItemList.add_item(train.get_file().get_basename())


# Play Page:
func _on_PlayPlay_pressed():
	if currentScenario == "" or currentTrack == "" or currentTrain == "": return
	var index = $Play/Selection/Tracks/ItemList.get_selected_items()[0]
	Root.currentScenario = currentScenario
	Root.currentTrain = currentTrain
	Root.EasyMode = $Play/Info/Info/EasyMode.pressed
	$MenuBackground.hide()
	$Play.hide()
	$Loading.show()
	## Load
	var track_name = foundTracks[index].get_basename().get_file()
	var save_path = foundTracks[index].get_basename() + "-scenarios.cfg"

	if currentTrack.get_basename().get_file() == "Tutorials":
		$Background.texture = load("res://Worlds/"+track_name + "/screenshot.png")
	else:
		$Background.texture = _current_track_screenshot_texture
	loadScenePath = foundTracks[index]

var loadScenePath = ""
var load_scene_timer = 0
func load_scene(delta):
	if loadScenePath != "":
		load_scene_timer += delta
		if load_scene_timer > 0.2:
			get_tree().change_scene(loadScenePath)

var _current_track_screenshot_texture
func _on_ItemList_itemTracks_selected(index):
	currentTrack = foundTracks[index]
	Root.checkAndLoadTranslationsForTrack(currentTrack.get_file().get_basename())
	currentScenario = ""
	var save_path = foundTracks[index].get_basename() + "-scenarios.cfg"
	$jSaveModule.set_save_path(save_path)

	var wData = $jSaveModule.get_value("world_config", null)
	if wData == null:
		print(save_path)
		$Play/Info/Description.text = TranslationServer.translate("MENU_NO_SCENARIO_FOUND")
		$Play/Info/Description.text = TranslationServer.translate(save_path)
		$Play/Selection/Scenarios.hide()
		return
	$Play/Info/Description.text = TranslationServer.translate(wData["TrackDesciption"])
	$Play/Info/Info/Author.text = " "+ TranslationServer.translate("MENU_AUTHOR") + ": " + wData["Author"] + " "
	$Play/Info/Info/ReleaseDate.text = " "+ TranslationServer.translate("MENU_RELEASE") + ": " + String(wData["ReleaseDate"][1]) + " " + String(wData["ReleaseDate"][2]) + " "
	var track_name = currentTrack.get_basename().get_file()
	print(track_name)

	if track_name == "Tutorials":
		$Play/Info/Screenshot.texture = load("res://Worlds/"+track_name + "/screenshot.png")
	else:
		# Import at runtime:
		var screenshot = Image.new()
		screenshot.load("res://Worlds/"+track_name + "/screenshot.png")
		_current_track_screenshot_texture = ImageTexture.new()
		_current_track_screenshot_texture.create_from_image(screenshot)
		$Play/Info/Screenshot.texture = _current_track_screenshot_texture


	$Play/Selection/Scenarios.show()
	$Play/Selection/Scenarios/ItemList.clear()
	$Play/Selection/Trains.hide()
	$Play/Info/Info/EasyMode.hide()
	var scenarios = $jSaveModule.get_value("scenario_list", [])
	for scenario in scenarios:
		if mobile_version and (scenario == "The Basics" or scenario == "Advanced Train Driving"):
			continue
		if not mobile_version and scenario == "The Basics - Mobile Version":
			continue
		$Play/Selection/Scenarios/ItemList.add_item(scenario)

## Content Page:
func update_content():
	$Content/Label.text = tr("MENU_TO_ADD_CONTENT") + " %s, %s" % \
			[OS.get_executable_path().get_base_dir(), OS.get_user_data_dir() + "/addons"]
	$Content/ItemList.clear()
	for contentPack in foundContentPacks:
		$Content/ItemList.add_item(contentPack)



func _on_BackContent_pressed():
	$MenuBackground.hide()
	$Content.hide()
	$Front.show()

func _on_ReloadContent_pressed():
	update_config()
	update_content()


func _on_ItemList_scenario_selected(index):
	currentScenario = $Play/Selection/Scenarios/ItemList.get_item_text(index)
	var save_path = foundTracks[$Play/Selection/Tracks/ItemList.get_selected_items()[0]].get_basename() + "-scenarios.cfg"
	var sData = $jSaveModule.get_value("scenario_data")
	$Play/Info/Description.text = TranslationServer.translate(sData[currentScenario]["Description"])
	$Play/Info/Info/Duration.text = TranslationServer.translate("MENU_DURATION")+": " + String(sData[currentScenario]["Duration"]) + " min"
	$Play/Selection/Trains.show()
	$Play/Info/Info/EasyMode.hide()
	update_train_list()

	# Search and preselect train from scenario:
	$Play/Selection/Trains/ItemList.unselect_all()
	var preferredTrain = sData[currentScenario]["Trains"].get("Player", {}).get("PreferredTrain", "")
	if preferredTrain != "":
		for i in range(foundTrains.size()):
			if foundTrains[i].find(preferredTrain) != -1:
				$Play/Selection/Trains/ItemList.select(i)
				_on_ItemList_Train_selected(i)






func _on_ItemList_Train_selected(index):
	currentTrain = foundTrains[index]
	Root.checkAndLoadTranslationsForTrain(currentTrain.get_base_dir())
	var train = load(currentTrain).instance()
	currentTrain = foundTrains[index]
	print("Current Train: "+currentTrain)
	$Play/Info/Description.text = TranslationServer.translate(train.description)
	$Play/Info/Info/ReleaseDate.text = TranslationServer.translate("MENU_RELEASE")+": "+ train.releaseDate
	$Play/Info/Info/Author.text = TranslationServer.translate("MENU_AUTHOR")+": "+ train.author
	$Play/Info/Screenshot.texture = load(train.screenshotPath)
	var electric = TranslationServer.translate("YES")
	if not train.electric:
		electric = TranslationServer.translate("NO")
	$Play/Info/Info/Duration.text = TranslationServer.translate("MENU_ELECTRIC")+ ": " + electric
	if not Root.mobile_version:
		$Play/Info/Info/EasyMode.show()
	else:
		$Play/Info/Info/EasyMode.pressed = true
	train.queue_free()



func _on_ButtonFeedback_pressed():
	jSaveManager.save_value("feedback_pressed", true)
	OS.shell_open("https://www.libre-trainsim.de/feedback")



func _on_OpenWebBrowser_pressed():
	_on_ButtonFeedback_pressed()
	$FeedBack.hide()


func _on_Later_pressed():
	$FeedBack.hide()









func update_project_for_mobile(value):
	Root.set_low_resolution(value)
	mobile_version = value






func _on_FrontCreate_pressed():
#	OS.shell_open("https://www.libre-trainsim.de/contribute")
	$Editor_Configuration.init()
	$MenuBackground.show()
	$Editor_Configuration.show()
	$Front.hide()




func _on_Options_pressed_delme():
	jSettings.open_window()


func hide_editor_configuration():
	$MenuBackground.hide()
	$Editor_Configuration.hide()
	$Front.show()


func _on_Editor_Configuration_Back_Button_pressed():
	hide_editor_configuration()
