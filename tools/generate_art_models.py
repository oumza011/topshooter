from __future__ import annotations

import math
from pathlib import Path

import numpy as np
import trimesh
from trimesh.transformations import euler_matrix, identity_matrix, translation_matrix
from trimesh.visual.material import PBRMaterial


ROOT_DIR = Path(__file__).resolve().parents[1]
OUT_DIR = ROOT_DIR / "art" / "models"


def rgba(r: float, g: float, b: float, a: float = 1.0) -> list[float]:
	return [r, g, b, a]


MATERIALS = {
	"robot_shell": PBRMaterial(name="warm_ivory_robot_shell", baseColorFactor=rgba(0.86, 0.84, 0.76), metallicFactor=0.12, roughnessFactor=0.58),
	"robot_shadow": PBRMaterial(name="warm_gray_shadow_armor", baseColorFactor=rgba(0.42, 0.44, 0.42), metallicFactor=0.18, roughnessFactor=0.64),
	"robot_dark": PBRMaterial(name="soft_black_rubber_and_visor", baseColorFactor=rgba(0.025, 0.03, 0.035), metallicFactor=0.0, roughnessFactor=0.82),
	"robot_trim": PBRMaterial(name="cream_highlight_trim", baseColorFactor=rgba(0.96, 0.94, 0.86), metallicFactor=0.04, roughnessFactor=0.5),
	"robot_amber": PBRMaterial(name="amber_status_lights", baseColorFactor=rgba(1.0, 0.48, 0.12), emissiveFactor=[1.0, 0.32, 0.06], metallicFactor=0.0, roughnessFactor=0.35),
	"robot_cyan": PBRMaterial(name="cyan_ai_core_and_visor", baseColorFactor=rgba(0.08, 0.76, 1.0), emissiveFactor=[0.0, 0.72, 1.0], metallicFactor=0.0, roughnessFactor=0.24),
	"robot_worn_ivory": PBRMaterial(name="worn_ivory_showcase_armor", baseColorFactor=rgba(0.78, 0.72, 0.60), metallicFactor=0.16, roughnessFactor=0.66),
	"robot_warm_black": PBRMaterial(name="warm_black_showcase_joints", baseColorFactor=rgba(0.035, 0.032, 0.028), metallicFactor=0.28, roughnessFactor=0.62),
	"robot_showcase_amber": PBRMaterial(name="amber_showcase_lights", baseColorFactor=rgba(1.0, 0.56, 0.13), emissiveFactor=[1.0, 0.42, 0.08], metallicFactor=0.0, roughnessFactor=0.22),
	"robot_panel_line": PBRMaterial(name="thin_brown_panel_lines", baseColorFactor=rgba(0.28, 0.19, 0.12), metallicFactor=0.0, roughnessFactor=0.9),
	"robot_deep_gap": PBRMaterial(name="deep_recessed_panel_gaps", baseColorFactor=rgba(0.015, 0.014, 0.012), metallicFactor=0.0, roughnessFactor=0.95),
	"mila_jacket": PBRMaterial(name="mila_oversized_warm_jacket", baseColorFactor=rgba(0.88, 0.80, 0.58), metallicFactor=0.0, roughnessFactor=0.88),
	"mila_shadow": PBRMaterial(name="hoodie_shadow_corduroy", baseColorFactor=rgba(0.52, 0.42, 0.30), metallicFactor=0.0, roughnessFactor=0.92),
	"mila_skin": PBRMaterial(name="mila_skin_warm", baseColorFactor=rgba(0.86, 0.63, 0.48), metallicFactor=0.0, roughnessFactor=0.76),
	"mila_blush": PBRMaterial(name="mila_soft_blush", baseColorFactor=rgba(0.96, 0.47, 0.42), metallicFactor=0.0, roughnessFactor=0.78),
	"mila_hair": PBRMaterial(name="mila_chestnut_hair", baseColorFactor=rgba(0.20, 0.105, 0.055), metallicFactor=0.0, roughnessFactor=0.72),
	"mila_pants": PBRMaterial(name="mila_blue_pants", baseColorFactor=rgba(0.16, 0.28, 0.40), metallicFactor=0.0, roughnessFactor=0.86),
	"mila_boot": PBRMaterial(name="mila_dark_boots", baseColorFactor=rgba(0.08, 0.065, 0.055), metallicFactor=0.0, roughnessFactor=0.82),
	"mila_pack": PBRMaterial(name="brown_survival_backpack", baseColorFactor=rgba(0.36, 0.18, 0.09), metallicFactor=0.0, roughnessFactor=0.84),
	"mila_red": PBRMaterial(name="red_scarf_and_tags", baseColorFactor=rgba(0.86, 0.14, 0.10), metallicFactor=0.0, roughnessFactor=0.68),
	"mila_light": PBRMaterial(name="warm_flashlight_lens", baseColorFactor=rgba(1.0, 0.82, 0.42), emissiveFactor=[1.0, 0.7, 0.28], metallicFactor=0.0, roughnessFactor=0.28),
	"mila_teddy": PBRMaterial(name="small_teddy_charm", baseColorFactor=rgba(0.56, 0.33, 0.16), metallicFactor=0.0, roughnessFactor=0.9),
	"alien_body": PBRMaterial(name="alien_red_black_chitin", baseColorFactor=rgba(0.58, 0.045, 0.04), metallicFactor=0.0, roughnessFactor=0.64),
	"alien_dark": PBRMaterial(name="alien_dark_inner_chitin", baseColorFactor=rgba(0.055, 0.035, 0.04), metallicFactor=0.0, roughnessFactor=0.78),
	"alien_acid": PBRMaterial(name="alien_green_biolight", baseColorFactor=rgba(0.36, 1.0, 0.16), emissiveFactor=[0.18, 1.0, 0.08], metallicFactor=0.0, roughnessFactor=0.2),
	"alien_bone": PBRMaterial(name="alien_raw_edge_plates", baseColorFactor=rgba(0.82, 0.30, 0.20), metallicFactor=0.0, roughnessFactor=0.72),
	"drone_red": PBRMaterial(name="destroyer_drone_red_armor", baseColorFactor=rgba(0.82, 0.09, 0.07), metallicFactor=0.35, roughnessFactor=0.48),
	"drone_black": PBRMaterial(name="destroyer_drone_black_frame", baseColorFactor=rgba(0.035, 0.04, 0.045), metallicFactor=0.5, roughnessFactor=0.52),
	"drone_steel": PBRMaterial(name="destroyer_drone_gunmetal", baseColorFactor=rgba(0.34, 0.37, 0.38), metallicFactor=0.55, roughnessFactor=0.42),
	"drone_orange": PBRMaterial(name="destroyer_drone_warning_light", baseColorFactor=rgba(1.0, 0.34, 0.06), emissiveFactor=[1.0, 0.20, 0.0], metallicFactor=0.0, roughnessFactor=0.28),
}


