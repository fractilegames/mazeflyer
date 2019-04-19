extends Spatial

export var color = Color(1.0, 1.0, 1.0, 1.0)


var fragment_scene = preload("res://fragment.tscn")
var timer = 0.0
var life_time = 1.0


func _ready():

	get_node("Sound").pitch_scale = 0.9 + randf() * 0.2

	var center = get_global_transform().origin
	for yaw in range(0, 8):
		for pitch in range(0, 8):
			var direction = Basis(Vector3(0.0, 1.0, 0.0), yaw * 2.0 * PI / 8.0) * Basis(Vector3(1.0, 0.0, 0.0), pitch * 2.0 * PI / 8.0) * Vector3(0.0, 0.0, -1.0)
			var fragment = fragment_scene.instance()
			fragment.color = Color(color.r, color.g, color.b, 0.0)
			fragment.set_translation(center + direction * 0.5)
			fragment.linear_velocity = direction * (3.0 + randf() * 3.0)
			fragment.angular_velocity = Vector3(randf() * 5.0 - 2.5, randf() * 5.0 - 2.5, randf() * 5.0 - 2.5)
			get_parent().add_child(fragment)


func _process(delta):
	var light = get_node("Light")

	timer += delta
	if timer > life_time:
		if not get_node("Sound").is_playing():
			queue_free()
	else:
		var value = clamp((life_time - timer) / life_time, 0.0, 1.0)
		var intensity = clamp(value * 1.5, 0.0, 1.0)
		light.light_color = Color(color.r * intensity, color.g * intensity, color.b * intensity, 1.0)
		light.omni_range = value * 15.0