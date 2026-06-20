from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT_DIR = Path(__file__).resolve().parents[1]
MODEL_DIR = ROOT_DIR / "art" / "models"
PREVIEW_DIR = ROOT_DIR / "art" / "previews"


def clear_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()


def material(name: str, color: tuple[float, float, float, float], metallic: float = 0.0, roughness: float = 0.6, emission: tuple[float, float, float] | None = None, strength: float = 0.0) -> bpy.types.Material:
	mat = bpy.data.materials.new(name)
	mat.use_nodes = True
	bsdf = mat.node_tree.nodes.get("Principled BSDF")
	if bsdf:
		if "Base Color" in bsdf.inputs:
			bsdf.inputs["Base Color"].default_value = color
		if "Metallic" in bsdf.inputs:
			bsdf.inputs["Metallic"].default_value = metallic
		if "Roughness" in bsdf.inputs:
			bsdf.inputs["Roughness"].default_value = roughness
		if emission and "Emission Color" in bsdf.inputs:
			bsdf.inputs["Emission Color"].default_value = (emission[0], emission[1], emission[2], 1.0)
		if "Emission Strength" in bsdf.inputs:
			bsdf.inputs["Emission Strength"].default_value = strength
	return mat


IVORY = material("worn warm ivory armor", (0.78, 0.72, 0.60, 1.0), metallic=0.18, roughness=0.64)
IVORY_LIGHT = material("cream raised trim", (0.94, 0.88, 0.74, 1.0), metallic=0.08, roughness=0.58)
DARK = material("soft black rubber joints", (0.025, 0.023, 0.020, 1.0), metallic=0.25, roughness=0.62)
VISOR = material("deep black glossy visor", (0.002, 0.006, 0.010, 1.0), metallic=0.0, roughness=0.18)
AMBER = material("warm amber emissive lights", (1.0, 0.58, 0.14, 1.0), metallic=0.0, roughness=0.22, emission=(1.0, 0.42, 0.08), strength=2.8)
AMBER_SOFT = material("soft yellow eye glow", (1.0, 0.96, 0.28, 1.0), metallic=0.0, roughness=0.16, emission=(1.0, 0.84, 0.18), strength=4.0)
GAP = material("deep recessed gaps", (0.006, 0.005, 0.004, 1.0), metallic=0.05, roughness=0.9)
LINE = material("fine bronze panel seams", (0.42, 0.25, 0.13, 1.0), metallic=0.15, roughness=0.76)
BLUE_RIM = material("subtle cool reflected metal", (0.18, 0.28, 0.38, 1.0), metallic=0.25, roughness=0.55)


def set_smooth(obj: bpy.types.Object) -> bpy.types.Object:
	if obj.type == "MESH":
		for polygon in obj.data.polygons:
			polygon.use_smooth = True
		wn = obj.modifiers.new("weighted normals", "WEIGHTED_NORMAL")
		wn.keep_sharp = True
	return obj


def bevel(obj: bpy.types.Object, width: float = 0.03, segments: int = 5) -> bpy.types.Object:
	bpy.context.view_layer.objects.active = obj
	obj.select_set(True)
	bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
	obj.select_set(False)
	mod = obj.modifiers.new("soft bevel", "BEVEL")
	mod.width = width
	mod.segments = segments
	mod.affect = "EDGES"
	set_smooth(obj)
	return obj


def assign(obj: bpy.types.Object, mat: bpy.types.Material) -> bpy.types.Object:
	obj.data.materials.append(mat)
	return obj


