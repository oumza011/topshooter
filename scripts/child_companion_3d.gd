extends CharacterBody3D

@export var follow_distance := 1.7
@export var speed := 4.2
@export var max_hp := 5

var hp := 5
var target: Node3D
var _hurt_flash := 0.0
var _jacket_material: StandardMaterial3D
var _model_root: Node3D
var _head: MeshInstance3D
var _left_sleeve: MeshInstance3D
var _right_sleeve: MeshInstance3D
var _left_boot: MeshInstance3D
var _right_boot: MeshInstance3D
var _backpack: MeshInstance3D
var _flashlight: MeshInstance3D
var _flashlight_beam: SpotLight3D
var _walk_time := 0.0
var _idle_time := 0.0
var _collapse_time := 0.0
var _celebrating := false


func _ready() -> void:
	add_to_group("companion")
	hp = max_hp
	_build_child()


func _physics_process(delta: float) -> void:
	_hurt_flash = maxf(_hurt_flash - delta, 0.0)
	if is_instance_valid(_jacket_material):
		_jacket_material.albedo_color = Color(1.0, 0.65, 0.55) if _hurt_flash > 0.0 else Color(0.86, 0.72, 0.45)

	if hp <= 0:
		velocity = Vector3.ZERO
		_collapse_time += delta
		_animate_child(delta, 0.0, 0.0)
		return

	if not is_instance_valid(target):
		velocity = Vector3.ZERO
		_animate_child(delta, 0.0, 0.0)
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

	_animate_child(delta, velocity.length() / speed, distance)


func hit(damage: int) -> void:
	hp = max(hp - damage, 0)
	_hurt_flash = 0.16

	if get_tree().current_scene.has_method("on_actor_hit"):
		get_tree().current_scene.on_actor_hit()

	if hp <= 0 and get_tree().current_scene.has_method("fail_demo"):
		_collapse_time = 0.01
		get_tree().current_scene.fail_demo("Mila could not keep going.")


func celebrate() -> void:
	_celebrating = true


