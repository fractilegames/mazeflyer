extends Spatial


var map = PoolIntArray()
var map_size = 0
var vertices
var normals
var start_points = Array()


func _ready():
	generate(5, 10)


func get_start_point_count():
	return start_points.size()


func get_start_point(var index):
	return get_map_cell_center_point(start_points[index].x, start_points[index].y, start_points[index].z) 


func generate(var size, var random_seed):
	
	var mesh_instance = get_node("MeshInstance")
	var collision_shape = get_node("Body/CollisionShape")

	seed(random_seed)
	
	start_points = Array()
	generate_map(size)
	
	vertices = PoolVector3Array()
	normals = PoolVector3Array()
	for x in range(0, map_size):
		for y in range(0, map_size):
			for z in range(0, map_size):
				generate_map_cell_walls(x, y, z)
	
	var arrays = []
	arrays.resize(ArrayMesh.ARRAY_MAX)
	arrays[ArrayMesh.ARRAY_VERTEX] = vertices
	arrays[ArrayMesh.ARRAY_NORMAL] = normals
	
	# Re-use material from existing mesh instance
	var material = mesh_instance.get_surface_material(0)
	
	# Set up new mesh
	# TODO: Should we free the old array mesh first?
	var array_mesh = ArrayMesh.new()
	array_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	array_mesh.surface_set_material(0, material)
	mesh_instance.mesh = array_mesh
	
	# Set up new collision shape
	# TODO: Should we free the old shape first?
	var shape = ConcavePolygonShape.new()
	shape.set_faces(vertices)
	collision_shape.shape = shape


func generate_map(var size):
	
	map_size = size
	
	# Start with full grid
	map.resize(size * size * size)
	for i in range(0, map.size()):
		map[i] = 1
	
	# Randomize start point
	var position = Vector3(randi() % size, randi() % size, randi() % size)
	start_points.append(position)
	
	# Set start point empty
	set_map_cell(position.x, position.y, position.z, 0)
	
	# Dig a random tunnel
	var direction = randomize_direction()
	for i in range(0, size * size * size * 1.2):
		
		var new_position = position + direction
		if test_map_cell_inside(new_position.x, new_position.y, new_position.z):
			position = new_position
			set_map_cell(position.x, position.y, position.z, 0)
			if randi() % 4 == 0:
				direction = randomize_direction()
			if randi() % 2 == 0 and check_start_point(position):
				start_points.append(position)
		else:
			direction = randomize_direction()


func check_start_point(var position):
	
	for i in range(0, start_points.size()):
		if (start_points[i] - position).length() < 3.0:
			return false
			
	return true

func randomize_direction():
	var random = randi() % 6
	if random == 0:
		return Vector3(-1, 0, 0)
	elif random == 1:
		return Vector3(1, 0, 0)
	elif random == 2:
		return Vector3(0, -1, 0)
	elif random == 3:
		return Vector3(0, 1, 0)
	elif random == 4:
		return Vector3(0, 0, -1)
	else:
		return Vector3(0, 0, 1)


func generate_map_cell_walls(var x, var y, var z):
	
	var cell = get_map_cell(x, y, z)
	var cell_center = get_map_cell_center_point(x, y, z)
	
	# Generate left/right walls
	generate_map_cell_wall(cell, get_map_cell(x - 1, y, z), cell_center + Vector3(-2.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, -1.0))
	generate_map_cell_wall(cell, get_map_cell(x + 1, y, z), cell_center + Vector3(2.0, 0.0, 0.0), Vector3(0.0, 1.0, 0.0), Vector3(0.0, 0.0, 1.0))
	
	# Generate front/back walls
	generate_map_cell_wall(cell, get_map_cell(x, y, z - 1), cell_center + Vector3(0.0, 0.0, -2.0), Vector3(0.0, 1.0, 0.0), Vector3(1.0, 0.0, 0.0))
	generate_map_cell_wall(cell, get_map_cell(x, y, z + 1), cell_center + Vector3(0.0, 0.0, 2.0), Vector3(0.0, 1.0, 0.0), Vector3(-1.0, 0.0, 0.0))
	
	# Generate top/bottom walls
	generate_map_cell_wall(cell, get_map_cell(x, y - 1, z), cell_center + Vector3(0.0, -2.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(1.0, 0.0, 0.0))
	generate_map_cell_wall(cell, get_map_cell(x, y + 1, z), cell_center + Vector3(0.0, 2.0, 0.0), Vector3(0.0, 0.0, -1.0), Vector3(-1.0, 0.0, 0.0))


func generate_map_cell_wall(var front_cell, var back_cell, var wall_center, var wall_up, var wall_right):
	
	if front_cell != 0 or back_cell != 1:
		return
	
	var wall_size = 2.0
	var wall_normal = wall_right.cross(wall_up)
	vertices.push_back(wall_center + wall_right * wall_size - wall_up * wall_size)
	normals.push_back(wall_normal)
	vertices.push_back(wall_center - wall_right * wall_size - wall_up * wall_size)
	normals.push_back(wall_normal)
	vertices.push_back(wall_center - wall_right * wall_size + wall_up * wall_size)
	normals.push_back(wall_normal)
	vertices.push_back(wall_center + wall_right * wall_size - wall_up * wall_size)
	normals.push_back(wall_normal)
	vertices.push_back(wall_center - wall_right * wall_size + wall_up * wall_size)
	normals.push_back(wall_normal)
	vertices.push_back(wall_center + wall_right * wall_size + wall_up * wall_size)
	normals.push_back(wall_normal)


func get_map_cell(var x, var y, var z):
	if not test_map_cell_inside(x, y, z):
		return 1
	
	return map[z * map_size * map_size + y * map_size + x]


func set_map_cell(var x, var y, var z, var value):
	map[z * map_size * map_size + y * map_size + x] = value


func test_map_cell_inside(var x, var y, var z):
	if x < 0 or x >= map_size:
		return false
	if y < 0 or y >= map_size:
		return false
	if z < 0 or z >= map_size:
		return false
		
	return true


func get_map_cell_center_point(var x, var y, var z):
	return Vector3(x * 4.0 + 2.0, y * 4.0 + 2.0, z * 4.0 + 2.0) - Vector3(map_size * 2.0, map_size * 2.0, map_size * 2.0)


