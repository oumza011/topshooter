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
	var shell := _mat(Color(0.62, 0.68, 0.7))
	var armor := _mat(Color(0.28, 0.36, 0.4))
	var dark := _mat(Color(0.035, 0.045, 0.055))
	var rubber := _mat(Color(0.07, 0.08, 0.085))
	var trim := _mat(Color(0.78, 0.84, 0.82))
	var amber := _mat(Color(0.95, 0.47, 0.12), Color(1.0, 0.38, 0.05), 1.7)
	var teal := _mat(Color(0.1, 0.75, 1.0), Color(0.0, 0.75, 1.0), 2.6)
	var soft_white := _mat(Color(0.82, 0.9, 0.9), Color(0.5, 0.9, 1.0), 0.65)
	_body_material = shell
	_core_material = teal

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.42
	capsule.height = 1.55
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.78, 0.0)
	add_child(collision)

	_add_box("PelvisFrame", Vector3(0.0, 0.62, 0.02), Vector3(0.82, 0.28, 0.48), armor)
	_add_box("LowerTorsoArmor", Vector3(0.0, 0.86, 0.0), Vector3(0.74, 0.46, 0.5), shell)
	_add_box("UpperChestArmor", Vector3(0.0, 1.16, -0.02), Vector3(0.92, 0.52, 0.48), shell)
	_add_box("ChestDarkInset", Vector3(0.0, 1.15, -0.275), Vector3(0.55, 0.34, 0.04), dark)
	_add_cylinder("HeartCoreGlass", Vector3(0.0, 1.16, -0.31), 0.18, 0.08, teal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder("CoreOuterRing", Vector3(0.0, 1.16, -0.322), 0.25, 0.035, trim, Vector3(90.0, 0.0, 0.0))
	_add_box("CoreGuardTop", Vector3(0.0, 1.37, -0.33), Vector3(0.45, 0.05, 0.06), armor)
	_add_box("CoreGuardBottom", Vector3(0.0, 0.95, -0.33), Vector3(0.45, 0.05, 0.06), armor)
	_add_box("LeftChestPanel", Vector3(-0.32, 1.16, -0.29), Vector3(0.12, 0.24, 0.045), armor)
	_add_box("RightChestPanel", Vector3(0.32, 1.16, -0.29), Vector3(0.12, 0.24, 0.045), armor)

	_add_box("NeckJoint", Vector3(0.0, 1.47, 0.0), Vector3(0.28, 0.16, 0.26), rubber)
	_add_box("HeadShell", Vector3(0.0, 1.7, 0.0), Vector3(0.74, 0.44, 0.56), shell)
	_add_box("HelmetBrow", Vector3(0.0, 1.84, -0.08), Vector3(0.82, 0.12, 0.5), trim)
	_add_box("FacePlate", Vector3(0.0, 1.69, -0.31), Vector3(0.6, 0.22, 0.04), dark)
	_add_box("VisorGlow", Vector3(0.0, 1.7, -0.34), Vector3(0.46, 0.105, 0.035), teal)
	_add_box("LeftVisorPixel", Vector3(-0.16, 1.7, -0.365), Vector3(0.065, 0.045, 0.025), soft_white)
	_add_box("RightVisorPixel", Vector3(0.16, 1.7, -0.365), Vector3(0.065, 0.045, 0.025), soft_white)
	_add_cylinder("LeftAudioSensor", Vector3(-0.44, 1.7, -0.01), 0.12, 0.08, armor, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("RightAudioSensor", Vector3(0.44, 1.7, -0.01), 0.12, 0.08, armor, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("AntennaStem", Vector3(0.24, 2.02, 0.05), 0.025, 0.32, dark)
	_add_sphere("AntennaTip", Vector3(0.24, 2.2, 0.05), 0.055, amber)

	_add_box("LeftShoulderBlock", Vector3(-0.65, 1.22, 0.0), Vector3(0.32, 0.28, 0.42), armor)
	_add_box("RightShoulderBlock", Vector3(0.65, 1.22, 0.0), Vector3(0.32, 0.28, 0.42), armor)
	_add_sphere("LeftShoulderLamp", Vector3(-0.65, 1.36, -0.23), 0.065, amber)
	_add_sphere("RightShoulderLamp", Vector3(0.65, 1.36, -0.23), 0.065, amber)
	_add_cylinder("LeftUpperArmJoint", Vector3(-0.77, 1.0, 0.0), 0.105, 0.28, rubber)
	_add_cylinder("RightUpperArmJoint", Vector3(0.77, 1.0, 0.0), 0.105, 0.28, rubber)
	_add_box("LeftForearmArmor", Vector3(-0.82, 0.77, -0.03), Vector3(0.22, 0.46, 0.28), shell)
	_add_box("RightForearmArmor", Vector3(0.82, 0.77, -0.03), Vector3(0.22, 0.46, 0.28), shell)
	_add_box("LeftWristClamp", Vector3(-0.82, 0.5, -0.04), Vector3(0.24, 0.12, 0.3), armor)
	_add_box("RightWristClamp", Vector3(0.82, 0.5, -0.04), Vector3(0.24, 0.12, 0.3), armor)
	_add_box("LeftHandPincerA", Vector3(-0.9, 0.39, -0.12), Vector3(0.08, 0.16, 0.2), rubber, Vector3(0.0, 0.0, -12.0))
	_add_box("LeftHandPincerB", Vector3(-0.74, 0.39, -0.12), Vector3(0.08, 0.16, 0.2), rubber, Vector3(0.0, 0.0, 12.0))
	_add_cylinder("RightBlasterBarrel", Vector3(0.82, 0.47, -0.32), 0.075, 0.48, dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder("RightBlasterMuzzleGlow", Vector3(0.82, 0.47, -0.58), 0.085, 0.035, teal, Vector3(90.0, 0.0, 0.0))

	_add_box("BackpackMain", Vector3(0.0, 1.12, 0.36), Vector3(0.6, 0.78, 0.22), armor)
	_add_box("BackpackBatteryLeft", Vector3(-0.22, 1.13, 0.5), Vector3(0.16, 0.62, 0.12), dark)
	_add_box("BackpackBatteryRight", Vector3(0.22, 1.13, 0.5), Vector3(0.16, 0.62, 0.12), dark)
	_add_cylinder("BackpackCoolantPipeTop", Vector3(0.0, 1.47, 0.53), 0.035, 0.5, teal, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("BackpackCoolantPipeBottom", Vector3(0.0, 0.8, 0.53), 0.03, 0.5, teal, Vector3(0.0, 0.0, 90.0))

	_add_cylinder("LeftHipJoint", Vector3(-0.28, 0.52, 0.0), 0.12, 0.22, rubber, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("RightHipJoint", Vector3(0.28, 0.52, 0.0), 0.12, 0.22, rubber, Vector3(0.0, 0.0, 90.0))
	_add_box("LeftThighPlate", Vector3(-0.28, 0.31, 0.02), Vector3(0.24, 0.42, 0.28), shell)
	_add_box("RightThighPlate", Vector3(0.28, 0.31, 0.02), Vector3(0.24, 0.42, 0.28), shell)
	_add_box("LeftKneePad", Vector3(-0.28, 0.22, -0.18), Vector3(0.26, 0.16, 0.08), armor)
	_add_box("RightKneePad", Vector3(0.28, 0.22, -0.18), Vector3(0.26, 0.16, 0.08), armor)
	_add_box("LeftFoot", Vector3(-0.28, 0.06, -0.09), Vector3(0.34, 0.14, 0.52), rubber)
	_add_box("RightFoot", Vector3(0.28, 0.06, -0.09), Vector3(0.34, 0.14, 0.52), rubber)
	_add_box("LeftToeLight", Vector3(-0.28, 0.11, -0.37), Vector3(0.18, 0.04, 0.035), amber)
	_add_box("RightToeLight", Vector3(0.28, 0.11, -0.37), Vector3(0.18, 0.04, 0.035), amber)

	_add_point_light("RobotCoreLight", Vector3(0.0, 1.25, -0.45), Color(0.15, 0.85, 1.0), 1.6, 2.8)
	_add_point_light("RobotShoulderLightLeft", Vector3(-0.68, 1.42, -0.38), Color(1.0, 0.45, 0.1), 0.55, 1.8)
	_add_point_light("RobotShoulderLightRight", Vector3(0.68, 1.42, -0.38), Color(1.0, 0.45, 0.1), 0.55, 1.8)


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


func _add_sphere(node_name: String, position: Vector3, radius: float, material: Material) -> MeshInstance3D:
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


func _add_point_light(node_name: String, position: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	add_child(light)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.72
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
