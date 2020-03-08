extends Node2D

export (PackedScene) var Block

signal game_over

export var input := {"left": "", "right": ""}

var size = Vector2(512.0, 1600.0)
var lane_pos_x := [0.0, 0.0]
var player_spawn_pos: Vector2
var neutral_pos = size.y / 2 - 200

# For spawning blocks V V V
var block = []
var block_distance = [300.0, 500]
var block_length = [200.0, 512.0]
var last_block :int
var spawn_path = 0 # 0-1

export var block_speed_min := 800.0 # Start speed
export var block_speed_max := 1500.0
export var block_speed_inc := 0.01
var block_speed := 0.0

func _enter_tree():
	calculate_lane_pos_x()
	player_spawn_pos = Vector2(lane_pos_x[0], neutral_pos)
	
	reset()


func _physics_process(delta: float):
	#delta = 0.1
	#if Input.is_action_just_pressed("ui_up"):
	if true:
		blocks_spawning()
		
		# Move blocks and push player on collision
		move_blocks(delta)
		
		# When player is below 'neutral_pos'
		move_player_up(delta)
		
		# Fixes the problem with collision detection when two objects move to each other in the same frame using move_and_collide
		collision_fix()
		
		if $Player.get_flag("changing_lane"):
			player_lane_changing(delta)
		else:
			player_input()
		
		difficulty_scaling(delta)
		
		blocks_deletion()
		
		check_game_over()


# Deals when to spawn a new block and store them in an array
func blocks_spawning():
	# First block
	if block.empty():
		block.append(spawn_block(0.0))
		last_block = 0
	else: # next blocks
		if block[last_block].get_top_pos() >= 0.0:
			spawn_path = !spawn_path
			var distance = rand_range(block_distance[0], block_distance[1])
			
			last_block = block.find(null)
			if last_block == -1:
				last_block = block.size()
				block.append(spawn_block(distance))
			else:
				block[last_block] = spawn_block(distance)


# Move blocks and push player on collision
func move_blocks(delta: float):
	$Player.set_flag("being_pushed", false)
	for i in block.size():
		if block[i] != null:
			var vec = Vector2(0.0, 1.0) * block_speed
			var collision = block[i].get_node("Body").move_and_collide(vec * delta)
			if collision && collision.get_collider_id() == $Player/Body.get_instance_id():
				$Player.set_flag("being_pushed", true)
				block[i].get_node("Body").position += collision.remainder
				$Player/Body.position.y = block[i].get_node("Body").position.y + block[i].get_length()/2 + $Player.get_size().y/2


# Move player up if is below 'neutral_pos'
# and if is not being pushed by a block
func move_player_up(delta: float):
	if not $Player.get_flag("being_pushed") && $Player.get_position().y > neutral_pos:
		# speed is lower the closer the player is to the neutral_pos
		$Player.speed.y = lerp(10.0, $Player.speed_max_y, ($Player/Body.position.y - neutral_pos) / (size.y - neutral_pos))
		$Player/Body.move_and_collide(Vector2(0.0, -1.0) * $Player.speed.y * delta)
		
		if $Player.get_position().y < neutral_pos:
			$Player/Body.position.y = neutral_pos


func player_input():
	if Input.is_action_just_pressed(input.left):
		$Player.set_direction(-1) #includes setting changing_lane flag
	elif Input.is_action_just_pressed(input.right):
		$Player.set_direction(1)


# Fixes the problem with collision detection when two objects move to each other in the same frame using move_and_collide
func collision_fix():
	$Player.update_rect()
	for i in block.size():
		if block[i] != null:
			block[i].update_rect()
			if block[i].rect.intersects($Player.rect):
				$Player/Body.position.y = block[i].get_node("Body").position.y + block[i].get_length()/2 + $Player.get_size().y/2


# Spawn one block and return it
func spawn_block(distance: float):
	var new_block = Block.instance()
	new_block.set_length(rand_range(block_length[0], block_length[1]))
	new_block.set_spawn_pos(Vector2(lane_pos_x[spawn_path as int], -distance - new_block.get_length() / 2))
	add_child(new_block)
	return new_block


func player_lane_changing(delta: float):
	var collision = $Player/Body.move_and_collide(Vector2($Player.get_direction(), 0) * $Player.speed.x * delta)
	# Change direction after hitting a block or a wall
	if collision:
		$Player/Body.position += -collision.remainder
		$Player.set_direction(-$Player.get_direction())
	
	# Check if player is moving to other lane, not a wall, and stop player when reach correct pos
	var pt_lane :int = $Player.target_lane
	if pt_lane >= 0 and pt_lane < lane_pos_x.size():
		if $Player.get_direction() == 1:
			if $Player.get_position().x >= lane_pos_x[pt_lane]:
				$Player.set_position(Vector2(lane_pos_x[pt_lane], $Player.get_position().y))
				$Player.set_direction(0)
		elif $Player.get_direction() == -1:
			if $Player.get_position().x <= lane_pos_x[pt_lane]:
				$Player.set_position(Vector2(lane_pos_x[pt_lane], $Player.get_position().y))
				$Player.set_direction(0)


func difficulty_scaling(delta: float):
	# Block speed
	if block_speed_max - block_speed > 0.1:
		block_speed = lerp(block_speed, block_speed_max, block_speed_inc * delta)


func blocks_deletion():
	for i in block.size():
		if block[i] != null && is_out_bottom(block[i].get_top_pos()):
			block[i].queue_free()
			block[i] = null


func check_game_over():
	if is_out_bottom($Player.get_top_pos()):
		emit_signal("game_over")


func is_out_bottom(object_pos_y) -> bool:
	return object_pos_y > size.y


func calculate_lane_pos_x():
	lane_pos_x[0] = size.x / 4
	lane_pos_x[1] = (size.x / 4) * 3


func reset():
	# Delete all blocks
	for i in block.size():
		if block[i] != null:
			block[i].queue_free()
			block[i] = null
	block = []
	
	block_speed = block_speed_min
	
	# Move player to start pos
	spawn_path = 0
	$Player.target_lane = 0
	$Player.set_direction(0)
	$Player.set_position(player_spawn_pos)
