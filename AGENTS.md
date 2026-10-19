# Guidelines for AI Coding Agents

## ⚠️ Test Execution & Watchdog Requirement (MANDATORY)

**ALWAYS run tests under a watchdog runner.** 

### Why
When Godot runs a test script in headless mode (`--headless --script <path>`), any unhandled script error or assertion failure halts script execution **without terminating the Godot process**. Godot remains alive indefinitely in the background, consuming CPU/memory and causing orphaned tasks to get stuck.

### How to Run Tests Under the Watchdog

#### macOS & Linux
Use the watchdog script [`tests/run.sh`](tests/run.sh), which enforces a 10-minute global watchdog and per-test timeout guards (45s per standalone test, 25s per multiplayer scenario) that automatically kill (`kill -9`) hung processes and clean up child processes on exit:

```bash
# Run full test suite (all 15 unit tests + 4 multiplayer scenarios) under watchdog:
./tests/run.sh

# Run a single test script under watchdog:
./tests/run.sh tests/shot_percentage.gd
./tests/run.sh tests/finishing.gd
./tests/run.sh tests/arena_3d.gd
```

#### Windows
Use [`tests/run.ps1`](tests/run.ps1), which enforces global 10-minute and per-test 45-second timeouts:

```powershell
powershell -ExecutionPolicy Bypass -File tests/run.ps1
```

#### ❌ Never Do This
Do **not** run raw headless Godot commands directly in background tasks without a timeout or watchdog:
```bash
# DO NOT DO THIS - will hang indefinitely on script error:
/Applications/Godot.app/Contents/MacOS/Godot --headless --script tests/finishing.gd
```

### 🚨 Watchdog Timeouts ARE Test Failures

**If a test times out because of the watchdog, consider it a FAILURE.**

- **Never treat a watchdog timeout as an environment fluke, transient delay, or ignorable warning.**
- A watchdog timeout indicates a genuine bug:
  - An unhandled script exception that halted execution without terminating or calling `quit()`
  - An infinite loop or stalled timer in physics, animation, or match state transitions
  - A deadlock or missed synchronization signal in multiplayer peer fixtures
- **Required Action on Timeout**:
  1. Inspect the console output and logs (e.g. `tests/<scenario>-*.log` and `tests/<scenario>-*-error.log`).
  2. Identify the stalled stage, assertion, or error trace.
  3. Fix the underlying simulation or test code so the test completes cleanly with exit code 0 well within its watchdog timeout.

---

## Architecture & Code Conventions

1. **Authoritative Simulation (`scripts/match_state.gd`)**:
   - `MatchState` contains all game rules, player dictionaries, physics ticks, shot calculations, and state machines.
   - Must remain fully deterministic and headless-compatible.
   - All state must serialize cleanly in `state.snapshot()` and restore cleanly in `state.apply_snapshot(data)`.

2. **Presentation Layer (`scripts/arena_3d.gd`, `scripts/main.gd`)**:
   - `ArenaView` is presentation-only (3D scene, meshes, cameras, HY-Motion rig animation).
   - Calling `arena.present(state, ...)` **must never mutate gameplay state** (verified by `check(state.snapshot() == before, ...)`).
   - Do not store authoritative gameplay variables in visual nodes.

3. **Multiplayer Networking (`scripts/network.gd`)**:
   - Uses Godot's ENet multiplayer peer.
   - Network test fixtures (`tests/network_*.gd`) require host and client peers communicating asynchronously.
