extends RigidBody

export var color = Color(1.0, 1.0, 1.0, 0.0)
var cube = -1
var life_time = 0.0


func _ready():
	cube = Cubes.get_free_cube()
	life_time = 10.0 + randf() * 10.0


func _exit_tree():
	Cubes.release_cube(cube)


func _process(delta):
	if cube >= 0:
		var basis = Basis(get_global_transform().basis)
		basis = basis.scaled(Vector3(0.2, 0.2, 0.2))
		Cubes.set_cube_transform(cube, Transform(basis, get_global_transform().origin))
		Cubes.set_cube_color(cube, color)
	
	life_time -= delta
	if life_time <= 0.0:
		terminate()


func terminate():
	Cubes.release_cube(cube)
	queue_free()