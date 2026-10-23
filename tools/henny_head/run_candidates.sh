#!/usr/bin/env bash
# Four PanoHead inversions of the cropped portrait, on Metal.
set -euo pipefail
export PYTORCH_ENABLE_MPS_FALLBACK=1
ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
PY="$ROOT/tools/henny_head/.venv/bin/python"
cd "$ROOT/tools/henny_head/vendor/PanoHead"
if ! grep -q "torch.device('mps'" projector_withseg.py; then
  git apply "$ROOT/tools/henny_head/panohead_mps.patch"
fi
for seed in 0 1 2 3; do
  echo "=== seed ${seed} ==="
  "$PY" projector_withseg.py \
    --network "$ROOT/tools/henny_head/models/easy-khair-180-gpc0.8-trans10-025000.pkl" \
    --target_img "$ROOT/tools/henny_head/dataset" \
    --outdir "$ROOT/tools/henny_head/candidates/seed${seed}" \
    --num-steps 100 \
    --num-steps-pti 100 \
    --seed "$seed" \
    --save-video false \
    --shapes true \
    --idx 0
done
echo ALL_CANDIDATES_DONE
