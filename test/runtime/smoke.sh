#!/usr/bin/env bash
set -euo pipefail

name="${NAME:-fedora-toolbox-smoke}"
image="${IMAGE:-fedora-toolbox:test}"
script_path="$(dirname "$0")/../build/smoke.sh"
abs_script="$(readlink -f "$script_path")"

if command -v distrobox >/dev/null 2>&1; then
  distrobox rm --force "$name" >/dev/null 2>&1 || true
  distrobox create --yes --name "$name" --image "$image"
  distrobox enter "$name" -- bash -lc "$abs_script"
elif command -v toolbox >/dev/null 2>&1; then
  if toolbox list | grep -q "^$name\b"; then
    toolbox rm -f "$name"
  fi
  toolbox create -y -c "$name" --image "$image"
  toolbox run -c "$name" bash -lc "$abs_script"
else
  echo "Neither distrobox nor toolbox is installed" >&2
  exit 1
fi
