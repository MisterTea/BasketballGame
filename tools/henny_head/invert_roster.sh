#!/usr/bin/env bash
# Crop and invert Gauci, Wang, and Waters on Metal.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PY="$ROOT/tools/henny_head/.venv/bin/python"
PANO="$ROOT/tools/henny_head/vendor/PanoHead"
export PYTORCH_ENABLE_MPS_FALLBACK=1

crop() {
  local name="$1"
  local input="$2"
  local dir="$ROOT/tools/henny_head/roster/$name"
  mkdir -p "$dir/dataset"
  "$PY" "$ROOT/tools/henny_head/crop_head.py" --input "$ROOT/$input" --output "$dir/crop.png"
  "$PY" - << PY
from PIL import Image
Image.open("$dir/crop.png").convert("RGB").save("$dir/dataset/crop.png")
PY
  cp "$ROOT/tools/henny_head/dataset/dataset.json" "$dir/dataset/dataset.json"
}

crop gauci Gauci.jpg
crop wang Wang.png
crop waters KeriWaters.jpeg

cd "$PANO"
if ! grep -q "torch.device('mps'" projector_withseg.py; then
  git apply "$ROOT/tools/henny_head/panohead_mps.patch"
fi

for name in gauci wang waters; do
  for seed in 0 1; do
    echo "=== $name seed $seed ==="
    "$PY" projector_withseg.py \
      --network "$ROOT/tools/henny_head/models/easy-khair-180-gpc0.8-trans10-025000.pkl" \
      --target_img "$ROOT/tools/henny_head/roster/$name/dataset" \
      --outdir "$ROOT/tools/henny_head/roster/$name/seed${seed}" \
      --num-steps 100 \
      --num-steps-pti 100 \
      --seed "$seed" \
      --save-video false \
      --shapes false \
      --idx 0
  done
done
echo ROSTER_INVERSIONS_DONE
