extends Node3D

const RobotPlayer := preload("res://scripts/robot_player_3d.gd")
const ChildCompanion := preload("res://scripts/child_companion_3d.gd")
const EnemyThreat := preload("res://scripts/enemy_threat_3d.gd")

const RESCUE_POINT := Vector3(12.0, 0.0, -6.5)

var player
var child
var camera: Camera3D
var child_bar: ProgressBar
var robot_bar: ProgressBar
var status_label: Label
var objective_label: Label
var rescued := false
var failed := false
var remaining_threats := 0

var mat_floor: StandardMaterial3D
var mat_wall: StandardMaterial3D
var mat_wall_dark: StandardMaterial3D
var mat_light_blue: StandardMaterial3D
var mat_warning: StandardMaterial3D
var mat_rescue: StandardMaterial3D
var mat_crate: StandardMaterial3D
var mat_green: StandardMaterial3D


func _ready() -> void:
	randomize()
	_make_materials()
	_make_lighting()
	_make_world()
	_make_characters()
	_make_camera()
	_make_ui()
	_spawn_starting_threats()
	_update_ui()


func _process(_delta: float) -> void:
	if is_instance_valid(camera) and is_instance_valid(player):
		camera.global_position = player.global_position + Vector3(0.0, 16.0, 13.0)
		camera.look_at(player.global_position + Vector3(0.0, 0.4, 0.0), Vector3.UP)

	if rescued or failed:
		return

	if is_instance_valid(child) and child.global_position.distance_to(RESCUE_POINT) < 2.4:
		_win_demo()

	_update_ui()


func _make_materials() -> void:
	mat_floor = _mat(Color(0.11, 0.14, 0.16))
	mat_wall = _mat(Color(0.18, 0.22, 0.26))
	mat_wall_dark = _mat(Color(0.07, 0.08, 0.1))
	mat_light_blue = _mat(Color(0.16, 0.42, 0.78), Color(0.1, 0.55, 1.0), 1.4)
	mat_warning = _mat(Color(0.9, 0.26, 0.12), Color(1.0, 0.18, 0.05), 1.8)
	mat_rescue = _mat(Color(0.12, 0.85, 0.45), Color(0.0, 1.0, 0.35), 2.6)
	mat_crate = _mat(Color(0.28, 0.23, 0.17))
	mat_green = _mat(Color(0.08, 0.42, 0.22), Color(0.0, 0.8, 0.22), 0.8)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.86
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


func _make_lighting() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.02, 0.025, 0.035)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.32, 0.36)
	env.ambient_light_energy = 0.8
	environment.environment = env
	add_child(environment)

	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-58.0, 45.0, 0.0)
	sun.light_color = Color(0.75, 0.85, 1.0)
	sun.light_energy = 1.2
	add_child(sun)


func _make_world() -> void:
	_add_floor("DeckPlate", Vector3.ZERO, Vector3(31.0, 0.16, 21.0), mat_floor)
	_add_floor("RescueLandingPad", RESCUE_POINT + Vector3(0.0, 0.03, 0.0), Vector3(5.4, 0.18, 4.2), mat_green)

	_add_wall("NorthWall", Vector3(0.0, 1.0, -10.5), Vector3(31.0, 2.0, 0.5), mat_wall)
	_add_wall("SouthWall", Vector3(0.0, 1.0, 10.5), Vector3(31.0, 2.0, 0.5), mat_wall)
	_add_wall("WestWall", Vector3(-15.5, 1.0, 0.0), Vector3(0.5, 2.0, 21.0), mat_wall)
	_add_wall("EastWall", Vector3(15.5, 1.0, 0.0), Vector3(0.5, 2.0, 21.0), mat_wall)

	_add_wall("MedbayDivider", Vector3(-5.0, 1.0, -5.4), Vector3(0.5, 2.0, 7.2), mat_wall_dark)
	_add_wall("FactoryDivider", Vector3(4.0, 1.0, 4.8), Vector3(0.5, 2.0, 8.2), mat_wall_dark)
	_add_wall("HydroponicsDivider", Vector3(5.0, 1.0, -4.7), Vector3(7.4, 2.0, 0.5), mat_wall_dark)
	_add_wall("BrokenBulkheadA", Vector3(-9.5, 1.0, 2.0), Vector3(5.5, 2.0, 0.5), mat_wall_dark)
	_add_wall("BrokenBulkheadB", Vector3(9.6, 1.0, 1.7), Vector3(4.8, 2.0, 0.5), mat_wall_dark)

	for x in [-13.0, -7.0, -1.0, 5.0, 11.0]:
		_add_light_strip(Vector3(x, 0.08, -9.4), mat_warning)
		_add_light_strip(Vector3(x, 0.08, 9.4), mat_light_blue)

	_add_beacon(RESCUE_POINT)
	_add_props()


func _make_characters() -> void:
	player = RobotPlayer.new()
	player.name = "RobotAI"
	player.position = Vector3(-12.0, 0.0, 6.5)
	add_child(player)

	child = ChildCompanion.new()
	child.name = "Mila"
	child.target = player
	child.position = Vector3(-10.6, 0.0, 7.2)
	add_child(child)


func _make_camera() -> void:
	camera = Camera3D.new()
	camera.name = "TopDownCamera"
	camera.current = true
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.0
	add_child(camera)


