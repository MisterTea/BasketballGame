# Validation — 2026-10-18

Engine: official Godot 4.5.1 stable (f62fdbde1), Windows, OpenGL Compatibility / NVIDIA RTX 4060 Ti.

- Clean editor import and GDScript compilation: pass.
- Existing simulation suite: all 17 assertions passed, including a complete CPU match.
- New 3D suite: all 15 assertions passed. These check rectangular court geometry, repeating hardwood, articulated humanoids and jump/shoot poses, control markers, fire effects, basket geometry and shot-height alignment, 464 billboard spectators, GPU animation, camera framing, client interpolation, and simulation immutability.
- Four-process loopback multiplayer: host + three clients passed; unique slots 0/2/1/3, selections synchronized, all peers readied and started, each client received 45 compressed authoritative snapshots and verified movement on its own slot. All client departures processed without network errors.
- GPU rendering: title/menu, selection, options, instructions, network setup, lobby, 3D gameplay, dunk/fire, Big Head mode, and results captured without Godot script errors.
- Actual billboard animation: the GPU captures, taken 0.3 seconds apart, differed at 1,803 sampled crowd pixels (threshold: 100).
- Visually inspected the 3D court's perspective, wood pattern, markings, players, modeled baskets, crowd, airborne dunk/fire pose, and Big Head pose.
- Gameplay simulation, CPU, networking, team ratings, and input mappings remain unchanged. Tests confirm that ordinary and interpolated 3D presentation do not mutate match snapshots.
- No external assets, libraries, addons, or credentials required.

Tests do not establish internet-latency quality, packet-loss resilience, gamepad hardware compatibility, full arcade feature parity, or production readiness. The Windows export preset is included; export templates and distributable builds were not tested.

Run `tests/run.ps1 -Capture` to reproduce with a Godot executable. The render test suppresses records persistence for its synthetic result. `docs/gameplay.png` is the updated 3D preview.
# HY-Motion addition — local inference and matching player rig

- Actual local standard HY-Motion 1.0 (1B) inference completed for all 10 basketball actions, using 50 Euler steps, CFG 5.0, fixed per-action seeds, and full float32 motion weights. Qwen3-8B text encoding used int8 on the GPU; CLIP/Qwen were unloaded before motion inference.
- Raw model outputs contain 855 frames at 30 FPS (28.5 seconds). Runtime loops are cropped by pose similarity; rotations are converted to XYZW quaternions, source heading normalized, and wrist event timing tagged for gameplay alignment. Native raw NPZ results remain in ignored local storage.
- Observed peak allocated VRAM during generation: 4.94–5.33 GiB on the RTX 4060 Ti 16 GB.
- Godot Skeleton3D matches all 52 upstream SMPL-H joint names, parents and rest positions. The first 22 receive generated rotations; fingers remain at rest.
- All 13 new HY-Motion tests pass, including native forward-kinematics parity, quaternion validity, actual motion variation, action selection, and nonmutation of gameplay state.
- Existing 17 simulation tests, 15 arena tests, four-process loopback networking, and GPU screen/crowd captures pass with the new rigs.
- All ten clips rendered into a 180-frame preview. Idle, running, shooting and dunking samples visually inspected on the native rigs.
- Prompts, seeds, exact code/model revisions, final clip checksums, generation scripts, dependency pins, licensing notices and export inclusion filters are included. Large checkpoints and the inference environment are excluded from Git and Godot imports.
- No game simulation, controls, CPU logic or multiplayer protocol changes were required.



- Export pack successfully built with all animation/skeleton JSON and license notices; the packed game boots successfully without the Python runtime.
