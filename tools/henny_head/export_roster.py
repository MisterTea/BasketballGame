#!/usr/bin/env python3
"""Pick each roster inversion and export a head with the shoulder pieces removed."""

import io
import os
import sys
from pathlib import Path

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

import numpy as np
import torch
from PIL import Image
from skimage.metrics import structural_similarity

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / "tools" / "henny_head"))


def _load_from_bytes(b):
    return torch.load(io.BytesIO(b), map_location="cpu", weights_only=False)


torch.storage._load_from_bytes = _load_from_bytes

import render_candidates as rc
import trimesh

PEOPLE = ("gauci", "wang", "waters")
TARGET_HEIGHT = 0.445
SKULL_BOTTOM = -0.21


def seed_dirs(person: str):
    root = ROOT / "tools" / "henny_head" / "roster" / person
    found = []
    for seed in (0, 1):
        matches = list((root / f"seed{seed}").glob("*/0"))
        if matches:
            found.append((seed, matches[0]))
    if not found:
        raise FileNotFoundError(person)
    return found


def ssim(front: Image.Image, crop: Image.Image) -> float:
    size = (256, 256)
    left = np.asarray(front.convert("RGB").resize(size), dtype=np.float32) / 255.0
    right = np.asarray(crop.convert("RGB").resize(size), dtype=np.float32) / 255.0
    return float(structural_similarity(left, right, channel_axis=2, data_range=1.0))


def mirrored(back: Image.Image) -> bool:
    # A face on the back has two eyes and a mouth. Hair and ears do not.
    from crop_head import parse_labels
    labels = parse_labels(back.convert("RGB"), rc.DEVICE)
    eyes = int(np.isin(labels, [4, 5]).sum())
    mouth = int(np.isin(labels, [10, 11, 12]).sum())
    return eyes >= 150 and mouth >= 80


def fit_head(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    parts = mesh.split(only_watertight=False)
    head = max(parts, key=lambda part: len(part.faces))
    height = float(head.bounds[1, 1] - head.bounds[0, 1])
    head.apply_scale(TARGET_HEIGHT / height)
    lift = SKULL_BOTTOM - float(head.bounds[0, 1])
    center_x = float(head.bounds[:, 0].mean())
    center_z = float(head.bounds[:, 2].mean())
    head.apply_translation([-center_x, lift, -center_z])
    return head


def mesh_for(folder: Path, base) -> trimesh.Trimesh:
    generator = rc.load_generator(folder / "fintuned_generator.pkl")
    payload = np.load(folder / "projected_w.npz")
    latent = torch.from_numpy(payload["w"]).to(rc.DEVICE)
    if "c" in payload:
        front = torch.from_numpy(payload["c"]).to(device=rc.DEVICE, dtype=torch.float32)
    else:
        front = rc.frontal_camera(base)
    front_image = np.asarray(rc.render(generator, latent, front))
    Image.fromarray(front_image).save(folder / "front.png")
    back_image = np.asarray(rc.render(generator, latent, rc.camera(np.pi / 2 + np.pi)))
    Image.fromarray(back_image).save(folder / "back.png")
    volume, box = rc.density_grid(generator, latent, 192)
    mesh = rc.mesh_from_volume(volume, box)
    right = np.asarray(rc.render(generator, latent, rc.camera(np.pi)))
    left = np.asarray(rc.render(generator, latent, rc.camera(0.0)))
    mesh.visual = trimesh.visual.ColorVisuals(
        mesh=mesh,
        vertex_colors=rc.bake_colors(mesh, front_image, back_image, right, left),
    )
    return fit_head(mesh)


def main() -> None:
    base = rc.load_generator(ROOT / "tools" / "henny_head" / "models" / "easy-khair-180-gpc0.8-trans10-025000.pkl")
    for person in PEOPLE:
        crop = Image.open(ROOT / "tools" / "henny_head" / "roster" / person / "dataset" / "crop.png")
        ranked = []
        meshes = {}
        for seed, folder in seed_dirs(person):
            print(f"meshing {person} seed {seed}", flush=True)
            mesh = mesh_for(folder, base)
            meshes[seed] = mesh
            score = ssim(Image.open(folder / "front.png"), crop)
            bad = mirrored(Image.open(folder / "back.png"))
            ranked.append((score, bad, seed))
            print(f"  ssim {score:.3f} mirrored {bad} faces {len(mesh.faces)}", flush=True)
        eligible = [item for item in ranked if not item[1]] or ranked
        _score, _bad, winner = max(eligible)
        out = ROOT / "assets" / f"{person}_head.glb"
        meshes[winner].export(out)
        print(f"{person} winner seed {winner} -> {out}", flush=True)


if __name__ == "__main__":
    main()
