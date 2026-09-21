#!/usr/bin/env bash
# Exports the browser build into docs/, which is what GitHub Pages serves,
# and copies the two fonts the loading page uses next to it.
set -euo pipefail
cd "$(dirname "$0")/.."
GODOT="${GODOT:-godot}"
"$GODOT" --headless --export-release "Web" docs/index.html
cp assets/PressStart2P-Regular.ttf docs/title.ttf
cp assets/Silkscreen-Regular.ttf docs/body.ttf
touch docs/.nojekyll
echo "exported $(du -sh docs | cut -f1) into docs/"
