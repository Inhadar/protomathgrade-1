extends Control


@onready var master_slider = %Master
@onready var music_slider = %Music
@onready var sfx_slider = %Sfx
@onready var mute_button = %Mute


func _ready() -> void:
	Globals.load_data()
	load_volume_settings()






func load_volume_settings():
	master_slider.value = Globals.master_volume
	music_slider.value = Globals.music_volume
	sfx_slider.value = Globals.sfx_volume
	mute_button.button_pressed = Globals.mute_volume
	set_volume_settings(Globals.master_volume, Globals.music_volume,Globals.sfx_volume,Globals.mute_volume)


func save_volume_settings():
	Globals.master_volume = master_slider.value 
	Globals.music_volume = music_slider.value
	Globals.sfx_volume = sfx_slider.value
	Globals.mute_volume = mute_button.button_pressed
	Globals.save_data()


func set_volume_settings(master,music,sfx,mute):
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),master)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),music)
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"),sfx)
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(idx,mute)


func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),value)


func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),value)


func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"),value)


func _on_mute_toggled(toggled_on: bool) -> void:
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(idx,toggled_on)




# This function is called when the start button is pressed
func _on_start_pressed() -> void:
	# Change the scene to the level menu scene
	#get_tree().change_scene_to_file("res://Menues/level_menu.tscn")
	$VBoxContainer.hide()
	$LevelMenu.show()
	$LevelMenu/MenuBackButton.show()

func _on_settings_pressed() -> void:
	$VBoxContainer.visible = false
	$Settings.visible = true
	$BackButton.visible = true

func _on_quit_pressed() -> void:
	get_tree().quit()


func _on_back_button_pressed() -> void:
	if $Settings.visible == true:
		$Settings.visible = false
		$VBoxContainer.visible = true
		$BackButton.visible = false
		save_volume_settings()


func _on_level_menu_back_to_start_menu() -> void:
	$LevelMenu.hide()
	$VBoxContainer.show()
