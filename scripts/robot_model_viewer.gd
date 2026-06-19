extends Node3D

const ROBOT_SCENE := preload("res://art/models/robot_showcase.glb")

var _robot_pivot: Node3D
var _camera: Camera3D
var _distance := 7.2
var _dragging := false
var _auto_rotate := true
var _pitch := 0.0
var _yaw := 0.0


func _ready() -> void:
	_make_world()
	_make_robot()
	_make_camera()
	_make_lights()
	_make_ui()
	_update_camera()


func _process(delta: float) -> void:
	if _auto_rotate and not _dragging:
		_yaw += delta * 0.34
	_update_robot_rotation()
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse.pressed
			if mouse.pressed:
				_auto_rotate = false
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_distance = maxf(_distance - 0.45, 4.4)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_distance = minf(_distance + 0.45, 10.0)

	if event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * 0.008
		_pitch = clampf(_pitch - motion.relative.y * 0.006, deg_to_rad(-14.0), deg_to_rad(18.0))

	if event is InputEventKey:
		var key_event := event as InputEventKey
		if key_event.pressed and not key_event.echo:
			if key_event.keycode == KEY_R:
				_yaw = 0.0
				_pitch = 0.0
				_distance = 7.2
				_auto_rotate = true
			elif key_event.keycode == KEY_SPACE:
				_auto_rotate = not _auto_rotate


func _make_robot() -> void:
	_robot_pivot = Node3D.new()
	_robot_pivot.name = "RobotTurntable"
	add_child(_robot_pivot)

	var robot := ROBOT_SCENE.instantiate()
	robot.name = "RobotShowcaseModel"
	robot.position = Vector3(0.0, -0.04, 0.0)
	_robot_pivot.add_child(robot)


func _make_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "ShowcaseCamera"
	_camera.current = true
	_camera.fov = 34.0
	_camera.near = 0.05
	_camera.far = 60.0
	add_child(_camera)


func _update_camera() -> void:
	if not is_instance_valid(_camera):
		return
	var target := Vector3(0.0, 2.55, 0.0)
	_camera.position = target + Vector3(0.0, 0.55, _distance)
	_camera.look_at(target, Vector3.UP)


func _update_robot_rotation() -> void:
	if not is_instance_valid(_robot_pivot):
		return
	_robot_pivot.rotation = Vector3(_pitch, _yaw, 0.0)


func _make_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.015, 0.017, 0.022)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.28, 0.30, 0.34)
	env.ambient_light_energy = 0.85
	environment.environment = env
	add_child(environment)

	var base_mat := _mat(Color(0.075, 0.085, 0.095))
	var trim_mat := _mat(Color(0.30, 0.36, 0.38), Color(0.0, 0.32, 0.48), 0.3)
	var glow_mat := _mat(Color(1.0, 0.46, 0.12), Color(1.0, 0.28, 0.04), 1.2)

	_add_cylinder("ShowcasePedestal", Vector3(0.0, -0.08, 0.0), 1.55, 0.16, base_mat)
	_add_cylinder("ShowcasePedestalTrim", Vector3(0.0, 0.03, 0.0), 1.66, 0.035, trim_mat)
	_add_cylinder("ShowcaseAmberRing", Vector3(0.0, 0.065, 0.0), 1.76, 0.018, glow_mat)
	_add_floor_grid()


func _make_lights() -> void:
	var key := DirectionalLight3D.new()
	key.name = "LargeSoftKeyLight"
	key.rotation_degrees = Vector3(-44.0, -32.0, 0.0)
	key.light_color = Color(0.93, 0.88, 0.76)
	key.light_energy = 2.3
	add_child(key)

	var face := OmniLight3D.new()
	face.name = "AmberFaceKick"
	face.position = Vector3(0.0, 4.1, 2.2)
	face.light_color = Color(1.0, 0.54, 0.18)
	face.light_energy = 1.4
	face.omni_range = 4.8
	add_child(face)

	var rim_left := OmniLight3D.new()
	rim_left.name = "BlueRimLeft"
	rim_left.position = Vector3(-2.8, 3.0, -1.8)
	rim_left.light_color = Color(0.28, 0.62, 1.0)
	rim_left.light_energy = 2.0
	rim_left.omni_range = 5.5
	add_child(rim_left)

	var rim_right := OmniLight3D.new()
	rim_right.name = "WarmRimRight"
	rim_right.position = Vector3(2.4, 2.4, 1.8)
	rim_right.light_color = Color(1.0, 0.36, 0.12)
	rim_right.light_energy = 1.2
	rim_right.omni_range = 4.8
	add_child(rim_right)


func _make_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "ViewerHUD"
	add_child(layer)

	var label := Label.new()
	label.text = "Robot model viewer   Drag: rotate   Wheel: zoom   Space: auto rotate   R: reset"
	label.position = Vector2(22.0, 18.0)
	label.add_theme_font_size_override("font_size", 18)
	label.modulate = Color(0.86, 0.92, 0.95)
	layer.add_child(label)


func _add_floor_grid() -> void:
	var grid_mat := _mat(Color(0.12, 0.15, 0.17), Color(0.0, 0.18, 0.24), 0.18)
	for i in range(-5, 6):
		var f := float(i) * 0.55
		_add_box("GridLineX", Vector3(f, -0.16, 0.0), Vector3(0.014, 0.012, 5.8), grid_mat)
		_add_box("GridLineZ", Vector3(0.0, -0.159, f), Vector3(5.8, 0.012, 0.014), grid_mat)


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _add_cylinder(node_name: String, position: Vector3, radius: float, height: float, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = node_name
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 96
	mesh.mesh = cylinder
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.76
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