def transform(pos: tuple[float, float, float], rot: tuple[float, float, float] = (0.0, 0.0, 0.0), scale: tuple[float, float, float] = (1.0, 1.0, 1.0), align_axis: str | None = None) -> np.ndarray:
	scale_matrix = np.diag([scale[0], scale[1], scale[2], 1.0])
	if align_axis == "y":
		align = euler_matrix(math.radians(-90.0), 0.0, 0.0)
	elif align_axis == "x":
		align = euler_matrix(0.0, math.radians(90.0), 0.0)
	else:
		align = identity_matrix()

	rotation = euler_matrix(math.radians(rot[0]), math.radians(rot[1]), math.radians(rot[2]))
	return translation_matrix(pos) @ rotation @ align @ scale_matrix


def add(scene: trimesh.Scene, mesh: trimesh.Trimesh, name: str, material: PBRMaterial, matrix: np.ndarray | None = None) -> None:
	mesh.metadata["name"] = name
	mesh.visual.material = material
	scene.add_geometry(mesh, node_name=name, geom_name=name, transform=matrix)


def ellipsoid(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], size: tuple[float, float, float], material: PBRMaterial, rot: tuple[float, float, float] = (0.0, 0.0, 0.0), segments: tuple[int, int] = (48, 24)) -> None:
	mesh = trimesh.creation.uv_sphere(radius=0.5, count=segments)
	add(scene, mesh, name, material, transform(pos, rot, size))


def sphere(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], radius: float, material: PBRMaterial, segments: tuple[int, int] = (40, 20)) -> None:
	mesh = trimesh.creation.uv_sphere(radius=radius, count=segments)
	add(scene, mesh, name, material, transform(pos))


def capsule(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], radius: float, height: float, material: PBRMaterial, axis: str = "y", rot: tuple[float, float, float] = (0.0, 0.0, 0.0), count: tuple[int, int] = (32, 16)) -> None:
	mesh = trimesh.creation.capsule(height=height, radius=radius, count=count)
	add(scene, mesh, name, material, transform(pos, rot, align_axis=axis))


def cylinder(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], radius: float, height: float, material: PBRMaterial, axis: str = "y", rot: tuple[float, float, float] = (0.0, 0.0, 0.0), sections: int = 48) -> None:
	mesh = trimesh.creation.cylinder(radius=radius, height=height, sections=sections)
	add(scene, mesh, name, material, transform(pos, rot, align_axis=axis))


def cone(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], radius: float, height: float, material: PBRMaterial, axis: str = "y", rot: tuple[float, float, float] = (0.0, 0.0, 0.0), sections: int = 40) -> None:
	mesh = trimesh.creation.cone(radius=radius, height=height, sections=sections)
	add(scene, mesh, name, material, transform(pos, rot, align_axis=axis))


def rounded_box(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], size: tuple[float, float, float], material: PBRMaterial, rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> None:
	mesh = trimesh.creation.box(extents=size)
	add(scene, mesh, name, material, transform(pos, rot))


def torus(scene: trimesh.Scene, name: str, pos: tuple[float, float, float], major: float, minor: float, material: PBRMaterial, rot: tuple[float, float, float] = (0.0, 0.0, 0.0)) -> None:
	mesh = trimesh.creation.torus(major_radius=major, minor_radius=minor, major_sections=64, minor_sections=16)
	add(scene, mesh, name, material, transform(pos, rot))


def export(scene: trimesh.Scene, filename: str) -> None:
	OUT_DIR.mkdir(parents=True, exist_ok=True)
	out_path = OUT_DIR / filename
	out_path.write_bytes(scene.export(file_type="glb"))
	print(f"wrote {out_path.relative_to(ROOT_DIR)}")


