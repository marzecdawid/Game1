extends Node2D


export var _size: Vector2 = Vector2(200.0, 200.0) setget set_size, get_size
export var speed_x_slow := 600.0
export var speed_x_fast := 1200.0
export var speed_y_max := 800.0
export var speed_boost := 2000.0
var speed := Vector2(speed_x_fast, 0.0)
var _direction :int = 0 setget set_direction, get_direction
var target_lane := 0# setget set_target_lane, get_target_lane
var hit_pos := 0.0
var block_passed := false
var number_of_blocks_passed := 0
var boost_available := false
var intersecting := false # for boost

var flag := {"being_pushed": false, 
		"changing_lane": false,
		"slowed": false,
		"using_boost": false}

var rect: Rect2


func _ready():
	set_size(_size)


func _physics_process(delta):
	$Sprite.position = $Body.position #TODO


# for ray to check if player passed a block
func update_ray_to_block():
	var cast_dir: int
	if target_lane == 0:
		cast_dir = 1
	elif target_lane == 1:
		cast_dir = -1
	
	$Body/RayToBlock.set_cast_to(Vector2(cast_dir * 300.0, 0))


func set_flag(flag_name: String, value: bool):
	if flag.has(flag_name):
		flag[flag_name] = value
	else:
		print(flag_name + " does not exist!")

func get_flag(flag_name: String) -> bool:
	if flag.has(flag_name):
		return flag[flag_name]
	else:
		print(flag_name + " does not exist!")
	return false


func set_size(new_size: Vector2):
	_size = new_size
	$Body/CollisionShape2D.shape.extents = _size / 2
	$Sprite/ColorRect.rect_size = _size
	$Sprite/ColorRect.rect_position = -_size / 2

func get_size() -> Vector2:
	return _size


func set_position(new_pos: Vector2):
	$Body.position = new_pos

func get_position() -> Vector2:
	return $Body.position


func get_top_pos() -> float:
	return $Body.position.y - _size.y / 2


func set_direction(new_pos: int):
	_direction = new_pos
	if _direction == 0:
		set_flag("changing_lane", false)
	else:
		set_flag("changing_lane", true)
	
	target_lane += _direction

func get_direction() -> int:
	return _direction


func update_rect():
	rect = Rect2($Body.position.x - $Body/CollisionShape2D.shape.extents.x,
			$Body.position.y - $Body/CollisionShape2D.shape.extents.y,
			$Body/CollisionShape2D.shape.extents.x * 2,
			$Body/CollisionShape2D.shape.extents.y * 2)


func reset():
	speed.x = speed_x_fast
	set_flag("slowed", false)
	$Sprite/Sprite.modulate = Color(1, 1, 1, 0) # temporary here
	target_lane = 0
	set_direction(0)
	update_ray_to_block()
	boost_available = false
	number_of_blocks_passed = 0
	intersecting = false
	$Body/CollisionShape2D.disabled = false
