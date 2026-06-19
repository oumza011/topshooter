extends CharacterBody3D

const DemoBullet := preload("res://scripts/demo_bullet_3d.gd")

@export var speed := 6.4
@export var fire_rate := 0.18
@export var max_hp := 8

var hp := 8
var _fire_cooldown := 0.0
var _body_material: StandardMaterial3D
var _core_material: StandardMaterial3D
var _base_shell_color := Color(0.62, 0.68, 0.7)
var _model_root: Node3D
var _head_shell: MeshInstance3D
var _upper_chest: MeshInstance3D
var _left_forearm: MeshInstance3D
var _right_forearm: MeshInstance3D
var _right_blaster: MeshInstance3D
var _muzzle_glow: MeshInstance3D
var _left_thigh: MeshInstance3D
var _right_thigh: MeshInstance3D
var _left_foot: MeshInstance3D
var _right_foot: MeshInstance3D
var _antenna_tip: MeshInstance3D
var _visor_glow: MeshInstance3D
var _art_sprite: Sprite3D
var _walk_time := 0.0
var _idle_time := 0.0
var _shoot_pulse := 0.0
var _hit_pulse := 0.0
var _death_time := 0.0
var _celebrating := false


func _ready() -> void:
	add_to_group("player")
	hp = max_hp
	_build_robot()


func _physics_process(delta: float) -> void:
	_fire_cooldown = maxf(_fire_cooldown - delta, 0.0)
	_shoot_pulse = maxf(_shoot_pulse - delta * 7.5, 0.0)
	_hit_pulse = maxf(_hit_pulse - delta * 5.5, 0.0)

	if hp <= 0:
		velocity = Vector3.ZERO
		_death_time += delta
		_animate_robot(delta, 0.0)
		return

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

	_animate_robot(delta, input.length())


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
	_shoot_pulse = 1.0


func hit(damage: int) -> void:
	hp = max(hp - damage, 0)
	_hit_pulse = 1.0
	if get_tree().current_scene.has_method("on_actor_hit"):
		get_tree().current_scene.on_actor_hit()

	if hp <= 0 and get_tree().current_scene.has_method("fail_demo"):
		_death_time = 0.01
		get_tree().current_scene.fail_demo("The robot core shut down.")


func celebrate() -> void:
	_celebrating = true


