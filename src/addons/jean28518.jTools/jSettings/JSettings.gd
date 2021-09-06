extends Control

func open_window():
	var node = get_tree().get_current_scene()
	var instance = self.duplicate()
	node.add_child(instance)
	instance.owner = node
	instance.update_and_prepare_language_handling()
	instance.update_settings_window()
	instance.show()

################################################################################

func _ready():
	if get_parent().name == "root":
		hide()

	if get_fullscreen() == null:
		set_fullscreen(true)

	if get_shadows() == null:
		set_shadows(true)

	if get_anti_aliasing() == null:
		set_anti_aliasing(2)

	if get_main_volume() == null:
		set_main_volume(1)

	if get_music_volume() == null:
		set_music_volume(1)

	if get_game_volume() == null:
		set_game_volume(1)

	if get_persons() == null:
		set_persons(true)

	apply_saved_settings()



func apply_saved_settings():
	OS.window_fullscreen = get_fullscreen()
	ProjectSettings.set_setting("rendering/quality/filters/msaa", get_anti_aliasing())

	## This can only be used, if JAudioManager is in project.
	if jConfig.enable_jAudioManager:
		jAudioManager.set_main_volume_db(get_main_volume())
		jAudioManager.set_game_volume_db(get_game_volume())
		jAudioManager.set_music_volume_db(get_music_volume())


func update_settings_window():
	$ScrollContainer/GridContainer/Fullscreen.pressed = get_fullscreen()
	$ScrollContainer/GridContainer/Shadows.pressed = get_shadows()
	$ScrollContainer/GridContainer/Fog.pressed = get_fog()
	$ScrollContainer/GridContainer/Persons.pressed = get_persons()
	$ScrollContainer/GridContainer/ViewDistance.value = get_view_distance()
	$ScrollContainer/GridContainer/Language.select(_language_table[get_language()])
	$ScrollContainer/GridContainer/AntiAliasing.selected = get_anti_aliasing()
	$ScrollContainer/GridContainer/MainVolume.value = get_main_volume()
	$ScrollContainer/GridContainer/MusicVolume.value = get_music_volume()
	$ScrollContainer/GridContainer/GameVolume.value = get_game_volume()
	$ScrollContainer/GridContainer/FramedropFix.pressed = get_framedrop_fix()

	if not jConfig.enable_jAudioManager:
		$ScrollContainer/GridContainer/Label4.hide()
		$ScrollContainer/GridContainer/GameVolume.hide()
		$ScrollContainer/GridContainer/Label5.hide()
		$ScrollContainer/GridContainer/MusicVolume.hide()

## Setter/Getter ###############################################################

func get_fullscreen():
	return jSaveManager.get_setting("fullscreen")

func set_fullscreen(val : bool):
	jSaveManager.save_setting("fullscreen", val)
	OS.window_fullscreen = val


func set_shadows(val : bool):
	jSaveManager.save_setting("shadows", val)

func get_shadows():
	return jSaveManager.get_setting("shadows")


func set_language(language_code : String):
	jSaveManager.save_setting("language", language_code)
	TranslationServer.set_locale(language_code)

func get_language():
	return jSaveManager.get_setting("language", TranslationServer.get_locale().rsplit("_")[0])


func set_anti_aliasing(val : int):
	jSaveManager.save_setting("antiAliasing", val)
	ProjectSettings.set_setting("rendering/quality/filters/msaa", val)

func get_anti_aliasing():
	return jSaveManager.get_setting("antiAliasing")


func set_main_volume(val : float):
	jSaveManager.save_setting("mainVolume", val)
	jAudioManager.set_main_volume_db(val)


func get_main_volume():
	return jSaveManager.get_setting("mainVolume")


func set_music_volume(val : float):
	jSaveManager.save_setting("musicVolume", val)
	jAudioManager.set_music_volume_db(val)

func get_music_volume():
	return jSaveManager.get_setting("musicVolume")


func set_game_volume(val : float):
	jSaveManager.save_setting("gameVolume", val)
	jAudioManager.set_game_volume_db(val)

func get_game_volume():
	return jSaveManager.get_setting("gameVolume")


func set_fog(value : bool):
	jSaveManager.save_setting("fog", value)

func get_fog():
	return jSaveManager.get_setting("fog", true)

func set_persons(value : bool):
	jSaveManager.save_setting("persons", value)

func get_persons():
	return jSaveManager.get_setting("persons", true)


func set_view_distance(value : int):
	jSaveManager.save_setting("view_distance", value)

func get_view_distance():
	return jSaveManager.get_setting("view_distance", 1000)


func set_framedrop_fix(value : bool):
	jSaveManager.save_setting("framedrop_fix", value)

func get_framedrop_fix():
	return jSaveManager.get_setting("framedrop_fix", true)


## Other Functionality #########################################################

var _language_table = {"en" : 0, "de" : 1} # Translates language codes to ids
func update_and_prepare_language_handling():
	var language_codes = TranslationServer.get_loaded_locales()
	language_codes = jEssentials.remove_duplicates(language_codes)
	if language_codes.size() == 0:
		$ScrollContainer/GridContainer/Label7.hide()
		$ScrollContainer/GridContainer/Language.hide()
		return


	# Prepare _language_table
	language_codes.sort()
	_language_table.clear()
	for i in language_codes.size():
		_language_table[language_codes[i]] = i

	# Prepare language
	for index in range(_language_table.size()):
		$ScrollContainer/GridContainer/Language.add_item("",index)
	for language in _language_table.keys():
		$ScrollContainer/GridContainer/Language.set_item_text(_language_table[language], TranslationServer.get_locale_name(language))

	# If Language is not found, select one language, which is available
	var language_code = get_language()
	if not _language_table.has(language_code):
		if not language_codes.has("en"):
			language_code = _language_table.keys()[0]
		else:
			language_code = "en"
	set_language(language_code)

func _id_to_language_code(id : int):
	for key in _language_table:
		if _language_table[key] == id:
			return key

## Other Signals ###############################################################

func _on_Back_pressed():
	queue_free()

func _on_Fullscreen_pressed():
	set_fullscreen($ScrollContainer/GridContainer/Fullscreen.pressed)

func _on_Shadows_pressed():
	set_shadows($ScrollContainer/GridContainer/Shadows.pressed)

func _on_Language_item_selected(index):
	set_language(_id_to_language_code(index))

func _on_Fog_pressed():
	set_fog($ScrollContainer/GridContainer/Fog.pressed)


func _on_Persons_pressed():
	set_persons($ScrollContainer/GridContainer/Persons.pressed)
