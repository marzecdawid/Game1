extends Node2D

const WIDTH = 256.0

var _length: float setget set_length, get_length
var rect: Rect2


func _ready():
	pass


func _physics_process(delta):
	$Sprite.position = $Body.position #TODO


func set_length(new_lenght: float):
	_length = new_lenght
	$Body/CollisionShape2D.shape = RectangleShape2D.new() # needed because shape is a separate object and changing shape.extents in one object would change it in others
	$Body/CollisionShape2D.shape.extents = Vector2(WIDTH / 2, _length / 2)
	$Sprite/ColorRect.rect_size.y = _length
	$Sprite/ColorRect.rect_position.y = -_length / 2


func get_length() -> float:
	return _length


func get_position() -> Vector2:
	return $Body.position


func get_top_pos() -> float:
	return $Body.get_position().y - _length / 2


func set_spawn_pos(new_pos: Vector2):
	$Body.position = new_pos
	$Sprite.position = $Body.position


func update_rect():
	rect = Rect2($Body.position.x - $Body/CollisionShape2D.shape.extents.x,
			$Body.position.y - $Body/CollisionShape2D.shape.extents.y,
			$Body/CollisionShape2D.shape.extents.x * 2,
			$Body/CollisionShape2D.shape.extents.y * 2)