def build_robot() -> None:
	s = trimesh.Scene()
	shell = MATERIALS["robot_shell"]
	shadow = MATERIALS["robot_shadow"]
	dark = MATERIALS["robot_dark"]
	trim = MATERIALS["robot_trim"]
	amber = MATERIALS["robot_amber"]
	cyan = MATERIALS["robot_cyan"]

	capsule(s, "PelvisFrame", (0.0, 0.62, 0.02), 0.24, 0.82, shadow, axis="x")
	capsule(s, "LowerTorsoArmor", (0.0, 0.88, 0.0), 0.30, 0.56, shell)
	ellipsoid(s, "UpperChestArmor", (0.0, 1.18, -0.02), (0.94, 0.60, 0.52), shell)
	ellipsoid(s, "ChestDarkInset", (0.0, 1.15, -0.285), (0.58, 0.34, 0.035), dark)
	ellipsoid(s, "LeftPectoralRoundedPlate", (-0.33, 1.21, -0.26), (0.28, 0.36, 0.08), trim, rot=(0, 0, -6))
	ellipsoid(s, "RightPectoralRoundedPlate", (0.33, 1.21, -0.26), (0.28, 0.36, 0.08), trim, rot=(0, 0, 6))
	torus(s, "CoreOuterRing", (0.0, 1.16, -0.33), 0.205, 0.025, trim)
	torus(s, "CoreAmberInnerRing", (0.0, 1.16, -0.345), 0.108, 0.015, amber)
	ellipsoid(s, "HeartCoreGlass", (0.0, 1.16, -0.36), (0.26, 0.26, 0.055), cyan)
	capsule(s, "CoreGuardTop", (0.0, 1.38, -0.33), 0.035, 0.46, shadow, axis="x")
	capsule(s, "CoreGuardBottom", (0.0, 0.94, -0.33), 0.035, 0.46, shadow, axis="x")
	capsule(s, "NeckJoint", (0.0, 1.47, 0.0), 0.12, 0.18, dark)

	ellipsoid(s, "HeadShell", (0.0, 1.70, 0.0), (0.76, 0.50, 0.58), shell)
	ellipsoid(s, "HeadTopDome", (0.0, 1.88, 0.03), (0.56, 0.24, 0.44), trim)
	capsule(s, "HelmetBrow", (0.0, 1.84, -0.16), 0.055, 0.74, trim, axis="x")
	ellipsoid(s, "FacePlate", (0.0, 1.69, -0.315), (0.62, 0.24, 0.04), dark)
	ellipsoid(s, "VisorGlow", (0.0, 1.70, -0.355), (0.46, 0.105, 0.025), cyan)
	sphere(s, "LeftVisorPixel", (-0.15, 1.705, -0.375), 0.036, trim)
	sphere(s, "RightVisorPixel", (0.15, 1.705, -0.375), 0.036, trim)
	ellipsoid(s, "LeftCheekArmor", (-0.35, 1.61, -0.22), (0.20, 0.22, 0.18), shadow)
	ellipsoid(s, "RightCheekArmor", (0.35, 1.61, -0.22), (0.20, 0.22, 0.18), shadow)
	cylinder(s, "LeftAudioSensor", (-0.43, 1.70, -0.02), 0.105, 0.09, shadow, axis="x")
	cylinder(s, "RightAudioSensor", (0.43, 1.70, -0.02), 0.105, 0.09, shadow, axis="x")
	capsule(s, "LeftHelmetEarFin", (-0.52, 1.83, 0.03), 0.055, 0.32, trim, axis="y", rot=(0, 0, -22))
	capsule(s, "RightHelmetEarFin", (0.52, 1.83, 0.03), 0.055, 0.32, trim, axis="y", rot=(0, 0, 22))
	cylinder(s, "AntennaStem", (0.24, 2.04, 0.05), 0.021, 0.34, dark)
	sphere(s, "AntennaTip", (0.24, 2.23, 0.05), 0.06, amber)

	for side, sign in [("Left", -1.0), ("Right", 1.0)]:
		capsule(s, f"{side}ShoulderBlock", (sign * 0.65, 1.22, 0.0), 0.17, 0.40, shadow, axis="z")
		ellipsoid(s, f"{side}ShoulderIvoryCap", (sign * 0.78, 1.22, -0.03), (0.26, 0.23, 0.30), shell, rot=(0, 0, -8 * sign))
		sphere(s, f"{side}ShoulderLamp", (sign * 0.65, 1.36, -0.23), 0.062, amber)
		sphere(s, f"{side}UpperArmJoint", (sign * 0.77, 1.0, 0.0), 0.13, dark)
		capsule(s, f"{side}ForearmArmor", (sign * 0.82, 0.77, -0.03), 0.135, 0.50, shell)
		capsule(s, f"{side}ForearmDarkRail", (sign * 0.82, 0.79, -0.17), 0.028, 0.46, dark)
		capsule(s, f"{side}WristClamp", (sign * 0.82, 0.50, -0.04), 0.08, 0.27, shadow, axis="z")

	capsule(s, "LeftHandPincerA", (-0.90, 0.39, -0.12), 0.038, 0.20, dark, axis="y", rot=(18, 0, -12))
	capsule(s, "LeftHandPincerB", (-0.74, 0.39, -0.12), 0.038, 0.20, dark, axis="y", rot=(18, 0, 12))
	cylinder(s, "RightBlasterBarrel", (0.82, 0.47, -0.34), 0.072, 0.52, dark, axis="z")
	cylinder(s, "RightBlasterMuzzleGlow", (0.82, 0.47, -0.62), 0.085, 0.04, cyan, axis="z")
	capsule(s, "RightBlasterUpperRail", (0.82, 0.56, -0.36), 0.025, 0.42, shadow, axis="z")

	capsule(s, "BackpackMain", (0.0, 1.12, 0.36), 0.21, 0.76, shadow)
	capsule(s, "BackpackBatteryLeft", (-0.22, 1.13, 0.51), 0.07, 0.60, dark)
	capsule(s, "BackpackBatteryRight", (0.22, 1.13, 0.51), 0.07, 0.60, dark)
	cylinder(s, "BackpackCoolantPipeTop", (0.0, 1.47, 0.54), 0.03, 0.50, cyan, axis="x")
	cylinder(s, "BackpackCoolantPipeBottom", (0.0, 0.80, 0.54), 0.028, 0.50, cyan, axis="x")
	sphere(s, "BackpackAmberStatusLeft", (-0.18, 1.38, 0.57), 0.045, amber)
	sphere(s, "BackpackAmberStatusRight", (0.18, 1.38, 0.57), 0.045, amber)

	for side, sign in [("Left", -1.0), ("Right", 1.0)]:
		sphere(s, f"{side}HipJoint", (sign * 0.28, 0.52, 0.0), 0.13, dark)
		capsule(s, f"{side}ThighPlate", (sign * 0.28, 0.31, 0.02), 0.135, 0.42, shell)
		capsule(s, f"{side}ThighSideRail", (sign * 0.39, 0.32, -0.05), 0.028, 0.33, shadow, rot=(0, 0, -8 * sign))
		capsule(s, f"{side}KneePad", (sign * 0.28, 0.22, -0.18), 0.065, 0.26, shadow, axis="x")
		capsule(s, f"{side}Foot", (sign * 0.28, 0.06, -0.10), 0.11, 0.50, dark, axis="z")
		ellipsoid(s, f"{side}ToeLight", (sign * 0.28, 0.105, -0.37), (0.16, 0.04, 0.035), amber)

	export(s, "robot_ai.glb")


