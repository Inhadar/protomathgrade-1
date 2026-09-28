extends Node2D

# Signals to notify when the level is completed or to send score data
signal level_complated
signal send_answered_data

# Counters to track question progress
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Dictionary containing object names and their frame indices
var object_list = {
	"drill":0,
	"saw":4,
	"axe":8,
	"hammer":11,
	"brush":14,
	"book1":16,
	"book2":17,
	"book3":18,
	"book4":19,
	"monitor":23,
	"controller":29,
	"bone":32,
	"glove":36,
	"compass":45,
}

# Level configuration: [number of objects to remember, time to view them]
var find_object_level_organizer = {
	"easy": {
		"1": {"object_count":3,"showtime":3},
		"2": {"object_count":3,"showtime":3},
		"3": {"object_count":4,"showtime":3},
		"4": {"object_count":4,"showtime":3},
		"5": {"object_count":3,"showtime":2},
		"6": {"object_count":5,"showtime":3},
	},
	"hard": {
		"1": {"object_count":3,"showtime":1},
		"2": {"object_count":3,"showtime":1},
		"3": {"object_count":4,"showtime":2},
		"4": {"object_count":4,"showtime":2},
		"5": {"object_count":5,"showtime":3},
		"6": {"object_count":6,"showtime":3},
	}
}

# References to scene and UI elements
@onready var scene = $Scene
@onready var answer_buttons = $AnswerBox.get_children()

# Current level and difficulty
var current_level = "1"
var current_difficulity = "easy"

func _ready() -> void:
	# Fetch current level and difficulty from global state
	current_difficulity = Globals.current_difficulity
	current_level = Globals.current_level
	
	# Create the initial memory question
	make_scene_memory_question(current_difficulity, current_level, scene)

func make_scene_memory_question(dificulity, level, image):
	# Prepare the question scene
	$AnswerBox.hide()
	scene.show()
	var progress_bar = $Scene/ProgressBar
	progress_bar.value = 100
	
	var objects = {}
	var object_count = find_object_level_organizer[dificulity][level]["object_count"]#find_object_level_organizer[dificulity][level][0]
	var showtime = find_object_level_organizer[dificulity][level]["showtime"]#find_object_level_organizer[dificulity][level][1]
	
	# Create a container for objects to be shown
	var object_parent_node = Node2D.new()
	scene.add_child(object_parent_node)
	
	# Calculate placement boundaries
	var viewport = get_viewport().get_visible_rect().size
	var image_size = (image.texture.get_size() * image.scale) - Vector2(196, 196)
	var offset = (viewport - image_size) / 2
	
	# Randomly place objects on the scene
	for i in object_count:
		var new_sprite = Sprite2D.new()
		object_parent_node.add_child(new_sprite)
		new_sprite.hframes = 46
		new_sprite.texture = load("res://assets/Sprites/objects_sheet.png")

		while true:
			var random_key = object_list.keys()[randi() % object_list.keys().size()]
			if !random_key in objects.keys():
				new_sprite.frame = object_list[random_key]
				
				var max_attempts = 100
				for m in max_attempts:
					randomize()
					var random_x = randf_range(offset.x, offset.x + image_size.x)
					var random_y = randf_range(offset.y, offset.y + image_size.y)
					var current_pos = Vector2(random_x, random_y)
				
					var valid = true
					for j in objects: 
						if current_pos.distance_to(objects[j]) < 128:
							valid = false
						break
					if valid:
						objects[random_key] = current_pos
						new_sprite.global_position = current_pos
						break
				break

	# Track question number and timer
	current_question += 1
	$ShowTimer.wait_time = showtime
	$ShowTimer.start()
	
	# Animate progress bar
	var tween = create_tween()
	tween.tween_property(progress_bar, "value", 0.0, showtime)
	$Sounds/clocktickling.play()
	# Configure the answer buttons
	set_answers_buttons(objects, object_count, object_parent_node)

# Data containers to track answers and current correct objects
var set_buttons = {}
var current_objects = []

func set_answers_buttons(objects, count, object_parent_node):
	set_buttons.clear()
	current_objects.clear()
	
	# Assign correct objects to random buttons
	for i in count:
		while true:
			var random_button = randi() % answer_buttons.size()
			if !random_button in set_buttons:
				set_buttons[random_button] = [true, objects.keys()[i]]
				answer_buttons[random_button].get_node(NodePath("Sprite2D")).frame = object_list[objects.keys()[i]]
				current_objects.append(objects.keys()[i])
				break

	# Fill remaining buttons with incorrect options
	for i in answer_buttons.size():
		if !i in set_buttons.keys():
			while true:
				var random_object_key = object_list.keys()[randi() % object_list.keys().size()]
				if !random_object_key in current_objects: 
					set_buttons[i] = [false, random_object_key]
					current_objects.append(random_object_key)
					answer_buttons[i].get_node(NodePath("Sprite2D")).frame = object_list[random_object_key]
					break

	# Connect button toggles to handler
	if answer_buttons.size() == set_buttons.size():
		for button in answer_buttons:
			button.connect("toggled", Callable(self, "button_toggled").bind(int(button.name), count, object_parent_node))

# Track correct selections
var true_buttons = []
var choosed_button_count = 0

func button_toggled(toggled, button_index, object_count, object_parent_node):
	var showtime = find_object_level_organizer[current_difficulity][current_level]["showtime"]

	# Update button selection count and check correctness
	if toggled:
		if choosed_button_count < object_count:
			choosed_button_count += 1
		if set_buttons[button_index][0] == true:
			true_buttons.append(set_buttons[button_index][1])
	else:
		if choosed_button_count > 0:
			choosed_button_count -= 1
		if set_buttons[button_index][0] == true:
			true_buttons.erase(set_buttons[button_index][1])
	
	# All correct answers selected
	if true_buttons.size() == object_count:
		print("True")
		answered_question += 1
		answered_correct_question += 1
		$Bar/AnimationPlayer.play("true")

		# Reset for next question
		for button in answer_buttons:
			button.button_pressed = false
		true_buttons.clear()
		object_parent_node.queue_free()
		for button in answer_buttons:
			button.disconnect("toggled", Callable(self, "button_toggled"))

		if current_question < max_question_count:
			make_scene_memory_question(current_difficulity, current_level, scene)
		else:
			$ShowTimer.stop()
			$Scene/ProgressBar.value = 100
			# End of level logic
			pass
	else:
		# All selected but not correct
		if choosed_button_count == object_count:
			for button in answer_buttons:
				button.button_pressed = false
			true_buttons.clear()
			$AnswerBox.hide()
			scene.show()
			var progress_bar = $Scene/ProgressBar
			progress_bar.value = 100
			var tween = create_tween()
			tween.tween_property(progress_bar, "value", 0.0, showtime)
			$ShowTimer.start()
			print("False")
			answered_question += 1
			$Bar/AnimationPlayer.play("false")
			$Sounds/clocktickling.play()

# Called when the object viewing time ends
func _on_show_timer_timeout() -> void:
	scene.hide()
	$AnswerBox.show()

# Emit results at the end of the level
func success_rate():
	if answered_correct_question > answered_question / 2:
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

# Triggered when animation ends, checks for level completion
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if answered_question == max_question_count:
		success_rate()
	print(answered_correct_question, "/", answered_question)
