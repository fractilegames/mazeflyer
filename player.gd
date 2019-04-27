extends RigidBody


var projectile_scene = preload("res://projectile.tscn")
var explosion_scene = preload("res://explosion.tscn")
var control_active = false
var shoot_delay = 0.0
var linear_velocity_request = Vector3(0.0, 0.0, 0.0)
var angular_velocity_request = Vector3(0.0, 0.0, 0.0)
var shoot_effect = 0.0
var integrity = 100
var mouse_delta = Vector2(0.0, 0.0)
var pitch_control_multiplier = 1.0


signal on_damage
signal on_destruction


func _ready():
	pass


func _process(delta):
	
	if control_active:
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
			angular_velocity_request.x = pow(Input.get_action_strength("player_pitch_up"), 2.0) * 3.0 * pitch_control_multiplier
		elif Input.is_action_pressed("player_pitch_down"):
			angular_velocity_request.x = pow(Input.get_action_strength("player_pitch_down"), 2.0) * -3.0 * pitch_control_multiplier
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
			
		if abs(mouse_delta.y) > 0.01:
			angular_velocity_request.x = mouse_delta.y / 10 * pitch_control_multiplier
		if abs(mouse_delta.x) > 0.01:
			angular_velocity_request.y = mouse_delta.x / -10
			
		mouse_delta.y -= mouse_delta.y * clamp(delta * 20.0, 0.0, 1.0)
		mouse_delta.x -= mouse_delta.x * clamp(delta * 20.0, 0.0, 1.0)
			
		if Input.is_action_pressed("player_shoot") and shoot_delay <= 0.0 and is_alive():
			shoot()
			shoot_delay = 0.25
	else:
		linear_velocity_request = Vector3(0.0, 0.0, 0.0)
		angular_velocity_request = Vector3(0.0, 0.0, 0.0)
	
	# Update shoot delay timer
	shoot_delay -= delta
	
	# Flash weapon light on shoot
	if shoot_effect > 0.0:
		shoot_effect -= delta * 4.0
		if shoot_effect < 0.0:
			shoot_effect = 0.0
	get_node("WeaponLight").light_color = Color(0.0, 0.0, shoot_effect, 0.0)
	get_node("WeaponLight").visible = (shoot_effect > 0.0)
	
	# Update thruster sound according to movement requests
	# TODO: This should be based on actual forces applied so that deceleration causes sound too!
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


func _input(event):
	if control_active:
		if event is InputEventMouseMotion:
			mouse_delta += event.get_relative()


func _integrate_forces(var state):
	
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


func set_active(active):
	control_active = active
	if control_active:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		mouse_delta = Vector2(0.0, 0.0)
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func set_invert_pitch_control(invert):
	if invert:
		pitch_control_multiplier = -1.0
	else:
		pitch_control_multiplier = 1.0

