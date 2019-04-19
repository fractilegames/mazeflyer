extends RigidBody


var projectile_scene = preload("res://projectile.tscn")
var explosion_scene = preload("res://explosion.tscn")
var shoot_delay = 0.0
var linear_velocity_request = Vector3(0.0, 0.0, 0.0)
var angular_velocity_request = Vector3(0.0, 0.0, 0.0)
var shoot_effect = 0.0
var integrity = 100


signal on_damage
signal on_destruction


func _ready():
	pass


func _process(delta):
	
	if Input.is_action_pressed("player_yaw_left"):
		angular_velocity_request.y = pow(Input.get_action_strength("player_yaw_left"), 2.0) * 3.0
	elif Input.is_action_pressed("player_yaw_right"):
		angular_velocity_request.y = pow(Input.get_action_strength("player_yaw_right"), 2.0) * -3.0
	else:
		angular_velocity_request.y = 0.0
	
	if Input.is_action_pressed("player_roll_left"):
		angular_velocity_request.z = pow(Input.get_action_strength("player_roll_left"), 2.0) * 3.0
	elif Input.is_action_pressed("player_roll_right"):
		angular_velocity_request.z = pow(Input.get_action_strength("player_roll_right"), 2.0) * -3.0
	else:
		angular_velocity_request.z = 0.0
	
	if Input.is_action_pressed("player_pitch_up"):
		angular_velocity_request.x = pow(Input.get_action_strength("player_pitch_up"), 2.0) * 3.0
	elif Input.is_action_pressed("player_pitch_down"):
		angular_velocity_request.x = pow(Input.get_action_strength("player_pitch_down"), 2.0) * -3.0
	else:
		angular_velocity_request.x = 0.0
	
	if Input.is_action_pressed("player_move_forward"):
		linear_velocity_request.z = Input.get_action_strength("player_move_forward") * -5.0
	elif Input.is_action_pressed("player_move_backward"):
		linear_velocity_request.z = Input.get_action_strength("player_move_backward") * 5.0
	else:
		linear_velocity_request.z = 0.0
	
	if Input.is_action_pressed("player_move_up"):
		linear_velocity_request.y = Input.get_action_strength("player_move_up") * 5.0
	elif Input.is_action_pressed("player_move_down"):
		linear_velocity_request.y = Input.get_action_strength("player_move_down") * -5.0
	else:
		linear_velocity_request.y = 0.0
	
	if Input.is_action_pressed("player_move_left"):
		linear_velocity_request.x = Input.get_action_strength("player_move_left") * -5.0
	elif Input.is_action_pressed("player_move_right"):
		linear_velocity_request.x = Input.get_action_strength("player_move_right") * 5.0
	else:
		linear_velocity_request.x = 0.0
	
	shoot_delay -= delta
	if Input.is_action_pressed("player_shoot") and shoot_delay <= 0.0 and is_alive():
		shoot()
		shoot_delay = 0.25
	
	# Flash weapon light on shoot
	if shoot_effect > 0.0:
		shoot_effect -= delta * 4.0
		if shoot_effect < 0.0:
			shoot_effect = 0.0
	get_node("WeaponLight").light_color = Color(0.0, 0.0, shoot_effect, 0.0)
	get_node("WeaponLight").visible = (shoot_effect > 0.0)
	
	# Update thruster sound according to movement requests
	# TODO: This should be based on actual forces applied so that deceleration couses sound too!
	get_node("ThrusterSound").translation = -linear_velocity_request.normalized()
	if linear_velocity_request.length() > 0.0:
		get_node("ThrusterSound").max_db = -15
	elif angular_velocity_request.length() > 0.0:
		get_node("ThrusterSound").max_db = -20
	else:
		get_node("ThrusterSound").max_db = -36

	# TODO: Looping on AudioStreamPlayer3D does not work in game (works in preview), so this is the quick workaround. Get rid of this!
	if not get_node("ThrusterSound").is_playing():
		get_node("ThrusterSound").play()


func _integrate_forces(var state):
	
#	var forward = -get_global_transform().basis.z
#	var right = get_global_transform().basis.x
#	var up = get_global_transform().basis.y
	
#	state.add_central_force(Input.get_action_strength("player_move_forward") * forward * 250)
#	state.add_central_force(Input.get_action_strength("player_move_backward") * forward * -250)
#	state.add_central_force(Input.get_action_strength("player_move_up") * up * 250)
#	state.add_central_force(Input.get_action_strength("player_move_down") * up * -250)
#	state.add_central_force(Input.get_action_strength("player_move_left") * right * -250)
#	state.add_central_force(Input.get_action_strength("player_move_right") * right * 250)
#
#	state.add_torque(Input.get_action_strength("player_yaw_left") * up * 15)
#	state.add_torque(Input.get_action_strength("player_yaw_right") * up * -15)
#	state.add_torque(Input.get_action_strength("player_roll_left") * forward * -15)
#	state.add_torque(Input.get_action_strength("player_roll_right") * forward * 15)
#	state.add_torque(Input.get_action_strength("player_pitch_up") * right * 15)
#	state.add_torque(Input.get_action_strength("player_pitch_down") * right * -15)

	#state.add_central_force(get_linear_velocity() * -50)
	#state.add_torque(get_angular_velocity() * -10)

	# Apply force to reach requested linear velocity
	var request = get_global_transform().basis * linear_velocity_request
	state.add_central_force(Vector3((request.x - state.linear_velocity.x) * 50.0, (request.y - state.linear_velocity.y) * 50.0, (request.z - state.linear_velocity.z) * 50.0))

	# Apply torque to reach requested angular velocity
	request = get_global_transform().basis * angular_velocity_request
	state.add_torque(Vector3((request.x - state.angular_velocity.x) * 10.0, (request.y - state.angular_velocity.y) * 10.0, (request.z - state.angular_velocity.z) * 10.0))


func shoot():
	var projectile = projectile_scene.instance()
	projectile.set_translation(get_node("Weapon").get_global_transform().origin)
	projectile.velocity = -get_global_transform().basis.z * 20
	projectile.color = Color(0.0, 0.0, 1.0, 0.2)
	get_parent().add_child(projectile)
	
	get_node("ShootSound").play()
	
	shoot_effect = 1.0


func apply_damage(damage):
	
	if integrity > 0.0:
		integrity -= damage
		if integrity <= 0.0:
			explode()
			emit_signal("on_destruction")
		else:
			get_node("DamageSound").play()
			emit_signal("on_damage")


func is_alive():
	return (integrity > 0.0)


func explode():
	
	var explosion = explosion_scene.instance()
	explosion.color = Color(0.0, 0.0, 1.0, 1.0)
	explosion.transform = transform
	get_parent().add_child(explosion)


func start_match(var position):
	set_transform(Transform(Basis(), position))
	integrity = 100
	shoot_effect = 0.0
	shoot_delay = 0.0

