extends Node3D

const MILA_RIG_SCENE := preload("res://art/models/mila_child1_rig_test.glb")

var _pivot: Node3D
var _camera: Camera3D
var _animation_player: AnimationPlayer
var _yaw := 0.0
var _distance := 6.2
var _dragging := false
var _auto_rotate := true


func _ready() -> void:
	_make_world()
	_make_model()
	_make_camera()
	_make_lights()
	_make_ui()
	_play_first_animation()


func _process(delta: float) -> void:
	if _auto_rotate and not _dragging:
		_yaw += delta * 0.28
	if is_instance_valid(_pivot):
		_pivot.rotation.y = _yaw
	_update_camera()


func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton:
		var mouse := event as InputEventMouseButton
		if mouse.button_index == MOUSE_BUTTON_LEFT:
			_dragging = mouse.pressed
			if mouse.pressed:
				_auto_rotate = false
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_UP and mouse.pressed:
			_distance = maxf(_distance - 0.35, 3.8)
		elif mouse.button_index == MOUSE_BUTTON_WHEEL_DOWN and mouse.pressed:
			_distance = minf(_distance + 0.35, 9.0)

	if event is InputEventMouseMotion and _dragging:
		var motion := event as InputEventMouseMotion
		_yaw -= motion.relative.x * 0.008

	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_SPACE:
				_auto_rotate = not _auto_rotate
			elif key.keycode == KEY_R:
				_yaw = 0.0
				_distance = 6.2
				_auto_rotate = true
				_play_first_animation()


func _make_model() -> void:
	_pivot = Node3D.new()
	_pivot.name = "MilaRigTurntable"
	add_child(_pivot)

	var model := MILA_RIG_SCENE.instantiate()
	model.name = "MilaChildRigTest"
	model.scale = Vector3.ONE * 4.2
	_pivot.add_child(model)

	_animation_player = model.find_child("AnimationPlayer", true, false) as AnimationPlayer


func _play_first_animation() -> void:
	if not is_instance_valid(_animation_player):
		return
	var animations := _animation_player.get_animation_list()
	if animations.is_empty():
		return
	_animation_player.play(animations[0])


func _make_camera() -> void:
	_camera = Camera3D.new()
	_camera.name = "MilaRigCamera"
	_camera.current = true
	_camera.fov = 38.0
	_camera.near = 0.05
	_camera.far = 80.0
	add_child(_camera)
	_update_camera()


func _update_camera() -> void:
	if not is_instance_valid(_camera):
		return
	var target := Vector3(0.0, 2.15, 0.0)
	_camera.position = target + Vector3(0.0, 0.15, _distance)
	_camera.look_at(target, Vector3.UP)


func _make_world() -> void:
	var environment := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.025, 0.025, 0.03)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.36, 0.34, 0.32)
	env.ambient_light_energy = 0.9
	environment.environment = env
	add_child(environment)

	var base_mat := _mat(Color(0.075, 0.075, 0.08))
	var ring_mat := _mat(Color(0.95, 0.62, 0.32), Color(1.0, 0.38, 0.08), 0.8)
	_add_cylinder("RigPreviewPedestal", Vector3(0.0, -0.08, 0.0), 1.45, 0.16, base_mat)
	_add_cylinder("RigPreviewLightRing", Vector3(0.0, 0.03, 0.0), 1.55, 0.035, ring_mat)


func _make_lights() -> void:
	var key := DirectionalLight3D.new()
	key.name = "MilaKeyLight"
	key.rotation_degrees = Vector3(-42.0, -28.0, 0.0)
	key.light_color = Color(1.0, 0.92, 0.82)
	key.light_energy = 2.0
	add_child(key)

	var fill := OmniLight3D.new()
	fill.name = "MilaFaceFill"
	fill.position = Vector3(0.0, 3.0, 3.2)
	fill.light_color = Color(1.0, 0.72, 0.52)
	fill.light_energy = 1.8
	fill.omni_range = 5.5
	add_child(fill)

	var rim := OmniLight3D.new()
	rim.name = "MilaCoolRim"
	rim.position = Vector3(-2.8, 2.7, -2.0)
	rim.light_color = Color(0.35, 0.62, 1.0)
	rim.light_energy = 1.5
	rim.omni_range = 5.0
	add_child(rim)


func _make_ui() -> void:
	var layer := CanvasLayer.new()
	layer.name = "MilaRigHUD"
	add_child(layer)

	var label := Label.new()
	label.position = Vector2(22.0, 18.0)
	label.text = "Mila rig test: auto-playing first GLB animation   Drag: rotate   Wheel: zoom   Space: auto rotate   R: reset"
	label.add_theme_font_size_override("font_size", 17)
	label.modulate = Color(0.92, 0.9, 0.86)
	layer.add_child(label)


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
	material.roughness = 0.78
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
