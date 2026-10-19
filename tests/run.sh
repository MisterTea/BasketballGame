#!/usr/bin/env bash
set -euo pipefail

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GODOT="${GODOT:-}"
TARGET_SCRIPT=""

for arg in "$@"; do
    if [[ "$arg" == *.gd ]]; then
        TARGET_SCRIPT="$arg"
    elif [ -x "$arg" ]; then
        GODOT="$arg"
    fi
done

if [ -z "$GODOT" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    GODOT=/Applications/Godot.app/Contents/MacOS/Godot
fi

if [ -z "$GODOT" ]; then
    for name in godot godot4 godot_console; do
        if command -v "$name" >/dev/null 2>&1; then
            GODOT=$(command -v "$name")
            break
        fi
    done
fi

if [ -z "$GODOT" ]; then
    echo "[ERROR] Godot was not found. Install Godot 4.5.1+ or set GODOT environment variable." >&2
    exit 1
fi

# =========================================================================
# 10-MINUTE GLOBAL WATCHDOG
# Kills all child processes and exits with failure if total run exceeds 10m.
# =========================================================================
PARENT_PID=$$
(
    sleep 600
    echo "" >&2
    echo "[TEST FAILED: GLOBAL WATCHDOG TIMEOUT] Test suite exceeded 10-minute maximum timeout. Aborting with failure!" >&2
    kill -9 "$PARENT_PID" 2>/dev/null || true
) &
WATCHDOG_PID=$!

cleanup() {
    local exit_code=$?
    if [ -n "${WATCHDOG_PID:-}" ]; then
        kill "$WATCHDOG_PID" 2>/dev/null || true
        wait "$WATCHDOG_PID" 2>/dev/null || true
    fi
    # Kill any spawned background test processes
    jobs -p 2>/dev/null | xargs -r kill -9 2>/dev/null || true
    if [ "$exit_code" -ne 0 ]; then
        echo "" >&2
        echo "======================================================================" >&2
        echo "[SUITE FAILED] One or more tests failed or timed out (exit code $exit_code)." >&2
        echo "======================================================================" >&2
    fi
}
trap cleanup EXIT

run_godot_test() {
    local script_path="$1"
    local timeout_secs="${2:-45}"
    local description="${3:-$script_path}"

    echo "=== Running $description ($script_path) ==="
    
    # Run in background and enforce per-test timeout
    "$GODOT" --headless --path "$PROJECT_ROOT" --script "$script_path" &
    local test_pid=$!

    local elapsed=0
    while kill -0 "$test_pid" 2>/dev/null; do
        if [ "$elapsed" -ge "$timeout_secs" ]; then
            echo "" >&2
            echo "[TEST FAILED: WATCHDOG TIMEOUT] Test '$description' timed out after ${timeout_secs}s and was killed by watchdog!" >&2
            kill -9 "$test_pid" 2>/dev/null || true
            wait "$test_pid" 2>/dev/null || true
            return 1
        fi
        sleep 1
        elapsed=$((elapsed + 1))
    done

    wait "$test_pid"
    local exit_code=$?
    if [ "$exit_code" -ne 0 ]; then
        echo "[TEST FAILURE] Test '$description' failed with exit code $exit_code." >&2
        return "$exit_code"
    fi
}

echo "Building latest project code..."
"$GODOT" --headless --path "$PROJECT_ROOT" --editor --quit

# If a single test script was requested, run it and exit
if [ -n "$TARGET_SCRIPT" ]; then
    if [[ "$TARGET_SCRIPT" != res://* ]]; then
        TARGET_SCRIPT="res://${TARGET_SCRIPT#./}"
    fi
    run_godot_test "$TARGET_SCRIPT" 45 "Single test: $TARGET_SCRIPT"
    echo ""
    echo "TEST PASSED SUCCESSFULLY UNDER WATCHDOG!"
    exit 0
fi

# Standalone unit tests
run_godot_test "res://tests/simulation.gd" 45 "Simulation tests"
run_godot_test "res://tests/tipoff.gd" 45 "Tip-off tests"
run_godot_test "res://tests/arcade_rules.gd" 45 "Arcade rules tests"
run_godot_test "res://tests/shot_percentage.gd" 45 "Shot percentage tests"
run_godot_test "res://tests/finishing.gd" 45 "Finishing and passing tests"
run_godot_test "res://tests/alley_oop.gd" 45 "Coordinated alley-oop tests"
run_godot_test "res://tests/backboards.gd" 45 "Backboard tests"
run_godot_test "res://tests/arena_3d.gd" 45 "3D arena tests"
run_godot_test "res://tests/hy_motion.gd" 45 "HY-Motion rig and playback tests"
run_godot_test "res://tests/gamepad.gd" 45 "Gamepad tests"
run_godot_test "res://tests/arcade_mechanics_update.gd" 45 "Arcade mechanics update tests"
run_godot_test "res://tests/arcade_mechanics_pass2.gd" 45 "Arcade mechanics pass 2 tests"
run_godot_test "res://tests/arcade_mechanics_pass3.gd" 45 "Arcade mechanics pass 3 tests"
run_godot_test "res://tests/arcade_mechanics_pass4.gd" 45 "Arcade mechanics pass 4 tests"
run_godot_test "res://tests/arcade_mechanics_pass5.gd" 45 "Arcade mechanics pass 5 tests"

# Multiplayer network scenarios
run_network_scenario() {
    local script_name="$1"
    local peers="$2"
    local timeout_secs=25

    echo "=== Running multiplayer network scenario: $script_name ($peers peers) ==="
    local pids=()
    for (( i=0; i<peers; i++ )); do
        local args=(--headless --path "$PROJECT_ROOT" --script "res://tests/${script_name}.gd")
        if [ "$i" -eq 0 ]; then
            args+=(-- --host)
        fi
        local log_out="$PROJECT_ROOT/tests/${script_name}-${i}.log"
        local log_err="$PROJECT_ROOT/tests/${script_name}-${i}-error.log"
        "$GODOT" "${args[@]}" > "$log_out" 2> "$log_err" &
        pids+=($!)
        if [ "$i" -eq 0 ]; then
            sleep 1
        fi
    done

    local elapsed=0
    local any_running=true
    while [ "$any_running" = true ]; do
        any_running=false
        for pid in "${pids[@]}"; do
            if kill -0 "$pid" 2>/dev/null; then
                any_running=true
                break
            fi
        done
        if [ "$any_running" = true ]; then
            if [ "$elapsed" -ge "$timeout_secs" ]; then
                echo "" >&2
                echo "[TEST FAILED: WATCHDOG TIMEOUT] Network scenario '$script_name' timed out after ${timeout_secs}s and was killed by watchdog!" >&2
                for pid in "${pids[@]}"; do
                    kill -9 "$pid" 2>/dev/null || true
                done
                return 1
            fi
            sleep 1
            elapsed=$((elapsed + 1))
        fi
    done

    for pid in "${pids[@]}"; do
        wait "$pid" || {
            echo "[TEST FAILURE] Peer $pid failed in scenario $script_name." >&2
            return 1
        }
    done
}

run_network_scenario "network_peer" 4
run_network_scenario "network_actions" 2
run_network_scenario "network_tipoff" 2
run_network_scenario "network_alley" 4

echo ""
echo "ALL TEST SUITES PASSED SUCCESSFULLY UNDER WATCHDOG!"
