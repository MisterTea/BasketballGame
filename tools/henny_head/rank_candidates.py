#!/usr/bin/env python3
"""Pick the head whose front matches the crop and whose back is not a face."""

import json
import os
import shutil
from pathlib import Path

os.environ.setdefault("PYTORCH_ENABLE_MPS_FALLBACK", "1")

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from skimage.metrics import structural_similarity
from transformers import SegformerForSemanticSegmentation, SegformerImageProcessor

ROOT = Path(__file__).resolve().parents[2]
CANDIDATES = ROOT / "tools" / "henny_head" / "candidates"
CROP = ROOT / "tools" / "henny_head" / "dataset" / "crop.png"
ASSET = ROOT / "assets" / "henny_head.glb"
EYE_LABELS = {4, 5}
MOUTH_LABELS = {10, 11, 12}


def candidate_dirs():
    found = []
    for seed in range(4):
        matches = list((CANDIDATES / f"seed{seed}").glob("*/0"))
        if not matches:
            raise FileNotFoundError(f"missing candidate for seed {seed}")
        found.append((seed, matches[0]))
    return found


def parse(image: Image.Image, processor, model, device) -> np.ndarray:
    inputs = processor(images=image.convert("RGB"), return_tensors="pt")
    inputs = {key: value.to(device) for key, value in inputs.items()}
    with torch.no_grad():
        logits = model(**inputs).logits
    logits = F.interpolate(logits, size=image.size[::-1], mode="bilinear", align_corners=False)
    return logits.argmax(1)[0].cpu().numpy()


def ssim_score(front: Image.Image, crop: Image.Image) -> float:
    size = (256, 256)
    left = np.asarray(front.convert("RGB").resize(size), dtype=np.float32) / 255.0
    right = np.asarray(crop.convert("RGB").resize(size), dtype=np.float32) / 255.0
    return float(structural_similarity(left, right, channel_axis=2, data_range=1.0))


def mirrored_face(labels: np.ndarray) -> bool:
    eyes = int(np.isin(labels, list(EYE_LABELS)).sum())
    mouth = int(np.isin(labels, list(MOUTH_LABELS)).sum())
    return eyes >= 150 and mouth >= 80


def main() -> None:
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    processor = SegformerImageProcessor.from_pretrained("jonathandinu/face-parsing")
    model = SegformerForSemanticSegmentation.from_pretrained("jonathandinu/face-parsing").to(device).eval()
    crop = Image.open(CROP)
    ranking = []
    for seed, folder in candidate_dirs():
        front = Image.open(folder / "front.png")
        back = Image.open(folder / "back.png")
        labels = parse(back, processor, model, device)
        entry = {
            "seed": seed,
            "ssim": ssim_score(front, crop),
            "mirrored_face": mirrored_face(labels),
            "glb": str((folder / "head.glb").relative_to(ROOT)),
        }
        ranking.append(entry)
        print(entry, flush=True)
    eligible = [entry for entry in ranking if not entry["mirrored_face"]]
    pool = eligible or ranking
    winner = max(pool, key=lambda entry: entry["ssim"])
    ASSET.parent.mkdir(parents=True, exist_ok=True)
    shutil.copyfile(ROOT / winner["glb"], ASSET)
    report = {"winner_seed": winner["seed"], "fell_back_to_mirrored": not eligible, "candidates": ranking}
    (CANDIDATES / "ranking.json").write_text(json.dumps(report, indent=2))
    print(f"winner seed {winner['seed']} -> {ASSET}", flush=True)


if __name__ == "__main__":
    main()
