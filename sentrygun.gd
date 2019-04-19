extends RigidBody


var projectile_scene = preload("res://projectile.tscn")
var explosion_scene = preload("res://explosion.tscn")
var target_position = Vector3(0.0, 0.0, 0.0)
var target_node = null
var target_timer = 0.0
var raycast = null
var idle_target_timer = 0.0
var shoot_delay = 0.0
var integrity = 35
var light_flash = 0.0


func _ready():
	raycast = get_node("RayCast")


func _process(delta):
	var player = get_node("../Player")
	var light = get_node("Light")
	
	# Test if we can see the player
	var offset_to_player = get_global_transform().inverse() * player.get_global_transform().origin
	raycast.set_cast_to(offset_to_player)
	raycast.force_raycast_update()
	if not raycast.is_colliding() and player.is_alive():
		# Turn towards player
		target_position = player.get_global_transform().origin
		target_node = player
		target_timer += delta
	else:
		# No target available
		target_node = null
		target_timer = 0.0
		
		# Look around randomly until we can see the player again
		idle_target_timer += delta
		if idle_target_timer > 4.0:
			target_position = get_global_transform().origin + Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5) * 5.0
			idle_target_timer = randf() * 2.0
	
	# Shoot at target after a delay
	# TODO: This should also check that we're actually facing the target
	shoot_delay -= delta
	if target_timer > 1.0 and shoot_delay <= 0.0:
		shoot()
		shoot_delay = 0.25
		
	# Fade out weapon flash effect in light color
	if light_flash > 0.0:
		light_flash -= delta * 10
		if light_flash < 0.0:
			light_flash = 0.0
	light.light_color = Color(0.5 + light_flash * 0.5, 0.0, 0.0, 1.0)


func _integrate_forces(state):
	
	var forward = -get_global_transform().basis.z
	var direction_to_target = (target_position - get_global_transform().origin).normalized()
	
	state.add_torque(forward.cross(direction_to_target) * 50)
	state.add_torque(angular_velocity * -10)


func apply_damage(damage):
	integrity -= damage
	if integrity <= 0.0:
		explode()
	else:
		get_node("DamageSound").play()


func shoot():
	var projectile = projectile_scene.instance()
	projectile.set_translation(get_node("Weapon").get_global_transform().origin)
	projectile.velocity = -get_global_transform().basis.z * 20
	projectile.color = Color(1.0, 0.0, 0.0, 0.2)
	get_parent().add_child(projectile)
	
	get_node("ShootSound").play()
	light_flash = 1.0


func explode():
	
	var explosion = explosion_scene.instance()
	explosion.color = Color(1.0, 0.0, 0.0, 1.0)
	explosion.transform = transform
	get_parent().add_child(explosion)
	
	queue_free()


func is_active_enemy():
	return true