def build_robot_showcase() -> None:
	s = trimesh.Scene()
	ivory = MATERIALS["robot_worn_ivory"]
	dark = MATERIALS["robot_warm_black"]
	line = MATERIALS["robot_panel_line"]
	gap = MATERIALS["robot_deep_gap"]
	amber = MATERIALS["robot_showcase_amber"]
	trim = MATERIALS["robot_trim"]
	shadow = MATERIALS["robot_shadow"]

	# Feet and legs: broad, toy-like proportions with layered armor plates.
	for side, sign in [("Left", -1.0), ("Right", 1.0)]:
		capsule(s, f"{side}FootBase", (sign * 0.32, 0.09, -0.14), 0.13, 0.62, dark, axis="z")
		ellipsoid(s, f"{side}FootIvoryToe", (sign * 0.32, 0.15, -0.35), (0.34, 0.16, 0.30), ivory)
		ellipsoid(s, f"{side}FootTopLayerPlate", (sign * 0.32, 0.27, -0.36), (0.26, 0.055, 0.22), ivory)
		capsule(s, f"{side}FootToePanelLine", (sign * 0.32, 0.30, -0.52), 0.010, 0.22, line, axis="x")
		capsule(s, f"{side}FootSoleDarkLayer", (sign * 0.32, 0.05, -0.22), 0.055, 0.62, gap, axis="z")
		capsule(s, f"{side}AnkleBlackPistonA", (sign * 0.22, 0.32, -0.02), 0.035, 0.36, dark, rot=(0, 0, -7 * sign))
		capsule(s, f"{side}AnkleBlackPistonB", (sign * 0.43, 0.32, -0.02), 0.035, 0.34, dark, rot=(0, 0, 7 * sign))
		cylinder(s, f"{side}AnkleSideDiscOuter", (sign * 0.52, 0.35, -0.05), 0.12, 0.055, dark, axis="x")
		cylinder(s, f"{side}AnkleSideDiscAmber", (sign * 0.555, 0.35, -0.05), 0.062, 0.025, amber, axis="x")
		ellipsoid(s, f"{side}ShinArmorLower", (sign * 0.32, 0.64, -0.02), (0.30, 0.46, 0.25), ivory)
		ellipsoid(s, f"{side}ShinArmorUpper", (sign * 0.31, 1.02, -0.02), (0.34, 0.48, 0.27), ivory)
		ellipsoid(s, f"{side}ShinRaisedFrontPlate", (sign * 0.31, 0.92, -0.22), (0.22, 0.32, 0.055), ivory)
		capsule(s, f"{side}ShinPanelLineA", (sign * 0.32, 0.86, -0.16), 0.014, 0.45, line, rot=(0, 0, -3 * sign))
		capsule(s, f"{side}ShinPanelLineB", (sign * 0.42, 0.76, -0.14), 0.010, 0.28, line, rot=(0, 0, 18 * sign))
		cylinder(s, f"{side}KneeBlackRing", (sign * 0.31, 1.33, -0.10), 0.18, 0.09, dark, axis="x")
		cylinder(s, f"{side}KneeIvoryCap", (sign * 0.35, 1.33, -0.11), 0.12, 0.04, ivory, axis="x")
		cylinder(s, f"{side}KneeAmberDot", (sign * 0.385, 1.33, -0.11), 0.045, 0.025, amber, axis="x")
		ellipsoid(s, f"{side}ThighOuterArmor", (sign * 0.35, 1.65, -0.02), (0.44, 0.58, 0.34), ivory)
		ellipsoid(s, f"{side}ThighInnerBlackGap", (sign * 0.18, 1.66, -0.03), (0.18, 0.48, 0.26), dark)
		ellipsoid(s, f"{side}ThighRaisedKitePlate", (sign * 0.38, 1.72, -0.28), (0.22, 0.34, 0.06), ivory, rot=(0, 0, 8 * sign))
		capsule(s, f"{side}ThighPanelLine", (sign * 0.36, 1.70, -0.23), 0.014, 0.42, line, rot=(0, 0, 10 * sign))
		cylinder(s, f"{side}HipBlackRing", (sign * 0.36, 2.02, -0.02), 0.20, 0.12, dark, axis="x")
		cylinder(s, f"{side}HipIvoryCap", (sign * 0.43, 2.02, -0.02), 0.13, 0.05, ivory, axis="x")

	# Pelvis and abdomen.
	ellipsoid(s, "PelvisIvoryCup", (0.0, 2.05, -0.01), (0.76, 0.34, 0.40), ivory)
	capsule(s, "PelvisLowerDarkSeal", (0.0, 1.88, -0.03), 0.055, 0.58, dark, axis="x")
	for i, y in enumerate([2.22, 2.37, 2.52, 2.67]):
		ellipsoid(s, f"AbdomenDarkRib{i}", (0.0, y, -0.10), (0.58 - i * 0.045, 0.13, 0.20), dark)
		capsule(s, f"AbdomenIvorySeparator{i}", (0.0, y + 0.065, -0.18), 0.018, 0.42 - i * 0.035, line, axis="x")

	# Chest armor with heart core, matching the reference's friendly focal point.
	ellipsoid(s, "UpperChestIvoryShell", (0.0, 3.00, -0.03), (1.20, 0.72, 0.58), ivory)
	ellipsoid(s, "LeftChestRaisedPlate", (-0.42, 3.08, -0.32), (0.42, 0.44, 0.13), ivory, rot=(0, 0, -8))
	ellipsoid(s, "RightChestRaisedPlate", (0.42, 3.08, -0.32), (0.42, 0.44, 0.13), ivory, rot=(0, 0, 8))
	ellipsoid(s, "LeftUpperChestSmallInset", (-0.20, 3.34, -0.38), (0.20, 0.08, 0.035), gap, rot=(0, 0, 8))
	ellipsoid(s, "RightUpperChestSmallButton", (0.34, 3.30, -0.39), (0.12, 0.10, 0.035), shadow)
	cylinder(s, "RightUpperChestAmberDot", (0.34, 3.30, -0.42), 0.034, 0.018, amber, axis="z")
	ellipsoid(s, "ChestDarkInsetPlate", (0.0, 2.98, -0.39), (0.48, 0.44, 0.08), dark)
	torus(s, "HeartCoreOctoRing", (0.0, 2.98, -0.455), 0.205, 0.025, shadow)
	ellipsoid(s, "HeartCoreAmberTopLeft", (-0.055, 3.03, -0.49), (0.11, 0.12, 0.025), amber)
	ellipsoid(s, "HeartCoreAmberTopRight", (0.055, 3.03, -0.49), (0.11, 0.12, 0.025), amber)
	cone(s, "HeartCoreAmberPoint", (0.0, 2.91, -0.49), 0.13, 0.16, amber, axis="y", rot=(180, 0, 45), sections=4)
	capsule(s, "ChestTopPanelLine", (0.0, 3.38, -0.33), 0.018, 0.72, line, axis="x")
	capsule(s, "LeftChestPanelLine", (-0.48, 3.02, -0.40), 0.014, 0.34, line, rot=(0, 0, -26))
	capsule(s, "RightChestPanelLine", (0.48, 3.02, -0.40), 0.014, 0.34, line, rot=(0, 0, 26))
	cylinder(s, "TinyAmberChestLightLeft", (-0.62, 2.88, -0.39), 0.035, 0.025, amber, axis="z")
	cylinder(s, "TinyAmberChestLightRight", (0.62, 2.88, -0.39), 0.035, 0.025, amber, axis="z")

	# Backpack and neck.
	capsule(s, "NeckBlackStackA", (0.0, 3.46, -0.02), 0.18, 0.20, dark)
	capsule(s, "NeckBlackStackB", (0.0, 3.58, -0.02), 0.16, 0.18, dark)
	ellipsoid(s, "BackpackRoundedMain", (0.0, 3.02, 0.48), (0.58, 0.92, 0.30), shadow)
	capsule(s, "BackpackTopHandle", (0.0, 3.72, 0.56), 0.055, 0.58, dark, axis="x")
	capsule(s, "BackpackRightLightSlot", (0.40, 3.12, 0.28), 0.030, 0.42, amber)
	cylinder(s, "BackpackAntennaStem", (0.54, 4.33, 0.30), 0.025, 0.58, dark)
	sphere(s, "BackpackAntennaTip", (0.54, 4.66, 0.30), 0.052, amber)

	# Head: large rounded helmet, black visor, amber face.
	ellipsoid(s, "HelmetLargeIvoryDome", (0.0, 4.02, -0.02), (1.12, 0.82, 0.78), ivory)
	ellipsoid(s, "HelmetLowerJawIvory", (0.0, 3.80, -0.08), (1.00, 0.40, 0.66), ivory)
	ellipsoid(s, "HelmetLeftCheekRaisedArmor", (-0.48, 3.82, -0.35), (0.22, 0.20, 0.08), ivory, rot=(0, 0, -16))
	ellipsoid(s, "HelmetRightCheekRaisedArmor", (0.48, 3.82, -0.35), (0.22, 0.20, 0.08), ivory, rot=(0, 0, 16))
	ellipsoid(s, "VisorBlackGlass", (0.0, 4.02, -0.49), (0.88, 0.38, 0.08), dark)
	capsule(s, "VisorAmberEyeLeft", (-0.27, 4.04, -0.545), 0.055, 0.24, amber)
	capsule(s, "VisorAmberEyeRight", (0.27, 4.04, -0.545), 0.055, 0.24, amber)
	capsule(s, "VisorAmberMouth", (0.0, 3.82, -0.555), 0.018, 0.18, amber, axis="x")
	ellipsoid(s, "HelmetTopPanel", (0.0, 4.45, -0.04), (0.42, 0.12, 0.28), trim)
	capsule(s, "HelmetTopPanelLineA", (-0.18, 4.48, -0.12), 0.010, 0.24, line, rot=(0, 0, -18))
	capsule(s, "HelmetTopPanelLineB", (0.18, 4.48, -0.12), 0.010, 0.24, line, rot=(0, 0, 18))
	capsule(s, "HelmetBrowPanelLine", (0.0, 4.25, -0.52), 0.014, 0.74, line, axis="x")
	capsule(s, "HelmetLeftVerticalSeam", (-0.46, 4.23, -0.37), 0.010, 0.33, line, rot=(0, 0, -14))
	capsule(s, "HelmetRightVerticalSeam", (0.46, 4.23, -0.37), 0.010, 0.33, line, rot=(0, 0, 14))
	capsule(s, "HelmetLeftLowerSeam", (-0.38, 3.66, -0.42), 0.010, 0.28, line, rot=(0, 0, 26))
	capsule(s, "HelmetRightLowerSeam", (0.38, 3.66, -0.42), 0.010, 0.28, line, rot=(0, 0, -26))
	for i, x in enumerate([-0.32, -0.16, 0.16, 0.32]):
		capsule(s, f"HelmetTinyBrowNotch{i}", (x, 4.305, -0.54), 0.007, 0.08, line, axis="y")
	cylinder(s, "LeftEarDarkRing", (-0.62, 4.02, -0.02), 0.24, 0.12, dark, axis="x")
	cylinder(s, "RightEarDarkRing", (0.62, 4.02, -0.02), 0.24, 0.12, dark, axis="x")
	cylinder(s, "LeftEarIvoryCap", (-0.70, 4.02, -0.02), 0.18, 0.06, ivory, axis="x")
	cylinder(s, "RightEarIvoryCap", (0.70, 4.02, -0.02), 0.18, 0.06, ivory, axis="x")
	cylinder(s, "LeftEarAmberRing", (-0.735, 4.02, -0.02), 0.115, 0.025, amber, axis="x")
	cylinder(s, "RightEarAmberRing", (0.735, 4.02, -0.02), 0.115, 0.025, amber, axis="x")

	# Arms, hands, and detailed finger silhouette.
	for side, sign in [("Left", -1.0), ("Right", 1.0)]:
		cylinder(s, f"{side}ShoulderBlackRing", (sign * 0.86, 3.22, -0.02), 0.25, 0.16, dark, axis="x")
		ellipsoid(s, f"{side}ShoulderIvoryArmor", (sign * 1.00, 3.20, -0.05), (0.40, 0.42, 0.36), ivory)
		cylinder(s, f"{side}ShoulderAmberDisc", (sign * 1.17, 3.20, -0.10), 0.105, 0.035, amber, axis="x")
		torus(s, f"{side}ShoulderAmberOuterRing", (sign * 1.18, 3.20, -0.10), 0.13, 0.012, line, rot=(0, 90, 0))
		capsule(s, f"{side}ShoulderTopSeam", (sign * 1.00, 3.42, -0.14), 0.011, 0.25, line, axis="x")
		capsule(s, f"{side}UpperArmDarkPistonA", (sign * 0.98, 2.83, -0.02), 0.052, 0.46, dark, rot=(0, 0, 4 * sign))
		capsule(s, f"{side}UpperArmDarkPistonB", (sign * 1.12, 2.82, -0.02), 0.045, 0.40, dark, rot=(0, 0, -5 * sign))
		ellipsoid(s, f"{side}ForearmIvoryMain", (sign * 1.02, 2.42, -0.05), (0.34, 0.62, 0.28), ivory, rot=(0, 0, 6 * sign))
		ellipsoid(s, f"{side}ForearmRaisedOuterPanel", (sign * 1.12, 2.44, -0.20), (0.15, 0.42, 0.05), ivory, rot=(0, 0, 6 * sign))
		capsule(s, f"{side}ForearmPanelLineA", (sign * 1.02, 2.42, -0.25), 0.012, 0.42, line, rot=(0, 0, 5 * sign))
		capsule(s, f"{side}ForearmPanelLineB", (sign * 0.90, 2.48, -0.23), 0.010, 0.26, line, rot=(0, 0, -18 * sign))
		cylinder(s, f"{side}ElbowBlackRing", (sign * 1.02, 2.77, -0.02), 0.16, 0.12, dark, axis="x")
		cylinder(s, f"{side}WristBlackRing", (sign * 1.00, 2.06, -0.04), 0.13, 0.10, dark, axis="x")
		ellipsoid(s, f"{side}PalmDarkBlock", (sign * 1.00, 1.88, -0.07), (0.22, 0.18, 0.16), dark)
		for i, offset in enumerate([-0.12, -0.04, 0.04, 0.12]):
			capsule(s, f"{side}Finger{i}", (sign * (0.95 + offset * sign), 1.67, -0.13), 0.025, 0.24, dark, rot=(12, 0, 5 * sign))
			capsule(s, f"{side}Finger{i}Tip", (sign * (0.95 + offset * sign), 1.54, -0.15), 0.020, 0.12, dark, rot=(20, 0, 5 * sign))
			cylinder(s, f"{side}Finger{i}Knuckle", (sign * (0.95 + offset * sign), 1.73, -0.12), 0.028, 0.018, line, axis="y")
		capsule(s, f"{side}Thumb", (sign * 1.16, 1.80, -0.05), 0.030, 0.24, dark, rot=(42, 0, 32 * sign))
		capsule(s, f"{side}ThumbTip", (sign * 1.23, 1.66, -0.12), 0.023, 0.13, dark, rot=(52, 0, 38 * sign))
		cylinder(s, f"{side}ForearmTinyAmberSlot", (sign * 1.07, 2.48, -0.25), 0.030, 0.025, amber, axis="z")

	# Small scratches and surface breaks sell the worn art reference without texture maps.
	for i, (x, y, z, rot_z, length) in enumerate([
		(-0.25, 4.30, -0.48, -18, 0.16), (0.36, 4.23, -0.50, 22, 0.14),
		(-0.42, 3.18, -0.43, 30, 0.18), (0.34, 2.82, -0.46, -18, 0.16),
		(-0.35, 1.66, -0.26, -12, 0.14), (0.32, 1.06, -0.22, 18, 0.16),
		(-1.03, 2.45, -0.28, 10, 0.13), (1.04, 2.42, -0.28, -10, 0.13),
	]):
		capsule(s, f"PaintScratch{i}", (x, y, z), 0.006, length, line, axis="x", rot=(0, 0, rot_z))

	export(s, "robot_showcase.glb")


