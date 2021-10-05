class_name Room
extends Area2D

export var color: Color = Color.white
var rng_mean: float = 700.0
var rng_deviation: float = 300.0

var height 
var width

var _rng = RandomNumberGenerator.new()
var _rect;


func _ready():
	_rng.randomize()
	height = _rng.randfn(rng_mean, rng_deviation);
	width = _rng.randfn(rng_mean, rng_deviation);
	
	var shape = RectangleShape2D.new()
	shape.extents = Vector2(width/2, height/2);
	
	$CollisionShape2D.shape = shape;
	
	_rect = Rect2(-shape.extents.x, -shape.extents.y, 2*shape.extents.x, 2*shape.extents.y)
	

func _draw():
	draw_rect(_rect, color);
