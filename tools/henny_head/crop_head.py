#!/usr/bin/env python3
"""Cut Eric's head out of EricH.png for PanoHead.

Keeps hair, face, and ears. Drops the neck, collar, shirt, shoulders, and backdrop,
then centers the head in a square on a flat background.
"""

import argparse
from pathlib import Path

import numpy as np
import torch
import torch.nn.functional as F
from PIL import Image
from scipy import ndimage
from transformers import SegformerForSemanticSegmentation, SegformerImageProcessor

# CelebAMask labels used by jonathandinu/face-parsing (BiSeNet-equivalent classes).
FACE = {1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 15}
KEEP = FACE | {13, 14}  # hair, hat
DROP = {0, 16, 17, 18}  # background, neck, neckline, cloth


def parse_labels(image: Image.Image, device: torch.device) -> np.ndarray:
    processor = SegformerImageProcessor.from_pretrained("jonathandinu/face-parsing")
    model = SegformerForSemanticSegmentation.from_pretrained("jonathandinu/face-parsing")
    model.to(device).eval()
    inputs = processor(images=image, return_tensors="pt")
    inputs = {key: value.to(device) for key, value in inputs.items()}
    with torch.no_grad():
        logits = model(**inputs).logits
    logits = F.interpolate(logits, size=image.size[::-1], mode="bilinear", align_corners=False)
    return logits.argmax(dim=1)[0].detach().cpu().numpy().astype(np.uint8)


def head_mask(labels: np.ndarray, chin_fraction: float) -> np.ndarray:
    keep = np.isin(labels, list(KEEP))
    face = np.isin(labels, list(FACE))
    rows = np.where(face.any(axis=1))[0]
    if rows.size == 0:
        raise RuntimeError("face parser found no face in the portrait")
    chin = int(rows.max())
    face_height = max(int(rows.max() - rows.min()), 1)
    # The neck is often labeled skin. Cut just under the chin so ears stay.
    cut = chin + max(4, int(chin_fraction * face_height))
    keep[cut:, :] = False
    keep[np.isin(labels, [0, 18])] = False
    keep = ndimage.binary_fill_holes(keep)
    # Drop the light fringe where the parser includes backdrop pixels along the hair.
    keep = ndimage.binary_erosion(keep, iterations=2)
    labeled, count = ndimage.label(keep)
    if count > 1:
        sizes = ndimage.sum(keep, labeled, range(1, count + 1))
        keep = labeled == (1 + int(np.argmax(sizes)))
    return keep


def square_crop(image: Image.Image, mask: np.ndarray, margin: float) -> Image.Image:
    ys, xs = np.where(mask)
    if ys.size == 0:
        raise RuntimeError("head mask is empty after the neck cut")
    y0, y1 = int(ys.min()), int(ys.max())
    x0, x1 = int(xs.min()), int(xs.max())
    height = y1 - y0 + 1
    width = x1 - x0 + 1
    side = int(max(height, width) * (1.0 + margin))
    cx = (x0 + x1) / 2.0
    cy = (y0 + y1) / 2.0
    left = int(round(cx - side / 2.0))
    top = int(round(cy - side / 2.0))
    rgb = np.array(image.convert("RGB"))
    canvas = np.full((side, side, 3), 196, dtype=np.uint8)
    alpha = np.zeros((side, side), dtype=np.uint8)
    src_y0 = max(0, top)
    src_x0 = max(0, left)
    src_y1 = min(rgb.shape[0], top + side)
    src_x1 = min(rgb.shape[1], left + side)
    dst_y0 = src_y0 - top
    dst_x0 = src_x0 - left
    dst_y1 = dst_y0 + (src_y1 - src_y0)
    dst_x1 = dst_x0 + (src_x1 - src_x0)
    region = mask[src_y0:src_y1, src_x0:src_x1]
    canvas[dst_y0:dst_y1, dst_x0:dst_x1][region] = rgb[src_y0:src_y1, src_x0:src_x1][region]
    alpha[dst_y0:dst_y1, dst_x0:dst_x1][region] = 255
    out = np.dstack([canvas, alpha])
    return Image.fromarray(out, "RGBA")


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--input", type=Path, default=Path("EricH.png"))
    parser.add_argument("--output", type=Path, default=Path("tools/henny_head/crop.png"))
    parser.add_argument("--size", type=int, default=512)
    parser.add_argument("--margin", type=float, default=0.12)
    parser.add_argument("--chin", type=float, default=0.12, help="extra jaw below the chin, as a fraction of face height")
    args = parser.parse_args()
    device = torch.device("mps" if torch.backends.mps.is_available() else "cpu")
    image = Image.open(args.input).convert("RGB")
    labels = parse_labels(image, device)
    mask = head_mask(labels, args.chin)
    cropped = square_crop(image, mask, args.margin).resize((args.size, args.size), Image.Resampling.LANCZOS)
    args.output.parent.mkdir(parents=True, exist_ok=True)
    cropped.save(args.output)
    print(f"wrote {args.output} on {device}")


if __name__ == "__main__":
    main()
