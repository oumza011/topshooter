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
var mat_trim: StandardMaterial3D
var mat_panel: StandardMaterial3D
var mat_cable: StandardMaterial3D
var mat_glass: StandardMaterial3D
var mat_screen: StandardMaterial3D
var mat_medical: StandardMaterial3D
var mat_alien_growth: StandardMaterial3D
var mat_hazard: StandardMaterial3D


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
	mat_floor = _texture_mat("res://art/game_assets/ship_floor_texture.png", Color(0.86, 0.86, 0.86))
	mat_wall = _mat(Color(0.18, 0.22, 0.26))
	mat_wall_dark = _mat(Color(0.07, 0.08, 0.1))
	mat_light_blue = _mat(Color(0.16, 0.42, 0.78), Color(0.1, 0.55, 1.0), 1.4)
	mat_warning = _mat(Color(0.9, 0.26, 0.12), Color(1.0, 0.18, 0.05), 1.8)
	mat_rescue = _mat(Color(0.12, 0.85, 0.45), Color(0.0, 1.0, 0.35), 2.6)
	mat_crate = _mat(Color(0.28, 0.23, 0.17))
	mat_green = _mat(Color(0.08, 0.42, 0.22), Color(0.0, 0.8, 0.22), 0.8)
	mat_trim = _mat(Color(0.31, 0.37, 0.4))
	mat_panel = _mat(Color(0.085, 0.1, 0.115))
	mat_cable = _mat(Color(0.025, 0.03, 0.035))
	mat_glass = _mat(Color(0.08, 0.42, 0.55), Color(0.02, 0.42, 0.65), 0.5)
	mat_screen = _mat(Color(0.04, 0.18, 0.28), Color(0.0, 0.55, 0.9), 1.8)
	mat_medical = _mat(Color(0.85, 0.9, 0.86))
	mat_alien_growth = _texture_mat("res://art/game_assets/alien_nest_texture.png", Color(0.7, 0.35, 0.35), Color(0.65, 0.02, 0.08), 0.55)
	mat_hazard = _mat(Color(0.95, 0.66, 0.12), Color(1.0, 0.42, 0.0), 0.75)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.86
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material


