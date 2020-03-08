extends Node2D


export var _size: Vector2 = Vector2(200.0, 200.0) setget set_size, get_size
export var speed := Vector2(500.0, 0.0)
export var speed_max_y := 800.0
var _direction :int = 0 setget set_direction, get_direction
var target_lane := 0# setget set_target_lane, get_target_lane

var flag := {"being_pushed": false, 
		"changing_lane": false}

var rect: Rect2


func _ready():
	set_size(_size)


func _physics_process(delta):
	$Sprite.position = $Body.position #TODO


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
	return $Body.get_position().y - _size.y / 2


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