def rounded_box(name: str, loc: tuple[float, float, float], dims: tuple[float, float, float], mat: bpy.types.Material, bevel_width: float = 0.035, segments: int = 6, rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
	bpy.ops.mesh.primitive_cube_add(size=1.0, location=loc, rotation=rot)
	obj = bpy.context.object
	obj.name = name
	obj.dimensions = dims
	assign(obj, mat)
	return bevel(obj, bevel_width, segments)


def ellipsoid(name: str, loc: tuple[float, float, float], scale: tuple[float, float, float], mat: bpy.types.Material, segments: int = 64, rings: int = 32, rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
	bpy.ops.mesh.primitive_uv_sphere_add(segments=segments, ring_count=rings, radius=1.0, location=loc, rotation=rot)
	obj = bpy.context.object
	obj.name = name
	obj.scale = scale
	assign(obj, mat)
	return set_smooth(obj)


def cylinder(name: str, loc: tuple[float, float, float], radius: float, depth: float, mat: bpy.types.Material, vertices: int = 64, axis: str = "z", rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
	axis_rot = {
		"x": (0.0, math.radians(90.0), 0.0),
		"y": (math.radians(90.0), 0.0, 0.0),
		"z": (0.0, 0.0, 0.0),
	}[axis]
	final_rot = (axis_rot[0] + rot[0], axis_rot[1] + rot[1], axis_rot[2] + rot[2])
	bpy.ops.mesh.primitive_cylinder_add(vertices=vertices, radius=radius, depth=depth, location=loc, rotation=final_rot)
	obj = bpy.context.object
	obj.name = name
	assign(obj, mat)
	return bevel(obj, min(radius * 0.18, 0.025), 4)


def capsule(name: str, loc: tuple[float, float, float], radius: float, length: float, mat: bpy.types.Material, axis: str = "z", rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> list[bpy.types.Object]:
	parts = [cylinder(f"{name}_shaft", loc, radius, length, mat, vertices=48, axis=axis, rot=rot)]
	offset = Vector((0.0, 0.0, length * 0.5))
	if axis == "x":
		offset = Vector((length * 0.5, 0.0, 0.0))
	elif axis == "y":
		offset = Vector((0.0, length * 0.5, 0.0))
	base = Vector(loc)
	parts.append(ellipsoid(f"{name}_cap_a", tuple(base + offset), (radius, radius, radius), mat, segments=32, rings=16))
	parts.append(ellipsoid(f"{name}_cap_b", tuple(base - offset), (radius, radius, radius), mat, segments=32, rings=16))
	return parts


def torus(name: str, loc: tuple[float, float, float], major: float, minor: float, mat: bpy.types.Material, rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> bpy.types.Object:
	bpy.ops.mesh.primitive_torus_add(major_radius=major, minor_radius=minor, major_segments=96, minor_segments=16, location=loc, rotation=rot)
	obj = bpy.context.object
	obj.name = name
	assign(obj, mat)
	return set_smooth(obj)


def curve_line(name: str, points: list[tuple[float, float, float]], mat: bpy.types.Material, bevel_depth: float = 0.008) -> bpy.types.Object:
	curve = bpy.data.curves.new(name, "CURVE")
	curve.dimensions = "3D"
	curve.resolution_u = 2
	curve.bevel_depth = bevel_depth
	curve.bevel_resolution = 2
	spline = curve.splines.new("POLY")
	spline.points.add(len(points) - 1)
	for p, co in zip(spline.points, points):
		p.co = (co[0], co[1], co[2], 1.0)
	obj = bpy.data.objects.new(name, curve)
	bpy.context.collection.objects.link(obj)
	obj.data.materials.append(mat)
	return obj


def add_heart(loc: tuple[float, float, float], scale: float = 1.0) -> None:
	x, y, z = loc
	ellipsoid("heart_lobe_left", (x - 0.065 * scale, y, z + 0.055 * scale), (0.075 * scale, 0.018 * scale, 0.075 * scale), AMBER)
	ellipsoid("heart_lobe_right", (x + 0.065 * scale, y, z + 0.055 * scale), (0.075 * scale, 0.018 * scale, 0.075 * scale), AMBER)
	rounded_box("heart_lower_faceted_point", (x, y, z - 0.035 * scale), (0.16 * scale, 0.035 * scale, 0.18 * scale), AMBER, bevel_width=0.01 * scale, segments=2, rot=(0.0, 0.0, math.radians(45.0)))


def robot_model() -> None:
	robot = bpy.data.collections.new("Robot_Blender_Showcase")
	bpy.context.scene.collection.children.link(robot)
	bpy.context.view_layer.active_layer_collection = bpy.context.view_layer.layer_collection

	# Feet and legs.
	for side, sign in [("L", -1.0), ("R", 1.0)]:
		rounded_box(f"{side}_foot_dark_sole", (sign * 0.34, -0.03, 0.12), (0.56, 0.82, 0.16), DARK, 0.06)
		rounded_box(f"{side}_foot_ivory_toe", (sign * 0.34, -0.28, 0.28), (0.48, 0.45, 0.18), IVORY, 0.055)
		rounded_box(f"{side}_foot_top_plate", (sign * 0.34, -0.33, 0.42), (0.34, 0.24, 0.055), IVORY_LIGHT, 0.018)
		cylinder(f"{side}_ankle_side_disc_dark", (sign * 0.66, -0.02, 0.64), 0.13, 0.08, DARK, axis="x")
		cylinder(f"{side}_ankle_side_disc_amber", (sign * 0.71, -0.02, 0.64), 0.066, 0.035, AMBER, axis="x")
		capsule(f"{side}_ankle_piston_front", (sign * 0.36, -0.23, 0.73), 0.035, 0.48, DARK)
		ellipsoid(f"{side}_shin_lower_ivory", (sign * 0.34, -0.02, 1.04), (0.23, 0.23, 0.42), IVORY)
		rounded_box(f"{side}_shin_front_panel", (sign * 0.34, -0.25, 1.10), (0.27, 0.055, 0.48), IVORY_LIGHT, 0.025)
		cylinder(f"{side}_knee_dark_ring", (sign * 0.36, -0.04, 1.50), 0.18, 0.12, DARK, axis="x")
		cylinder(f"{side}_knee_ivory_cap", (sign * 0.42, -0.04, 1.50), 0.115, 0.05, IVORY, axis="x")
		cylinder(f"{side}_knee_amber_core", (sign * 0.46, -0.04, 1.50), 0.047, 0.025, AMBER, axis="x")
		ellipsoid(f"{side}_thigh_outer_ivory", (sign * 0.39, -0.02, 1.93), (0.30, 0.27, 0.48), IVORY)
		rounded_box(f"{side}_thigh_front_plate", (sign * 0.39, -0.26, 1.98), (0.28, 0.055, 0.45), IVORY_LIGHT, 0.026)
		ellipsoid(f"{side}_inner_hip_black", (sign * 0.18, -0.02, 1.95), (0.14, 0.18, 0.44), DARK)
		cylinder(f"{side}_hip_dark_joint", (sign * 0.46, -0.02, 2.34), 0.21, 0.16, DARK, axis="x")

		for z in [0.96, 1.19, 1.88, 2.10]:
			curve_line(f"{side}_leg_bronze_seam_{z}", [(sign * 0.20, -0.295, z), (sign * 0.44, -0.305, z + 0.10)], LINE, 0.006)

	# Pelvis and flexible abdomen.
	ellipsoid("pelvis_ivory_cup", (0.0, -0.02, 2.28), (0.72, 0.36, 0.24), IVORY)
	rounded_box("pelvis_dark_lower_gap", (0.0, -0.02, 2.15), (0.72, 0.32, 0.12), DARK, 0.05)
	for i, z in enumerate([2.52, 2.68, 2.84, 3.00]):
		rounded_box(f"abdomen_black_segment_{i}", (0.0, -0.08, z), (0.68 - i * 0.05, 0.36, 0.095), DARK, 0.04)
		curve_line(f"abdomen_bronze_separator_{i}", [(-0.33 + i * 0.02, -0.29, z + 0.055), (0.33 - i * 0.02, -0.29, z + 0.055)], LINE, 0.010)

	# Chest.
	ellipsoid("main_rounded_chest_shell", (0.0, -0.03, 3.34), (0.98, 0.48, 0.56), IVORY)
	rounded_box("left_chest_raised_plate", (-0.36, -0.42, 3.45), (0.42, 0.10, 0.40), IVORY_LIGHT, 0.045, rot=(0.0, 0.0, math.radians(-8.0)))
	rounded_box("right_chest_raised_plate", (0.36, -0.42, 3.45), (0.42, 0.10, 0.40), IVORY_LIGHT, 0.045, rot=(0.0, 0.0, math.radians(8.0)))
	cylinder("heart_core_dark_housing", (0.0, -0.53, 3.32), 0.26, 0.07, DARK, vertices=8, axis="y", rot=(0.0, 0.0, math.radians(22.5)))
	torus("heart_core_bronze_ring", (0.0, -0.575, 3.32), 0.22, 0.018, LINE, rot=(math.radians(90.0), 0.0, 0.0))
	add_heart((0.0, -0.61, 3.32), 1.15)
	rounded_box("upper_chest_black_inset", (-0.22, -0.52, 3.75), (0.32, 0.045, 0.085), DARK, 0.012)
	cylinder("upper_chest_tiny_button", (0.36, -0.53, 3.68), 0.058, 0.025, DARK, axis="y")
	cylinder("upper_chest_tiny_amber_dot", (0.36, -0.55, 3.68), 0.026, 0.012, AMBER, axis="y")
	for x in [-0.68, 0.68]:
		capsule(f"tiny_vertical_chest_light_{x}", (x, -0.54, 3.25), 0.026, 0.20, AMBER)
	for x1, x2, z in [(-0.82, -0.35, 3.58), (0.35, 0.82, 3.58), (-0.56, -0.26, 3.18), (0.26, 0.56, 3.18)]:
		curve_line(f"chest_panel_line_{x1}", [(x1, -0.57, z), (x2, -0.57, z + 0.08)], LINE, 0.007)

	# Backpack and neck.
	rounded_box("large_rounded_backpack", (0.0, 0.42, 3.40), (0.78, 0.42, 1.04), DARK, 0.10)
	capsule("backpack_top_handle", (0.0, 0.35, 4.05), 0.05, 0.56, DARK, axis="x")
	capsule("backpack_vertical_amber_slot", (0.46, 0.19, 3.50), 0.035, 0.38, AMBER)
	cylinder("neck_black_stack_bottom", (0.0, -0.03, 3.95), 0.22, 0.18, DARK)
	cylinder("neck_black_stack_top", (0.0, -0.03, 4.11), 0.18, 0.14, DARK)

	# Helmet and face.
	ellipsoid("large_ivory_helmet_dome", (0.0, -0.02, 4.62), (0.96, 0.66, 0.62), IVORY, segments=96, rings=48)
	ellipsoid("lower_helmet_jaw_volume", (0.0, -0.10, 4.36), (0.88, 0.52, 0.34), IVORY)
	rounded_box("visor_black_rounded_glass", (0.0, -0.62, 4.62), (1.34, 0.08, 0.42), VISOR, 0.16, 14)
	rounded_box("left_amber_eye_pill", (-0.34, -0.685, 4.65), (0.14, 0.035, 0.36), AMBER_SOFT, 0.065, 12)
	rounded_box("right_amber_eye_pill", (0.34, -0.685, 4.65), (0.14, 0.035, 0.36), AMBER_SOFT, 0.065, 12)
	rounded_box("small_amber_mouth_pill", (0.0, -0.69, 4.35), (0.28, 0.030, 0.055), AMBER_SOFT, 0.025, 8)
	rounded_box("helmet_top_service_panel", (0.0, -0.05, 5.20), (0.44, 0.34, 0.055), IVORY_LIGHT, 0.035, rot=(math.radians(12.0), 0.0, 0.0))
	rounded_box("left_cheek_armor_pad", (-0.58, -0.47, 4.30), (0.24, 0.10, 0.22), IVORY, 0.055, rot=(0.0, 0.0, math.radians(-16.0)))
	rounded_box("right_cheek_armor_pad", (0.58, -0.47, 4.30), (0.24, 0.10, 0.22), IVORY, 0.055, rot=(0.0, 0.0, math.radians(16.0)))
	for side, sign in [("L", -1.0), ("R", 1.0)]:
		cylinder(f"{side}_ear_dark_outer_ring", (sign * 0.86, -0.02, 4.61), 0.27, 0.16, DARK, axis="x")
		cylinder(f"{side}_ear_ivory_cap", (sign * 0.94, -0.02, 4.61), 0.20, 0.075, IVORY_LIGHT, axis="x")
		torus(f"{side}_ear_amber_ring", (sign * 0.99, -0.02, 4.61), 0.13, 0.018, AMBER, rot=(0.0, math.radians(90.0), 0.0))
		cylinder(f"{side}_ear_inner_dark_dot", (sign * 1.03, -0.02, 4.61), 0.055, 0.025, DARK, axis="x")
	curve_line("helmet_brow_bronze_seam", [(-0.60, -0.69, 4.92), (-0.20, -0.72, 4.99), (0.20, -0.72, 4.99), (0.60, -0.69, 4.92)], LINE, 0.010)
	for i, x in enumerate([-0.46, -0.26, -0.06, 0.16, 0.38]):
		curve_line(f"helmet_tiny_notch_{i}", [(x, -0.705, 4.95), (x, -0.72, 5.08)], LINE, 0.007)
	for x in [-0.58, 0.58]:
		curve_line(f"helmet_side_vertical_seam_{x}", [(x, -0.60, 4.80), (x * 0.82, -0.61, 5.05)], LINE, 0.007)
	cylinder("backpack_antenna_stem", (0.56, 0.20, 5.08), 0.025, 0.72, DARK)
	ellipsoid("backpack_antenna_amber_tip", (0.56, 0.20, 5.48), (0.07, 0.07, 0.07), AMBER)

	# Arms and hands.
	for side, sign in [("L", -1.0), ("R", 1.0)]:
		cylinder(f"{side}_shoulder_black_ring", (sign * 1.03, -0.02, 3.58), 0.28, 0.18, DARK, axis="x")
		ellipsoid(f"{side}_shoulder_ivory_cap", (sign * 1.20, -0.06, 3.58), (0.33, 0.30, 0.34), IVORY)
		cylinder(f"{side}_shoulder_amber_disc", (sign * 1.36, -0.20, 3.57), 0.095, 0.03, AMBER, axis="y")
		torus(f"{side}_shoulder_bronze_ring", (sign * 1.36, -0.215, 3.57), 0.125, 0.010, LINE, rot=(math.radians(90.0), 0.0, 0.0))
		capsule(f"{side}_upper_arm_front_piston", (sign * 1.17, -0.17, 3.12), 0.052, 0.52, DARK)
		capsule(f"{side}_upper_arm_back_piston", (sign * 1.33, 0.02, 3.10), 0.046, 0.46, DARK)
		cylinder(f"{side}_elbow_black_ring", (sign * 1.22, -0.08, 2.84), 0.16, 0.12, DARK, axis="x")
		ellipsoid(f"{side}_forearm_ivory_shell", (sign * 1.18, -0.12, 2.45), (0.24, 0.22, 0.44), IVORY)
		rounded_box(f"{side}_forearm_front_raised_plate", (sign * 1.18, -0.34, 2.47), (0.22, 0.055, 0.44), IVORY_LIGHT, 0.026, rot=(0.0, 0.0, math.radians(5.0 * sign)))
		cylinder(f"{side}_wrist_dark_ring", (sign * 1.17, -0.10, 2.08), 0.13, 0.11, DARK, axis="x")
		ellipsoid(f"{side}_palm_dark_block", (sign * 1.17, -0.13, 1.90), (0.18, 0.13, 0.15), DARK)
		for i, offset in enumerate([-0.15, -0.05, 0.05, 0.15]):
			fx = sign * (1.11 + offset * sign)
			capsule(f"{side}_finger_{i}_base", (fx, -0.18, 1.70), 0.025, 0.20, DARK)
			capsule(f"{side}_finger_{i}_tip", (fx, -0.20, 1.54), 0.020, 0.14, DARK)
			cylinder(f"{side}_finger_{i}_bronze_knuckle", (fx, -0.18, 1.78), 0.030, 0.018, LINE)
		capsule(f"{side}_thumb", (sign * 1.36, -0.12, 1.78), 0.030, 0.26, DARK, rot=(0.0, math.radians(25.0 * sign), 0.0))
		cylinder(f"{side}_forearm_amber_slot", (sign * 1.31, -0.35, 2.46), 0.035, 0.025, AMBER, axis="y")
		for z in [2.33, 2.60, 3.45]:
			curve_line(f"{side}_arm_scratch_{z}", [(sign * 1.06, -0.38, z), (sign * 1.23, -0.39, z + 0.12)], LINE, 0.006)

	# Worn paint scratches.
	for i, (x, y, z, dx, dz) in enumerate([
		(-0.35, -0.73, 4.97, 0.12, 0.05), (0.34, -0.73, 4.82, 0.15, -0.04),
		(-0.52, -0.56, 3.55, 0.16, 0.10), (0.48, -0.55, 3.18, -0.14, 0.08),
		(-0.38, -0.31, 1.86, 0.10, 0.08), (0.34, -0.32, 1.18, 0.10, 0.05),
		(-0.22, -0.34, 0.38, 0.14, 0.06), (0.42, -0.31, 0.96, -0.10, 0.10),
	]):
		curve_line(f"worn_paint_scratch_{i}", [(x, y, z), (x + dx, y - 0.01, z + dz)], LINE, 0.0055)


def make_view_scene() -> None:
	base_mat = material("dark studio pedestal", (0.055, 0.063, 0.070, 1.0), roughness=0.72)
	grid_mat = material("blue studio grid glow", (0.10, 0.18, 0.22, 1.0), emission=(0.05, 0.32, 0.46), strength=0.25)
	cylinder("turntable_dark_pedestal", (0.0, 0.0, -0.08), 1.65, 0.16, base_mat, vertices=128)
	torus("turntable_amber_light_ring", (0.0, 0.0, 0.03), 1.55, 0.018, AMBER)
	for i in range(-5, 6):
		v = i * 0.55
		rounded_box(f"grid_x_{i}", (v, 1.4, -0.18), (0.012, 5.8, 0.012), grid_mat, 0.002, 1)
		rounded_box(f"grid_y_{i}", (0.0, v + 1.4, -0.18), (5.8, 0.012, 0.012), grid_mat, 0.002, 1)

	bpy.ops.object.light_add(type="AREA", location=(0.0, -4.2, 6.2))
	key = bpy.context.object
	key.name = "large warm softbox"
	key.data.energy = 620
	key.data.size = 5.0
	bpy.ops.object.light_add(type="POINT", location=(-3.5, -1.5, 4.2))
	rim = bpy.context.object
	rim.name = "cool blue rim light"
	rim.data.color = (0.35, 0.60, 1.0)
	rim.data.energy = 160
	bpy.ops.object.light_add(type="POINT", location=(2.7, -2.5, 3.4))
	warm = bpy.context.object
	warm.name = "warm amber rim light"
	warm.data.color = (1.0, 0.45, 0.14)
	warm.data.energy = 110

	bpy.ops.object.camera_add(location=(0.0, -9.8, 3.15))
	camera = bpy.context.object
	bpy.context.scene.camera = camera
	camera.name = "robot showcase camera"
	camera.data.lens = 42
	look_at(camera, Vector((0.0, -0.06, 2.85)))

	bpy.context.scene.render.resolution_x = 1400
	bpy.context.scene.render.resolution_y = 1800
	bpy.context.scene.eevee.taa_render_samples = 64
	bpy.context.scene.world = bpy.data.worlds.new("black studio world")
	bpy.context.scene.world.color = (0.002, 0.003, 0.004)


def look_at(obj: bpy.types.Object, target: Vector) -> None:
	direction = target - obj.location
	obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def export_files() -> None:
	MODEL_DIR.mkdir(parents=True, exist_ok=True)
	PREVIEW_DIR.mkdir(parents=True, exist_ok=True)
	blend_path = MODEL_DIR / "robot_blender_showcase.blend"
	glb_path = MODEL_DIR / "robot_blender_showcase.glb"
	preview_path = PREVIEW_DIR / "robot_blender_showcase.png"

	bpy.ops.wm.save_as_mainfile(filepath=str(blend_path))
	bpy.ops.export_scene.gltf(filepath=str(glb_path), export_format="GLB", export_apply=True)
	bpy.context.scene.render.filepath = str(preview_path)
	bpy.ops.render.render(write_still=True)

	print(f"saved {blend_path}")
	print(f"saved {glb_path}")
	print(f"saved {preview_path}")


def main() -> None:
	clear_scene()
	robot_model()
	make_view_scene()
	export_files()


if __name__ == "__main__":
	main()