def build_mila() -> None:
	s = trimesh.Scene()
	jacket = MATERIALS["mila_jacket"]
	shadow = MATERIALS["mila_shadow"]
	skin = MATERIALS["mila_skin"]
	blush = MATERIALS["mila_blush"]
	hair = MATERIALS["mila_hair"]
	pants = MATERIALS["mila_pants"]
	boot = MATERIALS["mila_boot"]
	pack = MATERIALS["mila_pack"]
	red = MATERIALS["mila_red"]
	light = MATERIALS["mila_light"]
	teddy = MATERIALS["mila_teddy"]
	dark = MATERIALS["robot_dark"]

	ellipsoid(s, "OversizedJacketBody", (0.0, 0.72, 0.0), (0.58, 0.72, 0.42), jacket)
	capsule(s, "JacketLowerHem", (0.0, 0.43, -0.01), 0.07, 0.64, shadow, axis="x")
	capsule(s, "SoftJacketCollar", (0.0, 1.01, -0.09), 0.06, 0.54, shadow, axis="x")
	capsule(s, "RedScarfWrap", (0.0, 0.99, -0.18), 0.043, 0.48, red, axis="x")
	capsule(s, "RedScarfTail", (0.16, 0.83, -0.23), 0.034, 0.28, red, rot=(18, 0, -18))
	ellipsoid(s, "HoodBack", (0.0, 1.04, 0.16), (0.50, 0.32, 0.22), shadow)
	capsule(s, "LeftSleeve", (-0.37, 0.74, -0.02), 0.095, 0.50, jacket, rot=(0, 0, 6))
	capsule(s, "RightSleeve", (0.37, 0.74, -0.02), 0.095, 0.50, jacket, rot=(0, 0, -6))
	capsule(s, "LeftCuff", (-0.43, 0.51, -0.06), 0.05, 0.18, shadow, axis="x")
	capsule(s, "RightCuff", (0.43, 0.51, -0.06), 0.05, 0.18, shadow, axis="x")
	sphere(s, "LeftHand", (-0.43, 0.48, -0.08), 0.072, skin)
	sphere(s, "RightHand", (0.43, 0.48, -0.08), 0.072, skin)
	rounded_box(s, "ZipperStrip", (0.0, 0.74, -0.212), (0.035, 0.5, 0.022), dark)
	ellipsoid(s, "SmallNamePatch", (-0.18, 0.9, -0.23), (0.14, 0.075, 0.022), MATERIALS["robot_cyan"])
	ellipsoid(s, "EmergencyPatch", (0.18, 0.64, -0.23), (0.11, 0.09, 0.022), red)

	sphere(s, "Head", (0.0, 1.18, -0.02), 0.22, skin)
	ellipsoid(s, "SmallNose", (0.0, 1.15, -0.235), (0.045, 0.035, 0.03), skin)
	sphere(s, "LeftCheek", (-0.115, 1.14, -0.19), 0.04, blush)
	sphere(s, "RightCheek", (0.115, 1.14, -0.19), 0.04, blush)
	ellipsoid(s, "LeftEye", (-0.065, 1.20, -0.235), (0.036, 0.042, 0.014), dark)
	ellipsoid(s, "RightEye", (0.065, 1.20, -0.235), (0.036, 0.042, 0.014), dark)
	ellipsoid(s, "TinyMouth", (0.0, 1.095, -0.238), (0.085, 0.018, 0.014), dark)
	ellipsoid(s, "HairCap", (0.0, 1.34, -0.02), (0.46, 0.22, 0.38), hair)
	capsule(s, "MessyBangA", (-0.12, 1.27, -0.205), 0.04, 0.22, hair, rot=(0, 0, -12))
	capsule(s, "MessyBangB", (0.03, 1.27, -0.22), 0.043, 0.24, hair, rot=(0, 0, 9))
	capsule(s, "MessyBangC", (0.17, 1.25, -0.195), 0.037, 0.18, hair, rot=(0, 0, 18))
	capsule(s, "MessyBangD", (-0.22, 1.23, -0.16), 0.034, 0.18, hair, rot=(0, 0, -28))
	capsule(s, "LeftSideHair", (-0.24, 1.18, 0.0), 0.052, 0.28, hair)
	capsule(s, "RightSideHair", (0.24, 1.18, 0.0), 0.052, 0.26, hair)
	sphere(s, "LeftHairBun", (-0.26, 1.32, 0.05), 0.09, hair)
	sphere(s, "RightHairBun", (0.26, 1.32, 0.05), 0.09, hair)
	capsule(s, "LeftHairTie", (-0.27, 1.28, -0.02), 0.023, 0.15, red, axis="x")
	capsule(s, "RightHairTie", (0.27, 1.28, -0.02), 0.023, 0.15, red, axis="x")

	capsule(s, "LeftShortsLeg", (-0.13, 0.33, -0.01), 0.09, 0.26, pants)
	capsule(s, "RightShortsLeg", (0.13, 0.33, -0.01), 0.09, 0.26, pants)
	capsule(s, "LeftSock", (-0.13, 0.19, -0.01), 0.055, 0.18, skin)
	capsule(s, "RightSock", (0.13, 0.19, -0.01), 0.055, 0.18, skin)
	capsule(s, "LeftBoot", (-0.14, 0.08, -0.025), 0.08, 0.22, boot)
	capsule(s, "RightBoot", (0.14, 0.08, -0.025), 0.08, 0.22, boot)
	capsule(s, "LeftBootToe", (-0.14, 0.08, -0.16), 0.055, 0.20, boot, axis="z")
	capsule(s, "RightBootToe", (0.14, 0.08, -0.16), 0.055, 0.20, boot, axis="z")
	capsule(s, "LeftBootLace", (-0.14, 0.13, -0.13), 0.013, 0.16, jacket, axis="x")
	capsule(s, "RightBootLace", (0.14, 0.13, -0.13), 0.013, 0.16, jacket, axis="x")

	ellipsoid(s, "Backpack", (0.0, 0.73, 0.27), (0.44, 0.52, 0.22), pack)
	capsule(s, "BackpackTopRoll", (0.0, 1.01, 0.28), 0.06, 0.45, shadow, axis="x")
	rounded_box(s, "LeftBackpackStrap", (-0.18, 0.76, -0.215), (0.07, 0.52, 0.025), dark)
	rounded_box(s, "RightBackpackStrap", (0.18, 0.76, -0.215), (0.07, 0.52, 0.025), dark)
	sphere(s, "BackpackButtonLeft", (-0.15, 0.78, 0.47), 0.035, MATERIALS["robot_cyan"])
	sphere(s, "BackpackButtonRight", (0.15, 0.78, 0.47), 0.035, red)
	sphere(s, "TeddyHead", (-0.36, 0.68, 0.34), 0.075, teddy)
	sphere(s, "TeddyBody", (-0.36, 0.56, 0.34), 0.085, teddy)
	sphere(s, "TeddyEarLeft", (-0.42, 0.73, 0.34), 0.028, teddy)
	sphere(s, "TeddyEarRight", (-0.30, 0.73, 0.34), 0.028, teddy)
	capsule(s, "TeddyArm", (-0.36, 0.56, 0.25), 0.022, 0.13, teddy, axis="z")
	rounded_box(s, "FlashlightBody", (0.45, 0.75, -0.14), (0.11, 0.11, 0.34), dark)
	cylinder(s, "FlashlightLens", (0.45, 0.75, -0.34), 0.062, 0.045, light, axis="z")

	export(s, "mila_child.glb")


