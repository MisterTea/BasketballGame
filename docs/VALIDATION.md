# Validation — 2026-10-18

Engine: official Godot 4.5.1 stable (f62fdbde1), Windows, OpenGL Compatibility / NVIDIA RTX 4060 Ti.

- Clean editor import and GDScript compilation: pass.
- Simulation suite: 17 assertions passed, including a complete CPU match.
- Four-process loopback multiplayer: host + three clients passed; unique slots 0/2/1/3, selections synchronized, all peers readied and started, each client received 45 compressed authoritative snapshots and verified movement on its own slot.
- All three client departures processed and removed from host roster; no network errors logged after disabling unnecessary peer-to-peer relay.
- GPU rendering: title/menu, selection, options, instructions, network setup, lobby, gameplay, results all captured without Godot script errors. Menus, team cards, instructions, court, and lobby visually inspected.
- No external assets, libraries, addons, or credentials required.

Tests do not establish internet-latency quality, packet-loss resilience, gamepad hardware compatibility, full arcade feature parity, or production readiness. The Windows export preset is included; export templates and distributable builds were not tested.

Run `tests/run.ps1` to reproduce. The render test suppresses records persistence for its synthetic result.
