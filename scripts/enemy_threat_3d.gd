extends CharacterBody3D

@export var speed := 3.1
@export var max_hp := 2

var hp := 2
var threat_type := "alien"
var target: Node3D
var fallback_target: Node3D
var _attack_cooldown := 0.0
var _body_material: StandardMaterial3D
var _model_root: Node3D
var _collision: CollisionShape3D
var _sensor_face: MeshInstance3D
var _left_rotor_a: MeshInstance3D
var _left_rotor_b: MeshInstance3D
var _right_rotor_a: MeshInstance3D
var _right_rotor_b: MeshInstance3D
var _left_claw: MeshInstance3D
var _right_claw: MeshInstance3D
var _tail: MeshInstance3D
var _left_eye: MeshInstance3D
var _right_eye: MeshInstance3D
var _walk_time := 0.0
var _spin_time := 0.0
var _attack_pulse := 0.0
var _hit_pulse := 0.0
var _is_dying := false
var _base_positions := {}
var _base_rotations := {}


func _ready() -> void:
	add_to_group("threats")
	hp = max_hp
	_build_visual()


func _physics_process(delta: float) -> void:
	if _is_dying:
		return

	_attack_cooldown = maxf(_attack_cooldown - delta, 0.0)
	_attack_pulse = maxf(_attack_pulse - delta * 5.5, 0.0)
	_hit_pulse = maxf(_hit_pulse - delta * 7.0, 0.0)

	var chase_target := target if is_instance_valid(target) else fallback_target
	if not is_instance_valid(chase_target):
		velocity = Vector3.ZERO
		_animate_threat(delta, 0.0)
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
			_attack_pulse = 1.0
			_attack_cooldown = 0.8

	_animate_threat(delta, velocity.length() / speed)


func hit(damage: int) -> void:
	if _is_dying:
		return

	hp -= damage
	_hit_pulse = 1.0
	if is_instance_valid(_body_material):
		_body_material.albedo_color = Color(1.0, 0.35, 0.25)

	if hp <= 0:
		if get_tree().current_scene.has_method("on_threat_destroyed"):
			get_tree().current_scene.on_threat_destroyed()
		_play_death_animation()


func _animate_threat(delta: float, move_amount: float) -> void:
	if not is_instance_valid(_model_root):
		return

	_walk_time += delta * (7.5 if move_amount > 0.05 else 2.4)
	_spin_time += delta * 860.0

	var step: float = sin(_walk_time)
	var bob: float = abs(sin(_walk_time)) * move_amount
	var attack: float = _attack_pulse
	var hit: float = _hit_pulse

	if threat_type == "drone":
		var hover := sin(_walk_time * 2.0)
		_model_root.position.y = 0.08 + hover * 0.08 + attack * 0.12
		_model_root.rotation_degrees = Vector3(attack * -12.0 - move_amount * 4.0, 0.0, step * 7.0 * move_amount)
		_spin_blade(_left_rotor_a)
		_spin_blade(_left_rotor_b)
		_spin_blade(_right_rotor_a)
		_spin_blade(_right_rotor_b)
		if is_instance_valid(_sensor_face):
			_sensor_face.scale = Vector3(1.0 + attack * 0.35 + hit * 0.25, 1.0 + attack * 0.2, 1.0)
	else:
		_model_root.position.y = bob * 0.05
		_model_root.rotation_degrees = Vector3(attack * -10.0 - move_amount * 2.5, 0.0, step * 5.0 * move_amount)
		if is_instance_valid(_left_claw):
			_pose(_left_claw, Vector3(-attack * 34.0, 0.0, step * 18.0 * move_amount - attack * 8.0))
		if is_instance_valid(_right_claw):
			_pose(_right_claw, Vector3(-attack * 34.0, 0.0, -step * 18.0 * move_amount + attack * 8.0))
		if is_instance_valid(_tail):
			_pose(_tail, Vector3(0.0, step * 12.0 * move_amount, 0.0))
		if is_instance_valid(_left_eye):
			_left_eye.scale = Vector3.ONE * (1.0 + attack * 0.45 + hit * 0.25)
		if is_instance_valid(_right_eye):
			_right_eye.scale = Vector3.ONE * (1.0 + attack * 0.45 + hit * 0.25)

	if is_instance_valid(_body_material):
		var base_color: Color = Color(0.8, 0.12, 0.1) if threat_type == "alien" else Color(0.8, 0.12, 0.1)
		_body_material.albedo_color = base_color.lerp(Color(1.0, 0.85, 0.3), hit)


