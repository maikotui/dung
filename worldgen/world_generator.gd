extends Node2D


onready var _settings := get_node("/root/WorldGenSettings")
onready var _rng := get_node("/root/RNGManager")

export(int) var generator_seed = 0
export(Array, Resource) var room_prefabs: Array

export(int) var init_room_count = 100
export(float) var init_room_radius = 2000.0
export(int) var room_spread_speed = 1
export(int) var main_room_count = 15

var _minimum_span_path: AStar2D


func _ready():
	# We need this to process after children (default 0)
	# Smaller priorities will be called first
	process_priority = 0
	if generator_seed == 0:
		_rng.randomize()
	else:
		_rng.set_seed(10)
	
	assert(room_prefabs.size() > 0, "no room prefabs given")
	
	var info = str("starting world generation with the following settings:\n"\
			,"seed: ", _rng.get_seed(), "\n"\
			,"grid size: ", _settings.grid_size, "\n"\
			,"number of rooms: ", init_room_count, "\n"\
			,"initial room spawn radius: ", init_room_radius, "\n"\
			,"room spread speed: ", room_spread_speed, "\n"\
			,"max number of main rooms: ", main_room_count\
			)
	print_debug(info)
	
	_init_place_rooms(room_prefabs, init_room_count, init_room_radius)
	print_debug("rooms placed successfully")
	
	yield(get_tree(), "physics_frame")
	
	var main_rooms = _find_largest_rooms(main_room_count)
	var room_graph = RoomGraph.new(main_rooms)
	print_debug("found the largest rooms")
	
	yield(_separate_rooms(room_spread_speed), "completed")
	print_debug("rooms spread successfully")
	
	for room in main_rooms:
		room = room as Room
		room.color = Color(0, 1, 0)
		room.update()

	var del_indexes = _construct_delaunay_graph(main_rooms)
	info = str("constructed delaunay graph: ", del_indexes)
	print_debug(info)
	
	for n in len(del_indexes) -1:
		room_graph.add_edge(del_indexes[n], del_indexes[n+1])
	
	_minimum_span_path = room_graph.calc_mst()
	
	if _minimum_span_path:
		for p in _minimum_span_path.get_points():
			for c in _minimum_span_path.get_point_connections(p):
				var pp = _minimum_span_path.get_point_position(p)
				var cp = _minimum_span_path.get_point_position(c)
				
				var line = Line2D.new()
				line.z_index = 1
				line.width = 150
				line.default_color = Color(1,0,0)
				line.add_point(Vector2(pp.x, pp.y))
				line.add_point(Vector2(cp.x, cp.y))
				add_child(line)
	update()
	
	_construct_minimal_spanning_tree()
	_add_loops_to_minimal_spanning_tree()
	_construct_corridors()


func _draw():
	pass

func _init_place_rooms(room_data: Array, num_rooms, radius):
	for i in num_rooms:
		var room_scene: PackedScene = _get_random_room_from_weighted_list(room_data)
		var room = room_scene.instance()
		room.add_to_group("rooms")
		room.position = _get_random_point_in_circle(radius)
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


func _get_random_point_in_circle(radius: float) -> Vector2:
	var t = 2 * PI * _rng.randf()
	var u = _rng.randf() + _rng.randf()
	var r = null
	if u > 1:
		r = 2 - u
	else:
		r = u
	var retval = Vector2()
	retval.x = _settings.float_world_to_grid(radius*r*cos(t))
	retval.y = _settings.float_world_to_grid(radius*r*sin(t))
	return retval


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
				vel *= _settings.grid_size * speed
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


func _construct_delaunay_graph(main_rooms: Array) -> PoolIntArray:
	var center_points = PoolVector2Array()
	for i in main_rooms.size():
		var room = main_rooms[i] as Room
		center_points.append(room.position)
	
	var del_indexes = Geometry.triangulate_delaunay_2d(center_points)
	
	# Draw del lines (temporary)
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

	return del_indexes


func _construct_minimal_spanning_tree():
	pass


func _add_loops_to_minimal_spanning_tree():
	pass


func _construct_corridors():
	pass

class RoomGraph:
	var _adj_matrix: Array = []
	var _room_data: Array = []
	
	
	func _init(rooms: Array):
		_room_data = rooms
		for i in rooms.size():
			_adj_matrix.append([])
			for j in rooms.size():
				_adj_matrix[i].append(0)
	
	
	func add_edge(a, b):
		_adj_matrix[a][b] = 1
		_adj_matrix[b][a] = 1
	
	
	func remove_edge(a, b):
		_adj_matrix[a][b] = 0
		_adj_matrix[b][a] = 0
	
	
	func get_adjacency_matrix() -> Array:
		return _adj_matrix.duplicate(true)
	
	
	func calc_mst() -> Path:
		var nodes = _room_data.duplicate()

		var path = AStar2D.new()
		path.add_point(path.get_available_point_id(), nodes.pop_front().position)
		
		while nodes:
			var min_dist = INF
			var min_p = null
			var p = null
			
			for p1 in path.get_points():
				p1 = path.get_point_position(p1)
				
				for p2 in nodes:
					if p1.distance_to(p2.position) < min_dist:
						min_dist = p1.distance_to(p2.position)
						min_p = p2
						p = p1
			
			var n = path.get_available_point_id()
			path.add_point(n, min_p.position)
			path.connect_points(path.get_closest_point(p), n)
			
			nodes.erase(min_p)
		
		return path
