extends Node2D

export (PackedScene) var Block

signal game_over

export var input := {"left": "", "right": "", "up": ""}
export var number_of_blocks_for_boost := 10

var size = Vector2(512.0, 1920.0)
var lane_pos_x := [0.0, 0.0]
var player_spawn_pos: Vector2
var neutral_pos = size.y / 2 - 200

var block = []
var block_distance = [300.0, 500.0]
var block_length = [200.0, 512.0]
var last_block :int
var spawn_path = 0 # 0-1

export var block_speed_min := 800.0 # Start speed
export var block_speed_max := 1500.0
export var block_speed_inc := 0.01
var block_speed := 0.0
var distance_to_correct := 0.0

export var bot_enabled := false
var player_passed_block := true #for the bot

var touch_area : Rect2 # Global position
var touch_index := -1

func _enter_tree():
	calculate_lane_pos_x()
	player_spawn_pos = Vector2(lane_pos_x[0], neutral_pos)
	$Player/Body/RayCast2D.enabled = bot_enabled
	reset()

func _input(event):
	if !$Player.get_flag("changing_lane"):
		touch_input(event)


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
		if !$Player.get_flag("using_boost"):
			collision_fix()
		
		if bot_enabled and !$Player.get_flag("changing_lane"):
			dumb_bot()
		
		player_input()
		
		if $Player.get_flag("using_boost"):
			use_boost(delta)
		
		if $Player.get_flag("changing_lane"):
			player_lane_changing(delta)
		
		update_boost_info()
		
		# Moves everything down, when player gets to far by using boost
		move_everything()
		
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
	if !$Player.get_flag("being_pushed") && !$Player.get_flag("using_boost") && $Player.get_position().y > neutral_pos:
		# speed is lower the closer the player is to the neutral_pos
		$Player.speed.y = lerp(10.0, $Player.speed_y_max, ($Player/Body.position.y - neutral_pos) / (size.y - neutral_pos))
		$Player/Body.move_and_collide(Vector2(0.0, -1.0) * $Player.speed.y * delta)
		
		if $Player.get_position().y < neutral_pos:
			$Player/Body.position.y = neutral_pos


func player_input():
	if !$Player.get_flag("changing_lane") and !$Player.get_flag("using_boost"):
		if $Player.boost_available and Input.is_action_just_pressed(input.up):
			$Player.set_flag("using_boost", true)
		elif Input.is_action_just_pressed(input.left):
			$Player.set_direction(-1) #includes setting changing_lane flag
		elif Input.is_action_just_pressed(input.right):
			$Player.set_direction(1)


# Fixes the problem with collision detection when two objects move to each other in the same frame using move_and_collide
# and at the same time a workaround for a bug #36432
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
	# Set x speed
	if $Player.get_flag("slowed"):
		var weight: float = ($Player.get_position().x - lane_pos_x[$Player.target_lane]) / ($Player.hit_pos - lane_pos_x[$Player.target_lane])
		$Player.speed.x = lerp($Player.speed_x_slow, 0.5, weight)
		$Player/Sprite/Sprite.modulate = Color(1, 1, 1, weight) # temporary here
	else:
		$Player.speed.x = $Player.speed_x_fast
	
	var collision = $Player/Body.move_and_collide(Vector2($Player.get_direction(), 0) * $Player.speed.x * delta)
	
	# Change direction after hitting a block or a wall
	if collision:
		$Player.hit_pos = $Player.get_position().x
		$Player.set_flag("slowed", true)
		
		$Player/Body.position += -collision.remainder
		$Player.set_direction(-$Player.get_direction())
		
		$Player.number_of_blocks_passed = 0 
		
		player_passed_block = true # for bot
		
	# Check if player is moving to other lane, not a wall, and stop player when reach correct pos
	var pt_lane :int = $Player.target_lane
	if pt_lane >= 0 and pt_lane < lane_pos_x.size():
		var btmp = false
		if $Player.get_direction() == 1:
			if $Player.get_position().x >= lane_pos_x[pt_lane]:
				btmp = true
		elif $Player.get_direction() == -1:
			if $Player.get_position().x <= lane_pos_x[pt_lane]:
				btmp = true
		if btmp:
			$Player.set_position(Vector2(lane_pos_x[pt_lane], $Player.get_position().y))
			$Player.set_direction(0)
			$Player.set_flag("slowed", false)
			$Player/Sprite/Sprite.modulate = Color(1, 1, 1, 0) # temporary here
			
			$Player.update_ray_to_block()


