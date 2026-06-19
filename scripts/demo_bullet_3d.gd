extends Area3D

@export var speed := 15.0
@export var lifetime := 1.5

var direction := Vector3.FORWARD
var _age := 0.0


func _ready() -> void:
	monitoring = true
	monitorable = false
	_build_visual()


func _physics_process(delta: float) -> void:
	global_position += direction * speed * delta
	_age += delta

	for threat in get_tree().get_nodes_in_group("threats"):
		var threat_3d := threat as Node3D
		if is_instance_valid(threat_3d) and global_position.distance_to(threat_3d.global_position + Vector3(0.0, 0.65, 0.0)) < 0.75:
			if threat.has_method("hit"):
				threat.hit(1)
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

	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.12
	sphere.height = 0.24
	mesh.mesh = sphere
	mesh.material_override = _mat(Color(1.0, 0.88, 0.2), Color(1.0, 0.78, 0.05), 2.2)
	add_child(mesh)


func _mat(albedo: Color, emission: Color, energy: float) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.emission_enabled = true
	material.emission = emission
	material.emission_energy_multiplier = energy
	return material
