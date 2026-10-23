#!/usr/bin/env python3
"""Render each inverted head and export a game-ready mesh.

Writes a front view, a back view, a turntable, and a GLB whose face points +Z
and whose height matches the low-poly skull (0.42).
"""

import io
import os
import sys
from pathlib import Path

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

import numpy as np
import torch
from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PANO = ROOT / "tools" / "henny_head" / "vendor" / "PanoHead"
sys.path.insert(0, str(PANO))

def _load_from_bytes(b):
    return torch.load(io.BytesIO(b), map_location="cpu", weights_only=False)

torch.storage._load_from_bytes = _load_from_bytes

import dnnlib
import legacy
from camera_utils import LookAtPoseSampler
from skimage.measure import marching_cubes
import trimesh

DEVICE = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
INTRINSICS = torch.tensor([[4.2647, 0, 0.5], [0, 4.2647, 0.5], [0, 0, 1]], dtype=torch.float32)
SKULL_HEIGHT = 0.42
SEED_COUNT = 4


def load_generator(path: Path):
    with dnnlib.util.open_url(str(path)) as handle:
        return legacy.load_network_pkl(handle)["G_ema"].to(DEVICE).eval()


def camera(yaw: float, pitch: float = np.pi / 2, radius: float = 2.7) -> torch.Tensor:
    lookat = torch.zeros(3, device=DEVICE)
    pose = LookAtPoseSampler.sample(yaw, pitch, lookat, radius=radius, device=DEVICE)
    intr = INTRINSICS.to(DEVICE)
    return torch.cat([pose.reshape(1, 16), intr.reshape(1, 9)], 1)


def frontal_camera(generator) -> torch.Tensor:
    # Match projector_withseg.project: one learned camera offset from the mean latent.
    base = camera(np.pi / 2)
    z_mean = np.random.RandomState(123).randn(512, generator.z_dim).mean(axis=0, keepdims=True)
    z_mean = torch.from_numpy(z_mean).to(device=DEVICE, dtype=torch.float32)
    delta = generator.t_mapping(z_mean, base, truncation_psi=1.0, truncation_cutoff=None, update_emas=False)
    delta = torch.squeeze(delta, 1)
    base = base.clone()
    base[:, 3] += delta[:, 0]
    base[:, 7] += delta[:, 1]
    base[:, 11] += delta[:, 2]
    return base


def render(generator, latent: torch.Tensor, cam: torch.Tensor) -> Image.Image:
    with torch.no_grad():
        image = generator.synthesis(latent, c=cam, noise_mode="const")["image"]
    image = (image[0].permute(1, 2, 0).clamp(-1, 1) * 127.5 + 127.5).to(torch.uint8).cpu().numpy()
    return Image.fromarray(image, "RGB")


def density_grid(generator, latent: torch.Tensor, resolution: int = 256):
    box = float(generator.rendering_kwargs["box_warp"])
    coords = torch.linspace(-box / 2, box / 2, resolution, device=DEVICE)
    z, y, x = torch.meshgrid(coords, coords, coords, indexing="ij")
    points = torch.stack([x, y, z], dim=-1).reshape(1, -1, 3)
    directions = torch.zeros_like(points)
    directions[..., 2] = -1
    sigmas = []
    batch = 250000
    with torch.no_grad():
        for start in range(0, points.shape[1], batch):
            out = generator.sample_mixed(
                points[:, start:start + batch],
                directions[:, start:start + batch],
                latent,
                truncation_psi=1,
                noise_mode="const",
            )
            sigmas.append(out["sigma"].reshape(-1).detach().cpu())
    volume = torch.cat(sigmas).reshape(resolution, resolution, resolution).numpy()
    return volume, box


def _content_box(image: np.ndarray):
    mask = image.max(axis=2) > 18
    ys, xs = np.where(mask)
    if ys.size == 0:
        height, width = image.shape[:2]
        return 0, 0, width - 1, height - 1
    return int(xs.min()), int(ys.min()), int(xs.max()), int(ys.max())


def _sample_image(image: np.ndarray, u: np.ndarray, v: np.ndarray) -> np.ndarray:
    x0, y0, x1, y1 = _content_box(image)
    px = np.clip(x0 + u * max(x1 - x0, 1), 0, image.shape[1] - 1).astype(np.int32)
    py = np.clip(y0 + (1.0 - v) * max(y1 - y0, 1), 0, image.shape[0] - 1).astype(np.int32)
    return image[py, px].astype(np.float64)


