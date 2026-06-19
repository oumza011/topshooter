extends Area3D

@export var speed := 15.0
@export var lifetime := 1.5

var direction := Vector3.FORWARD
var _age := 0.0
var _visual_root: Node3D
var _orb: MeshInstance3D
var _trail: MeshInstance3D
var _light: OmniLight3D


func _ready() -> void:
	monitoring = true
	monitorable = false
	_build_visual()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta
	if direction.length() > 0.01:
		look_at(global_position + direction, Vector3.UP)

	if is_instance_valid(_orb):
		var pulse := 1.0 + sin(_age * 42.0) * 0.18
		_orb.scale = Vector3.ONE * pulse
	if is_instance_valid(_trail):
		_trail.scale.z = 1.0 + _age * 0.6
	if is_instance_valid(_light):
		_light.light_energy = 1.8 + sin(_age * 36.0) * 0.55

	for threat in get_tree().get_nodes_in_group("threats"):
		var threat_3d := threat as Node3D
		if is_instance_valid(threat_3d) and global_position.distance_to(threat_3d.global_position + Vector3(0.0, 0.65, 0.0)) < 0.75:
			if threat.has_method("hit"):
				threat.hit(1)
			_spawn_impact()
			queue_free()
			return

	if _age >= lifetime:
		queue_free()


func _build_visual() -> void:
	var collision := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.12
	collision.shape = shape
	add_child(collision)

	_visual_root = Node3D.new()
	_visual_root.name = "BulletVisual"
	add_child(_visual_root)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh.mesh = sphere
	mesh.material_override = _mat(Color(1.0, 0.88, 0.2), Color(1.0, 0.78, 0.05), 2.2)
	_visual_root.add_child(mesh)
	_orb = mesh

	var trail := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.045
	cylinder.bottom_radius = 0.12
	cylinder.height = 0.72
	cylinder.radial_segments = 14
	trail.mesh = cylinder
	trail.position = Vector3(0.0, 0.0, 0.3)
	trail.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	trail.material_override = _mat(Color(1.0, 0.5, 0.08), Color(1.0, 0.4, 0.0), 1.4)
	_visual_root.add_child(trail)
	_trail = trail

	_light = OmniLight3D.new()
	_light.light_color = Color(1.0, 0.72, 0.18)
	_light.light_energy = 2.0
	_light.omni_range = 2.2
	_visual_root.add_child(_light)


func _spawn_impact() -> void:
	var impact := Node3D.new()
	impact.global_position = global_position
	get_tree().current_scene.add_child(impact)

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.18
	sphere.height = 0.36
	mesh.mesh = sphere
	mesh.material_override = _mat(Color(1.0, 0.45, 0.1), Color(1.0, 0.24, 0.0), 2.8)
	impact.add_child(mesh)

	var light := OmniLight3D.new()
	light.light_color = Color(1.0, 0.34, 0.08)
	light.light_energy = 3.0
	light.omni_range = 2.6
	impact.add_child(light)

	var tween := impact.create_tween()
	tween.set_parallel(true)
	tween.tween_property(mesh, "scale", Vector3.ONE * 2.3, 0.16)
	tween.tween_property(light, "light_energy", 0.0, 0.16)
	tween.tween_property(mesh, "transparency", 1.0, 0.16)
	tween.set_parallel(false)
	tween.tween_callback(impact.queue_free)


func _mat(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material
