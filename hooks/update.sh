#!/usr/bin/env bash
# Tras `duran update ancient`
set -uo pipefail
root="$(dirname "$(realpath "$0")")/.."
chmod +x "$root"/scripts/*.sh 2>/dev/null