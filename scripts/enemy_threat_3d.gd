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
		_add_sphere("DroneBody", Vector3(0.0, 0.92, 0.0), 0.38, _body_material)
		_add_box("DroneWingL", Vector3(-0.48, 0.92, 0.0), Vector3(0.42, 0.1, 0.18), dark)
		_add_box("DroneWingR", Vector3(0.48, 0.92, 0.0), Vector3(0.42, 0.1, 0.18), dark)
	else:
		speed = 2.8
		max_hp = 3
		hp = max_hp
		_add_sphere("AlienHead", Vector3(0.0, 0.88, -0.05), 0.32, _body_material)
		_add_box("AlienBody", Vector3(0.0, 0.42, 0.0), Vector3(0.62, 0.55, 0.5), _body_material)
		_add_box("LeftClaw", Vector3(-0.42, 0.5, -0.18), Vector3(0.18, 0.18, 0.45), dark)
		_add_box("RightClaw", Vector3(0.42, 0.5, -0.18), Vector3(0.18, 0.18, 0.45), dark)


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.name = node_name
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


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


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.82
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

