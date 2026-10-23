# Capital Punishment Basketball

An original Godot 4.5 arcade basketball game inspired by the pace and three-button controls of NBA Jam. The project contains all source, a true 3D arena with procedural meshes and textures, and synthesized sound; no asset downloads or addons are required.

## Run

Import `project.godot` in **Godot 4.5.1 or newer 4.x**, then press **F6/F5** to play. From a terminal:

```powershell
godot --path E:/github/jam_game
```

A Windows convenience launcher is included: `./play.ps1 -Godot 'C:/path/to/godot.exe'`. Pass `-QuickPlay` (or `-Quick` / `-qp`) to jump straight into a match with the standard teams, bypassing all menus for fast gameplay iteration: `./play.ps1 -QuickPlay`. No exported executable or Godot engine binary is checked into Git.

On macOS, the window automatically follows the current display's backing scale: 2560 × 1600 on a 2× Retina display and 1280 × 800 on a 1× display. Moving the game between displays updates the window size, with automatic fitting when the usable desktop is smaller than the preferred size.

## 3D arena

The court is a rectangular 28 × 15 mesh with a repeating, staggered hardwood plank texture, painted keys, regulation-style markings, and a closer sideline perspective camera that pans smoothly with possession. Off-screen athlete arrows preserve court awareness; results restore a full-court overview. Both baskets have modeled poles, padded bases, bracing, transparent framed backboards, orange rims, and tapered string nets.

Four low-poly humanoids wear team jerseys and use the native HY-Motion/SMPL-H skeleton (52 joints, 22 animated body joints). Their eleven motion clips were generated locally with the standard HY-Motion 1.0 model. Running, jumping, shooting, dunks, stuns, and dribbling are presented from the existing match state. Controlled-player rings, name tags, shot meters, fire effects, and Big Head mode remain available. The crowd consists of 464 camera-facing billboard spectators, drawn with one MultiMesh and an animated four-frame cheering atlas with eight spectator variants.

The 3D presentation uses the same controls and simulation coordinates as the initial game. Arcade rule refinements are documented in [the research log](docs/ARCADE_RESEARCH.md). Clients' smoothed network positions feed the 3D models. The scoreboard, menus, and control hints retain their existing layout. All geometry, hardwood, and crowd artwork are generated locally; no external assets are needed.

![3D gameplay](docs/gameplay.png)

## HY-Motion player animations

The shipped player clips are actual machine-generated outputs of a local **Tencent HY-Motion 1.0 standard (1B)** run: idle, run, dribble, defense, shoot, pass, dunk, block, steal, stun/recovery, and a dedicated running layup. Each player has a Godot `Skeleton3D` whose bone names, hierarchy, and rest transforms match HY-Motion's official 52-joint SMPL-H skeleton. The model generates the first 22 body rotations; the 30 finger joints remain in their native rest pose.

The animation layer preserves the existing controls and basketball simulation. Model-generated joint rotations blend between gameplay actions; the simulation continues to own horizontal movement and arcade jump height. Peak wrist poses are aligned to shot/block/dunk timing. Generated clips and source metadata are committed under `animations/hy_motion/`; the large weights and Python environment remain in ignored `.runtime/` storage. **Playing the game does not require Python, CUDA, or model downloads.**

See [generation and rig details](docs/HY_MOTION.md), [recorded provenance](animations/hy_motion/provenance.json), and [the animation preview](docs/hy_motion_preview.gif). To regenerate on this Windows machine:

```powershell
.\tools\setup_hy_motion.ps1 -Python 'C:/Users/JasonGauci/miniconda3/python.exe'
# Re-export the cached model outputs after changing conversion/loop rules:
.\.runtime\venv\Scripts\python.exe .\tools\generate_hy_motion.py --phase export
```

## Play modes

