extends Node



var master_volume :float = 0.0
var music_volume :float= 0.0
var sfx_volume :float = 0.0
var mute_volume :bool = false


# Variables to hold the current game type, challenge, level, and difficulty
var current_gametype = null
var current_challenge = null
var current_level = null
var current_difficulity = null

# Variable to store level data and the save file path
var level_data = null
const savefile := "user://save_file.save"

# Function to save the level data to the save file
func save_data():
	# Open the save file in write mode
	var new_save_data := FileAccess.open(savefile, FileAccess.WRITE)
	# Store the level data to the save file
	new_save_data.store_var(level_data)
	new_save_data.store_var(master_volume)
	new_save_data.store_var(music_volume)
	new_save_data.store_var(sfx_volume)
	new_save_data.store_var(mute_volume)
	# Close the file after saving
	new_save_data.close()

# Function to load level data from the save file
func load_data():
	# Check if the save file exists
	if FileAccess.file_exists(savefile):
		# Open the save file in read mode
		var load_file := FileAccess.open(savefile, FileAccess.READ)
		# Get the level data from the save file
		level_data = load_file.get_var()
		master_volume = load_file.get_var()
		music_volume = load_file.get_var()
		sfx_volume = load_file.get_var()
		mute_volume = load_file.get_var()
		# Close the file after loading
		load_file.close()
