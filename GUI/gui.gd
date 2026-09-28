extends CanvasLayer

@onready var answer_score_label = $NextLevelMenu/VBoxContainer/Answers_Score
@onready var game_state_message = $NextLevelMenu/VBoxContainer/Game_State_Message
signal go_next_level 


@onready var master_slider = %Master
@onready var music_slider = %Music
@onready var sfx_slider = %Sfx
@onready var mute_button = %Mute


# Lose messages array: Messages to display when the player loses
var lose_messages = [
	"Oops! Give it another shot!",
	"You're getting closer!",
	"Nice try!",
	"Keep going!",
	"You can do it!",
	"One more try!",
	"Don't give up!",
	"Let's try that again!"
]

# Win messages array: Messages to display when the player wins
var win_messages = [
	"Great job!",
	"You got it!",
	"Well done!",
	"Awesome work!",
	"That's right!",
	"Superstar!",
	"You're amazing!"
]

# Called when the scene is ready
func _ready() -> void:
	$GameData/LevelName.text = "Level Number: " + Globals.current_level
	#write_answer_score(3,5)
	#write_game_state_message("you_win")
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
	pass

	
	
	
	
	
	
	
	
	
	
	
	
	
	
# Called every frame to update the FPS label
func _process(delta: float) -> void:
	$GameData/Fps.text = "FPS: "+ str(Engine.get_frames_per_second())

# Function to update the answer score display
func write_answer_score(correct,all):
	answer_score_label.text = "Correct Answers:"+"\n"+str(correct) +"/"+str(all)

# Function to display the game state message based on the result
func write_game_state_message(game_state):
	if game_state == "you_win":
		# Display a random win message
		var current_message_index = randi()%win_messages.size()
		game_state_message.text = win_messages[current_message_index]
	
	elif game_state == "you_lose":
		# Display a random lose message
		var current_message_index = randi()%lose_messages.size()
		game_state_message.text = lose_messages[current_message_index]

##### NEXT LEVEL MENU ##### 
# Function to show the next level menu, paused state is activated
func show_next_level_menu(value):
	get_tree().paused = true
	$NextLevelMenu.show()
	if value == "win":
		# Enable the "Next" button if the player won
		$NextLevelMenu/HBoxContainer/Next.disabled = false
		$Sounds/Won.play()
	elif value == "lose":
		# Disable the "Next" button if the player lost
		$NextLevelMenu/HBoxContainer/Next.disabled = true
		$Sounds/Lose.play()

# Function to transition to the main menu
func _on_menu_pressed() -> void:
	get_tree().change_scene_to_file("res://Menues/level_menu.tscn")

# Function to reload the current scene (restart)
func _on_restart_pressed() -> void:
	var _reset = get_tree().reload_current_scene()

# Function to go to the next level when the "Next" button is pressed
func _on_next_pressed() -> void:
	go_next_level.emit()

# Function to pause the game and show the pause menu
func _on_pause_button_pressed() -> void:
	get_tree().paused = true
	$PauseMenu.show()

# Function to return from the pause menu and resume the game
func _on_return_pressed() -> void:
	get_tree().paused = false
	$PauseMenu.hide()


func _on_settings_pressed() -> void:
	
	%Settings.show()
	%VBoxContainer.hide()
	

func _on_back_pressed() -> void:
	%Settings.hide()
	%VBoxContainer.show()
	save_volume_settings()


func _on_master_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"),value)


func _on_music_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Music"),value)


func _on_sfx_value_changed(value: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Sfx"),value)


func _on_mute_toggled(toggled_on: bool) -> void:
	var idx = AudioServer.get_bus_index("Master")
	AudioServer.set_bus_mute(idx,toggled_on)
