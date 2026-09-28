extends Node2D

# Signals for external communication
signal level_complated
signal send_answered_data

# Question counters
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Sequence config data for each level and difficulty
var light_sequencer_level_organizer = {
	"easy": {
		"1": {"sequence_count": 2, "wait_time": 1},
		"2": {"sequence_count": 2, "wait_time": 0.7},
		"3": {"sequence_count": 3, "wait_time": 0.7},
		"4": {"sequence_count": 3, "wait_time": 0.5},
		"5": {"sequence_count": 4, "wait_time": 0.5},
		"6": {"sequence_count": 4, "wait_time": 0.5},
	},
	"hard": {
		"1": {"sequence_count": 5, "wait_time": 1},
		"2": {"sequence_count": 5, "wait_time": 1},
		"3": {"sequence_count": 6, "wait_time": 1},
		"4": {"sequence_count": 6, "wait_time": 1},
		"5": {"sequence_count": 7, "wait_time": 1},
		"6": {"sequence_count": 7, "wait_time": 1},
	}
}

# Current level and difficulty (fetched from global variables)
var current_level = "1"
var current_difficulity = "easy"

# The actual sequence and the player's input
var current_sequence = []
var input_sequence = []

# Whether the player is allowed to press buttons
var press_perm = false
@onready var ledsounds = $Sounds/LedSounds.get_children()







func _ready() -> void:
	# Set level and difficulty from global variables
	current_difficulity = Globals.current_difficulity
	current_level = Globals.current_level

	# Set up LED-button connections
	set_led_buttons()

	# Generate the first sequence
	make_sequence()

	# Debug labels to show sequence and input
	$Label.text = str(current_sequence)
	$Label2.text = str(input_sequence)

	# Disable buttons at the start
	disable_enable_buttons(true)

func make_sequence():
	# Clear sequences before generating a new one
	current_sequence.clear()
	input_sequence.clear()

	var led_count = $Leds.get_child_count()
	var sequence_count = light_sequencer_level_organizer[current_difficulity][current_level]["sequence_count"]

	# Create a new random sequence of LEDs
	for i in sequence_count:
		var random_led_index = randi() % led_count
		current_sequence.append(random_led_index)

	# Show the new sequence in debug label
	$Label.text = str(current_sequence)

	# Increment question count and start animation
	current_question += 1
	start()

func start():
	# Get wait time for current difficulty and level
	var wait_time = light_sequencer_level_organizer[current_difficulity][current_level]["wait_time"]

	# Wait 2 seconds before showing the sequence
	await get_tree().create_timer(2).timeout

	# Animate each LED in the sequence
	for led_index in current_sequence.size():
		var current_led = $Leds.get_children()[current_sequence[led_index]].get_node(NodePath("Sprite2D"))
		
		ledsounds[current_sequence[led_index]].play()
		
		current_led.frame_coords.x = 3
		await get_tree().create_timer(wait_time).timeout
		current_led.frame_coords.x = 0
		await get_tree().create_timer(wait_time).timeout

		# Enable buttons after the last LED is shown
		if led_index == current_sequence.size() - 1:
			disable_enable_buttons(false)

func set_led_buttons():
	# Connect each button to the press handler with the corresponding LED
	for i in $Buttons.get_child_count():
		var current_button = $Buttons.get_children()[i]
		var current_led = $Leds.get_children()[i].get_node(NodePath("Sprite2D"))

		current_button.connect("pressed", Callable(self, "led_button_pressed").bind(current_button, current_led))
		current_button.text = str(i)

func led_button_pressed(button, led):
	var wait_time = light_sequencer_level_organizer[current_difficulity][current_level]["wait_time"]

	# If input is still being collected
	if input_sequence.size() < current_sequence.size():
		# Record the player's input
		input_sequence.append(int(str(button.name)))
		$Label2.text = str(input_sequence)

		# If input is complete, check the answer
		if input_sequence.size() == current_sequence.size():
			if input_sequence == current_sequence:
				# Correct answer
				print("answer is true")
				answered_question += 1
				answered_correct_question += 1
				$Bar/AnimationPlayer.play("true")

				if current_question < max_question_count:
					make_sequence()
				else:
					print("End of the level")
			else:
				# Wrong answer
				print("answer is wrong")
				answered_question += 1
				$Bar/AnimationPlayer.play("false")
				disable_enable_buttons(true)
				input_sequence.clear()
				start()
	
	
	ledsounds[int(button.text)].play()
	# Flash the pressed LED briefly
	led.frame_coords.x = 3
	await get_tree().create_timer(wait_time).timeout
	led.frame_coords.x = 0

func disable_enable_buttons(value):
	# Enable or disable all buttons
	for i in $Buttons.get_children():
		i.disabled = value

func success_rate():
	# Emit result based on correct answer rate
	if answered_correct_question > answered_question / 2:
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	# At the end of an animation, check if the game is over
	if answered_question == max_question_count:
		success_rate()
	print(answered_correct_question, "/", answered_question)