func _animate_robot(delta: float, move_amount: float) -> void:
	if not is_instance_valid(_model_root):
		return

	_idle_time += delta
	_walk_time += delta * (8.5 if move_amount > 0.05 else 2.2)

	var step: float = sin(_walk_time)
	var counter_step: float = sin(_walk_time + PI)
	var bob: float = abs(sin(_walk_time)) if move_amount > 0.05 else 0.0
	var idle_breath: float = sin(_idle_time * 2.0) * 0.025
	var shoot: float = _shoot_pulse
	var hit: float = _hit_pulse

	_model_root.position = Vector3(0.0, idle_breath + bob * 0.07 - shoot * 0.035, 0.0)
	_model_root.rotation_degrees = Vector3(-shoot * 5.5, 0.0, step * 2.5 * move_amount)

	if is_instance_valid(_head_shell):
		_head_shell.rotation_degrees = Vector3(sin(_idle_time * 1.5) * 1.5, sin(_idle_time * 0.9) * 4.0, -step * move_amount * 1.6)
	if is_instance_valid(_upper_chest):
		_upper_chest.rotation_degrees = Vector3(0.0, 0.0, -step * move_amount * 1.8)

	if is_instance_valid(_left_forearm):
		_left_forearm.rotation_degrees = Vector3(counter_step * 14.0 * move_amount, 0.0, -8.0 - shoot * 6.0)
	if is_instance_valid(_right_forearm):
		_right_forearm.rotation_degrees = Vector3(step * 8.0 * move_amount - shoot * 22.0, 0.0, 8.0 + shoot * 4.0)
		_right_forearm.position.z = -0.03 - shoot * 0.08
	if is_instance_valid(_right_blaster):
		_right_blaster.position.z = -0.32 - shoot * 0.16
	if is_instance_valid(_muzzle_glow):
		_muzzle_glow.scale = Vector3.ONE * (1.0 + shoot * 2.2)
		_muzzle_glow.visible = shoot > 0.02

	if is_instance_valid(_left_thigh):
		_left_thigh.rotation_degrees = Vector3(step * 18.0 * move_amount, 0.0, -3.0 * move_amount)
	if is_instance_valid(_right_thigh):
		_right_thigh.rotation_degrees = Vector3(counter_step * 18.0 * move_amount, 0.0, 3.0 * move_amount)
	if is_instance_valid(_left_foot):
		_left_foot.position.y = 0.06 + maxf(step, 0.0) * 0.05 * move_amount
		_left_foot.rotation_degrees.x = 90.0 - step * 8.0 * move_amount
	if is_instance_valid(_right_foot):
		_right_foot.position.y = 0.06 + maxf(counter_step, 0.0) * 0.05 * move_amount
		_right_foot.rotation_degrees.x = 90.0 - counter_step * 8.0 * move_amount

	if is_instance_valid(_antenna_tip):
		_antenna_tip.position.y = 2.2 + sin(_idle_time * 5.0) * 0.025
	if is_instance_valid(_visor_glow):
		var pulse_scale := 1.0 + sin(_idle_time * 4.0) * 0.08 + shoot * 0.25
		_visor_glow.scale = Vector3(pulse_scale, pulse_scale, 1.0)
	if is_instance_valid(_art_sprite):
		_art_sprite.position = Vector3(0.0, 1.32 + idle_breath + bob * 0.08 - shoot * 0.04, 0.0)
		_art_sprite.rotation_degrees = Vector3(0.0, 0.0, step * 2.2 * move_amount - shoot * 2.0)
		_art_sprite.modulate = Color.WHITE.lerp(Color(1.0, 0.45, 0.32), hit)

	if is_instance_valid(_body_material):
		_body_material.albedo_color = _base_shell_color.lerp(Color(1.0, 0.38, 0.28), hit)

	if _celebrating and hp > 0:
		var cheer: float = abs(sin(_idle_time * 7.5))
		_model_root.position.y += cheer * 0.08
		if is_instance_valid(_left_forearm):
			_left_forearm.rotation_degrees = Vector3(-45.0 + cheer * 12.0, 0.0, -22.0)
		if is_instance_valid(_right_forearm):
			_right_forearm.rotation_degrees = Vector3(-42.0 + cheer * 10.0, 0.0, 22.0)
		if is_instance_valid(_visor_glow):
			_visor_glow.scale = Vector3(1.25 + cheer * 0.25, 1.18 + cheer * 0.22, 1.0)
		if is_instance_valid(_art_sprite):
			_art_sprite.position.y += cheer * 0.08
			_art_sprite.rotation_degrees.z = sin(_idle_time * 8.0) * 3.0

	if hp <= 0:
		var fall: float = minf(_death_time / 0.45, 1.0)
		_model_root.rotation_degrees = Vector3(0.0, 0.0, lerpf(0.0, 78.0, fall))
		_model_root.position.y = lerpf(_model_root.position.y, 0.08, fall)
		if is_instance_valid(_art_sprite):
			_art_sprite.rotation_degrees.z = lerpf(0.0, 78.0, fall)
			_art_sprite.position.y = lerpf(_art_sprite.position.y, 0.65, fall)


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

	_model_root = Node3D.new()
	_model_root.name = "RobotModel"
	add_child(_model_root)

	_add_capsule("PelvisFrame", Vector3(0.0, 0.62, 0.02), 0.25, 0.86, armor, Vector3(0.0, 0.0, 90.0))
	_add_capsule("LowerTorsoArmor", Vector3(0.0, 0.86, 0.0), 0.34, 0.64, shell)
	_add_ellipsoid("UpperChestArmor", Vector3(0.0, 1.16, -0.02), Vector3(0.95, 0.6, 0.54), shell)
	_add_box("ChestDarkInset", Vector3(0.0, 1.15, -0.275), Vector3(0.55, 0.34, 0.04), dark)
	_add_cylinder("HeartCoreGlass", Vector3(0.0, 1.16, -0.31), 0.18, 0.08, teal, Vector3(90.0, 0.0, 0.0))
	_add_cylinder("CoreOuterRing", Vector3(0.0, 1.16, -0.322), 0.25, 0.035, trim, Vector3(90.0, 0.0, 0.0))
	_add_box("CoreGuardTop", Vector3(0.0, 1.37, -0.33), Vector3(0.45, 0.05, 0.06), armor)
	_add_box("CoreGuardBottom", Vector3(0.0, 0.95, -0.33), Vector3(0.45, 0.05, 0.06), armor)
	_add_box("LeftChestPanel", Vector3(-0.32, 1.16, -0.29), Vector3(0.12, 0.24, 0.045), armor)
	_add_box("RightChestPanel", Vector3(0.32, 1.16, -0.29), Vector3(0.12, 0.24, 0.045), armor)

	_add_capsule("NeckJoint", Vector3(0.0, 1.47, 0.0), 0.14, 0.2, rubber)
	_add_ellipsoid("HeadShell", Vector3(0.0, 1.7, 0.0), Vector3(0.76, 0.48, 0.58), shell)
	_add_capsule("HelmetBrow", Vector3(0.0, 1.84, -0.08), 0.08, 0.8, trim, Vector3(0.0, 0.0, 90.0))
	_add_box("FacePlate", Vector3(0.0, 1.69, -0.31), Vector3(0.6, 0.22, 0.04), dark)
	_add_box("VisorGlow", Vector3(0.0, 1.7, -0.34), Vector3(0.46, 0.105, 0.035), teal)
	_add_box("LeftVisorPixel", Vector3(-0.16, 1.7, -0.365), Vector3(0.065, 0.045, 0.025), soft_white)
	_add_box("RightVisorPixel", Vector3(0.16, 1.7, -0.365), Vector3(0.065, 0.045, 0.025), soft_white)
	_add_cylinder("LeftAudioSensor", Vector3(-0.44, 1.7, -0.01), 0.12, 0.08, armor, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("RightAudioSensor", Vector3(0.44, 1.7, -0.01), 0.12, 0.08, armor, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("AntennaStem", Vector3(0.24, 2.02, 0.05), 0.025, 0.32, dark)
	_add_sphere("AntennaTip", Vector3(0.24, 2.2, 0.05), 0.055, amber)

	_add_capsule("LeftShoulderBlock", Vector3(-0.65, 1.22, 0.0), 0.18, 0.42, armor, Vector3(90.0, 0.0, 0.0))
	_add_capsule("RightShoulderBlock", Vector3(0.65, 1.22, 0.0), 0.18, 0.42, armor, Vector3(90.0, 0.0, 0.0))
	_add_sphere("LeftShoulderLamp", Vector3(-0.65, 1.36, -0.23), 0.065, amber)
	_add_sphere("RightShoulderLamp", Vector3(0.65, 1.36, -0.23), 0.065, amber)
	_add_sphere("LeftUpperArmJoint", Vector3(-0.77, 1.0, 0.0), 0.13, rubber)
	_add_sphere("RightUpperArmJoint", Vector3(0.77, 1.0, 0.0), 0.13, rubber)
	_add_capsule("LeftForearmArmor", Vector3(-0.82, 0.77, -0.03), 0.14, 0.52, shell)
	_add_capsule("RightForearmArmor", Vector3(0.82, 0.77, -0.03), 0.14, 0.52, shell)
	_add_capsule("LeftWristClamp", Vector3(-0.82, 0.5, -0.04), 0.09, 0.3, armor, Vector3(90.0, 0.0, 0.0))
	_add_capsule("RightWristClamp", Vector3(0.82, 0.5, -0.04), 0.09, 0.3, armor, Vector3(90.0, 0.0, 0.0))
	_add_capsule("LeftHandPincerA", Vector3(-0.9, 0.39, -0.12), 0.045, 0.2, rubber, Vector3(18.0, 0.0, -12.0))
	_add_capsule("LeftHandPincerB", Vector3(-0.74, 0.39, -0.12), 0.045, 0.2, rubber, Vector3(18.0, 0.0, 12.0))
	_add_cylinder("RightBlasterBarrel", Vector3(0.82, 0.47, -0.32), 0.075, 0.48, dark, Vector3(90.0, 0.0, 0.0))
	_add_cylinder("RightBlasterMuzzleGlow", Vector3(0.82, 0.47, -0.58), 0.085, 0.035, teal, Vector3(90.0, 0.0, 0.0))

	_add_capsule("BackpackMain", Vector3(0.0, 1.12, 0.36), 0.22, 0.78, armor)
	_add_capsule("BackpackBatteryLeft", Vector3(-0.22, 1.13, 0.5), 0.075, 0.62, dark)
	_add_capsule("BackpackBatteryRight", Vector3(0.22, 1.13, 0.5), 0.075, 0.62, dark)
	_add_cylinder("BackpackCoolantPipeTop", Vector3(0.0, 1.47, 0.53), 0.035, 0.5, teal, Vector3(0.0, 0.0, 90.0))
	_add_cylinder("BackpackCoolantPipeBottom", Vector3(0.0, 0.8, 0.53), 0.03, 0.5, teal, Vector3(0.0, 0.0, 90.0))

	_add_sphere("LeftHipJoint", Vector3(-0.28, 0.52, 0.0), 0.14, rubber)
	_add_sphere("RightHipJoint", Vector3(0.28, 0.52, 0.0), 0.14, rubber)
	_add_capsule("LeftThighPlate", Vector3(-0.28, 0.31, 0.02), 0.14, 0.44, shell)
	_add_capsule("RightThighPlate", Vector3(0.28, 0.31, 0.02), 0.14, 0.44, shell)
	_add_capsule("LeftKneePad", Vector3(-0.28, 0.22, -0.18), 0.075, 0.28, armor, Vector3(0.0, 0.0, 90.0))
	_add_capsule("RightKneePad", Vector3(0.28, 0.22, -0.18), 0.075, 0.28, armor, Vector3(0.0, 0.0, 90.0))
	_add_capsule("LeftFoot", Vector3(-0.28, 0.06, -0.09), 0.12, 0.52, rubber, Vector3(90.0, 0.0, 0.0))
	_add_capsule("RightFoot", Vector3(0.28, 0.06, -0.09), 0.12, 0.52, rubber, Vector3(90.0, 0.0, 0.0))
	_add_box("LeftToeLight", Vector3(-0.28, 0.11, -0.37), Vector3(0.18, 0.04, 0.035), amber)
	_add_box("RightToeLight", Vector3(0.28, 0.11, -0.37), Vector3(0.18, 0.04, 0.035), amber)

	_add_point_light("RobotCoreLight", Vector3(0.0, 1.25, -0.45), Color(0.15, 0.85, 1.0), 1.6, 2.8)
	_add_point_light("RobotShoulderLightLeft", Vector3(-0.68, 1.42, -0.38), Color(1.0, 0.45, 0.1), 0.55, 1.8)
	_add_point_light("RobotShoulderLightRight", Vector3(0.68, 1.42, -0.38), Color(1.0, 0.45, 0.1), 0.55, 1.8)
	_cache_animation_parts()
	_add_art_sprite()


func _cache_animation_parts() -> void:
	_head_shell = _model_root.get_node_or_null("HeadShell") as MeshInstance3D
	_upper_chest = _model_root.get_node_or_null("UpperChestArmor") as MeshInstance3D
	_left_forearm = _model_root.get_node_or_null("LeftForearmArmor") as MeshInstance3D
	_right_forearm = _model_root.get_node_or_null("RightForearmArmor") as MeshInstance3D
	_right_blaster = _model_root.get_node_or_null("RightBlasterBarrel") as MeshInstance3D
	_muzzle_glow = _model_root.get_node_or_null("RightBlasterMuzzleGlow") as MeshInstance3D
	_left_thigh = _model_root.get_node_or_null("LeftThighPlate") as MeshInstance3D
	_right_thigh = _model_root.get_node_or_null("RightThighPlate") as MeshInstance3D
	_left_foot = _model_root.get_node_or_null("LeftFoot") as MeshInstance3D
	_right_foot = _model_root.get_node_or_null("RightFoot") as MeshInstance3D
	_antenna_tip = _model_root.get_node_or_null("AntennaTip") as MeshInstance3D
	_visor_glow = _model_root.get_node_or_null("VisorGlow") as MeshInstance3D
	if is_instance_valid(_muzzle_glow):
		_muzzle_glow.visible = false


func _add_art_sprite() -> void:
	_art_sprite = Sprite3D.new()
	_art_sprite.name = "RobotArtSprite"
	_art_sprite.texture = load("res://art/game_assets/robot_sprite.png")
	_art_sprite.pixel_size = 0.00172
	_art_sprite.position = Vector3(0.0, 1.32, 0.0)
	_art_sprite.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_art_sprite.shaded = true
	add_child(_art_sprite)
	_model_root.visible = false


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
	sphere.radial_segments = 32
	sphere.rings = 16
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
	capsule.radial_segments = 24
	capsule.rings = 12
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


func _add_point_light(node_name: String, position: Vector3, color: Color, energy: float, light_range: float) -> void:
	var light := OmniLight3D.new()
	light.name = node_name
	light.position = position
	light.light_color = color
	light.light_energy = energy
	light.omni_range = light_range
	_model_root.add_child(light)


func _mat(albedo: Color, emission: Color = Color.BLACK, energy: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = albedo
	material.roughness = 0.72
	if energy > 0.0:
		material.emission_enabled = true
		material.emission = emission
		material.emission_energy_multiplier = energy
	return material