- Quick Play: one human with a CPU teammate against two CPU opponents.
- Local Versus: two humans on opposite teams, with CPU teammates; keyboard or two gamepads.
- Arcade Ladder: defeat each of the other seven teams to earn a championship.
- Network Play: a host and up to three clients, with CPU players in vacant slots. The first client plays the opposing side; subsequent clients fill the home and away teammate slots.

Eight fictional teams feature sixteen athletes with different speed, shooting, dunking, and defense ratings. Big Head and Infinite Turbo house rules are available in Options. Quarter length and CPU difficulty are configurable. Initials, win/loss records, best score, and championships persist locally in Godot's `user://records.cfg`.

## Controls

| Action | Player 1 / any network player | Player 2, local versus | Gamepad |
| --- | --- | --- | --- |
| Move | WASD | Arrow keys | Left stick or D-pad |
| Shoot / layup / dunk / head fake | J | Numpad 1 | X (or Y) |
| Pass / dish / alley-oop lob | K | Numpad 2 | A (or B) |
| Steal (swipe defense) | K | Numpad 2 | B (or A) |
| Shove (turbo knockdown) | L (or Turbo + Steal) | Numpad + (or Turbo + Steal) | B with Turbo held |
| Elbow clear-out (offense) | L | Numpad 6 | B |
| Spin move (offense) | Shift + L | Numpad 0 + Numpad 6 | RT + B |
| Block / rebound (defense) | J | Numpad 1 | Y (or X) |
| Boost (turbo) | Shift | Numpad 0 | RT (Right Trigger) |
| Switch athlete (offline) | F (or Tab) | Numpad 3 | RB (Right Bumper) |
| Pause / resume | Escape | Escape | Start or Back |
| Menu navigation | Mouse / Arrow keys | Arrow keys | D-pad / Left stick, A to select, B to cancel |
| Toggle sound | M | M | Keyboard M |

Keyboard controls use `WASD` for movement, `Shift` for turbo, and `F` for switching, while the right hand controls shooting/blocking on `J`, passing/stealing on `K`, and the context-sensitive contact move on `L`. With the ball, `L` elbows and `Shift + L` spins; on defense, `L` shoves. `Tab` remains an alternate switch key.

Gamepad support features standard arcade gamepad controls: four face buttons on the right thumb (X shoots/dunks/fakes, A passes/lobs, B steals/shoves/elbows, Y blocks/rebounds), Boost on the Right Trigger (RT), and athlete switching on the Right Bumper (RB). With the ball, B elbows and RT + B spins. Full controller menu navigation and pause handling are supported via D-pad, stick, A, B, and Start.

At the opening toss, tap Shoot as the ball rises, near the timing mark. The better-timed center tips to their partner; a human with a CPU center can order its jump. Both clocks start after the tip is judged. Early held input does not auto-jump, and only the first valid press counts.

Tap Shoot for a head-fake. For jump shots, hold Shoot as the athlete elevates into the air while the shot meter fills; the apex of the jump coincides with the gold mark at 0.58 seconds, rewarding release at peak elevation with the highest shot accuracy and a graceful landing descent. Running toward the rim and holding Shoot launches a regular dunk close to the basket; add Turbo for a higher specialty dunk. A short running hold and release without Turbo attempts a layup. Standing shots remain jumpers. Finishers glide from their launch point toward the rim; they no longer teleport forward.

Press Pass during a dunk to dish to your teammate; blocked dunks cannot be rescued. Turbo + Pass travels faster, or throws an alley-oop to a teammate near the rim. Defenders can pick off passes in their lane. Steal attempts trigger a full swiping animation with reach delay (~0.45s). When a steal connects, the ball may be cleanly pocketed or poked loose; loose balls bounce free and cannot be instantly recovered right away, creating scrambles on the hardwood. Shoving (`L` or Turbo + Steal) follows Tournament Edition rules: it checks one opponent in the forward cone at the animation's contact frame, then either leaves the ball with the carrier or knocks it loose. A standing elbow clear-out is the move that can hit both nearby defenders. When jumping for a block, defenders drop into a crouch squat for leverage before leaping straight up with both arms raised overhead. Missed shots ricochet off the rim in a high parabolic rebound arc (>3.5m) that can be snatched out of the air mid-jump or rebounded off floor bounces. After a goal, the inbounding athlete stands off-court behind the baseline, unable to shoot, and must pass the ball in to start the action. When your CPU teammate owns the ball, Pass requests a pass back and Shoot orders their shot. Another human keeps control of their own actions.

