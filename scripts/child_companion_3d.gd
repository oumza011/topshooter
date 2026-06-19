extends CharacterBody3D

@export var follow_distance := 1.7
@export var speed := 4.2
@export var max_hp := 5

var hp := 5
var target: Node3D
var _hurt_flash := 0.0
var _jacket_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("companion")
	hp = max_hp
	_build_child()


func _physics_process(delta: float) -> void:
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if is_instance_valid(_jacket_material):
		_jacket_material.albedo_color = Color(1.0, 0.65, 0.55) if _hurt_flash > 0.0 else Color(0.86, 0.72, 0.45)

	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		return

	var to_target := target.global_position - global_position
	to_target.y = 0.0
	var distance := to_target.length()

	if distance > follow_distance:
		velocity = to_target.normalized() * speed
		move_and_slide()
		look_at(Vector3(target.global_position.x, global_position.y, target.global_position.z), Vector3.UP)
	else:
		velocity = Vector3.ZERO


func hit(damage: int) -> void:
	hp = max(hp - damage, 0)
	_hurt_flash = 0.16

	if get_tree().current_scene.has_method("on_actor_hit"):
		get_tree().current_scene.on_actor_hit()

	if hp <= 0 and get_tree().current_scene.has_method("fail_demo"):
		get_tree().current_scene.fail_demo("Mila could not keep going.")


func _build_child() -> void:
	_jacket_material = _mat(Color(0.86, 0.72, 0.45))
	var hair_mat := _mat(Color(0.08, 0.07, 0.06))
	var skin_mat := _mat(Color(0.86, 0.63, 0.48))
	var boot_mat := _mat(Color(0.11, 0.09, 0.08))
	var pack_mat := _mat(Color(0.18, 0.24, 0.26))

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.15
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.58, 0.0)
	add_child(collision)

	_add_box("Jacket", Vector3(0.0, 0.72, 0.0), Vector3(0.48, 0.58, 0.34), _jacket_material)
	_add_box("Head", Vector3(0.0, 1.17, -0.02), Vector3(0.36, 0.34, 0.32), skin_mat)
	_add_box("Hair", Vector3(0.0, 1.34, 0.0), Vector3(0.42, 0.18, 0.36), hair_mat)
	_add_box("Backpack", Vector3(0.0, 0.72, 0.24), Vector3(0.38, 0.48, 0.16), pack_mat)
	_add_box("LeftBoot", Vector3(-0.14, 0.14, 0.0), Vector3(0.14, 0.28, 0.18), boot_mat)
	_add_box("RightBoot", Vector3(0.14, 0.14, 0.0), Vector3(0.14, 0.28, 0.18), boot_mat)
	_add_box("Flashlight", Vector3(0.33, 0.76, -0.14), Vector3(0.1, 0.1, 0.32), _mat(Color(0.2, 0.22, 0.25), Color(1.0, 0.85, 0.4), 1.2))


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.name = node_name
	mesh.position = position
	mesh.material_override = material
	add_child(mesh)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.9
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material

