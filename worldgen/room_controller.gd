#
# Represents a simple room with a randomly generated size for world generation.
#
class_name Room
extends RigidBody2D


# Singleton references
onready var _settings := get_node("/root/WorldGenSettings")
onready var _rng := get_node("/root/RNGManager")

# Color and size variables
export var color: Color = Color.white
export var min_height: int = 8
export var min_width: int = 10

# RNG variables (for standard deviation rng)
export var rng_mean: float = 12
export var rng_deviation: float = 5

# The size of this shape (width x height)
var size: Vector2

# The rectangle to draw
var _rect: Rect2


# Called after all children are ready at start of program
func _ready():
	# Calculate and store a random size that fits in the grid
	var height = -INF
	var width = -INF
	while height < min_width:
		height = floor(_rng.randfn(rng_mean, rng_deviation))
	while width < min_height:
		width = floor(_rng.randfn(rng_mean, rng_deviation))
	size = Vector2(height, width) * _settings.grid_size
	
	# Create the collision shape based on this size
	var shape = RectangleShape2D.new()
	shape.extents = size
	$CollisionShape2D.shape = shape
	
	# Create the drawable rectangle based on the size
	_rect = Rect2(-size.x, -size.y, 2*size.x, 2*size.y)


# Called almost every frame
func _process(delta):
	update() # Redraws the shape


# Redraws the rectangle
func _draw():
	draw_rect(_rect, color, false);