def build_alien() -> None:
	s = trimesh.Scene()
	body = MATERIALS["alien_body"]
	dark = MATERIALS["alien_dark"]
	acid = MATERIALS["alien_acid"]
	bone = MATERIALS["alien_bone"]

	ellipsoid(s, "AlienCranium", (0.0, 0.94, -0.08), (0.72, 0.52, 0.64), body)
	ellipsoid(s, "AlienMaw", (0.0, 0.80, -0.40), (0.42, 0.18, 0.20), dark)
	sphere(s, "LeftAlienEye", (-0.12, 0.99, -0.38), 0.05, acid)
	sphere(s, "RightAlienEye", (0.12, 0.99, -0.38), 0.05, acid)
	for i, x in enumerate([-0.16, -0.08, 0.0, 0.08, 0.16]):
		cone(s, f"AlienMawTooth{i}", (x, 0.73, -0.50), 0.018, 0.11, bone, axis="y", rot=(180, 0, 0))
	ellipsoid(s, "AlienRibBody", (0.0, 0.45, 0.02), (0.72, 0.55, 0.56), body)
	ellipsoid(s, "AlienBellyGlow", (0.0, 0.46, -0.29), (0.34, 0.28, 0.045), acid)
	for i, y in enumerate([0.70, 0.55, 0.40, 0.25]):
		capsule(s, f"AlienRibLeft{i}", (-0.22, y, -0.26), 0.025, 0.38, bone, axis="x", rot=(0, 12, -18))
		capsule(s, f"AlienRibRight{i}", (0.22, y, -0.26), 0.025, 0.38, bone, axis="x", rot=(0, -12, 18))
	for i, (y, z, size) in enumerate([(0.73, 0.34, 0.28), (0.54, 0.36, 0.34), (0.34, 0.32, 0.26), (0.18, 0.25, 0.20)]):
		cone(s, f"SpinePlate{i}", (0.0, y, z), 0.07, size, dark, axis="z", rot=(-18, 0, 0))
	capsule(s, "LeftClawUpper", (-0.42, 0.52, -0.18), 0.075, 0.46, dark, rot=(72, 0, -18))
	capsule(s, "RightClawUpper", (0.42, 0.52, -0.18), 0.075, 0.46, dark, rot=(72, 0, 18))
	capsule(s, "LeftClawTip", (-0.50, 0.44, -0.45), 0.05, 0.26, acid, rot=(70, 0, -18))
	capsule(s, "RightClawTip", (0.50, 0.44, -0.45), 0.05, 0.26, acid, rot=(70, 0, 18))
	capsule(s, "LeftHindLeg", (-0.28, 0.13, 0.18), 0.065, 0.42, dark, rot=(18, 0, -12))
	capsule(s, "RightHindLeg", (0.28, 0.13, 0.18), 0.065, 0.42, dark, rot=(18, 0, 12))
	capsule(s, "LeftFrontLeg", (-0.34, 0.16, -0.18), 0.052, 0.36, dark, rot=(52, 0, -28))
	capsule(s, "RightFrontLeg", (0.34, 0.16, -0.18), 0.052, 0.36, dark, rot=(52, 0, 28))
	capsule(s, "TailStub", (0.0, 0.30, 0.48), 0.08, 0.58, dark, axis="z", rot=(12, 0, 0))
	for i, x in enumerate([-0.32, -0.16, 0.16, 0.32]):
		sphere(s, f"AcidSac{i}", (x, 0.58, 0.20), 0.055, acid)

	export(s, "alien_threat.glb")