def bake_colors(mesh: trimesh.Trimesh, front: np.ndarray, back: np.ndarray, right: np.ndarray, left: np.ndarray) -> np.ndarray:
    # Paint each side from the render of that side. Mesh +Z is the face and +Y is up.
    bounds = mesh.bounds
    span = np.maximum(bounds[1] - bounds[0], 1e-6)
    unit = (mesh.vertices - bounds[0]) / span
    normals = mesh.vertex_normals
    accumulated = np.zeros((len(mesh.vertices), 3), dtype=np.float64)
    weight = np.zeros(len(mesh.vertices), dtype=np.float64)
    for axis, sign, image in (
        (2, 1.0, front),
        (2, -1.0, back),
        (0, 1.0, right),
        (0, -1.0, left),
    ):
        facing = normals[:, axis] * sign
        horizontal = unit[:, 0] if axis == 2 else unit[:, 2]
        if sign < 0 and axis == 2:
            horizontal = 1.0 - horizontal
        if sign > 0 and axis == 0:
            horizontal = 1.0 - horizontal
        sampled = _sample_image(image, horizontal, unit[:, 1])
        usable = sampled.max(axis=1) > 18
        view_weight = np.where((facing > 0.15) & usable, facing, 0.0)
        accumulated += sampled * view_weight[:, None]
        weight += view_weight
    colors = np.full((len(mesh.vertices), 4), 170, dtype=np.uint8)
    colors[:, 3] = 255
    covered = weight > 1e-6
    colors[covered, :3] = np.clip(accumulated[covered] / weight[covered, None], 0, 255)
    return colors


def mesh_from_volume(volume: np.ndarray, box: float) -> trimesh.Trimesh:
    finite = volume[np.isfinite(volume)]
    level = float(np.percentile(finite, 92))
    for candidate in (10.0, 5.0, 2.0, 1.0, 0.0, level):
        try:
            verts, faces, _normals, _values = marching_cubes(volume, level=candidate)
        except (ValueError, RuntimeError):
            continue
        if 2000 <= len(faces) <= 250000:
            level = candidate
            break
    else:
        verts, faces, _normals, _values = marching_cubes(volume, level=level)
    resolution = volume.shape[0]
    origin = -box / 2
    voxel = box / (resolution - 1)
    # volume axes are (z, y, x) from the meshgrid in density_grid.
    points = np.zeros_like(verts)
    points[:, 0] = origin + verts[:, 2] * voxel
    points[:, 1] = origin + verts[:, 1] * voxel
    points[:, 2] = origin + verts[:, 0] * voxel
    return trimesh.Trimesh(points, faces, process=False)


def fit_game_head(mesh: trimesh.Trimesh) -> trimesh.Trimesh:
    bounds = mesh.bounds
    height = float(bounds[1, 1] - bounds[0, 1])
    if height <= 1e-6:
        raise RuntimeError("extracted head has no height")
    mesh.apply_scale(SKULL_HEIGHT / height)
    center = mesh.bounds.mean(axis=0)
    mesh.apply_translation(-center)
    return mesh


def candidate_dir(seed: int) -> Path:
    root = ROOT / "tools" / "henny_head" / "candidates" / f"seed{seed}"
    matches = list(root.glob("*/0"))
    if not matches:
        raise FileNotFoundError(f"no inversion output for seed {seed}")
    return matches[0]


def export_candidate(seed: int, base_generator) -> None:
    folder = candidate_dir(seed)
    print(f"rendering seed {seed} from {folder}", flush=True)
    generator = load_generator(folder / "fintuned_generator.pkl")
    payload = np.load(folder / "projected_w.npz")
    latent = torch.from_numpy(payload["w"]).to(DEVICE)
    if "c" in payload:
        front = torch.from_numpy(payload["c"]).to(device=DEVICE, dtype=torch.float32)
    else:
        front = frontal_camera(base_generator)
    render(generator, latent, front).save(folder / "front.png")
    back_yaw = np.pi / 2 + np.pi
    render(generator, latent, camera(back_yaw)).save(folder / "back.png")
    frames = []
    for step in range(12):
        yaw = np.pi / 2 + step * (2 * np.pi / 12)
        frame = render(generator, latent, camera(yaw))
        frames.append(frame)
    strip = Image.new("RGB", (frames[0].width * len(frames), frames[0].height))
    for index, frame in enumerate(frames):
        strip.paste(frame, (index * frame.width, 0))
    strip.save(folder / "turntable.png")
    frames[0].save(folder / "turntable.gif", save_all=True, append_images=frames[1:], duration=120, loop=0)
    volume, box = density_grid(generator, latent, 256)
    mesh = mesh_from_volume(volume, box)
    print(f"raw bounds {mesh.bounds.tolist()}", flush=True)
    front_image = np.asarray(Image.open(folder / "front.png"))
    back_image = np.asarray(Image.open(folder / "back.png"))
    right_image = np.asarray(render(generator, latent, camera(np.pi / 2 + np.pi / 2)))
    left_image = np.asarray(render(generator, latent, camera(np.pi / 2 - np.pi / 2)))
    colors = bake_colors(mesh, front_image, back_image, right_image, left_image)
    mesh.visual = trimesh.visual.ColorVisuals(mesh=mesh, vertex_colors=colors)
    mesh = fit_game_head(mesh)
    mesh.export(folder / "head.glb")
    print(f"seed {seed}: {len(mesh.faces)} faces", flush=True)


def main() -> None:
    base = load_generator(ROOT / "tools" / "henny_head" / "models" / "easy-khair-180-gpc0.8-trans10-025000.pkl")
    for seed in range(SEED_COUNT):
        export_candidate(seed, base)


if __name__ == "__main__":
    main()