func _make_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "HUD"
	add_child(layer)

	var margin := MarginContainer.new()
	margin.set_anchors_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 22)
	margin.add_theme_constant_override("margin_top", 18)
	margin.add_theme_constant_override("margin_right", 22)
	margin.add_theme_constant_override("margin_bottom", 18)
	layer.add_child(margin)

	var vbox := VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	margin.add_child(vbox)

	objective_label = Label.new()
	objective_label.text = "Escort Mila to the green rescue beacon"
	objective_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(objective_label)

	status_label = Label.new()
	status_label.text = ""
	status_label.add_theme_font_size_override("font_size", 16)
	vbox.add_child(status_label)

	robot_bar = _make_bar("Robot core")
	vbox.add_child(robot_bar)

	child_bar = _make_bar("Mila")
	vbox.add_child(child_bar)


func _make_bar(label_text: String) -> ProgressBar:
	var bar := ProgressBar.new()
	bar.min_value = 0.0
	bar.max_value = 1.0
	bar.value = 1.0
	bar.custom_minimum_size = Vector2(260.0, 18.0)
	bar.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	bar.show_percentage = false
	bar.tooltip_text = label_text
	return bar


func _spawn_starting_threats() -> void:
	_spawn_threat(Vector3(-2.0, 0.0, -7.0), "alien")
	_spawn_threat(Vector3(4.0, 0.0, -7.4), "drone")
	_spawn_threat(Vector3(8.5, 0.0, 3.5), "drone")
	_spawn_threat(Vector3(10.5, 0.0, -2.4), "alien")
	_spawn_threat(Vector3(2.5, 0.0, 7.2), "alien")


func _spawn_threat(position: Vector3, threat_type: String) -> void:
	var threat := EnemyThreat.new()
	threat.threat_type = threat_type
	threat.target = child
	threat.fallback_target = player
	threat.position = position
	add_child(threat)
	remaining_threats += 1


func _add_floor(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _add_wall(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var body := StaticBody3D.new()
	body.name = node_name
	body.position = position
	add_child(body)

	var mesh := MeshInstance3D.new()
	var box_mesh := BoxMesh.new()
	box_mesh.size = size
	mesh.mesh = box_mesh
	mesh.material_override = material
	body.add_child(mesh)

	var collision := CollisionShape3D.new()
	var box_shape := BoxShape3D.new()
	box_shape.size = size
	collision.shape = box_shape
	body.add_child(collision)


func _add_light_strip(position: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(2.2, 0.04, 0.18)
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _add_beacon(position: Vector3) -> void:
	var beacon := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.45
	cylinder.bottom_radius = 0.45
	cylinder.height = 2.4
	beacon.mesh = cylinder
	beacon.position = position + Vector3(0.0, 1.2, 0.0)
	beacon.material_override = mat_rescue
	add_child(beacon)

	var light := OmniLight3D.new()
	light.position = position + Vector3(0.0, 2.6, 0.0)
	light.light_color = Color(0.1, 1.0, 0.45)
	light.light_energy = 4.0
	light.omni_range = 7.0
	add_child(light)


func _add_props() -> void:
	for position in [Vector3(-12, 0.35, -6), Vector3(-10, 0.35, -5), Vector3(7, 0.35, 6), Vector3(12, 0.35, 4)]:
		_add_prop_box(position, Vector3(1.3, 0.7, 1.1), mat_crate)

	for position in [Vector3(7.5, 0.4, -7.4), Vector3(9.0, 0.4, -7.1), Vector3(10.5, 0.4, -7.6)]:
		_add_prop_box(position, Vector3(0.6, 0.8, 0.6), mat_green)

	for position in [Vector3(-3.0, 0.1, -8.7), Vector3(2.0, 0.1, 8.8), Vector3(13.4, 0.1, -1.5)]:
		var light := OmniLight3D.new()
		light.position = position + Vector3(0.0, 1.4, 0.0)
		light.light_color = Color(1.0, 0.28, 0.12)
		light.light_energy = 2.4
		light.omni_range = 4.8
		add_child(light)


func _add_prop_box(position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func on_threat_destroyed() -> void:
	remaining_threats = max(remaining_threats - 1, 0)
	_update_ui()


func on_actor_hit() -> void:
	_update_ui()


func fail_demo(reason: String) -> void:
	if rescued:
		return
	failed = true
	objective_label.text = "Mission failed"
	status_label.text = reason + "  Press R to restart."


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		get_tree().change_scene_to_file("res://scenes/reference_gallery.tscn")

	if failed or rescued:
		if event is InputEventKey:
			var key_event := event as InputEventKey
			if key_event.pressed and not key_event.echo and key_event.keycode == KEY_R:
				get_tree().reload_current_scene()


func _win_demo() -> void:
	rescued = true
	objective_label.text = "Rescue signal locked"
	status_label.text = "Mila reached the beacon. Prototype complete. Press R to restart."


func _update_ui() -> void:
	if not is_instance_valid(player) or not is_instance_valid(child):
		return

	robot_bar.value = float(player.hp) / float(player.max_hp)
	child_bar.value = float(child.hp) / float(child.max_hp)

	if not failed and not rescued:
		var distance: float = child.global_position.distance_to(RESCUE_POINT)
		status_label.text = "Threats: %d   Distance to rescue: %.1fm   LMB: fire   Esc: art gallery" % [remaining_threats, distance]
