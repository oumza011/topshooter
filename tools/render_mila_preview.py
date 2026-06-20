from __future__ import annotations

import math
from pathlib import Path

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[1]
SRC = ROOT / "art" / "models" / "mila_child1.glb"
OUT = ROOT / "art" / "previews" / "mila_child1_front.png"


def look_at(obj: bpy.types.Object, target: Vector) -> None:
	direction = target - obj.location
	obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def main() -> None:
	OUT.parent.mkdir(parents=True, exist_ok=True)
	bpy.ops.object.select_all(action="SELECT")
	bpy.ops.object.delete()
	bpy.ops.import_scene.gltf(filepath=str(SRC))

	meshes = [obj for obj in bpy.context.scene.objects if obj.type == "MESH"]
	if not meshes:
		raise RuntimeError("No mesh found in mila_child1.glb")

	obj = meshes[0]
	obj.name = "MilaSourceMesh"
	bpy.context.view_layer.objects.active = obj
	obj.select_set(True)
	bpy.ops.object.origin_set(type="ORIGIN_GEOMETRY", center="BOUNDS")
	obj.location = (0.0, 0.0, 0.5)

	bpy.ops.object.light_add(type="AREA", location=(0.0, -3.0, 3.0))
	light = bpy.context.object
	light.name = "PreviewSoftbox"
	light.data.energy = 450
	light.data.size = 4

	bpy.ops.object.camera_add(location=(0.0, -2.1, 0.64))
	camera = bpy.context.object
	bpy.context.scene.camera = camera
	look_at(camera, Vector((0.0, 0.0, 0.52)))
	camera.data.lens = 70

	bpy.context.scene.render.resolution_x = 1000
	bpy.context.scene.render.resolution_y = 1400
	bpy.context.scene.render.filepath = str(OUT)
	bpy.context.scene.world.color = (0.025, 0.025, 0.03)
	bpy.ops.render.render(write_still=True)

	print(f"rendered={OUT}")
	print(f"dims={tuple(round(v, 5) for v in obj.dimensions)}")


if __name__ == "__main__":
	main()
