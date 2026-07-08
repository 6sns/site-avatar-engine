#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="$(cd "$ROOT_DIR/../avatar-engine-inline" && pwd)"

test -f "$SRC_DIR/index.html"
test -d "$SRC_DIR/assets/fixed"

mkdir -p "$ROOT_DIR/assets/fixed" "$ROOT_DIR/assets/fonts/montserrat"

cp "$SRC_DIR/index.html" "$ROOT_DIR/index.html"
cp "$SRC_DIR/assets/fixed/"*.svg "$ROOT_DIR/assets/fixed/"
cp "$SRC_DIR/assets/fixed/group-2.png" "$ROOT_DIR/assets/fixed/"

if [[ -f "$SRC_DIR/assets/fonts/montserrat/LICENSE.txt" ]]; then
  cp "$SRC_DIR/assets/fonts/montserrat/LICENSE.txt" "$ROOT_DIR/assets/fonts/montserrat/"
fi

if [[ -f "$SRC_DIR/assets/fonts/montserrat/Montserrat-Regular.ttf" ]]; then
  cp "$SRC_DIR/assets/fonts/montserrat/"*.ttf "$ROOT_DIR/assets/fonts/montserrat/"
fi

touch "$ROOT_DIR/.nojekyll"

echo "Built publish-github/ from avatar-engine-inline"
