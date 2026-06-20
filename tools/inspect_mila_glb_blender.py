from __future__ import annotations

from pathlib import Path

import bpy


ROOT_DIR = Path(__file__).resolve().parents[1]
GLB_PATH = ROOT_DIR / "art" / "models" / "mila_child1.glb"


def main() -> None:
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()

	bpy.ops.import_scene.gltf(filepath=str(GLB_PATH))

	meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	armatures = [obj for obj in bpy.context.scene.objects if obj.type == "ARMATURE"]
	actions = list(bpy.data.actions)
	materials = list(bpy.data.materials)
	images = list(bpy.data.images)

	print(f"file={GLB_PATH}")
	print(f"mesh_objects={len(meshes)}")
	print(f"armatures={len(armatures)}")
	print(f"actions={len(actions)}")
	print(f"materials={len(materials)}")
	print(f"images={len(images)}")

	for obj in meshes:
		print(
			"mesh",
			obj.name,
			"verts",
			len(obj.data.vertices),
			"polys",
			len(obj.data.polygons),
			"dims",
			tuple(round(v, 5) for v in obj.dimensions),
			"loc",
			tuple(round(v, 5) for v in obj.location),
		)

	if len(meshes) == 1:
		obj = meshes[0]
		bpy.ops.object.select_all(action="DESELECT")
		obj.select_set(True)
		bpy.context.view_layer.objects.active = obj
		bpy.ops.object.mode_set(mode="EDIT")
		bpy.ops.mesh.select_all(action="SELECT")
		bpy.ops.mesh.separate(type="LOOSE")
		bpy.ops.object.mode_set(mode="OBJECT")

		loose_meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
		print(f"loose_parts_after_blender_separate={len(loose_meshes)}")
		for part in sorted(loose_meshes, key=lambda item: len(item.data.polygons), reverse=True)[:24]:
			print(
				"loose",
				part.name,
				"verts",
				len(part.data.vertices),
				"polys",
				len(part.data.polygons),
				"dims",
				tuple(round(v, 5) for v in part.dimensions),
				"loc",
				tuple(round(v, 5) for v in part.location),
			)


if __name__ == "__main__":
	main()
