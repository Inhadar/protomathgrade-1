extends Node2D

signal level_complated
signal send_answered_data

# Number of correct answers and total answered questions
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Shape, color, and design options for the game
var shapes = {"sphere": 0, "triangle": 1, "rect": 2, "pentagon": 3, "hexagon": 4}
var colors = {"red": Color.RED, "blue": Color.BLUE, "green": Color.GREEN, "pink": Color.PINK, "orange": Color.ORANGE, "yellow": Color.YELLOW, "purple": Color.PURPLE}
var designs = {"dots": 0, "traces": 1}
var sizes = {"0.5": Vector2(0.5,0.5), "1.0": Vector2(1.0,1.0), "1.5": Vector2(1.5,1.5)}
#var count = {"2": 0, "3": 0, "5": 0}
var rotations = {"45": 45, "90": 90, "180": 180}

# Structure to organize shape matching by difficulty and level
var shape_level_organizer = {
	"easy": {
		"1": [shapes, colors],
		"2": [shapes, colors],
		"3": [shapes, colors, designs],
		"4": [shapes, colors, sizes],
		"5": [shapes, colors,rotations],
		"6": [shapes, colors, designs]
	},
	"hard": {
		"1": [shapes, colors],
		"2": [shapes, colors],
		"3": [shapes, colors, designs],
		"4": [shapes, colors, sizes],
		"5": [shapes, colors,rotations],
		"6": [shapes, colors, designs]
	}
}

# Set the initial difficulty and level
var current_difficulty = Globals.current_difficulity
var current_level = Globals.current_level

# Function called when the node is ready
func _ready() -> void:
	current_difficulty = "easy"
	current_level = "1"
	randomize()  # Randomize the game setup
	make_shape_matching_question()  # Generate the first question

# Variables for managing the answer selection process
var pick_answer = false
var current_answer_box = null
var swipe_speed = 10
@onready var target_area_position = $AnswerPosition.global_position
var answer_old_poses = [null, null, null, null]
var answers_on_buttons = [null, null, null, null]
var reset_answer_box = false
var current_question_data = {}
var answer_is_placed = false

var swap_true_answer = {}
var swap_current_answer = {}

# Called every frame, for handling swipe behavior
func _physics_process(delta: float) -> void:
	shape_swipe_process(delta)  # Handle the swipe process for the answers
	pass

# Handle the swipe process for dragging the answer box
func shape_swipe_process(delta):
	if current_answer_box != null:
		var target_distance = current_answer_box.global_position.distance_to(target_area_position)
		var old_pos_distance = current_answer_box.global_position.distance_to(answer_old_poses[int(current_answer_box.name)])

		# Handle picking up the answer box
		if pick_answer:
			current_answer_box.global_position = lerp(current_answer_box.global_position, get_global_mouse_position(), delta * swipe_speed)

		# If not picking up, handle positioning the answer box correctly
		else:
			if not reset_answer_box:
				if target_distance < 50:
					# If the answer is correct
					if swap_true_answer == swap_current_answer:
						if not answer_is_placed:
							print("Answer is True")
							if answered_question < max_question_count:
								answered_correct_question += 1
								answered_question += 1
							$QuestionBox/Bar/AnimationPlayer.play("true")
							
							disable_all_buttons(true)
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true
							
					# If the answer is incorrect
					else:
						if not answer_is_placed:
							disable_all_buttons(true)
							$QuestionBox/Bar/AnimationPlayer.play("false")
							current_answer_box.global_position = target_area_position
							$ResetTimer.start()
							answer_is_placed = true

				elif old_pos_distance > 50 and target_distance > 50:
					current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)

				elif old_pos_distance < 50 and target_distance > 50:
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
			else:
				current_answer_box.global_position = lerp(current_answer_box.global_position, answer_old_poses[int(current_answer_box.name)], delta * swipe_speed)
				if old_pos_distance < 50:
					current_answer_box.global_position = answer_old_poses[int(current_answer_box.name)]
					reset_answer_box = false
					answer_is_placed = false
					if current_question < max_question_count:
						make_shape_matching_question()  # Generate a new question if not all are answered
					else:
						print("Level is finished", "<--- Next level menu")
						success_rate()  # Calculate the success rate at the end of the level

