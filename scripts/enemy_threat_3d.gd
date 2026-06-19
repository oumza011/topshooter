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
		_model_root.position.y = 0.08 + sin(_walk_time * 2.0) * 0.08 + attack * 0.12
		_model_root.rotation_degrees = Vector3(attack * -10.0, 0.0, step * 6.0 * move_amount)
		_spin_blade(_left_rotor_a)
		_spin_blade(_left_rotor_b)
		_spin_blade(_right_rotor_a)
		_spin_blade(_right_rotor_b)
		if is_instance_valid(_sensor_face):
			_sensor_face.scale = Vector3(1.0 + attack * 0.35 + hit * 0.25, 1.0 + attack * 0.2, 1.0)
	else:
		_model_root.position.y = bob * 0.05
		_model_root.rotation_degrees = Vector3(attack * -8.0, 0.0, step * 4.0 * move_amount)
		if is_instance_valid(_left_claw):
			_left_claw.rotation_degrees = Vector3(-attack * 28.0, 0.0, -18.0 + step * 16.0 * move_amount)
		if is_instance_valid(_right_claw):
			_right_claw.rotation_degrees = Vector3(-attack * 28.0, 0.0, 18.0 - step * 16.0 * move_amount)
		if is_instance_valid(_tail):
			_tail.rotation_degrees = Vector3(0.0, step * 10.0 * move_amount, 0.0)
		if is_instance_valid(_left_eye):
			_left_eye.scale = Vector3.ONE * (1.0 + attack * 0.45 + hit * 0.25)
		if is_instance_valid(_right_eye):
			_right_eye.scale = Vector3.ONE * (1.0 + attack * 0.45 + hit * 0.25)

	if is_instance_valid(_body_material):
		var base_color: Color = Color(0.8, 0.12, 0.1) if threat_type == "alien" else Color(0.8, 0.12, 0.1)
		_body_material.albedo_color = base_color.lerp(Color(1.0, 0.85, 0.3), hit)


func _spin_blade(blade: MeshInstance3D) -> void:
	if is_instance_valid(blade):
		blade.rotation_degrees.y = _spin_time


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

	_cache_animation_parts()


func _cache_animation_parts() -> void:
	_sensor_face = _model_root.get_node_or_null("DroneSensorFace") as MeshInstance3D
	_left_rotor_a = _model_root.get_node_or_null("LeftRotorBladeA") as MeshInstance3D
	_left_rotor_b = _model_root.get_node_or_null("LeftRotorBladeB") as MeshInstance3D
	_right_rotor_a = _model_root.get_node_or_null("RightRotorBladeA") as MeshInstance3D
	_right_rotor_b = _model_root.get_node_or_null("RightRotorBladeB") as MeshInstance3D
	_left_claw = _model_root.get_node_or_null("LeftClawUpper") as MeshInstance3D
	_right_claw = _model_root.get_node_or_null("RightClawUpper") as MeshInstance3D
	_tail = _model_root.get_node_or_null("TailStub") as MeshInstance3D
	_left_eye = _model_root.get_node_or_null("LeftAlienEye") as MeshInstance3D
	_right_eye = _model_root.get_node_or_null("RightAlienEye") as MeshInstance3D


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
