extends CharacterBody3D

@export var speed := 3.1
@export var max_hp := 2

var hp := 2
var threat_type := "alien"
var target: Node3D
var fallback_target: Node3D
var _attack_cooldown := 0.0
var _body_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("threats")
	hp = max_hp
	_build_visual()


func _physics_process(delta: float) -> void:
	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)

	var chase_target := target if is_instance_valid(target) else fallback_target
	if not is_instance_valid(chase_target):
		velocity = Vector3.ZERO
		return

	var to_target := chase_target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if distance > 0.95:
		velocity = to_target.normalized() * speed
		move_and_slide()
		look_at(Vector3(chase_target.global_position.x, global_position.y, chase_target.global_position.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO
		if _attack_cooldown <= 0.0 and chase_target.has_method("hit"):
			chase_target.hit(1)
			_attack_cooldown = 0.8


func hit(damage: int) -> void:
	hp -= damage
	if is_instance_valid(_body_material):
		_body_material.albedo_color = Color(1.0, 0.35, 0.25)

	if hp <= 0:
		if get_tree().current_scene.has_method("on_threat_destroyed"):
			get_tree().current_scene.on_threat_destroyed()
		queue_free()


func _build_visual() -> void:
	_body_material = _mat(Color(0.8, 0.12, 0.1), Color(1.0, 0.05, 0.0), 0.6)
	var dark := _mat(Color(0.1, 0.08, 0.09))
	var acid := _mat(Color(0.38, 1.0, 0.18), Color(0.15, 1.0, 0.1), 1.8)
	var steel := _mat(Color(0.35, 0.39, 0.42))
	var warning := _mat(Color(1.0, 0.36, 0.08), Color(1.0, 0.18, 0.0), 1.5)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.35
	capsule.height = 0.9
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.45, 0.0)
	add_child(collision)

	if threat_type == "drone":
		speed = 3.8
		max_hp = 2
		_add_sphere("DroneCore", Vector3(0.0, 0.92, 0.0), 0.33, steel)
		_add_box("DroneRedArmorTop", Vector3(0.0, 1.08, -0.03), Vector3(0.52, 0.13, 0.38), _body_material)
		_add_box("DroneSensorFace", Vector3(0.0, 0.94, -0.34), Vector3(0.32, 0.12, 0.035), warning)
		_add_box("DroneWingL", Vector3(-0.56, 0.94, 0.0), Vector3(0.58, 0.1, 0.2), dark)
		_add_box("DroneWingR", Vector3(0.56, 0.94, 0.0), Vector3(0.58, 0.1, 0.2), dark)
		_add_cylinder("LeftRotor", Vector3(-0.88, 0.98, 0.0), 0.24, 0.035, warning)
		_add_cylinder("RightRotor", Vector3(0.88, 0.98, 0.0), 0.24, 0.035, warning)
		_add_box("LeftRotorBladeA", Vector3(-0.88, 1.0, 0.0), Vector3(0.48, 0.025, 0.055), dark)
		_add_box("LeftRotorBladeB", Vector3(-0.88, 1.0, 0.0), Vector3(0.055, 0.025, 0.48), dark)
		_add_box("RightRotorBladeA", Vector3(0.88, 1.0, 0.0), Vector3(0.48, 0.025, 0.055), dark)
		_add_box("RightRotorBladeB", Vector3(0.88, 1.0, 0.0), Vector3(0.055, 0.025, 0.48), dark)
		_add_box("DroneStinger", Vector3(0.0, 0.75, -0.46), Vector3(0.12, 0.1, 0.36), dark)
	else:
		speed = 2.8
		max_hp = 3
		hp = max_hp
		_add_sphere("AlienCranium", Vector3(0.0, 0.93, -0.08), 0.34, _body_material)
		_add_box("AlienMaw", Vector3(0.0, 0.82, -0.38), Vector3(0.38, 0.16, 0.18), dark)
		_add_sphere("LeftAlienEye", Vector3(-0.11, 0.98, -0.36), 0.045, acid)
		_add_sphere("RightAlienEye", Vector3(0.11, 0.98, -0.36), 0.045, acid)
		_add_box("AlienRibBody", Vector3(0.0, 0.45, 0.02), Vector3(0.62, 0.52, 0.48), _body_material)
		_add_box("AlienBellyGlow", Vector3(0.0, 0.46, -0.26), Vector3(0.32, 0.28, 0.035), acid)
		_add_box("SpinePlateA", Vector3(0.0, 0.68, 0.32), Vector3(0.22, 0.08, 0.16), dark)
		_add_box("SpinePlateB", Vector3(0.0, 0.48, 0.34), Vector3(0.26, 0.08, 0.16), dark)
		_add_box("SpinePlateC", Vector3(0.0, 0.28, 0.31), Vector3(0.18, 0.08, 0.14), dark)
		_add_box("LeftClawUpper", Vector3(-0.42, 0.52, -0.18), Vector3(0.16, 0.16, 0.42), dark, Vector3(0.0, 0.0, -18.0))
		_add_box("RightClawUpper", Vector3(0.42, 0.52, -0.18), Vector3(0.16, 0.16, 0.42), dark, Vector3(0.0, 0.0, 18.0))
		_add_box("LeftClawTip", Vector3(-0.5, 0.44, -0.45), Vector3(0.12, 0.11, 0.24), acid, Vector3(-20.0, 0.0, -18.0))
		_add_box("RightClawTip", Vector3(0.5, 0.44, -0.45), Vector3(0.12, 0.11, 0.24), acid, Vector3(-20.0, 0.0, 18.0))
		_add_box("LeftHindLeg", Vector3(-0.28, 0.13, 0.18), Vector3(0.14, 0.26, 0.38), dark, Vector3(0.0, 0.0, -12.0))
		_add_box("RightHindLeg", Vector3(0.28, 0.13, 0.18), Vector3(0.14, 0.26, 0.38), dark, Vector3(0.0, 0.0, 12.0))
		_add_box("TailStub", Vector3(0.0, 0.3, 0.48), Vector3(0.18, 0.16, 0.46), dark)


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_sphere(node_name: String, position: Vector3, radius: float, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.name = node_name
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _add_cylinder(node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = radius
	cylinder.bottom_radius = radius
	cylinder.height = height
	cylinder.radial_segments = 18
	mesh.mesh = cylinder
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.82
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
