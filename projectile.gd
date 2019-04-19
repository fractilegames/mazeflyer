extends Spatial

export var velocity = Vector3(0.0, 0.0, 0.0)
export var life_time = 3.0
export var damage = 10.0
export var color = Color(1.0, 1.0, 1.0, 0.0)
var cube = -1
var age = 0.0


func _ready():
	cube = Cubes.get_free_cube()


func _exit_tree():
	Cubes.release_cube(cube)
	

func _process(delta):
	if cube >= 0:
		var basis = Basis(get_global_transform().basis)
		basis = basis.scaled(Vector3(0.1, 0.1, 0.1))
		Cubes.set_cube_transform(cube, Transform(basis, get_global_transform().origin))
		Cubes.set_cube_color(cube, color)
	
	age += delta
	if age > life_time:
		terminate()


func _physics_process(delta):
	var space_state = get_world().direct_space_state
	
	var from = get_global_transform().origin
	var to = from + velocity * delta
	var result = space_state.intersect_ray(from, to)
	if result:
		set_transform(Transform(Basis(), result.position))
		velocity = Vector3(0.0, 0.0, 0.0)
		if result.collider.has_method("apply_damage"):
			result.collider.apply_damage(damage)
		terminate()
	else:
		set_transform(Transform(Basis(), to))


func terminate():
	Cubes.release_cube(cube)
	queue_free()