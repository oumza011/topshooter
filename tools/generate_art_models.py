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
	build_mila()
	build_alien()
	build_drone()


if __name__ == "__main__":
	main()
