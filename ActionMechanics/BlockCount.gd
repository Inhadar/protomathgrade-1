extends Node2D

signal level_complated
signal send_answered_data

# Tracks how many correct and total questions have been answered
var answered_correct_question = 0
var answered_question = 0
var max_question_count = 5
var current_question = 0

# Stores level configuration based on difficulty and level number
var block_count_level_organizer = {
	"easy": {
		"1": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 1]},
		"2": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 2]},
		"3": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 2]},
		"4": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 3]},
		"5": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 3]},
		"6": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 4]},
	},
	"hard": {
		"1": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 4]},
		"2": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 5]},
		"3": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 5]},
		"4": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 6]},
		"5": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 6]},
		"6": {"layers": 2, "columns": 3, "rows": 3, "decrease_value": [0, 7]},
	}
}

var current_difficulity = "easy"
var current_level = "1"

@onready var parent_for_blocks = $parent_for_blocks

func _ready() -> void:
	# Set difficulty and level from global data
	current_difficulity = Globals.current_difficulity
	current_level = Globals.current_level
	make_block_count_question()

# Main function to generate a new block-count question
func make_block_count_question():
	$AnswerBox.hide()

	if current_question < max_question_count:
		# Get level structure settings
		var rows = block_count_level_organizer[current_difficulity][current_level]["rows"]
		var collumns = block_count_level_organizer[current_difficulity][current_level]["columns"]
		var layers = block_count_level_organizer[current_difficulity][current_level]["layers"]
		var decrease_value = block_count_level_organizer[current_difficulity][current_level]["decrease_value"]
		var rect_size = Vector2(64, 32)
		var viewport = get_viewport().get_visible_rect().size
		var offset = (viewport - rect_size) / 2
		var y_offset = 128
		var blocks_data = {}

		var start_row_len = rows
		var start_column_len = collumns
		var start_layer_len = layers

		# Create blocks based on rows, columns, and layers
		for y in start_layer_len:
			blocks_data[y] = {}
			for z in start_column_len:
				blocks_data[y][z] = {}
				for x in start_row_len:
					for i in 1000:
						var current_tile = randi() % rows
						var spawn_perm = false
						# Check if block below exists
						if blocks_data.has(y - 1):
							if blocks_data[y - 1].has(z):
								if blocks_data[y - 1][z].has(current_tile):
									spawn_perm = true
						else:
							if y == 0:
								spawn_perm = true

						if spawn_perm:
							if !current_tile in blocks_data[y][z].keys():
								var new_block = Sprite2D.new()
								parent_for_blocks.add_child(new_block)
								new_block.texture = load("res://assets/Sprites/cube_sheet.png")
								new_block.hframes = 11
								new_block.frame = randi() % 10
								new_block.name = str(y) + str(z) + str(current_tile)
								new_block.z_index = current_tile
								
								# Set initial off-screen position
								new_block.global_position = Vector2((rect_size.x * current_tile) + offset.x, (rect_size.y * current_tile) + offset.y)
								new_block.global_position.y += rect_size.y * z
								new_block.global_position.x -= rect_size.x * z
								new_block.global_position.y -= 1024
								
								# Calculate target position
								var target_pos = Vector2((rect_size.x * current_tile) + offset.x, (rect_size.y * current_tile) + offset.y)
								target_pos.y += rect_size.y * z
								target_pos.x -= rect_size.x * z
								target_pos.y -= (rect_size.x * y) + y_offset
								
								blocks_data[y][z][current_tile] = target_pos
								break
				# Randomly reduce row length for next layer
				start_row_len = randi_range(decrease_value[0], decrease_value[1])
		
		tween_mover(blocks_data)
		current_question += 1
	else:
		print("no more question")
		success_rate()

# Animates blocks into their target positions
func tween_mover(rows_and_columns):
	var children = parent_for_blocks.get_children()

	
	
	for i in children.size():
		var tween = create_tween()
		tween.connect("finished",Callable(self,"on_tween_finished"))
		
		var blockname = String(children[i].name)
		var y = int(blockname[0])
		var z = int(blockname[1])
		var x = int(blockname[2])
		var block_target_pos = Vector2(rows_and_columns[y][z][x])
		
		tween.tween_property(children[i], "position", block_target_pos, 0.2)
		await tween.finished
		# Generate multiple choice answers
		if i == children.size() - 1:
			var answers = []
			for j in $AnswerBox.get_children():
				var true_answer = parent_for_blocks.get_child_count()
				if answers.size() == 0:
					answers.append(true_answer)
				else:
					for d in 1000:
						var wrong_answer = randi() % (true_answer + (true_answer / 2))
						if !wrong_answer in answers:
							answers.append(wrong_answer)
							break

			var random_answers = answers.duplicate()
			random_answers.shuffle()
			for j in $AnswerBox.get_children():
				j.text = str(random_answers[int(j.name)])
				j.connect("pressed", Callable(self, "button_pressed").bind(answers[0], random_answers, j.name))
			$AnswerBox.show()

func on_tween_finished():
	$Sounds/blockplace.play()


func block_place_sound_finished(sound):
	sound.queue_free()

# Called when an answer button is pressed
func button_pressed(true_answer, answer_list, button_name):
	print(answer_list[int(button_name)])

	if answer_list[int(button_name)] == true_answer:
		print("answer is true")
		answered_correct_question += 1
		answered_question += 1
		$Bar/AnimationPlayer.play("true")
		disable_all_buttons(true)
		$ButtonUnlockTimer.start()
		

		# Clean up previous blocks
		for i in parent_for_blocks.get_children():
			parent_for_blocks.remove_child(i)
			i.free()
		
		for j in $AnswerBox.get_children():
			j.disconnect("pressed", Callable(self, "button_pressed"))
		
		
	else:
		print("answer is wrong")
		answered_question += 1
		disable_all_buttons(true)
		$ButtonUnlockTimer.start()
		$Bar/AnimationPlayer.play("false")

# Enable or disable all answer buttons
func disable_all_buttons(value):
	for i in $AnswerBox.get_children():
		i.disabled = value

# Called when all questions are answered; calculates success rate
func success_rate():
	if answered_correct_question > answered_question / 2:
		print("you_win")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_win")
		level_complated.emit("win")
	else:
		print("you_lose")
		send_answered_data.emit(answered_correct_question, max_question_count, "you_lose")
		level_complated.emit("lose")

# Called when animation ends
func _on_animation_player_animation_finished(anim_name: StringName) -> void:
	if anim_name == "true":
		if current_question < max_question_count:
			make_block_count_question()
	if answered_question == max_question_count:
		success_rate()

# Re-enable buttons after delay
func _on_button_unlock_timer_timeout() -> void:
	disable_all_buttons(false)
