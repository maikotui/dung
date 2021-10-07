class_name Room
extends Area2D

onready var _settings := get_node("/root/WorldGenSettings")
onready var _rng := get_node("/root/RNGManager")

export var color: Color = Color.white
export var min_width: int = 200
export var min_height: int = 150

export var rng_mean: float = 800.0
export var rng_deviation: float = 500

var shape: RectangleShape2D

var height = -1
var width = -1

var _rect;


func _ready():
	while height < min_width:
		height = _settings.float_world_to_grid(_rng.randfn(rng_mean, rng_deviation));
	while width < min_height:
		width = _settings.float_world_to_grid(_rng.randfn(rng_mean, rng_deviation));

	shape = RectangleShape2D.new()
	shape.extents = _settings.vector_world_to_grid(Vector2(width/2, height/2));
	
	$CollisionShape2D.shape = shape;
	
	_rect = Rect2(-shape.extents.x, -shape.extents.y, 2*shape.extents.x, 2*shape.extents.y)


func _draw():
	draw_rect(_rect, color);

func _get_shape():
	return $CollisionShape2D.shape;