func _spin_blade(blade: MeshInstance3D) -> void:
	if is_instance_valid(blade):
		_pose(blade, Vector3(0.0, _spin_time, 0.0))


func _play_death_animation() -> void:
	_is_dying = true
	remove_from_group("threats")
	if is_instance_valid(_collision):
		_collision.disabled = true
	velocity = Vector3.ZERO

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(_model_root, "scale", Vector3.ZERO, 0.22).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)
	tween.tween_property(_model_root, "rotation_degrees", Vector3(0.0, 540.0, 0.0), 0.22)
	tween.tween_property(_model_root, "position:y", 0.45, 0.22)
	tween.set_parallel(false)
	tween.tween_callback(queue_free)


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
	_collision = collision

	_model_root = Node3D.new()
	_model_root.name = "ThreatModel"
	add_child(_model_root)

	if _load_model_scene("res://art/models/drone_threat.glb" if threat_type == "drone" else "res://art/models/alien_threat.glb"):
		if threat_type == "drone":
			speed = 3.8
			max_hp = 2
		else:
			speed = 2.8
			max_hp = 3
			hp = max_hp
		_cache_animation_parts()
		return

	if threat_type == "drone":
		speed = 3.8
		max_hp = 2
		_add_sphere("DroneCore", Vector3(0.0, 0.92, 0.0), 0.33, steel)
		_add_ellipsoid("DroneRedArmorTop", Vector3(0.0, 1.08, -0.03), Vector3(0.58, 0.18, 0.42), _body_material)
		_add_box("DroneSensorFace", Vector3(0.0, 0.94, -0.34), Vector3(0.32, 0.12, 0.035), warning)
		_add_capsule("DroneWingL", Vector3(-0.56, 0.94, 0.0), 0.08, 0.58, dark, Vector3(0.0, 0.0, 90.0))
		_add_capsule("DroneWingR", Vector3(0.56, 0.94, 0.0), 0.08, 0.58, dark, Vector3(0.0, 0.0, 90.0))
		_add_cylinder("LeftRotor", Vector3(-0.88, 0.98, 0.0), 0.24, 0.035, warning)
		_add_cylinder("RightRotor", Vector3(0.88, 0.98, 0.0), 0.24, 0.035, warning)
		_add_box("LeftRotorBladeA", Vector3(-0.88, 1.0, 0.0), Vector3(0.48, 0.025, 0.055), dark)
		_add_box("LeftRotorBladeB", Vector3(-0.88, 1.0, 0.0), Vector3(0.055, 0.025, 0.48), dark)
		_add_box("RightRotorBladeA", Vector3(0.88, 1.0, 0.0), Vector3(0.48, 0.025, 0.055), dark)
		_add_box("RightRotorBladeB", Vector3(0.88, 1.0, 0.0), Vector3(0.055, 0.025, 0.48), dark)
		_add_capsule("DroneStinger", Vector3(0.0, 0.75, -0.46), 0.055, 0.36, dark, Vector3(90.0, 0.0, 0.0))
	else:
		speed = 2.8
		max_hp = 3
		hp = max_hp
		_add_sphere("AlienCranium", Vector3(0.0, 0.93, -0.08), 0.34, _body_material)
		_add_box("AlienMaw", Vector3(0.0, 0.82, -0.38), Vector3(0.38, 0.16, 0.18), dark)
		_add_sphere("LeftAlienEye", Vector3(-0.11, 0.98, -0.36), 0.045, acid)
		_add_sphere("RightAlienEye", Vector3(0.11, 0.98, -0.36), 0.045, acid)
		_add_ellipsoid("AlienRibBody", Vector3(0.0, 0.45, 0.02), Vector3(0.7, 0.55, 0.54), _body_material)
		_add_box("AlienBellyGlow", Vector3(0.0, 0.46, -0.26), Vector3(0.32, 0.28, 0.035), acid)
		_add_capsule("SpinePlateA", Vector3(0.0, 0.68, 0.32), 0.055, 0.24, dark, Vector3(90.0, 0.0, 90.0))
		_add_capsule("SpinePlateB", Vector3(0.0, 0.48, 0.34), 0.06, 0.28, dark, Vector3(90.0, 0.0, 90.0))
		_add_capsule("SpinePlateC", Vector3(0.0, 0.28, 0.31), 0.05, 0.2, dark, Vector3(90.0, 0.0, 90.0))
		_add_capsule("LeftClawUpper", Vector3(-0.42, 0.52, -0.18), 0.075, 0.46, dark, Vector3(72.0, 0.0, -18.0))
		_add_capsule("RightClawUpper", Vector3(0.42, 0.52, -0.18), 0.075, 0.46, dark, Vector3(72.0, 0.0, 18.0))
		_add_capsule("LeftClawTip", Vector3(-0.5, 0.44, -0.45), 0.055, 0.26, acid, Vector3(70.0, 0.0, -18.0))
		_add_capsule("RightClawTip", Vector3(0.5, 0.44, -0.45), 0.055, 0.26, acid, Vector3(70.0, 0.0, 18.0))
		_add_capsule("LeftHindLeg", Vector3(-0.28, 0.13, 0.18), 0.07, 0.4, dark, Vector3(18.0, 0.0, -12.0))
		_add_capsule("RightHindLeg", Vector3(0.28, 0.13, 0.18), 0.07, 0.4, dark, Vector3(18.0, 0.0, 12.0))
		_add_capsule("TailStub", Vector3(0.0, 0.3, 0.48), 0.08, 0.52, dark, Vector3(90.0, 0.0, 0.0))
	_cache_animation_parts()