def build_drone() -> None:
	s = trimesh.Scene()
	red = MATERIALS["drone_red"]
	black = MATERIALS["drone_black"]
	steel = MATERIALS["drone_steel"]
	orange = MATERIALS["drone_orange"]

	sphere(s, "DroneCore", (0.0, 0.92, 0.0), 0.32, steel)
	ellipsoid(s, "DroneRedArmorTop", (0.0, 1.08, -0.03), (0.60, 0.20, 0.42), red)
	ellipsoid(s, "DroneRedArmorBottom", (0.0, 0.79, 0.02), (0.46, 0.14, 0.34), red)
	ellipsoid(s, "DroneSensorFace", (0.0, 0.94, -0.345), (0.34, 0.13, 0.035), orange)
	capsule(s, "DroneWingL", (-0.56, 0.94, 0.0), 0.07, 0.62, black, axis="x")
	capsule(s, "DroneWingR", (0.56, 0.94, 0.0), 0.07, 0.62, black, axis="x")
	torus(s, "LeftRotor", (-0.88, 0.99, 0.0), 0.20, 0.022, orange, rot=(90, 0, 0))
	torus(s, "RightRotor", (0.88, 0.99, 0.0), 0.20, 0.022, orange, rot=(90, 0, 0))
	rounded_box(s, "LeftRotorBladeA", (-0.88, 1.0, 0.0), (0.50, 0.025, 0.055), black)
	rounded_box(s, "LeftRotorBladeB", (-0.88, 1.0, 0.0), (0.055, 0.025, 0.50), black)
	rounded_box(s, "RightRotorBladeA", (0.88, 1.0, 0.0), (0.50, 0.025, 0.055), black)
	rounded_box(s, "RightRotorBladeB", (0.88, 1.0, 0.0), (0.055, 0.025, 0.50), black)
	capsule(s, "DroneStinger", (0.0, 0.75, -0.46), 0.052, 0.36, black, axis="z")
	cylinder(s, "DroneFrontGun", (0.0, 0.88, -0.54), 0.045, 0.34, black, axis="z")
	sphere(s, "DroneLeftWarningLight", (-0.24, 1.08, -0.22), 0.045, orange)
	sphere(s, "DroneRightWarningLight", (0.24, 1.08, -0.22), 0.045, orange)

	export(s, "drone_threat.glb")


def main() -> None:
	build_robot()
	build_robot_showcase()
	build_mila()
	build_alien()
	build_drone()


if __name__ == "__main__":
	main()