Three consecutive unanswered baskets by one athlete ignite Fire for that athlete, improving shots and granting unlimited turbo. Fire survives misses and teammate baskets; an opponent's natural basket ends it. Before ignition, a miss or another scorer's basket resets the heating sequence. Descending released jump-shot contact near the rim awards goaltending points; the burning defender can legally block that shot. Held dunks can be legally rejected near the rim by any defender. Goaltending points do not change heat. These edge rules remain subject to original-cabinet footage verification. There are two- and three-point baskets, a 24-second shot clock, four three-minute quarters by default, a halftime side switch, shots allowed to finish after the buzzer, and repeated overtime for ties. Postgame statistics include points, field goals, dunks, steals, blocks, rebounds, and goaltends (GT). No fouls or free throws.

In Q4 and overtime, the first successful specialty dunk at each intact hoop shatters its backboard. Glass bursts into 70 fragments with a crash and camera impact. Both clocks pause for the spectacle, then the opponent inbounds normally. Broken glass stays absent until the next match, while debris settles and fades. The exact trigger and effect timing are original prototype choices awaiting cabinet-footage comparison.

## Network multiplayer

1. Host chooses Network Play → Host Game.
2. Clients enter the host's LAN IP and connect. Use `127.0.0.1` for multiple instances on one computer.
3. The first human on each side selects its team. Clients press Toggle Ready; the host starts the game once everyone is ready.
4. For internet play, forward **UDP 27888** to the host and allow the game through the host firewall. Direct-IP internet connections depend on router/NAT configuration. There is no matchmaking, NAT traversal service, or relay.

Each network human controls a fixed athlete using player-one controls. Disconnected clients are replaced with CPU players. The host can start a rematch from the results screen. Late joining and host migration are not supported; host departure ends the session.

The host simulates gameplay at 60 Hz and accepts only bounded input commands tied to the sender's assigned athlete. Shot/pass/team readiness messages and round starts use Godot RPCs; pass button events and opening jump presses are reliable. Compressed state snapshots use ordered unreliable delivery at 20 Hz. Clients never submit scores or authoritative player positions. This is a direct-IP prototype, with no accounts, authentication, rollback, or competitive anticheat.

## Tests

```powershell
./tests/run.ps1 -Godot 'C:/path/to/Godot_v4.5.1-stable_win64_console.exe'
# Include actual GPU rendering and screenshots of the UI screens:
./tests/run.ps1 -Godot 'C:/path/to/Godot_v4.5.1-stable_win64_console.exe' -Capture
```

