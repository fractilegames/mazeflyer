extends Spatial


var damage_effect = 0.0
var initial_enemy_count = 0
var match_active = false
var match_time = 0.0


func _ready():
	
	get_node("ViewportContainer/StartPopup/StartButton").connect("button_down", self, "on_start_button")
	get_node("ViewportContainer/StartPopup/ExitButton").connect("button_down", self, "on_exit_button")
	get_node("Entities/Player").connect("on_damage", self, "on_player_damage")
	get_node("Entities/Player").connect("on_destruction", self, "on_player_destruction")
	
	set_process(true)
	
	start_match()
	toggle_menu()


func _process(delta):
	
	get_node("ViewportContainer/Flash").color = Color(0.6, 0.0, 0.0, damage_effect)
	get_node("ViewportContainer/Flash").visible = (damage_effect > 0.0)
	
	if damage_effect > 0.0:
		damage_effect -= delta * 4.0
		if damage_effect < 0.0:
			damage_effect = 0.0
	
	if match_active:
		match_time += delta
	
	update_stats()


func _input(event):

	if event is InputEventKey:
		if event.scancode == KEY_ESCAPE and event.is_pressed():

			# Prevent popup from receiving the key press
			get_tree().set_input_as_handled()

			# Toggle pop up
			toggle_menu()


func toggle_menu():
	
	if get_node("ViewportContainer/StartPopup").is_visible():
		get_node("ViewportContainer/StartPopup").hide()
		get_node("Entities/Player").set_active(true)
	else:
		get_node("ViewportContainer/StartPopup").popup()
		get_node("Entities/Player").set_active(false)


func on_player_damage():
	damage_effect = 1.0


func on_player_destruction():
	match_active = false
	handle_game_over(false)


func on_start_button():
	start_match()
	toggle_menu()


func on_exit_button():
	get_tree().quit()


func start_match():
	
	var level = get_node("Level")
	var player = get_node("Entities/Player")
	var entities = get_node("Entities")
	
	# Destroy all remaining non-player entities here!
	var i = 0
	while i < entities.get_child_count():
		var child = entities.get_child(i)
		if child != player:
			entities.remove_child(child)
			child.queue_free()
		else:
			i += 1
	
	var level_size = int(get_node("ViewportContainer/StartPopup/GridContainer/SizeSpinBox").value)
	var level_seed = int(get_node("ViewportContainer/StartPopup/GridContainer/SeedSpinBox").value)
	level.generate(level_size, level_seed)
	
	player.set_invert_pitch_control(get_node("ViewportContainer/StartPopup/GridContainer/InvertCheckBox").is_pressed())
	player.start_match(level.get_start_point(0))
	
	initial_enemy_count = 0
	for i in range(1, level.get_start_point_count()):
		var sentry = load("res://sentrygun.tscn").instance()
		sentry.set_transform(Transform(Basis(), level.get_start_point(i)))
		entities.add_child(sentry)
		initial_enemy_count += 1
	
	match_active = true
	match_time = 0.0


func update_stats():
	var entities = get_node("Entities")
	
	var enemy_count = 0
	for i in range(0, entities.get_child_count()):
		var entity = entities.get_child(i)
		if(entity.has_method("is_active_enemy") and entity.is_active_enemy()):
			enemy_count += 1
	
	get_node("ViewportContainer/EnemyLabel").set_text("Enemies: " + str(enemy_count) + "/" + str(initial_enemy_count))
	get_node("ViewportContainer/TimeLabel").set_text("Time: " + "%.3fs" % match_time)
	
	if match_active and enemy_count == 0:
		match_active = false
		handle_game_over(true)


func handle_game_over(var success):
	if success:
		get_node("ViewportContainer/StartPopup/Label").set_text("Level complete in " + "%.3fs" % match_time)
	else:
		get_node("ViewportContainer/StartPopup/Label").set_text("You died!")
		
	toggle_menu()