func _texture_mat(texture_path: String, albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := _mat(albedo, emission, energy)
	material.albedo_texture = load(texture_path)
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

	_add_deck_detail()
	_add_wall_detail()
	_add_zone_setpieces()
	_add_curved_scene_skin()

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


func _add_deck_detail() -> void:
	for x_i in range(-14, 15, 4):
		var x: float = float(x_i)
		_add_prop_box(Vector3(x, 0.13, 0.0), Vector3(0.045, 0.035, 19.6), mat_trim)

	for z_i in range(-8, 9, 4):
		var z: float = float(z_i)
		_add_prop_box(Vector3(0.0, 0.135, z), Vector3(29.0, 0.035, 0.045), mat_trim)

	for x_i in range(-12, 13, 6):
		for z_i in range(-8, 9, 4):
			var x: float = float(x_i)
			var z: float = float(z_i)
			_add_prop_box(Vector3(x, 0.16, z), Vector3(2.55, 0.035, 1.35), mat_panel)
			_add_cylinder_prop("DeckBolt", Vector3(x - 1.12, 0.2, z - 0.52), 0.045, 0.035, mat_trim)
			_add_cylinder_prop("DeckBolt", Vector3(x + 1.12, 0.2, z - 0.52), 0.045, 0.035, mat_trim)
			_add_cylinder_prop("DeckBolt", Vector3(x - 1.12, 0.2, z + 0.52), 0.045, 0.035, mat_trim)
			_add_cylinder_prop("DeckBolt", Vector3(x + 1.12, 0.2, z + 0.52), 0.045, 0.035, mat_trim)

	_add_prop_box(Vector3(-12.0, 0.17, 6.5), Vector3(3.8, 0.045, 2.4), _mat(Color(0.12, 0.16, 0.2)))
	_add_prop_box(Vector3(-12.0, 0.2, 5.3), Vector3(3.8, 0.04, 0.12), mat_light_blue)
	_add_prop_box(Vector3(-12.0, 0.2, 7.7), Vector3(3.8, 0.04, 0.12), mat_warning)


func _add_wall_detail() -> void:
	for x_i in range(-14, 15, 2):
		var x: float = float(x_i)
		_add_prop_box(Vector3(x, 1.28, -10.16), Vector3(0.12, 2.15, 0.2), mat_trim)
		_add_prop_box(Vector3(x, 1.28, 10.16), Vector3(0.12, 2.15, 0.2), mat_trim)

	for z_i in range(-8, 9, 2):
		var z: float = float(z_i)
		_add_prop_box(Vector3(-15.16, 1.28, z), Vector3(0.2, 2.15, 0.12), mat_trim)
		_add_prop_box(Vector3(15.16, 1.28, z), Vector3(0.2, 2.15, 0.12), mat_trim)

	_add_cylinder_prop("NorthCoolantPipe", Vector3(0.0, 1.95, -10.18), 0.07, 28.0, mat_cable, Vector3(0.0, 0.0, 90.0))
	_add_cylinder_prop("SouthCoolantPipe", Vector3(0.0, 1.95, 10.18), 0.07, 28.0, mat_cable, Vector3(0.0, 0.0, 90.0))
	_add_cylinder_prop("WestPowerConduit", Vector3(-15.18, 1.78, 0.0), 0.06, 18.2, mat_cable, Vector3(90.0, 0.0, 0.0))
	_add_cylinder_prop("EastPowerConduit", Vector3(15.18, 1.78, 0.0), 0.06, 18.2, mat_cable, Vector3(90.0, 0.0, 0.0))

	_add_bulkhead_door(Vector3(-5.0, 1.25, -1.0), Vector3(0.0, 90.0, 0.0))
	_add_bulkhead_door(Vector3(4.0, 1.25, 0.0), Vector3(0.0, 90.0, 0.0))
	_add_bulkhead_door(Vector3(8.2, 1.25, -4.7), Vector3.ZERO)


func _add_zone_setpieces() -> void:
	_add_medbay_set()
	_add_hydroponics_set()
	_add_robot_bay_set()
	_add_alien_nest_set()
	_add_residential_set()


func _add_curved_scene_skin() -> void:
	for x_i in range(-14, 15, 4):
		var x: float = float(x_i)
		_add_capsule_prop("NorthRoundedRib", Vector3(x, 1.35, -10.23), 0.12, 2.25, mat_trim)
		_add_capsule_prop("SouthRoundedRib", Vector3(x, 1.35, 10.23), 0.12, 2.25, mat_trim)
		_add_capsule_prop("NorthTopRail", Vector3(x, 2.25, -10.05), 0.065, 3.2, mat_light_blue, Vector3(0.0, 0.0, 90.0))
		_add_capsule_prop("SouthTopRail", Vector3(x, 2.25, 10.05), 0.065, 3.2, mat_warning, Vector3(0.0, 0.0, 90.0))

	for z_i in range(-8, 9, 4):
		var z: float = float(z_i)
		_add_capsule_prop("WestRoundedRib", Vector3(-15.23, 1.35, z), 0.12, 2.25, mat_trim)
		_add_capsule_prop("EastRoundedRib", Vector3(15.23, 1.35, z), 0.12, 2.25, mat_trim)
		_add_capsule_prop("WestTopRail", Vector3(-15.05, 2.25, z), 0.065, 3.2, mat_light_blue, Vector3(90.0, 0.0, 0.0))
		_add_capsule_prop("EastTopRail", Vector3(15.05, 2.25, z), 0.065, 3.2, mat_warning, Vector3(90.0, 0.0, 0.0))

	for position in [Vector3(-5.0, 1.25, -1.0), Vector3(4.0, 1.25, 0.0), Vector3(8.2, 1.25, -4.7)]:
		_add_round_bulkhead_frame(position)

	for position in [Vector3(-12.0, 0.22, 6.5), Vector3(-6.8, 0.2, 5.8), Vector3(0.0, 0.2, 0.0), Vector3(6.4, 0.2, -2.8), Vector3(12.0, 0.2, -6.5)]:
		_add_cylinder_prop("OvalDeckPlate", position, 1.35, 0.045, mat_panel)
		_add_cylinder_prop("OvalDeckTrim", position + Vector3(0.0, 0.035, 0.0), 1.48, 0.025, mat_trim)

	_add_ellipsoid_prop("ObservationBubbleA", Vector3(-14.8, 1.42, -6.2), Vector3(0.12, 0.82, 1.6), mat_glass)
	_add_ellipsoid_prop("ObservationBubbleB", Vector3(14.8, 1.42, -6.2), Vector3(0.12, 0.82, 1.6), mat_glass)
	_add_capsule_prop("HangingCableA", Vector3(-3.4, 1.35, -9.2), 0.035, 2.5, mat_cable, Vector3(36.0, 0.0, 90.0))
	_add_capsule_prop("HangingCableB", Vector3(-1.9, 1.2, -9.15), 0.03, 1.8, mat_cable, Vector3(-24.0, 0.0, 90.0))
	_add_capsule_prop("HangingCableC", Vector3(13.1, 1.1, -1.5), 0.03, 1.6, mat_cable, Vector3(58.0, 0.0, 20.0))


func _add_round_bulkhead_frame(position: Vector3) -> void:
	_add_capsule_prop("BulkheadLeftRoundedColumn", position + Vector3(-0.75, 0.0, 0.0), 0.11, 2.1, mat_trim)
	_add_capsule_prop("BulkheadRightRoundedColumn", position + Vector3(0.75, 0.0, 0.0), 0.11, 2.1, mat_trim)
	_add_capsule_prop("BulkheadTopRoundedArc", position + Vector3(0.0, 0.95, 0.0), 0.11, 1.5, mat_trim, Vector3(0.0, 0.0, 90.0))
	_add_capsule_prop("BulkheadLowerRail", position + Vector3(0.0, -0.72, 0.0), 0.075, 1.35, mat_wall_dark, Vector3(0.0, 0.0, 90.0))
	_add_sphere_prop("BulkheadLeftLamp", position + Vector3(-0.92, 0.72, -0.1), 0.075, mat_warning)
	_add_sphere_prop("BulkheadRightLamp", position + Vector3(0.92, 0.72, -0.1), 0.075, mat_light_blue)


func _add_medbay_set() -> void:
	_add_prop_box(Vector3(-11.6, 0.45, -7.4), Vector3(2.1, 0.28, 0.78), mat_medical)
	_add_prop_box(Vector3(-11.6, 0.66, -7.4), Vector3(1.82, 0.12, 0.56), _mat(Color(0.38, 0.74, 0.82)))
	_add_prop_box(Vector3(-12.6, 0.86, -7.4), Vector3(0.18, 0.55, 0.74), mat_trim)
	_add_prop_box(Vector3(-9.3, 0.75, -8.0), Vector3(0.22, 1.0, 1.2), mat_wall_dark)
	_add_prop_box(Vector3(-9.42, 1.03, -8.0), Vector3(0.035, 0.42, 0.72), mat_screen)
	_add_cylinder_prop("MedScannerLeft", Vector3(-11.6, 0.95, -7.95), 0.04, 0.9, mat_light_blue)
	_add_cylinder_prop("MedScannerRight", Vector3(-11.6, 0.95, -6.85), 0.04, 0.9, mat_light_blue)
	_add_prop_box(Vector3(-11.6, 1.42, -7.4), Vector3(0.16, 0.12, 1.28), mat_light_blue)
	_add_prop_box(Vector3(-13.6, 0.6, -8.6), Vector3(0.8, 0.9, 0.42), mat_medical)
	_add_prop_box(Vector3(-13.6, 1.12, -8.6), Vector3(0.82, 0.08, 0.44), mat_warning)
	_add_point_light_world(Vector3(-11.4, 1.8, -7.4), Color(0.55, 0.9, 1.0), 1.2, 4.2)


func _add_hydroponics_set() -> void:
	for x_i in range(7, 13, 2):
		var x: float = float(x_i)
		_add_prop_box(Vector3(x, 0.32, -7.6), Vector3(1.35, 0.42, 0.7), mat_green)
		_add_prop_box(Vector3(x, 0.58, -7.6), Vector3(1.12, 0.12, 0.46), _mat(Color(0.06, 0.22, 0.1)))
		_add_cylinder_prop("PlantStem", Vector3(x - 0.32, 0.94, -7.58), 0.025, 0.62, mat_green)
		_add_cylinder_prop("PlantStem", Vector3(x + 0.32, 0.86, -7.58), 0.025, 0.5, mat_green)
		_add_sphere_prop("PlantLeaf", Vector3(x - 0.32, 1.28, -7.55), 0.18, mat_green)
		_add_sphere_prop("PlantLeaf", Vector3(x + 0.32, 1.12, -7.55), 0.16, mat_green)

	_add_prop_box(Vector3(10.0, 0.96, -5.5), Vector3(2.9, 1.3, 0.08), mat_glass)
	_add_prop_box(Vector3(10.0, 1.68, -5.5), Vector3(2.9, 0.08, 0.14), mat_light_blue)
	_add_cylinder_prop("HydroWaterPipe", Vector3(10.0, 1.72, -8.55), 0.05, 5.6, mat_light_blue, Vector3(0.0, 0.0, 90.0))
	_add_point_light_world(Vector3(10.0, 2.0, -7.4), Color(0.25, 1.0, 0.45), 1.1, 4.5)


func _add_robot_bay_set() -> void:
	_add_prop_box(Vector3(8.0, 0.48, 6.7), Vector3(3.2, 0.38, 1.1), mat_trim)
	_add_prop_box(Vector3(8.0, 0.79, 6.7), Vector3(2.8, 0.14, 0.9), mat_panel)
	_add_prop_box(Vector3(6.85, 1.1, 6.2), Vector3(0.14, 0.72, 0.14), mat_hazard)
	_add_cylinder_prop("RobotArmBase", Vector3(8.9, 0.92, 6.42), 0.2, 0.22, mat_wall_dark)
	_add_cylinder_prop("RobotArmUpper", Vector3(8.85, 1.25, 6.28), 0.055, 0.72, mat_hazard, Vector3(28.0, 0.0, 0.0))
	_add_cylinder_prop("RobotArmLower", Vector3(8.62, 1.45, 5.84), 0.045, 0.62, mat_hazard, Vector3(58.0, 0.0, 0.0))
	_add_box("RobotArmClampA", Vector3(8.51, 1.38, 5.48), Vector3(0.08, 0.2, 0.25), mat_wall_dark, Vector3(18.0, 0.0, 0.0))
	_add_box("RobotArmClampB", Vector3(8.72, 1.38, 5.48), Vector3(0.08, 0.2, 0.25), mat_wall_dark, Vector3(-18.0, 0.0, 0.0))
	_add_prop_box(Vector3(11.3, 0.85, 6.3), Vector3(0.8, 1.2, 0.42), mat_wall_dark)
	_add_prop_box(Vector3(11.3, 1.15, 6.04), Vector3(0.56, 0.36, 0.035), mat_screen)
	_add_point_light_world(Vector3(8.2, 1.7, 6.1), Color(1.0, 0.55, 0.12), 0.9, 3.8)


func _add_alien_nest_set() -> void:
	_add_prop_box(Vector3(10.7, 0.18, 2.9), Vector3(4.2, 0.06, 3.0), mat_alien_growth)
	_add_cylinder_prop("NestRibA", Vector3(9.1, 0.62, 2.1), 0.065, 2.2, mat_alien_growth, Vector3(62.0, 0.0, 26.0))
	_add_cylinder_prop("NestRibB", Vector3(11.6, 0.68, 3.8), 0.06, 2.0, mat_alien_growth, Vector3(45.0, 0.0, -34.0))
	_add_sphere_prop("NestPodA", Vector3(9.6, 0.52, 2.8), 0.38, mat_alien_growth)
	_add_sphere_prop("NestPodB", Vector3(11.4, 0.5, 2.2), 0.32, mat_alien_growth)
	_add_sphere_prop("NestPodC", Vector3(12.5, 0.45, 3.6), 0.28, mat_alien_growth)
	_add_prop_box(Vector3(10.7, 0.22, 4.7), Vector3(3.4, 0.08, 0.24), mat_alien_growth)
	_add_point_light_world(Vector3(10.7, 1.25, 3.0), Color(1.0, 0.05, 0.06), 1.0, 4.0)


func _add_residential_set() -> void:
	_add_prop_box(Vector3(-12.2, 0.42, 2.9), Vector3(1.9, 0.32, 0.86), _mat(Color(0.24, 0.28, 0.34)))
	_add_prop_box(Vector3(-12.2, 0.68, 2.9), Vector3(1.52, 0.12, 0.62), _mat(Color(0.72, 0.5, 0.32)))
	_add_prop_box(Vector3(-13.6, 0.74, 3.9), Vector3(0.7, 1.1, 0.46), mat_wall_dark)
	_add_prop_box(Vector3(-13.6, 1.36, 3.9), Vector3(0.72, 0.1, 0.48), mat_warning)
	_add_prop_box(Vector3(-10.6, 0.45, 2.6), Vector3(0.52, 0.42, 0.42), mat_crate)
	_add_prop_box(Vector3(-10.55, 0.74, 2.32), Vector3(0.38, 0.08, 0.04), mat_light_blue)
	_add_point_light_world(Vector3(-12.0, 1.55, 3.0), Color(1.0, 0.55, 0.3), 0.8, 3.4)


func _add_bulkhead_door(position: Vector3, rotation: Vector3) -> void:
	_add_prop_box(position + Vector3(0.0, 0.0, 0.0), Vector3(1.5, 2.1, 0.12), mat_trim, rotation)
	_add_prop_box(position + Vector3(0.0, 0.0, -0.03), Vector3(1.08, 1.45, 0.14), mat_wall_dark, rotation)
	_add_prop_box(position + Vector3(-0.54, 0.0, -0.08), Vector3(0.08, 1.65, 0.12), mat_warning, rotation)
	_add_prop_box(position + Vector3(0.54, 0.0, -0.08), Vector3(0.08, 1.65, 0.12), mat_light_blue, rotation)


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
	_add_cylinder_prop("RescueOuterPad", position + Vector3(0.0, 0.14, 0.0), 1.85, 0.055, mat_rescue)
	_add_cylinder_prop("RescueInnerPad", position + Vector3(0.0, 0.18, 0.0), 0.95, 0.06, mat_panel)
	_add_prop_box(position + Vector3(0.0, 0.24, -1.36), Vector3(2.8, 0.06, 0.14), mat_rescue)
	_add_prop_box(position + Vector3(0.0, 0.24, 1.36), Vector3(2.8, 0.06, 0.14), mat_rescue)
	_add_prop_box(position + Vector3(-1.36, 0.24, 0.0), Vector3(0.14, 0.06, 2.8), mat_rescue)
	_add_prop_box(position + Vector3(1.36, 0.24, 0.0), Vector3(0.14, 0.06, 2.8), mat_rescue)

	var beacon := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.45
	cylinder.bottom_radius = 0.45
	cylinder.height = 2.4
	beacon.mesh = cylinder
	beacon.position = position + Vector3(0.0, 1.2, 0.0)
	beacon.material_override = mat_rescue
	add_child(beacon)

	_add_cylinder_prop("RescueBeaconCore", position + Vector3(0.0, 1.2, 0.0), 0.18, 2.9, mat_light_blue)
	_add_cylinder_prop("RescueBeaconTopRing", position + Vector3(0.0, 2.42, 0.0), 0.72, 0.08, mat_rescue)
	_add_cylinder_prop("RescueBeaconBottomRing", position + Vector3(0.0, 0.42, 0.0), 0.72, 0.08, mat_rescue)
	_add_prop_box(position + Vector3(-1.8, 0.75, -1.35), Vector3(0.18, 1.3, 0.18), mat_trim)
	_add_prop_box(position + Vector3(1.8, 0.75, -1.35), Vector3(0.18, 1.3, 0.18), mat_trim)
	_add_prop_box(position + Vector3(-1.8, 0.75, 1.35), Vector3(0.18, 1.3, 0.18), mat_trim)
	_add_prop_box(position + Vector3(1.8, 0.75, 1.35), Vector3(0.18, 1.3, 0.18), mat_trim)
	_add_sphere_prop("RescuePostLightA", position + Vector3(-1.8, 1.5, -1.35), 0.12, mat_rescue)
	_add_sphere_prop("RescuePostLightB", position + Vector3(1.8, 1.5, -1.35), 0.12, mat_rescue)
	_add_sphere_prop("RescuePostLightC", position + Vector3(-1.8, 1.5, 1.35), 0.12, mat_rescue)
	_add_sphere_prop("RescuePostLightD", position + Vector3(1.8, 1.5, 1.35), 0.12, mat_rescue)

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

	_add_prop_box(Vector3(-3.2, 0.28, 8.4), Vector3(1.6, 0.28, 0.36), mat_wall_dark, Vector3(0.0, 18.0, 0.0))
	_add_prop_box(Vector3(-2.9, 0.45, 8.05), Vector3(0.72, 0.08, 0.08), mat_warning, Vector3(0.0, 18.0, 0.0))
	_add_prop_box(Vector3(2.6, 0.22, -1.8), Vector3(1.1, 0.1, 0.85), mat_trim, Vector3(0.0, 32.0, 0.0))
	_add_prop_box(Vector3(2.2, 0.28, -2.25), Vector3(0.68, 0.14, 0.42), mat_cable, Vector3(0.0, -18.0, 0.0))
	_add_cylinder_prop("LooseCableA", Vector3(-1.2, 0.22, 7.8), 0.035, 2.8, mat_cable, Vector3(90.0, 0.0, 58.0))
	_add_cylinder_prop("LooseCableB", Vector3(-0.2, 0.21, 8.4), 0.03, 2.1, mat_cable, Vector3(90.0, 0.0, -34.0))


func _add_prop_box(position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := _add_prop_box(position, size, material, rotation)
	mesh.name = node_name
	return mesh


func _add_ellipsoid_prop(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 32
	sphere.rings = 16
	mesh.mesh = sphere
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.scale = size
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_capsule_prop(node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 24
	capsule.rings = 12
	mesh.mesh = capsule
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_cylinder_prop(node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 24
	mesh.mesh = cylinder
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_sphere_prop(node_name: String, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.name = node_name
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_point_light_world(position: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	add_child(light)


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
	if is_instance_valid(player) and player.has_method("celebrate"):
		player.celebrate()
	if is_instance_valid(child) and child.has_method("celebrate"):
		child.celebrate()
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
