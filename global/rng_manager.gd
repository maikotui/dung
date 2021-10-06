extends Node2D


const initial_seed = 0

onready var _rand = RandomNumberGenerator.new()

func _ready():
	if(initial_seed != 0):
		_rand.seed = initial_seed
	else:
		_rand.randomize()


func set_seed(value: int):
	_rand.seed = value


func get_seed() -> int:
	return _rand.seed


func set_state(value: int):
	_rand.state = value


func get_state() -> int:
	return _rand.state


# RandomNumberGenerator extension methods
func randf() -> float:
	return _rand.randf()


func randf_range(from: float, to: float) -> float:
	return _rand.randf_range(from, to)


func randfn(mean: float = 0.0, deviation: float = 1.0) -> float:
	return _rand.randfn(mean, deviation)


func randi() -> int:
	return _rand.randi()


func randi_range(from: int, to: int) -> int:
	return _rand.randi_range(from, to)


func randomize():
	_rand.randomize()
