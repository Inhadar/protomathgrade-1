extends Node2D

# Signals for level completion and sending answer results
signal level_complated
signal send_answered_data

# Question tracking variables
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Drag & drop state variables
var pick_answer = false
var current_answer_box = null
var swipe_speed = 10

# Target position for dropping the correct answer
@onready var target_area_position = %AnswerAreaPos.global_position

# Position and value memory for answer boxes
var answer_old_poses = [null, null, null, null]
var answers_on_buttons = [null, null, null, null]

# Flags for reset and placement states
var reset_answer_box = false
var current_question_data = {}
var buttons_already_connected = false
var answer_is_placed = false

# Level configuration table
var math_level_organizer = {
	"easy": {
		"1": {"type": ["Addition"], "up_to_number": 5},
		"2": {"type": ["Subtraction"], "up_to_number": 5},
		"3": {"type": ["Addition", "Subtraction"], "up_to_number": 5},
		"4": {"type": ["Addition", "Subtraction"], "up_to_number": 5},
		"5": {"type": ["Multiplication"], "up_to_number": 5},
		"6": {"type": ["Multiplication"], "up_to_number": 5},
	},
	"hard": {
		"1": {"type": ["Division"], "up_to_number": 10},
		"2": {"type": ["Division"], "up_to_number": 10},
		"3": {"type": ["Multiplication", "Division"], "up_to_number": 10},
		"4": {"type": ["Multiplication", "Division"], "up_to_number": 10},
		"5": {"type": ["Multiplication", "Division", "Subtraction", "Addition"], "up_to_number": 10},
		"6": {"type": ["Multiplication", "Division", "Subtraction", "Addition"], "up_to_number": 10},
	}
}

# Current game difficulty and level
var current_difficulty = "easy"
var current_level = "1"


@onready var answers_buttons = $AnswerBox2.get_children()

func _ready() -> void:
	# Load global difficulty and level, then generate first question
	if Globals.current_difficulity != null and Globals.current_level != null:
		current_difficulty = Globals.current_difficulity
		current_level = Globals.current_level
	make_question()


"""
func _physics_process(delta: float) -> void:
	# Handle swipe and answer drop logic each frame
	#math_swipe_process(delta)
	pass

func math_swipe_process(delta):
	if current_answer_box != null:
		var target_distance = current_answer_box.global_position.distance_to(target_area_position)
		var old_pos_distance = current_answer_box.global_position.distance_to(answer_old_poses[int(current_answer_box.name)])

		if pick_answer:
			# Follow mouse while dragging
			current_answer_box.global_position = lerp(current_answer_box.global_position, get_global_mouse_position(), delta * swipe_speed)
		else:
			if reset_answer_box == false:
				if target_distance < 50:
					# Check if answer is correct when dropped in target zone
					var true_answer = current_question_data["answer"]
					var current_answer = int(current_answer_box.text)
					if true_answer == current_answer:
						if answer_is_placed == false:
							print("Answer is True")
							answered_correct_question += 1
							answered_question += 1
							$QuestionBox/Bar/AnimationPlayer.play("true")
							disable_all_buttons(true)
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true
					else:
						if answer_is_placed == false:
							# Wrong answer
							disable_all_buttons(true)
							$QuestionBox/Bar/AnimationPlayer.play("false")
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true
				elif old_pos_distance > 50 and target_distance > 50:
					# Smoothly return to old position if outside target area
					current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)
				elif old_pos_distance < 50 and target_distance > 50:
					# Snap back if already close
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
			else:
				# Smooth reset animation
				current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)
				if old_pos_distance < 50:
					# Complete reset
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
					reset_answer_box = false
					answer_is_placed = false
					if current_question < max_question_count:
						make_question()
					else:
						success_rate()
"""


func disable_all_buttons(value):
	# Enable or disable all buttons
	for i in answers_buttons:
		i.disabled = value

func set_answer_buttons(answers):
	# Connect button events if not already connected
	for i in answers_buttons:
		if !i.is_connected("pressed",Callable(self,"answer_button_pressed")):
			i.connect("pressed",Callable(self,"answer_button_pressed").bind(i))
	"""
	for i in $AnswerBox.get_children():
		i.get_node(NodePath("Button")).connect("button_down", Callable(self, "Answer_Picked").bind(i))
		i.get_node(NodePath("Button")).connect("button_up", Callable(self, "Answer_Released").bind(i))
	"""
	buttons_already_connected = true


