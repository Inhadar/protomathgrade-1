extends Node2D

# Signals to notify level completion and send result data
signal level_complated
signal send_answered_data

# Counters for tracking answered questions
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Flags and temporary references for answer interaction
var pick_answer = false
var current_answer_box = null
var swipe_speed = 10
@onready var target_area_position = %AnswerAreaPos.global_position
var answer_old_poses = [null, null, null, null]
var answers_on_buttons = [null, null, null, null]
var reset_answer_box = false
var current_question_data = {}

# Control flags
var buttons_already_connected = false
var answer_is_placed = false

# Question type configuration for different difficulty levels
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

var current_difficulty
var current_level

# Dictionary of available item types and their sprite frame indexes
var item_list = {
	"orange": 0,
	"lemon": 1,
	"grapes": 2,
	"banana": 3,
	"brocoli": 4,
	"cayenne_pepper": 5,
	"onion": 6,
	"bell_pepper": 7,
	"tomato": 8,
	"apple": 9,
}

# List of items already selected for visual consistency
var selected_items = []

func _ready() -> void:
	# Initialize difficulty and level from global variables
	current_difficulty = Globals.current_difficulity
	current_level = Globals.current_level
	make_question()

func _physics_process(delta: float) -> void:
	# Handle drag-and-drop logic per frame
	math_swipe_process(delta)

# Handles answer box dragging and placement logic
func math_swipe_process(delta):
	if current_answer_box != null:
		var target_distance = current_answer_box.global_position.distance_to(target_area_position)
		var old_pos_distance = current_answer_box.global_position.distance_to(answer_old_poses[int(current_answer_box.name)])
		
		if pick_answer:
			# Move box towards mouse
			current_answer_box.global_position = lerp(current_answer_box.global_position, get_global_mouse_position(), delta * swipe_speed)
		else:
			if reset_answer_box == false:
				if target_distance < 50:
					var true_answer = current_question_data["answer"]
					var current_answer = int(current_answer_box.get_node(NodePath("Label")).text)
					if true_answer == current_answer:
						if answer_is_placed == false:
							print("Answer is True")
							if answered_question < max_question_count:
								answered_correct_question += 1
								answered_question += 1
							$QuestionBox/Bar/AnimationPlayer.play("true")
							$Sounds/answerplacesfx.play()
							disable_all_buttons(true)
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true
					else:
						if answer_is_placed == false:
							disable_all_buttons(true)
							$QuestionBox/Bar/AnimationPlayer.play("false")
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true
				elif old_pos_distance > 50 and target_distance > 50:
					# Return to original position
					current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)
				elif old_pos_distance < 50 and target_distance > 50:
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
			else:
				# If reset flag is true, return to original position
				current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)
				if old_pos_distance < 50:
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
					reset_answer_box = false
					answer_is_placed = false
					if current_question < max_question_count:
						make_question()
						selected_items.clear()
					else:
						success_rate()

# Enables or disables all answer buttons
func disable_all_buttons(value):
	for i in $AnswerBox.get_children():
		i.get_node(NodePath("Button")).disabled = value

# Connects button signals and binds them to their respective answer boxes
func set_answer_buttons(answers):
	for i in $AnswerBox.get_children():
		i.get_node(NodePath("Button")).connect("button_down", Callable(self, "Answer_Picked").bind(i))
		i.get_node(NodePath("Button")).connect("button_up", Callable(self, "Answer_Released").bind(i))
	buttons_already_connected = true

# Called when answer box is picked
func Answer_Picked(answerbox):
	if answer_old_poses[int(answerbox.name)] == null:
		answer_old_poses[int(answerbox.name)] = answerbox.global_position
	current_answer_box = answerbox
	pick_answer = true

# Called when answer box is released
func Answer_Released(answerbox):
	pick_answer = false

# Updates the question symbols and items based on data
func write_current_question(question_data):
	spawn_items("FirstItems", question_data["first"])
	spawn_items("SecondItems", question_data["second"])
	if question_data["process"] == "Addition":
		$QuestionBox/process.text = "+"
	elif question_data["process"] == "Subtraction":
		$QuestionBox/process.text = "-"
	elif question_data["process"] == "Multiplication":
		$QuestionBox/process.text = "x"
	elif question_data["process"] == "Division":
		$QuestionBox/process.text = "÷"

# Assigns answers to buttons (1 correct + 3 wrong)
func set_answer_boxes():
	var first = current_question_data["first"]
	var second = current_question_data["second"]
	var process = current_question_data["process"]
	var answer = current_question_data["answer"]
	var up_to_number = math_level_organizer[current_difficulty][current_level]["up_to_number"]

	write_current_question(current_question_data)

	answers_on_buttons = [null, null, null, null]
	var index = randi() % answers_on_buttons.size()
	answers_on_buttons[index] = answer

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

	if !null in answers_on_buttons and buttons_already_connected == false:
		set_answer_buttons(answers_on_buttons)

# Generates a pair of numbers for the math question
func choose_numbers():
	var up_to_number = math_level_organizer[current_difficulty][current_level]["up_to_number"]
	var first_index = randi() % up_to_number
	var second_index = randi() % up_to_number
	return [first_index, second_index]

# Generates a new question and sets it up
func make_question():
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
			if second_number != 0 and first_number != 0 and first_number % second_number == 0:
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
	
	
	
# Spawns item sprites for given count
func spawn_items(parent_name, item_count):
	var parent = $QuestionBox.get_node(NodePath(parent_name))

	# Remove previous items
	for old_item in parent.get_children():
		parent.remove_child(old_item)
		old_item.free()

	var selected_frame = null
	var random_key = item_list.keys()[randi() % item_list.keys().size()]

	while true:
		if !random_key in selected_items:
			selected_frame = item_list[random_key]
			selected_items.append(random_key)
			break
		else:
			random_key = item_list.keys()[randi() % item_list.keys().size()]

	for i in item_count:
		var new_control = Control.new()
		var new_item = Sprite2D.new()
		parent.add_child(new_control)
		new_control.name = str(i)
		new_control.add_child(new_item)
		new_item.hframes = 10
		new_item.texture = load("res://assets/Sprites/fruits64x64.png")
		new_item.frame = item_list[random_key]

# Calculates and emits the result at the end of the level
func success_rate():
	if answered_correct_question > answered_question / 2:
		print("you_win")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		print("you_lose")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

# Timer reset handler to allow next interaction
func _on_reset_timer_timeout() -> void:
	reset_answer_box = true
	disable_all_buttons(false)

# Animation end handler for wrong answer
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "false":
		print("Answer is_wrong")
		if answered_question < max_question_count:
			answered_question += 1
			if answered_question == max_question_count:
				success_rate()