# Disable all buttons (used for preventing interactions after an answer is placed)
func disable_all_buttons(value):
	for i in $AnswerBox.get_children():
		i.get_node(NodePath("Button")).disabled = value

# Generate a new shape matching question
func make_shape_matching_question():
	var difficulty = current_difficulty
	var level = current_level
	
	var first_shape_data = {}
	var first_shape_result_data = {}
	var second_shape_data = {}
	var second_shape_result_data = {}
	var answers = {}
	
	if designs in shape_level_organizer[difficulty][level]:
		$QuestionBox/Shapes/Shape_set1/first/desing.show()
		$QuestionBox/Shapes/Shape_set1/first_resutlt/desing.show()
		$QuestionBox/Shapes/Shape_set2/second/desing.show()
		#buttons
		$"AnswerBox/0/design".show()
		$"AnswerBox/1/design".show()
		$"AnswerBox/2/design".show()
		$"AnswerBox/3/design".show()
		
	else:
		$QuestionBox/Shapes/Shape_set1/first/desing.hide()
		$QuestionBox/Shapes/Shape_set1/first_resutlt/desing.hide()
		$QuestionBox/Shapes/Shape_set2/second/desing.hide()
		#buttons
		$"AnswerBox/0/design".hide()
		$"AnswerBox/1/design".hide()
		$"AnswerBox/2/design".hide()
		$"AnswerBox/3/design".hide()
		
		
		
		
		
	# Pick random shapes and parameters for the question
	for i in shape_level_organizer[difficulty][level]:
		var current_index = shape_level_organizer[difficulty][level].find(i)
		var first_random_index = randi() % i.size()
		first_shape_data[current_index] = i.keys()[first_random_index]

	# Generate the correct and wrong answers based on the first shape data
	if first_shape_data.size() == shape_level_organizer[difficulty][level].size():
		var similarities = first_shape_data.duplicate()
		var dif_count = 1
		var differencies = {}

		for i in dif_count:
			var r = randi() % first_shape_data.size()
			differencies[r] = similarities[r]
			similarities.erase(r)

		# Generate the second shape's data and result based on the first shape
		for i in shape_level_organizer[difficulty][level]:
			for j in similarities:
				if similarities[j] in shape_level_organizer[difficulty][level][j].keys():
					if not j in first_shape_result_data:
						first_shape_result_data[j] = similarities[j]
					else: break

			for t in differencies:
				if differencies[t] in shape_level_organizer[difficulty][level][t].keys():
					if not t in first_shape_result_data:
						var first_shape_keys = []
						for d in first_shape_data:
							first_shape_keys.append(first_shape_data[d])

						for c in 1000:
							var random = randi() % shape_level_organizer[difficulty][level][t].keys().size()
							if not shape_level_organizer[difficulty][level][t].keys()[random] in first_shape_keys:
								first_shape_result_data[t] = shape_level_organizer[difficulty][level][t].keys()[random]
								break
					else: break

		# Duplicate the data to create the second shape
		second_shape_data = first_shape_data.duplicate()
		second_shape_result_data = first_shape_result_data.duplicate()

		# Choose a random difference for the second object
		var random_sim = randi() % similarities.size()
		var random_key = similarities.keys()[random_sim]
		var first_shape_keys = []
		for t in first_shape_data:
			first_shape_keys.append(first_shape_data[t])

		# Ensure the second shape has a different key from the first shape
		for c in 1000:
			var r = randi() % shape_level_organizer[difficulty][level][random_key].keys().size()
			if not shape_level_organizer[difficulty][level][random_key].keys()[r] in first_shape_keys:
				second_shape_data[random_key] = shape_level_organizer[difficulty][level][random_key].keys()[r]
				second_shape_result_data[random_key] = shape_level_organizer[difficulty][level][random_key].keys()[r]
				break

		# Generate incorrect answers
		var true_answer = second_shape_result_data.duplicate()
		
		print("True Answers: ",true_answer)
		swap_true_answer = second_shape_result_data.duplicate()
		var just_answers = []

		for w in 4:
			if w == 0:
				answers[w] = [true, true_answer]
				just_answers.append(true_answer)
			else:
				var wrong_answer = true_answer.duplicate()
				while true:
					var sim_random_key = similarities.keys()[randi() % similarities.size()]
					var r = randi() % shape_level_organizer[difficulty][level][sim_random_key].size()
					wrong_answer[sim_random_key] = shape_level_organizer[difficulty][level][sim_random_key].keys()[r]
					if not wrong_answer in just_answers:
						answers[w] = [false, wrong_answer]
						just_answers.append(wrong_answer)
						break

		# Set the visuals and answer buttons
		var shapes_data = {"first": first_shape_data, "first_result": first_shape_result_data, "second": second_shape_data, "answers": answers}
		
		print(shapes_data)
		
		set_shapes_visuals(shapes_data)
		set_answers_buttons(answers)
		current_question += 1