func _animate_child(delta: float, move_amount: float, distance_to_robot: float) -> void:
	if not is_instance_valid(_model_root):
		return

	_idle_time += delta
	_walk_time += delta * (9.5 if move_amount > 0.05 else 2.0)

	var step: float = sin(_walk_time)
	var counter_step: float = sin(_walk_time + PI)
	var bob: float = abs(sin(_walk_time)) * move_amount
	var fear: float = clampf((distance_to_robot - follow_distance) / 4.0, 0.0, 1.0)
	var hurt: float = _hurt_flash / 0.16

	_model_root.position = Vector3(0.0, sin(_idle_time * 2.2) * 0.018 + bob * 0.045, 0.0)
	_model_root.rotation_degrees = Vector3(hurt * 7.0, 0.0, step * 2.4 * move_amount + hurt * 8.0)

	if is_instance_valid(_head):
		_head.rotation_degrees = Vector3(-fear * 6.0 + sin(_idle_time * 2.6) * 1.2, sin(_idle_time * 1.4) * 3.5, -step * move_amount * 2.0)
	if is_instance_valid(_left_sleeve):
		_left_sleeve.rotation_degrees = Vector3(counter_step * 15.0 * move_amount, 0.0, 6.0 - fear * 8.0)
	if is_instance_valid(_right_sleeve):
		_right_sleeve.rotation_degrees = Vector3(step * 15.0 * move_amount, 0.0, -6.0 + fear * 8.0)
	if is_instance_valid(_left_boot):
		_left_boot.position.y = 0.08 + maxf(step, 0.0) * 0.035 * move_amount
		_left_boot.rotation_degrees.x = -step * 7.0 * move_amount
	if is_instance_valid(_right_boot):
		_right_boot.position.y = 0.08 + maxf(counter_step, 0.0) * 0.035 * move_amount
		_right_boot.rotation_degrees.x = -counter_step * 7.0 * move_amount
	if is_instance_valid(_backpack):
		_backpack.rotation_degrees = Vector3(step * 4.0 * move_amount, 0.0, -step * 3.0 * move_amount)
	if is_instance_valid(_flashlight):
		_flashlight.rotation_degrees = Vector3(step * 10.0 * move_amount + fear * 8.0, 0.0, -step * 4.0 * move_amount)
	if is_instance_valid(_flashlight_beam):
		_flashlight_beam.light_energy = 0.75 + abs(step) * 0.25 * move_amount + fear * 0.25

	if _celebrating and hp > 0:
		var hop: float = abs(sin(_idle_time * 8.0))
		_model_root.position.y += hop * 0.06
		_model_root.rotation_degrees.z = sin(_idle_time * 5.0) * 4.0
		if is_instance_valid(_left_sleeve):
			_left_sleeve.rotation_degrees = Vector3(-62.0 + hop * 12.0, 0.0, -18.0)
		if is_instance_valid(_right_sleeve):
			_right_sleeve.rotation_degrees = Vector3(-58.0 + hop * 12.0, 0.0, 18.0)
		if is_instance_valid(_head):
			_head.rotation_degrees.x = -8.0 + hop * 5.0

	if hp <= 0:
		var fall: float = minf(_collapse_time / 0.35, 1.0)
		_model_root.rotation_degrees = Vector3(0.0, 0.0, lerpf(0.0, -82.0, fall))
		_model_root.position.y = lerpf(_model_root.position.y, 0.04, fall)
		if is_instance_valid(_flashlight_beam):
			_flashlight_beam.light_energy = lerpf(_flashlight_beam.light_energy, 0.0, fall)


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

	_model_root = Node3D.new()
	_model_root.name = "ChildModel"
	add_child(_model_root)

	_add_ellipsoid("OversizedJacketBody", Vector3(0.0, 0.72, 0.0), Vector3(0.58, 0.7, 0.42), _jacket_material)
	_add_capsule("JacketLowerHem", Vector3(0.0, 0.43, -0.01), 0.08, 0.64, hoodie_shadow, Vector3(0.0, 0.0, 90.0))
	_add_ellipsoid("HoodBack", Vector3(0.0, 1.04, 0.16), Vector3(0.5, 0.32, 0.22), hoodie_shadow)
	_add_capsule("LeftSleeve", Vector3(-0.37, 0.74, -0.02), 0.1, 0.5, _jacket_material, Vector3(0.0, 0.0, 6.0))
	_add_capsule("RightSleeve", Vector3(0.37, 0.74, -0.02), 0.1, 0.5, _jacket_material, Vector3(0.0, 0.0, -6.0))
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

	_add_ellipsoid("HairCap", Vector3(0.0, 1.34, -0.02), Vector3(0.46, 0.2, 0.38), hair_mat)
	_add_capsule("MessyBangA", Vector3(-0.12, 1.27, -0.205), 0.045, 0.22, hair_mat, Vector3(0.0, 0.0, -12.0))
	_add_capsule("MessyBangB", Vector3(0.03, 1.27, -0.22), 0.048, 0.24, hair_mat, Vector3(0.0, 0.0, 9.0))
	_add_capsule("MessyBangC", Vector3(0.17, 1.25, -0.195), 0.04, 0.18, hair_mat, Vector3(0.0, 0.0, 18.0))
	_add_capsule("LeftSideHair", Vector3(-0.24, 1.18, 0.0), 0.055, 0.28, hair_mat)
	_add_capsule("RightSideHair", Vector3(0.24, 1.18, 0.0), 0.055, 0.26, hair_mat)

	_add_capsule("LeftShortsLeg", Vector3(-0.13, 0.33, -0.01), 0.095, 0.26, pants_mat)
	_add_capsule("RightShortsLeg", Vector3(0.13, 0.33, -0.01), 0.095, 0.26, pants_mat)
	_add_capsule("LeftSock", Vector3(-0.13, 0.19, -0.01), 0.06, 0.18, skin_mat)
	_add_capsule("RightSock", Vector3(0.13, 0.19, -0.01), 0.06, 0.18, skin_mat)
	_add_capsule("LeftBoot", Vector3(-0.14, 0.08, -0.025), 0.085, 0.22, boot_mat)
	_add_capsule("RightBoot", Vector3(0.14, 0.08, -0.025), 0.085, 0.22, boot_mat)
	_add_capsule("LeftBootToe", Vector3(-0.14, 0.08, -0.16), 0.06, 0.2, boot_mat, Vector3(90.0, 0.0, 0.0))
	_add_capsule("RightBootToe", Vector3(0.14, 0.08, -0.16), 0.06, 0.2, boot_mat, Vector3(90.0, 0.0, 0.0))

	_add_ellipsoid("Backpack", Vector3(0.0, 0.73, 0.27), Vector3(0.44, 0.52, 0.22), pack_mat)
	_add_capsule("BackpackTopRoll", Vector3(0.0, 1.01, 0.28), 0.065, 0.45, hoodie_shadow, Vector3(0.0, 0.0, 90.0))
	_add_box("LeftBackpackStrap", Vector3(-0.18, 0.76, -0.215), Vector3(0.07, 0.52, 0.025), strap_mat)
	_add_box("RightBackpackStrap", Vector3(0.18, 0.76, -0.215), Vector3(0.07, 0.52, 0.025), strap_mat)
	_add_box("KeepSafeTag", Vector3(-0.28, 0.54, -0.21), Vector3(0.055, 0.095, 0.02), patch_red)
	_add_box("FlashlightBody", Vector3(0.45, 0.75, -0.14), Vector3(0.11, 0.11, 0.34), strap_mat)
	_add_cylinder("FlashlightLens", Vector3(0.45, 0.75, -0.34), 0.065, 0.045, light_mat, Vector3(90.0, 0.0, 0.0))
	_add_flashlight_beam(Vector3(0.45, 0.75, -0.44))
	_cache_animation_parts()