func _cache_animation_parts() -> void:
	_sensor_face = _find_mesh("DroneSensorFace")
	_left_rotor_a = _find_mesh("LeftRotorBladeA")
	_left_rotor_b = _find_mesh("LeftRotorBladeB")
	_right_rotor_a = _find_mesh("RightRotorBladeA")
	_right_rotor_b = _find_mesh("RightRotorBladeB")
	_left_claw = _find_mesh("LeftClawUpper")
	_right_claw = _find_mesh("RightClawUpper")
	_tail = _find_mesh("TailStub")
	_left_eye = _find_mesh("LeftAlienEye")
	_right_eye = _find_mesh("RightAlienEye")
	for part in [_sensor_face, _left_rotor_a, _left_rotor_b, _right_rotor_a, _right_rotor_b, _left_claw, _right_claw, _tail, _left_eye, _right_eye]:
		_remember_base(part)


func _remember_base(mesh: MeshInstance3D) -> void:
	if not is_instance_valid(mesh):
		return
	_base_positions[mesh.name] = mesh.position
	_base_rotations[mesh.name] = mesh.rotation_degrees


func _pose(mesh: MeshInstance3D, rotation_offset: Vector3, position_offset: Vector3 = Vector3.ZERO) -> void:
	if not is_instance_valid(mesh):
		return
	var base_position: Vector3 = _base_positions.get(mesh.name, mesh.position)
	var base_rotation: Vector3 = _base_rotations.get(mesh.name, mesh.rotation_degrees)
	mesh.position = base_position + position_offset
	mesh.rotation_degrees = base_rotation + rotation_offset


func _load_model_scene(path: String) -> bool:
	var packed := load(path)
	if not packed is PackedScene:
		return false

	var instance := (packed as PackedScene).instantiate()
	instance.name = "ThreatArtModel"
	_model_root.add_child(instance)
	return true


func _find_mesh(node_name: String) -> MeshInstance3D:
	if not is_instance_valid(_model_root):
		return null
	return _model_root.find_child(node_name, true, false) as MeshInstance3D


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


func _add_sphere(node_name: String, position: Vector3, radius: float, material: Material) -> void:
	var mesh := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	mesh.mesh = sphere
	mesh.name = node_name
	mesh.position = position
	mesh.material_override = material
	_model_root.add_child(mesh)


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
	cylinder.radial_segments = 18
	mesh.mesh = cylinder
	mesh.name = node_name
	mesh.position = position
	mesh.rotation_degrees = rotation
	mesh.material_override = material
	_model_root.add_child(mesh)
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
