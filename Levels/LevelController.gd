extends Node

@onready var Gui = %GUI
@onready var current_mechanic = $Mechanic.get_children()[0]



# Called when the scene is ready
func _ready() -> void:
	var wrong_sfx = AudioStreamPlayer2D.new()
	var true_sfx = AudioStreamPlayer2D.new()
	add_child(wrong_sfx)
	add_child(true_sfx)
	#wrong_sfx = load()
	#true_sfx =load("res://Sounds/win sound 1-2.wav")
	# Unpause the game
	get_tree().paused = false
	
	# Connect signals from the mechanic to appropriate functions
	current_mechanic.connect("send_answered_data",Callable(self,"write_score"))
	current_mechanic.connect("level_complated",Callable(self,"level_complated"))
	
	# Connect the "go_next_level" signal from GUI to the check_next_level function
	Gui.connect("go_next_level",Callable(self,"check_next_level"))

# Function to write the score on the GUI
func write_score(correct_answers,max_answers,game_state):
	# Display the score and game state message
	Gui.write_answer_score(correct_answers,max_answers)
	Gui.write_game_state_message(game_state)

# Function to handle level completion
func level_complated(value):
	# Show the next level menu based on the completion value
	Gui.show_next_level_menu(value)

# Function to check and handle the next level transition
func check_next_level():
	var cur_gmtyp = Globals.current_gametype
	var cur_chlng = Globals.current_challenge
	var cur_dif = Globals.current_difficulity
	var cur_lvl = Globals.current_level
	
	# Get the current level set data
	var current_level_set = Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]
	
	# If there are more levels to go, unlock the next level
	if int(cur_lvl) < current_level_set["levels"].size():
		Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]["levels"][cur_lvl] = {"complated": true, "locked": false}
		
		# Update the current level to the next one
		Globals.current_level = str(int(cur_lvl) + 1)
		cur_lvl = str(int(cur_lvl) + 1)
		
		# Lock and mark the next level as incomplete
		Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]["levels"][cur_lvl] = {"complated": false, "locked": false}
		Globals.save_data()
		
		# Change to the next level scene
		var next_level_scene_path = "res://Levels/" + cur_gmtyp + "/" + cur_chlng + "/" + cur_dif + "/" + str(int(cur_lvl) + 1) + ".tscn"
		var change_to_scene = get_tree().change_scene_to_file(next_level_scene_path)
		print("Next: ", cur_lvl)
	
	# If all levels are completed, check difficulty and level transition
	else:
		if cur_dif == "easy":
			# Mark the current easy level as completed and unlock hard difficulty
			Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]["levels"][cur_lvl] = {"complated": true, "locked": false}
			Globals.current_difficulity = "hard"
			cur_dif = "hard"
			Globals.current_level = "1"
			cur_lvl = "1"
			
			# Unlock the first level in hard difficulty
			Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]["locked"] = false
			Globals.level_data[cur_gmtyp][cur_chlng][cur_dif]["levels"][cur_lvl] = {"complated": false, "locked": false}
			Globals.save_data()
			
			# Change to the first level in hard difficulty
			var next_level_scene_path = "res://Levels/" + cur_gmtyp + "/" + cur_chlng + "/" + cur_dif + "/" + "1" + ".tscn"
			var change_to_scene = get_tree().change_scene_to_file(next_level_scene_path)
		
			print("Next: ", "/", "current_level_set: ", cur_dif, " / ", "level: " + cur_lvl)
			
		else:
			# If it is the last level set, go back to the menu
			print("Last level set")
			# back to menu
	
	pass