The tip-off suite checks opening input, both teams winning, CPU/human authority, tie fallback, clocks, catches, snapshots, pause and actual scoring matches at all three CPU difficulties. The arcade-rules suite checks individual heat, fire turbo, legal blocks, CPU shot blocking, goaltending, teammate orders, head-fakes, airborne dishes, and snapshot restoration. The finishing/passing suite checks moving versus standing shots, regular/specialty dunks, layups, momentum, smooth flight, goaltending, interceptions and 500 paired passing-lane trials. The backboard suite checks scoring, clocks, buzzer/overtime behavior, physical hoop mapping, rematch repair, all fragment transforms, floor settling and replica reconstruction. The HY-Motion suite checks the exact skeleton, quaternion validity, actual motion variation, native FK parity, action selection, and simulation immutability. The 3D suite checks geometry, floor tiling, articulated poses, modeled baskets, crowd instancing, camera framing, interpolation, and simulation immutability. GPU capture checks that the crowd pixels animate, and captures dunk/fire and Big Head poses. The simulation suite checks turbo, shot release, scoring, fire, alley-oops, blocks, rebounds, steals/shoves, halftime, overtime, snapshot restoration, and a complete CPU match. The networking test starts four real Godot processes and checks slot assignment, team selection, readiness, authoritative snapshots including fire/goaltend state, head-fake state, and disconnection. A second two-process network test drives a remote head-fake, dunk and reliable airborne pass through the real host simulation and verifies teammate receipt, then drives a shattering fourth-quarter dunk and confirms inbound recovery, then executes a remote layup and lane swipe. A third two-process scenario wins the opening using a reliable press independently of held Shoot delivery. Render smoke tests exercise menus, selection, gameplay, options, help, network setup, lobby, and results. Screenshots and logs are generated under `tests/` and ignored by Git.

Tested with official Godot 4.5.1 on Windows; network tests use loopback. Public-internet latency, packet loss, real gamepad hardware, other operating systems, and exported builds have not been validated.

## Cloned Announcer Commentary

The game features dynamic, cloned arcade commentary generated via VoxCPM voice synthesis from iconic arcade announcer reference audio. Announcer clips are stored in `voices/announcer/` and loaded by `scripts/main.gd`. Whenever an in-game event triggers an announcement banner (e.g. tip-off, dunks, boomshakalaka, downtown threes, rejections, fire streaks, turnovers, goaltending, quarter transitions, and buzzer beaters), the dedicated `announcer_player` plays the corresponding voice line in sync with the visual announcement.

The synthesis scripts, reference audio, and model evaluation code live in `voices/`:
- `voices/synthesize_all_announcements.py`: batch synthesis pipeline that generates, trims, normalizes, and manifests all announcer lines.
- `voices/announcer/announcements_manifest.json`: dictionary mapping all banner events and IDs to audio streams.
- `voices/cloned_announcer_voxcpm/`: composite reference audio and pitch comparison evaluation results.

## Scope and remaining work

This is a playable original prototype, **not feature-for-feature NBA Jam arcade parity**. It uses original low-poly 3D art, an elevated sideline camera, and fictional teams, rather than licensed NBA rosters, digitized sprites, or original audio. Not included: all historical rosters and secret characters, substitutions, arcade cabinet credit/service/DIP-switch emulation, licensed commentary and music, original animation/collision fidelity, attract/replay sequences, exact original shattering triggers, online matchmaking, controller-only menus, remappable controls, and production-quality network prediction/reconnection. Tuning and extended human playtesting remain necessary.

## Source map

- `scripts/main.gd`: menu flow, local inputs, HUD, sound effects, cloned announcer voice playback, saved records, arcade ladder.
- `scripts/arena_3d.gd`: 3D arena, repeating hardwood, player action selection, baskets, billboard crowd shader/atlas, sideline camera, and ball presentation.
- `scripts/hy_motion_rig.gd`: exact SMPL-H Skeleton3D, bone-attached low-poly mesh, generated clip playback, blending and event timing.
- `tools/generate_hy_motion.py`: local text encoding, standard-model inference, native skeleton export, rotation conversion, loop selection, and provenance.
- `voices/`: announcer speech synthesis pipeline, models, audio references, experiments, and runtime commentary clips (`voices/announcer/`).
- `scripts/match_state.gd`: host/offline simulation, CPU behavior, basketball rules, snapshots.
- `scripts/network.gd`: ENet lobby, peer slots, readiness, validated inputs, state delivery.
- `scripts/teams.gd`: original teams and athlete ratings.

Godot networking references: [high-level multiplayer](https://docs.godotengine.org/en/4.5/tutorials/networking/high_level_multiplayer.html), [ENetMultiplayerPeer](https://docs.godotengine.org/en/4.5/classes/class_enetmultiplayerpeer.html).
