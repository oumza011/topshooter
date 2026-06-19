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
	var hoodie_shadow := _mat(Color(0.48, 0.39, 0.25))
	var hair_mat := _mat(Color(0.065, 0.052, 0.045))
	var skin_mat := _mat(Color(0.86, 0.63, 0.48))
	var blush_mat := _mat(Color(0.95, 0.48, 0.42))
	var pants_mat := _mat(Color(0.23, 0.34, 0.42))
	var boot_mat := _mat(Color(0.11, 0.09, 0.08))
	var pack_mat := _mat(Color(0.18, 0.24, 0.26))
	var strap_mat := _mat(Color(0.08, 0.1, 0.11))
	var patch_red := _mat(Color(0.9, 0.18, 0.15))
	var patch_blue := _mat(Color(0.1, 0.45, 0.85))
	var light_mat := _mat(Color(1.0, 0.88, 0.52), Color(1.0, 0.8, 0.35), 1.8)

	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.28
	capsule.height = 1.15
	collision.shape = capsule
	collision.position = Vector3(0.0, 0.58, 0.0)
	add_child(collision)

	_add_box("OversizedJacketBody", Vector3(0.0, 0.72, 0.0), Vector3(0.56, 0.62, 0.38), _jacket_material)
	_add_box("JacketLowerHem", Vector3(0.0, 0.43, -0.01), Vector3(0.62, 0.12, 0.42), hoodie_shadow)
	_add_box("HoodBack", Vector3(0.0, 1.04, 0.16), Vector3(0.48, 0.28, 0.18), hoodie_shadow)
	_add_box("LeftSleeve", Vector3(-0.37, 0.74, -0.02), Vector3(0.18, 0.48, 0.22), _jacket_material, Vector3(0.0, 0.0, 6.0))
	_add_box("RightSleeve", Vector3(0.37, 0.74, -0.02), Vector3(0.18, 0.48, 0.22), _jacket_material, Vector3(0.0, 0.0, -6.0))
	_add_sphere("LeftHand", Vector3(-0.43, 0.48, -0.08), 0.075, skin_mat)
	_add_sphere("RightHand", Vector3(0.43, 0.48, -0.08), 0.075, skin_mat)
	_add_box("ZipperStrip", Vector3(0.0, 0.74, -0.205), Vector3(0.035, 0.5, 0.025), strap_mat)
	_add_box("SmallNamePatch", Vector3(-0.18, 0.9, -0.22), Vector3(0.14, 0.075, 0.025), patch_blue)
	_add_box("EmergencyPatch", Vector3(0.18, 0.64, -0.22), Vector3(0.11, 0.09, 0.025), patch_red)

	_add_sphere("Head", Vector3(0.0, 1.18, -0.02), 0.22, skin_mat)
	_add_sphere("LeftCheek", Vector3(-0.115, 1.14, -0.19), 0.04, blush_mat)
	_add_sphere("RightCheek", Vector3(0.115, 1.14, -0.19), 0.04, blush_mat)
	_add_box("LeftEye", Vector3(-0.065, 1.2, -0.23), Vector3(0.035, 0.035, 0.02), strap_mat)
	_add_box("RightEye", Vector3(0.065, 1.2, -0.23), Vector3(0.035, 0.035, 0.02), strap_mat)
	_add_box("TinyMouth", Vector3(0.0, 1.095, -0.235), Vector3(0.085, 0.018, 0.018), strap_mat)

	_add_box("HairCap", Vector3(0.0, 1.34, -0.02), Vector3(0.43, 0.18, 0.36), hair_mat)
	_add_box("MessyBangA", Vector3(-0.12, 1.27, -0.205), Vector3(0.1, 0.19, 0.05), hair_mat, Vector3(0.0, 0.0, -12.0))
	_add_box("MessyBangB", Vector3(0.03, 1.27, -0.22), Vector3(0.1, 0.21, 0.05), hair_mat, Vector3(0.0, 0.0, 9.0))
	_add_box("MessyBangC", Vector3(0.17, 1.25, -0.195), Vector3(0.08, 0.16, 0.05), hair_mat, Vector3(0.0, 0.0, 18.0))
	_add_box("LeftSideHair", Vector3(-0.24, 1.18, 0.0), Vector3(0.08, 0.26, 0.22), hair_mat)
	_add_box("RightSideHair", Vector3(0.24, 1.18, 0.0), Vector3(0.08, 0.24, 0.22), hair_mat)

	_add_box("LeftShortsLeg", Vector3(-0.13, 0.33, -0.01), Vector3(0.18, 0.24, 0.22), pants_mat)
	_add_box("RightShortsLeg", Vector3(0.13, 0.33, -0.01), Vector3(0.18, 0.24, 0.22), pants_mat)
	_add_box("LeftSock", Vector3(-0.13, 0.19, -0.01), Vector3(0.115, 0.16, 0.13), skin_mat)
	_add_box("RightSock", Vector3(0.13, 0.19, -0.01), Vector3(0.115, 0.16, 0.13), skin_mat)
	_add_box("LeftBoot", Vector3(-0.14, 0.08, -0.025), Vector3(0.17, 0.16, 0.24), boot_mat)
	_add_box("RightBoot", Vector3(0.14, 0.08, -0.025), Vector3(0.17, 0.16, 0.24), boot_mat)
	_add_box("LeftBootToe", Vector3(-0.14, 0.08, -0.16), Vector3(0.19, 0.11, 0.12), boot_mat)
	_add_box("RightBootToe", Vector3(0.14, 0.08, -0.16), Vector3(0.19, 0.11, 0.12), boot_mat)

	_add_box("Backpack", Vector3(0.0, 0.73, 0.27), Vector3(0.42, 0.5, 0.18), pack_mat)
	_add_box("BackpackTopRoll", Vector3(0.0, 1.01, 0.28), Vector3(0.45, 0.1, 0.2), hoodie_shadow)
	_add_box("LeftBackpackStrap", Vector3(-0.18, 0.76, -0.215), Vector3(0.07, 0.52, 0.025), strap_mat)
	_add_box("RightBackpackStrap", Vector3(0.18, 0.76, -0.215), Vector3(0.07, 0.52, 0.025), strap_mat)
	_add_box("KeepSafeTag", Vector3(-0.28, 0.54, -0.21), Vector3(0.055, 0.095, 0.02), patch_red)
	_add_box("FlashlightBody", Vector3(0.45, 0.75, -0.14), Vector3(0.11, 0.11, 0.34), strap_mat)
	_add_cylinder("FlashlightLens", Vector3(0.45, 0.75, -0.34), 0.065, 0.045, light_mat, Vector3(90.0, 0.0, 0.0))
	_add_flashlight_beam(Vector3(0.45, 0.75, -0.44))


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
	cylinder.radial_segments = 16
	mesh.mesh = cylinder
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	add_child(mesh)
	return mesh


func _add_flashlight_beam(position: Vector3) -> void:
	var light := SpotLight3D.new()
	light.name = "FlashlightBeam"
	light.position = position
	light.light_color = Color(1.0, 0.82, 0.42)
	light.light_energy = 0.9
	light.spot_range = 5.5
	light.spot_angle = 26.0
	add_child(light)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.9
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
