extends CharacterBody3D

const DemoBullet := preload("res://scripts/demo_bullet_3d.gd")

@export var speed := 6.4
@export var fire_rate := 0.18
@export var max_hp := 8

var hp := 8
var _fire_cooldown := 0.0
var _body_material: StandardMaterial3D
var _core_material: StandardMaterial3D


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	_build_robot()


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)

	var input := _movement_input()
	velocity = input * speed
	move_and_slide()

	var aim_point := _mouse_point_on_deck()
	var flat_point := Vector3(aim_point.x, global_position.y, aim_point.z)
	if flat_point.distance_to(global_position) > 0.1:
		look_at(flat_point, Vector3.UP)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT) and _fire_cooldown <= 0.0:
		_fire(aim_point)
		_fire_cooldown = fire_rate


func _movement_input() -> Vector3:
	var x := 0.0
	var z := 0.0
	if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
		x -= 1.0
	if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
		x += 1.0
	if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
		z -= 1.0
	if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
		z += 1.0

	var direction := Vector3(x, 0.0, z)
	return direction.normalized() if direction.length() > 1.0 else direction


func _mouse_point_on_deck() -> Vector3:
	var camera := get_viewport().get_camera_3d()
	if camera == null:
		return global_position + -global_transform.basis.z * 6.0

	var mouse := get_viewport().get_mouse_position()
	var origin := camera.project_ray_origin(mouse)
	var direction := camera.project_ray_normal(mouse)
	var hit: Variant = Plane(Vector3.UP, 0.0).intersects_ray(origin, direction)
	if hit is Vector3:
		return hit
	return global_position + -global_transform.basis.z * 6.0


func _fire(aim_point: Vector3) -> void:
	var direction := Vector3(aim_point.x - global_position.x, 0.0, aim_point.z - global_position.z).normalized()
	if direction.length() <= 0.01:
		return

	var bullet := DemoBullet.new()
	bullet.direction = direction
	bullet.position = global_position + direction * 0.95 + Vector3(0.0, 0.82, 0.0)
	get_tree().current_scene.add_child(bullet)


func hit(damage: int) -> void:
	hp = max(hp - damage, 0)
	if get_tree().current_scene.has_method("on_actor_hit"):
		get_tree().current_scene.on_actor_hit()

	if hp <= 0 and get_tree().current_scene.has_method("fail_demo"):
		get_tree().current_scene.fail_demo("The robot core shut down.")


func _build_robot() -> void:
	_body_material = _mat(Color(0.42, 0.52, 0.58))
	_core_material = _mat(Color(0.1, 0.75, 1.0), Color(0.0, 0.75, 1.0), 2.0)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.55
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.78, 0.0)
	add_child(collision)

	_add_box("Torso", Vector3(0.0, 0.98, 0.0), Vector3(0.75, 0.9, 0.45), _body_material)
	_add_box("Head", Vector3(0.0, 1.65, 0.0), Vector3(0.62, 0.38, 0.48), _body_material)
	_add_box("Visor", Vector3(0.0, 1.67, -0.26), Vector3(0.44, 0.12, 0.04), _core_material)
	_add_box("Core", Vector3(0.0, 1.02, -0.25), Vector3(0.28, 0.24, 0.05), _core_material)
	_add_box("Backpack", Vector3(0.0, 1.02, 0.34), Vector3(0.5, 0.75, 0.18), _body_material)
	_add_box("LeftArm", Vector3(-0.55, 0.92, -0.02), Vector3(0.18, 0.78, 0.22), _body_material)
	_add_box("RightArm", Vector3(0.55, 0.92, -0.02), Vector3(0.18, 0.78, 0.22), _body_material)
	_add_box("LeftLeg", Vector3(-0.24, 0.3, 0.02), Vector3(0.22, 0.6, 0.24), _body_material)
	_add_box("RightLeg", Vector3(0.24, 0.3, 0.02), Vector3(0.22, 0.6, 0.24), _body_material)


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
	material.roughness = 0.72
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
