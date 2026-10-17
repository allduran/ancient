#!/usr/bin/env bash
# Desinstalación de ancient (duran ya lo ha parado y quitado su shell.lua).
set -euo pipefail

qs -c ancient kill 2>/dev/null || true
pkill -INT -x wf-recorder 2>/dev/null || true     # grabación en marcha
pkill -x hyprsunset 2>/dev/null || true           # luz nocturna
rm -rf "$HOME/.local/state/ancient"

echo "ancient desinstalado. Tus capturas y ~/.config/hypr no se tocan."