func _cache_animation_parts() -> void:
	_head = _model_root.get_node_or_null("Head") as MeshInstance3D
	_left_sleeve = _model_root.get_node_or_null("LeftSleeve") as MeshInstance3D
	_right_sleeve = _model_root.get_node_or_null("RightSleeve") as MeshInstance3D
	_left_boot = _model_root.get_node_or_null("LeftBoot") as MeshInstance3D
	_right_boot = _model_root.get_node_or_null("RightBoot") as MeshInstance3D
	_backpack = _model_root.get_node_or_null("Backpack") as MeshInstance3D
	_flashlight = _model_root.get_node_or_null("FlashlightBody") as MeshInstance3D
	_flashlight_beam = _model_root.get_node_or_null("FlashlightBeam") as SpotLight3D


func _add_box(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	_model_root.add_child(mesh)
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
	_model_root.add_child(mesh)
	return mesh


func _add_ellipsoid(node_name: String, position: Vector3, size: Vector3, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.5
	sphere.height = 1.0
	sphere.radial_segments = 24
	sphere.rings = 12
	mesh.mesh = sphere
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.scale = size
	mesh.material_override = material
	_model_root.add_child(mesh)
	return mesh


func _add_capsule(node_name: String, position: Vector3, radius: float, height: float, material: Material, rotation: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mesh := MeshInstance3D.new()
	var capsule := CapsuleMesh.new()
	capsule.radius = radius
	capsule.height = height
	capsule.radial_segments = 18
	capsule.rings = 8
	mesh.mesh = capsule
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	_model_root.add_child(mesh)
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
	_model_root.add_child(mesh)
	return mesh


func _add_flashlight_beam(position: Vector3) -> void:
	var light := SpotLight3D.new()
	light.name = "FlashlightBeam"
	light.position = position
	light.light_color = Color(1.0, 0.82, 0.42)
	light.light_energy = 0.9
	light.spot_range = 5.5
	light.spot_angle = 26.0
	_model_root.add_child(light)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.9
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
