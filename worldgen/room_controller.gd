class_name Room
extends Node2D

export var color: Color = Color.white
export var rng_mean: float = 500.0
export var rng_deviation: float = 250.0
var height 
var width
var rng = RandomNumberGenerator.new()


func _ready():
	rng.randomize()
	height = rng.randfn(rng_mean, rng_deviation);
	width = rng.randfn(rng_mean, rng_deviation);

	print_debug(str("initialized room (",height,"x",width,")"));


func _draw():
	var points = PoolVector2Array()
	var colors = PoolColorArray([color])

	points.push_back(Vector2(width/2, height/2))
	points.push_back(Vector2(-width/2, height/2))
	points.push_back(Vector2(-width/2, -height/2))
	points.push_back(Vector2(width/2, -height/2))

	draw_polygon(points, colors)
