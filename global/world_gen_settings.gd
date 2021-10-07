extends Node2D

const grid_size: int = 16

func vector_world_to_grid(world_coordinates: Vector2) -> Vector2:
	var grid_coordinates = Vector2()
	grid_coordinates.x = float_world_to_grid(world_coordinates.x)
	grid_coordinates.y = float_world_to_grid(world_coordinates.y)
	
	return grid_coordinates

func float_world_to_grid(value: float) -> int:
	return int(round(value / grid_size) * grid_size)
