#!/bin/sh

set -eu

project_dir=$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)
godot=""
quickplay=0

for arg in "$@"; do
    case "$arg" in
        --quickplay|--quick-play|-q|--qp|-QuickPlay|-quickplay)
            quickplay=1
            ;;
        *)
            if [ -z "$godot" ] && [ -e "$arg" ]; then
                godot="$arg"
            fi
            ;;
    esac
done

if [ -z "$godot" ] && [ -x /Applications/Godot.app/Contents/MacOS/Godot ]; then
    godot=/Applications/Godot.app/Contents/MacOS/Godot
fi

if [ -z "$godot" ]; then
    for name in godot godot4 godot_console; do
        if command -v "$name" >/dev/null 2>&1; then
            godot=$(command -v "$name")
            break
        fi
    done
fi

if [ -z "$godot" ]; then
    echo "Godot was not found. Install Godot 4.5.1+ or pass its path as the first argument." >&2
    exit 1
fi

echo "Building latest project code..."
"$godot" --headless --editor --path "$project_dir" --quit

if [ "$quickplay" -eq 1 ]; then
    echo "Starting Basketball Game in Quick Play..."
    exec "$godot" --path "$project_dir" -- --quickplay
else
    echo "Starting Basketball Game..."
    exec "$godot" --path "$project_dir"
fi
