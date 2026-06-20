from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art" / "models" / "mila_child1.glb"
OUT_GLB = ROOT / "art" / "models" / "mila_child1_rig_test.glb"
BLENDER_SOURCE_DIR = ROOT / "art" / "blender_sources"
OUT_BLEND = BLENDER_SOURCE_DIR / "mila_child1_rig_test.blend"


def clear_scene() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()


def normalize_mesh(obj: bpy.types.Object) -> None:
	bpy.ops.object.select_all(action="DESELECT")
	obj.select_set(True)
	bpy.context.view_layer.objects.active = obj
	bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)

	min_x = min(vertex.co.x for vertex in obj.data.vertices)
	max_x = max(vertex.co.x for vertex in obj.data.vertices)
	min_y = min(vertex.co.y for vertex in obj.data.vertices)
	max_y = max(vertex.co.y for vertex in obj.data.vertices)
	min_z = min(vertex.co.z for vertex in obj.data.vertices)
	center_x = (min_x + max_x) * 0.5
	center_y = (min_y + max_y) * 0.5

	for vertex in obj.data.vertices:
		vertex.co.x -= center_x
		vertex.co.y -= center_y
		vertex.co.z -= min_z
	obj.data.update()


def create_armature() -> bpy.types.Object:
	bpy.ops.object.armature_add(enter_editmode=True, location=(0.0, 0.0, 0.0))
	armature = bpy.context.object
	armature.name = "MilaRigTestArmature"
	armature.data.name = "MilaRigTestSkeleton"
	armature.show_in_front = True

	bones = armature.data.edit_bones
	root = bones[0]
	root.name = "root"
	root.head = (0.0, 0.0, 0.02)
	root.tail = (0.0, 0.0, 0.16)

	def add_bone(name: str, head: tuple[float, float, float], tail: tuple[float, float, float], parent: str | None = None) -> bpy.types.EditBone:
		bone = bones.new(name)
		bone.head = head
		bone.tail = tail
		if parent:
			bone.parent = bones[parent]
			bone.use_connect = False
		return bone

	add_bone("pelvis", (0.0, 0.0, 0.34), (0.0, 0.0, 0.48), "root")
	add_bone("spine", (0.0, 0.0, 0.48), (0.0, 0.0, 0.62), "pelvis")
	add_bone("chest", (0.0, 0.0, 0.62), (0.0, 0.0, 0.72), "spine")
	add_bone("neck", (0.0, 0.0, 0.70), (0.0, 0.0, 0.78), "chest")
	add_bone("head", (0.0, 0.0, 0.76), (0.0, 0.0, 0.98), "neck")

	for side, sign in [("L", -1.0), ("R", 1.0)]:
		add_bone(f"{side}_upper_arm", (sign * 0.115, 0.0, 0.62), (sign * 0.155, 0.0, 0.47), "chest")
		add_bone(f"{side}_forearm", (sign * 0.155, 0.0, 0.47), (sign * 0.165, 0.0, 0.34), f"{side}_upper_arm")
		add_bone(f"{side}_hand", (sign * 0.165, 0.0, 0.34), (sign * 0.165, 0.0, 0.25), f"{side}_forearm")
		add_bone(f"{side}_thigh", (sign * 0.065, 0.0, 0.36), (sign * 0.070, 0.0, 0.22), "pelvis")
		add_bone(f"{side}_shin", (sign * 0.070, 0.0, 0.22), (sign * 0.070, 0.0, 0.09), f"{side}_thigh")
		add_bone(f"{side}_foot", (sign * 0.070, -0.015, 0.09), (sign * 0.070, -0.080, 0.035), f"{side}_shin")

	bpy.ops.object.mode_set(mode="OBJECT")
	return armature


def create_vertex_groups(mesh: bpy.types.Object) -> None:
	groups = {}
	for name in [
		"root",
		"pelvis",
		"spine",
		"chest",
		"neck",
		"head",
		"L_upper_arm",
		"L_forearm",
		"L_hand",
		"R_upper_arm",
		"R_forearm",
		"R_hand",
		"L_thigh",
		"L_shin",
		"L_foot",
		"R_thigh",
		"R_shin",
		"R_foot",
	]:
		groups[name] = mesh.vertex_groups.new(name=name)

	def choose_bone(co: Vector) -> str:
		x = co.x
		z = co.z
		ax = abs(x)

		if z > 0.70:
			return "head"
		if 0.64 < z <= 0.72 and ax < 0.09:
			return "neck"

		if x < -0.105 and 0.27 < z < 0.68:
			if z > 0.51:
				return "L_upper_arm"
			if z > 0.36:
				return "L_forearm"
			return "L_hand"
		if x > 0.105 and 0.27 < z < 0.68:
			if z > 0.51:
				return "R_upper_arm"
			if z > 0.36:
				return "R_forearm"
			return "R_hand"

		if x < -0.025 and z <= 0.36:
			if z > 0.24:
				return "L_thigh"
			if z > 0.10:
				return "L_shin"
			return "L_foot"
		if x > 0.025 and z <= 0.36:
			if z > 0.24:
				return "R_thigh"
			if z > 0.10:
				return "R_shin"
			return "R_foot"

		if z < 0.42:
			return "pelvis"
		if z < 0.58:
			return "spine"
		return "chest"

	for vertex in mesh.data.vertices:
		bone_name = choose_bone(vertex.co)
		groups[bone_name].add([vertex.index], 1.0, "ADD")


