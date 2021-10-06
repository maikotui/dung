extends Node2D


onready var _rng := get_node("/root/RNGManager")

export(int) var generator_seed = 0
export(Array, Resource) var room_prefabs: Array

export(int) var init_room_count = 100
export(float) var init_room_radius = 3000.0
export(float) var room_spread_speed = 20.0
export(int) var main_room_count = 15

var draw_queue

func _ready():
	# We need this to process after children (default 0)
	# Smaller priorities will be called first
	process_priority = 0
	if generator_seed == 0:
		_rng.randomize()
	else:
		_rng.set_seed(10)
	
	assert(room_prefabs.size() > 0, "no room prefabs given")
	_init_place_rooms(room_prefabs, init_room_count, init_room_radius)
	
	yield(get_tree(), "physics_frame")
	
	var main_rooms = _find_largest_rooms(main_room_count)

	yield(_separate_rooms(room_spread_speed), "completed")
	
	for room in main_rooms:
		room = room as Room
		room.color = Color(1, 0, 0)
		room.update()

	_construct_delaunay_graph(main_rooms)

	_construct_minimal_spanning_tree()
	_add_loops_to_minimal_spanning_tree()
	_construct_corridors()


func _init_place_rooms(room_data: Array, num_rooms, radius):
	for i in num_rooms:
		var room_scene: PackedScene = _get_random_room_from_weighted_list(room_data)
		var room = room_scene.instance()
		room.add_to_group("rooms")
		room.position.x = (randf() * radius) - (radius / 2)
		room.position.y = (randf() * radius) - (radius / 2)
		add_child(room)


func _get_random_room_from_weighted_list(room_data: Array) -> PackedScene:
	var sum_of_weights = 0;
	for i in room_data.size():
		var data = room_data[i] as RoomSceneData
		sum_of_weights += data.weight
		
	var random = _rng.randi_range(0,sum_of_weights - 1)
	
	for i in room_data.size():
		var data = room_data[i] as RoomSceneData
		if random < data.weight:
			return data.room_resource
		random -= data.weight
	
	push_error("_get_random_room_from_weighted_list: sum_of_weight too low")
	return null


func _separate_rooms(speed: float):
	var rooms = get_tree().get_nodes_in_group("rooms")
	var none_are_touching = false
	while not none_are_touching:
		yield(get_tree(), "physics_frame")
		none_are_touching = true

		for room in rooms:
			room = room as Room
			var vel = _calculate_separation(room)
			if vel != Vector2.ZERO:
				none_are_touching = false
				vel *= speed
				room.position += vel


func _calculate_separation(room: Room):
	var velocity = Vector2(0,0)
	
	for neighbor in room.get_overlapping_areas():
		if(neighbor != room):
			velocity.x += neighbor.position.x - room.position.x
			velocity.y += neighbor.position.y - room.position.y

	velocity = velocity.normalized()
	velocity *= -1

	return velocity


func _find_largest_rooms(num_main_rooms) -> Array:
	var rooms = get_tree().get_nodes_in_group("rooms")
	rooms.sort_custom(self, "_sort_by_area_descending")
	var main_rooms = rooms.slice(0, num_main_rooms)
	return main_rooms
	

func _sort_by_area_descending(a: Room, b: Room):
	if a.width * a.height > b.width * b.height:
		return true
	return false


func _construct_delaunay_graph(main_rooms: Array):
	var center_points = PoolVector2Array()
	for room in main_rooms:
		room = room as Room
		center_points.append(room.position)
	
	var del_indexes = Geometry.triangulate_delaunay_2d(center_points)
	print(del_indexes)
	
	var del_points = PoolVector2Array()
	for index in len(del_indexes) / 3:
		for n in 3:
			del_points.append(main_rooms[del_indexes[index * 3 + n]].position)
	for index in len(del_points) / 3:
		var line = Line2D.new()
		line.width = 100
		line.default_color = Color(0,0,0)
		for n in 3:
			line.add_point(del_points[index * 3 + n])
		line.add_point(del_points[index * 3])
		add_child(line)
	return del_points


func _construct_minimal_spanning_tree():
	pass


func _add_loops_to_minimal_spanning_tree():
	pass


func _construct_corridors():
	pass