# Set visuals for the shapes based on the generated question data
func set_shapes_visuals(data):
	var first = $QuestionBox/Shapes/Shape_set1/first
	var first_result = $QuestionBox/Shapes/Shape_set1/first_resutlt
	var second = $QuestionBox/Shapes/Shape_set2/second
	
	# Set the shape and color for the first shape
	#print("AAA: ",data)
	

	
	 
	for i in data["first"]:
		if data["first"][i] in shapes:
			first.get_children()[0].frame = shapes[data["first"][i]]
		if data["first"][i] in colors:
			first.get_children()[0].modulate = colors[data["first"][i]]
		if data["first"][i] in sizes:
			first.get_children()[0].scale = sizes[data["first"][i]]
		if data["first"][i] in rotations:
			first.get_children()[0].rotation_degrees= rotations[data["first"][i]]
		if data["first"][i] in designs:
			if data["first"][i] == "dots":
				first.get_children()[1].texture = load("res://assets/Sprites/dots_sheet.png")
			elif data["first"][i] == "traces":
				first.get_children()[1].texture = load("res://assets/Sprites/trace_sheet.png")
			
			
			first.get_children()[1].show()
			for j in data["first"]:
				if  data["first"][j] in shapes:
					first.get_children()[1].frame= shapes[data["first"][j]]
		#else:
		#	first.get_children()[1].hide()
			
			
	# Set the shape and color for the first result shape
	for i in data["first_result"]:
		if data["first_result"][i] in shapes:
			first_result.get_children()[0].frame = shapes[data["first_result"][i]]
		if data["first_result"][i] in colors:
			first_result.get_children()[0].modulate = colors[data["first_result"][i]]
	
		if data["first_result"][i] in sizes:
			first_result.get_children()[0].scale = sizes[data["first_result"][i]]
		if data["first_result"][i] in rotations:
			first_result.get_children()[0].rotation_degrees= rotations[data["first_result"][i]]
		if data["first_result"][i] in designs:
			if data["first_result"][i] == "dots":
				first_result.get_children()[1].texture = load("res://assets/Sprites/dots_sheet.png")
			elif data["first_result"][i] == "traces":
				first_result.get_children()[1].texture = load("res://assets/Sprites/trace_sheet.png")
			
			first_result.get_children()[1].show()
			for j in data["first_result"]:
				if  data["first_result"][j] in shapes:
					first_result.get_children()[1].frame= shapes[data["first_result"][j]]
		#else:
		#	first_result.get_children()[1].hide()
			
	# Set the shape and color for the second shape
	for i in data["second"]:
		if data["second"][i] in shapes:
			second.get_children()[0].frame = shapes[data["second"][i]]
		if data["second"][i] in colors:
			second.get_children()[0].modulate = colors[data["second"][i]]
		
		if data["second"][i] in sizes:
			second.get_children()[0].scale = sizes[data["second"][i]]
		if data["second"][i] in rotations:
			second.get_children()[0].rotation_degrees= rotations[data["second"][i]]
		if data["second"][i] in designs:
			if data["second"][i] == "dots":
				second.get_children()[1].texture = load("res://assets/Sprites/dots_sheet.png")
			elif data["second"][i] == "traces":
				second.get_children()[1].texture = load("res://assets/Sprites/trace_sheet.png")
			
			second.get_children()[1].show()
			for j in data["second"]:
				if  data["second"][j] in shapes:
					second.get_children()[1].frame= shapes[data["second"][j]]
		#else:
		#	second.get_children()[1].hide()
			
