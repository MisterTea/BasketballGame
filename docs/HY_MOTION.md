# Local HY-Motion 1.0 player animations

## What was actually run

Eleven motions were generated locally with Tencent's **standard HY-Motion-1.0 model (1B)**, not Lite and not placeholder motion. The runtime loaded every motion-transformer checkpoint key successfully. Inference used 50 Euler flow-matching steps, guidance scale 5.0, one fixed seed per action, full float32 motion weights, and 30 FPS output.

Tested hardware: Windows, RTX 4060 Ti 16 GB, 64 GB system RAM, PyTorch 2.6.0+cu124. The two text encoders ran first: official CLIP and Qwen3-8B, with Qwen loaded in bitsandbytes int8. Their prompt embeddings were cached on CPU; the encoders were unloaded before motion inference. Observed peak allocated VRAM during motion inference was 4.94–5.33 GiB. Sampling uses only the valid motion frames instead of generating the official CLI's masked 360-frame padding.

Raw outputs total 945 frames (31.5 seconds). Runtime loops are selected from the generated clips by pose similarity, so the shipped animation set is shorter. No motion was substituted with hand-authored rotations.

Source versions:

- HY-Motion code: `4e426f5a1021cbcf7f375458c37b840ee7225229`.
- Standard checkpoint: `tencent/HY-Motion-1.0` at `620dd559f8d964aac2f82f1204fe6a35ad8ad14d`.
- Qwen: `Qwen/Qwen3-8B` at `b968826d9c46dd6066d109eabc6255188de91218`.
- CLIP: `openai/clip-vit-large-patch14` at `32bd64288804d66eefd0ccbe215aa642df71cc41`.

Each clip stores its prompt and seed. `animations/hy_motion/provenance.json` stores revisions and SHA-256 hashes of the final clip files. `tools/hy_motion_prompts.json` contains the reproducible prompt set.

The added layup uses seed 3111 and a three-second running one-handed layup prompt. Actual local standard-model sampling took 6.13 seconds and peaked at 5.14 GiB VRAM, after CLIP/Qwen text encoding completed. Its 90 native frames join the original ten clips, whose committed JSON files remain byte-identical. The exact prompt and checksum are in the manifest.

## Matching the skeleton

`animations/hy_motion/skeleton.json` comes directly from the official `dump_wooden` asset's `joint_names.json`, `kintree.bin`, and `j_template.bin`. All 52 names, parents, and rest joint positions are retained in their native order. Godot constructs local rest transforms by subtracting the parent's rest position. Bone rest bases are identity, matching the official forward-kinematics implementation.

The model outputs 22 body rotations. Their names are Pelvis; L/R Hip; Spine1; L/R Knee; Spine2; L/R Ankle; Spine3; L/R Foot; Neck; L/R Collar; Head; L/R Shoulder; L/R Elbow; L/R Wrist, in the precise source order recorded in the JSON. The remaining 30 finger bones retain identity pose rotations, just as the upstream inference code pads its generated body motion with identity hand rotations.

The original low-poly meshes are rebuilt as rigid segments attached to these bones with `BoneAttachment3D`. A uniform 1.16 scale fits the existing arcade player size without changing bone proportions or rest data. Jerseys, heads, limbs and sneakers follow the native hierarchy; there is no approximate bone-name remapping.

Conversion uses the official `rot6d_to_rotation_matrix` (interleaved 6D columns), followed by SciPy rotation conversion to Godot's XYZW quaternion order. Quaternion signs are made temporally continuous. Initial root yaw is removed so gameplay can control facing. The hierarchy is right-handed, Y-up, forward +Z.

## Gameplay integration

- Horizontal model root motion is discarded. The existing simulation owns court positions, speed, collision, turbo and multiplayer authority.
- Normal locomotion retains generated vertical root motion. During gameplay-controlled jumps and shot windups, pose-based foot grounding is combined with the existing arcade jump path to avoid applying the model's jump twice.
- Wrist-height peaks are recorded per clip and time-warped to the existing shot release, block apex and dunk timing. Shot success and input timing are unchanged.
- Running, dribbling and defense loops blend at transitions. Shot charge, flight time, block/stun timers, possession and cooldowns select and phase the action clips.
- Big Head mode scales the head mesh attachment. It does not change the skeleton.
- The crowd remains an independent billboard animation system.

This is generated sports motion adapted for an arcade game. Ball contact is still driven by the existing ball simulation; hand-to-ball IK and animation-authored physical contact are not implemented.

## Reproduce

Playing requires only the committed Godot game files. Generating new motion requires a CUDA-enabled PyTorch environment, Git LFS, model downloads (roughly 22 GB), and the pinned Python dependencies.

```powershell
.\tools\setup_hy_motion.ps1 -Python 'C:/path/to/CUDA-capable/python.exe'
```

The setup script clones the pinned official source revision into `.runtime/HY-Motion-1.0`, installs dependencies into `.runtime/venv`, downloads pinned official models, and runs the generator. It reuses an existing CUDA PyTorch installation through the virtual environment's system site packages. It does not alter global packages.

For the already installed environment:

```powershell
.\.runtime\venv\Scripts\python.exe .\tools\generate_hy_motion.py --phase encode
.\.runtime\venv\Scripts\python.exe .\tools\generate_hy_motion.py --phase generate --steps 50
# Export cached native NPZ outputs without rerunning neural inference:
.\.runtime\venv\Scripts\python.exe .\tools\generate_hy_motion.py --phase export
```

Delete/rename the corresponding `.runtime/raw_motion/<action>.npz` before regenerating that action with changed prompts, seeds or sampler settings. Existing raw outputs are deliberately reused. `.runtime/text_embeddings.pt` must also be regenerated after changing prompts. Use a complete generation pass to refresh the final all-clip provenance manifest.

Raw rotations/translations, text embeddings, upstream source, the Python environment and weights are ignored by Git and Godot. Export filters explicitly include the runtime clip/skeleton JSON and license notices while excluding the inference tools and `.runtime`.

To regenerate only the added motion, remove or rename `.runtime/raw_motion/layup.npz`, refresh text embeddings if the prompt changes, then run `generate_hy_motion.py --phase generate --only layup --steps 50`. Selective generation retains the other existing clips in the provenance manifest.

## Validation

`tests/hy_motion.gd` verifies all 52 bone names, parents and rest transforms; all eleven generated clips; normalized finite quaternions and motion variation; forward-kinematics parity; finger rest poses; gameplay action selection; simulation immutability; and local-generation provenance. `tests/run.ps1 -Capture` also runs existing simulation, arena, four-process network, crowd and rendering tests.

`tests/capture_hy_motion.gd` renders all eleven actual generated clips into 198 preview frames. The GIF in this directory shows these clips on the game's native HY-Motion rigs.

Official sources: [HY-Motion repository](https://github.com/Tencent-Hunyuan/HY-Motion-1.0), [standard model weights](https://huggingface.co/tencent/HY-Motion-1.0), [model download instructions](https://github.com/Tencent-Hunyuan/HY-Motion-1.0/blob/master/ckpts/README.md). The community license and required notice are included in `licenses/HY-Motion-1.0.txt` and `THIRD_PARTY_NOTICES.txt`.