func answer_button_pressed(answerbutton):
	$Sounds/click.play()
	current_answer_box = answerbutton
	print(int(current_answer_box.text))
	$QuestionBox/answer/Label.text = current_answer_box.text
	if int(current_answer_box.text) ==current_question_data["answer"]:
		
		answered_correct_question += 1
		answered_question += 1
		$QuestionBox/Bar/AnimationPlayer.play("true")
		disable_all_buttons(true)
		#$ButtonUnlockTimer.start()
		

	else:
		answered_question += 1
		disable_all_buttons(true)
		#$ButtonUnlockTimer.start()
		$QuestionBox/Bar/AnimationPlayer.play("false")

"""
func Answer_Picked(answerbox):
	# Store starting position and enable drag
	if answer_old_poses[int(answerbox.name)] == null:
		answer_old_poses[int(answerbox.name)] = answerbox.global_position
	current_answer_box = answerbox
	pick_answer = true

func Answer_Released(answerbox):
	# Stop dragging
	pick_answer = false
"""


func write_current_question(question_data):
	# Display current question on UI
	$QuestionBox/firts/Label.text = str(question_data["first"])
	$QuestionBox/second/Label.text = str(question_data["second"])
	
	if question_data["process"] == "Addition":
		$QuestionBox/process.text = "+"
	elif question_data["process"] == "Subtraction":
		$QuestionBox/process.text = "-"
	elif question_data["process"] == "Multiplication":
		$QuestionBox/process.text = "x"
	elif question_data["process"] == "Division":
		$QuestionBox/process.text = "÷"

func set_answer_boxes():
	# Set answers on buttons
	var first = current_question_data["first"]
	var second = current_question_data["second"]
	var process = current_question_data["process"]
	var answer = current_question_data["answer"]
	var up_to_number = math_level_organizer[current_difficulty][current_level]["up_to_number"]

	write_current_question(current_question_data)

	answers_on_buttons = [null, null, null, null]
	var index = randi() % answers_on_buttons.size()
	answers_on_buttons[index] = answer
	
	
	for i in answers_buttons:	
		if i.name == str(index):
			i.text = str(answer)
		else:
			while true:
				var wrong_answer = randi() % up_to_number
				if !wrong_answer in answers_on_buttons:
					answers_on_buttons[int(i.name)] = wrong_answer
					i.text = str(wrong_answer)
					break
	"""
	for i in $AnswerBox.get_children():	
		if i.name == str(index):
			i.get_node(NodePath("Label")).text = str(answer)
		else:
			while true:
				var wrong_answer = randi() % up_to_number
				if !wrong_answer in answers_on_buttons:
					answers_on_buttons[int(i.name)] = wrong_answer
					i.get_node(NodePath("Label")).text = str(wrong_answer)
					break
	"""
	if !null in answers_on_buttons:
		if buttons_already_connected == false:
			set_answer_buttons(answers_on_buttons)

# Generate two numbers for the current question
func choose_numbers():
	var first_index
	var second_index
	var up_to_number = math_level_organizer[current_difficulty][current_level]["up_to_number"]

	first_index = randi() % up_to_number
	second_index = randi() % up_to_number

	return [first_index, second_index]

# Create a new math question based on level rules
func make_question():
	$QuestionBox/answer/Label.text = "?"
	var question_type = math_level_organizer[current_difficulty][current_level]["type"]
	var random_type_index = randi() % question_type.size()
	var type = question_type[random_type_index]

	while true:
		var number_list = choose_numbers()
		var first_number = number_list[0]
		var second_number = number_list[1]
		var question
		var answer

		if type == "Division":
			if second_number != 0 and first_number != 0:
				if first_number % second_number == 0:
					answer = first_number / second_number
					current_question_data = {"first": first_number, "process": type, "second": second_number, "answer": answer}
					current_question += 1
					set_answer_boxes()
					break
		else:
			if type == "Addition":
				answer = first_number + second_number
			elif type == "Subtraction":
				answer = first_number - second_number
			elif type == "Multiplication":
				answer = first_number * second_number

			current_question_data = {"first": first_number, "process": type, "second": second_number, "answer": answer}
			current_question += 1
			set_answer_boxes()
			break

# Determine if player has passed the level
func success_rate():
	if answered_correct_question > answered_question / 2:
		print("you_win")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		print("you_lose")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

# Reset after answer placement
func _on_reset_timer_timeout() -> void:
	reset_answer_box = true
	disable_all_buttons(false)

# Handle end of animation
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	disable_all_buttons(false)
	if current_question < max_question_count:
		if anim_name == "true":
			make_question()
		elif  anim_name == "false":
			$QuestionBox/answer/Label.text = "?"
	if answered_question == max_question_count:
		success_rate()
	
	"""
	if anim_name == "false":
		# Count wrong answers and check if game should end
		answered_question += 1
		if answered_question == max_question_count:
			success_rate()
	"""

func _on_button_unlock_timer_timeout() -> void:
	disable_all_buttons(false)
