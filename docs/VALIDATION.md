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