def add_armature_modifier(mesh: bpy.types.Object, armature: bpy.types.Object) -> None:
	modifier = mesh.modifiers.new("MilaRigTestArmature", "ARMATURE")
	modifier.object = armature
	mesh.parent = armature


def key_pose(armature: bpy.types.Object, frame: int, rotations: dict[str, tuple[float, float, float]], root_z: float = 0.0) -> None:
	bpy.context.scene.frame_set(frame)
	armature.location.z = root_z
	armature.keyframe_insert(data_path="location", frame=frame)
	for pose_bone in armature.pose.bones:
		pose_bone.rotation_mode = "XYZ"
		pose_bone.rotation_euler = (0.0, 0.0, 0.0)
		if pose_bone.name in rotations:
			pose_bone.rotation_euler = tuple(math.radians(value) for value in rotations[pose_bone.name])
		pose_bone.keyframe_insert(data_path="rotation_euler", frame=frame)


def create_walk_animation(armature: bpy.types.Object) -> None:
	bpy.context.view_layer.objects.active = armature
	bpy.ops.object.mode_set(mode="POSE")
	action = bpy.data.actions.new("Mila_Rig_Test_Walk")
	armature.animation_data_create()
	armature.animation_data.action = action

	key_pose(
		armature,
		1,
		{
			"pelvis": (0, 0, 2),
			"chest": (-2, 0, -2),
			"head": (2, 0, -1),
			"L_thigh": (18, 0, 0),
			"L_shin": (-10, 0, 0),
			"L_foot": (-7, 0, 0),
			"R_thigh": (-16, 0, 0),
			"R_shin": (12, 0, 0),
			"R_foot": (8, 0, 0),
			"L_upper_arm": (-10, 0, -5),
			"L_forearm": (5, 0, 0),
			"R_upper_arm": (12, 0, 5),
			"R_forearm": (-5, 0, 0),
		},
		root_z=0.0,
	)
	key_pose(
		armature,
		13,
		{
			"pelvis": (0, 0, -2),
			"chest": (-1, 0, 2),
			"head": (1, 0, 1),
			"L_thigh": (-16, 0, 0),
			"L_shin": (12, 0, 0),
			"L_foot": (8, 0, 0),
			"R_thigh": (18, 0, 0),
			"R_shin": (-10, 0, 0),
			"R_foot": (-7, 0, 0),
			"L_upper_arm": (12, 0, -5),
			"L_forearm": (-5, 0, 0),
			"R_upper_arm": (-10, 0, 5),
			"R_forearm": (5, 0, 0),
		},
		root_z=0.015,
	)
	key_pose(
		armature,
		25,
		{
			"pelvis": (0, 0, 2),
			"chest": (-2, 0, -2),
			"head": (2, 0, -1),
			"L_thigh": (18, 0, 0),
			"L_shin": (-10, 0, 0),
			"L_foot": (-7, 0, 0),
			"R_thigh": (-16, 0, 0),
			"R_shin": (12, 0, 0),
			"R_foot": (8, 0, 0),
			"L_upper_arm": (-10, 0, -5),
			"L_forearm": (5, 0, 0),
			"R_upper_arm": (12, 0, 5),
			"R_forearm": (-5, 0, 0),
		},
		root_z=0.0,
	)

	bpy.context.scene.frame_start = 1
	bpy.context.scene.frame_end = 25
	bpy.ops.object.mode_set(mode="OBJECT")


def export_files() -> None:
	BLENDER_SOURCE_DIR.mkdir(parents=True, exist_ok=True)
	OUT_GLB.parent.mkdir(parents=True, exist_ok=True)
	bpy.ops.wm.save_as_mainfile(filepath=str(OUT_BLEND))
	bpy.ops.export_scene.gltf(
		filepath=str(OUT_GLB),
		export_format="GLB",
		export_apply=True,
		export_animations=True,
		export_current_frame=False,
	)
	print(f"saved={OUT_BLEND}")
	print(f"exported={OUT_GLB}")


def main() -> None:
	clear_scene()
	bpy.ops.import_scene.gltf(filepath=str(SRC))
	meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	if not meshes:
		raise RuntimeError("No mesh found in source GLB")
	mesh = meshes[0]
	mesh.name = "MilaRigTestMesh"
	normalize_mesh(mesh)

	armature = create_armature()
	create_vertex_groups(mesh)
	add_armature_modifier(mesh, armature)
	create_walk_animation(armature)
	export_files()


if __name__ == "__main__":
	main()