func use_boost(delta: float):
	$Player.number_of_blocks_passed = 0
	$Player/Body/CollisionShape2D.disabled = true
	
	$Player/Body.position.y -= $Player.speed_boost * delta
	$Player.update_rect()
	var btmp = false
	for i in block.size():
		if block[i] != null:
			block[i].update_rect()
			if block[i].rect.intersects($Player.rect):
				$Player.intersecting = true
				btmp = true
	if $Player.intersecting and !btmp:
		$Player.intersecting = false
		$Player.set_flag("using_boost", false)
		$Player/Body/CollisionShape2D.disabled = false
		$Player.boost_available = false
	
	if $Player.get_position().y < neutral_pos:
		distance_to_correct = neutral_pos - $Player.get_position().y


func update_boost_info():
	if !$Player.get_flag("using_boost"):
		$Player/Body/RayToBlock.force_raycast_update()
		if $Player/Body/RayToBlock.is_colliding():
			if !$Player.block_passed:
				$Player.number_of_blocks_passed += 1
				#print($Player.number_of_blocks_passed)
				$Player.block_passed = true
		else:
			if $Player.block_passed:
				$Player.block_passed = false
		if $Player.number_of_blocks_passed >= number_of_blocks_for_boost:
			$Player.boost_available = true


func move_everything():
	if distance_to_correct > 0.0:
		for i in block.size():
			if block[i] != null:
				block[i].get_node("Body").position.y += distance_to_correct
		
		$Player/Body.position.y += distance_to_correct
		distance_to_correct = 0.0


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


func touch_input(event):
	if event is InputEventScreenTouch:
		# Checks if starting position of the touch is on correct side of the screen and save the index of touch
		if event.pressed and touch_area.has_point(event.position):
			touch_index = event.index
		if !event.pressed and event.index == touch_index:
			touch_index = -1
	if event is InputEventScreenDrag and event.index == touch_index:
		if event.relative.x > 0:
			Input.action_press(input.right)
			touch_index = -1
		elif event.relative.x < 0:
			Input.action_press(input.left)
			touch_index = -1


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
	
	spawn_path = 0
	$Player.set_position(player_spawn_pos)
	$Player.reset()
	
	update_touch_area()
	
	player_passed_block = true


func update_touch_area():
	touch_area.position = self.global_position
	touch_area.size = self.size
	touch_area.size.y = 5000.0 # TODO


# Very simple bot based on casting a ray with small random offset and checking if doesn't hit a block
var offset := rand_range(-10.0, 50.0)
func dumb_bot():
	var cast_dir: int
	if $Player.target_lane == 0:
		cast_dir = 1
	elif $Player.target_lane == 1:
		cast_dir = -1
	
	$Player/Body/RayCast2D.set_position(Vector2(0, offset))
	$Player/Body/RayCast2D.set_cast_to(Vector2(cast_dir * 150.0, 0))
	$Player/Body/RayCast2D.force_raycast_update()
	
	if $Player/Body/RayCast2D.is_colliding():
		player_passed_block = true
	elif player_passed_block:
		if cast_dir == 1:
			Input.action_press(input.right)
		else:
			Input.action_press(input.left)
		offset = rand_range(-15.0, 60.0)
		
		player_passed_block = false
