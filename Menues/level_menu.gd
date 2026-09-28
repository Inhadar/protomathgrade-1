extends Control
signal back_to_start_menu
@onready var levels_file = "res://Levels/"

# Level data sheet: Stores levels' status such as locked and completed for each game type, challenge, and difficulty
var levels_data = {
	"MATH":{
		"Challenge_1":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}},
		"Challenge_2":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}}
	},
	
	"LOGIC":{
		"Challenge_1":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}},
		"Challenge_2":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}}
	},
	
	"MEMORY":{
		"Challenge_1":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}},
		"Challenge_2":{"easy":{"locked":false,"levels":{}},"hard":{"locked":true,"levels":{}}}
	}
}

# Levels menu setup
@onready var grid_container: = %LevelSets
var num_grids = 1
var current_grid = 1
var grid_width = 548

# Called when the scene is ready
func _ready():
	# Unpause the game and load data
	get_tree().paused = false
	Globals.load_data()
	
	# Initialize level menu settings
	num_grids = grid_container.get_child_count()
	grid_width = grid_container.custom_minimum_size.x
	check_gemetype_and_chalenge()
	calculate_level_data()
	pass

# Connect game type and challenge buttons to their respective functions
func check_gemetype_and_chalenge():
	for gametypebutton in $GameTypes.get_children():
		gametypebutton.connect("pressed",Callable(self,"GametypeButtonPressed").bind(gametypebutton))
	for challengebutton in $Challenges.get_children():
		challengebutton.connect("pressed",Callable(self,"ChallengeButtonPressed").bind(challengebutton))

var current_gametype = null
var current_challenge = null

# Handles the press of a game type button
func GametypeButtonPressed(button):
	print(button.name)
	$Challenges.show() 
	$GameTypes.hide()
	$MenuBackButton.show()
	current_gametype = str(button.name)
	Globals.current_gametype = str(button.name)
	$DataBox/GameTypeData.text = "Current Gametype: "+ str(button.name)

# Handles the press of a challenge button
func ChallengeButtonPressed(button):
	print(button.name)
	$Challenges.hide()
	$LevelMenu.show()
	current_challenge = str(button.name)
	Globals.current_challenge = str(button.name)
	$DataBox/ChallengesData.text = "Current Challenge: "+ str(button.name)
	set_level_buttons()

# Set up level buttons with appropriate states (locked, unlocked, completed)
func set_level_buttons():
	for i in %LevelSets.get_children():
		for j in i.get_children():
			if !j.is_connected("pressed",Callable(self,"LevelButtonPressed")):
				j.connect("pressed",Callable(self,"LevelButtonPressed").bind(i.name,j.name))
			
			if Globals.level_data != null:
				var current_levelset_data = Globals.level_data[current_gametype][current_challenge]
				if current_levelset_data[str(i.name)]["levels"][str(j.name)]["locked"] == false:
					j.disabled = current_levelset_data[str(i.name)]["levels"][str(j.name)]["locked"]
					j.get_node(NodePath("Label")).show()
					j.get_node(NodePath("Label")).text = j.name
				else:
					j.disabled = current_levelset_data[str(i.name)]["levels"][str(j.name)]["locked"]
					j.get_node(NodePath("Label")).hide()
					j.get_node(NodePath("Label")).text = j.name
				
				if current_levelset_data[str(i.name)]["levels"][str(j.name)]["complated"] == true:
					j.toggle_mode = true
					j.button_pressed = true
				else:
					j.toggle_mode = false
					j.button_pressed = false
					j.disabled = current_levelset_data[str(i.name)]["levels"][str(j.name)]["locked"]

# Handle level button presses
func LevelButtonPressed(difficulty, level_name):
	Globals.current_difficulity = difficulty
	Globals.current_level = level_name
	
	# Change scene to the selected level
	go_to_game_scene(current_gametype, current_challenge, difficulty, level_name)

# Calculate and set level data if not already set
func calculate_level_data():
	if Globals.level_data == null:
		for gametype in $GameTypes.get_children():
			for challenge in $Challenges.get_children():
				var current_levelset_data = levels_data[str(gametype.name)][str(challenge.name)]
				for i in %LevelSets.get_children():
					for j in i.get_children():
						if current_levelset_data[str(i.name)]["locked"] == false:
							if j.name == "1":
								current_levelset_data[str(i.name)]["levels"][str(j.name)] =  {"complated":false,"locked":false}
								j.disabled = current_levelset_data[str(i.name)]["levels"][str(j.name)]["locked"]
								j.get_node(NodePath("Label")).show()
								j.get_node(NodePath("Label")).text = j.name
							else:
								current_levelset_data[str(i.name)]["levels"][str(j.name)] = {"complated":false,"locked":true}
						else:
							current_levelset_data[str(i.name)]["levels"][str(j.name)] = {"complated":false,"locked":true}
					
		Globals.level_data = levels_data
		Globals.save_data()

# Handle back button press to navigate through level grids
func _on_back_button_pressed():
	if current_grid > 1:
		current_grid -= 1
		animateGridPosition(grid_container.position.x + grid_width)
		$LevelMenu/LevelSet.text = "Easy"

# Handle next button press to navigate through level grids
func _on_next_button_pressed():
	if current_grid < num_grids:
		current_grid += 1
		animateGridPosition(grid_container.position.x - grid_width)
		$LevelMenu/LevelSet.text = "Hard"

# Animate the grid movement when navigating between levels
func animateGridPosition(finalValue):
	create_tween().set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT).tween_property(
		grid_container, "position:x", finalValue, 0.5
	)

# Function to change to the game scene for a specific level
func go_to_game_scene(gametype, challenge, level_set, level_name):
	var target_scene = levels_file + gametype + "/" + challenge + "/" + level_set + "/" + level_name + ".tscn"
	
	if FileAccess.file_exists(target_scene):
		print("scene exists")
		get_tree().change_scene_to_file(target_scene)
	else:
		print("scene not found")
	print(target_scene)
	pass



# Handle menu back button press to navigate back through the menus
func _on_menu_back_button_pressed() -> void:
	if $GameTypes.visible:
		back_to_start_menu.emit()
		$MenuBackButton.hide()
		
	if $Challenges.visible:
		$GameTypes.visible = true
		$Challenges.visible = false
		#$MenuBackButton.hide()
		current_gametype = null
		Globals.current_gametype = null
	if $LevelMenu.visible:
		$LevelMenu.visible = false
		$Challenges.visible = true
		current_challenge = null
		Globals.current_challenge = null