# Set the answer buttons with random answers
func set_answers_buttons(answers):
	var random_answers = answers.keys()
	random_answers.shuffle()
	
	for button_index in $AnswerBox.get_child_count():
		var current_answer_index = random_answers[button_index]
		var current_button_shape = $AnswerBox.get_children()[button_index].get_node(NodePath("shape"))
		var current_button_design = $AnswerBox.get_children()[button_index].get_node(NodePath("design"))
		print(answers[current_answer_index][1])
		for i in answers[current_answer_index][1]:
			var current_parametr = answers[current_answer_index][1][i]
			
			if current_parametr in shapes:
				current_button_shape.frame = shapes[current_parametr]
			if current_parametr in colors:
				current_button_shape.modulate = colors[current_parametr]
			if current_parametr in designs:
				current_button_design.show()
				for j in answers[current_answer_index][1]:
					var crnt_index = answers[current_answer_index][1][j]
					if current_parametr=="dots":
						current_button_design.texture = load("res://assets/Sprites/dots_sheet.png")
					elif current_parametr =="traces":
						current_button_design.texture = load("res://assets/Sprites/trace_sheet.png")
					if crnt_index in shapes:
						current_button_design.frame = shapes[crnt_index]
			if current_parametr in sizes:
				current_button_shape.scale =  sizes[current_parametr]
				current_button_design.scale =  sizes[current_parametr]
			if current_parametr in rotations:
				current_button_design.rotation_degrees = rotations[current_parametr]
				current_button_shape.rotation_degrees = rotations[current_parametr]
				
				
		var button = $AnswerBox.get_children()[button_index].get_node(NodePath("Button"))
		if button.is_connected("button_down", Callable(self, "Answer_Picked")):
			button.disconnect("button_down", Callable(self, "Answer_Picked"))
		
		if button.is_connected("button_up", Callable(self, "Answer_Released")):
			button.disconnect("button_up", Callable(self, "Answer_Released"))
		
		# Connect answer pick and release events to the button
		button.connect("button_down", Callable(self, "Answer_Picked").bind(answers, random_answers, button_index, $AnswerBox.get_children()[button_index]))
		button.connect("button_up", Callable(self, "Answer_Released").bind(answers, random_answers, button_index, $AnswerBox.get_children()[button_index]))

# Called when an answer is picked (button down)
func Answer_Picked(answers, random_answers, button_index, button):
	swap_current_answer = answers[random_answers[button_index]][1]
	current_answer_box = button
	pick_answer = true
	if answer_old_poses[button_index] == null:
		answer_old_poses[int(button.name)] = button.global_position

# Called when an answer is released (button up)
func Answer_Released(answers, random_answers, button_index, button):
	pick_answer = false

# Function to check the success rate at the end of the game
func success_rate():
	if answered_correct_question > answered_question / 2:
		print("you_win")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		print("you_lose")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

# Called when the reset timer times out
func _on_reset_timer_timeout() -> void:
	reset_answer_box = true
	disable_all_buttons(false)

# Called when an animation finishes
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "false":
		print("Answer is_wrong")
		if answered_question < max_question_count:
			answered_question += 1
			if answered_question == max_question_count:
				success_rate()
