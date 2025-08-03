#!/usr/bin/env bash
set -euo pipefail

name="toolbox-smoke"
image="${IMAGE:-fedora-toolbox:test}"

# create and enter toolbox
if toolbox list | grep -q "^$name\b"; then
  toolbox rm -f "$name"
fi

toolbox create -y -c "$name" --image "$image"
# ensure entrypoint works by a simple command
toolbox run -c "$name" echo "entered toolbox"
# run build smoke test inside toolbox
# assume repository is mounted at current directory
script_path="$(dirname "$0")/../build/smoke.sh"
# use absolute path for toolbox run
abs_script="$(readlink -f "$script_path")"
toolbox run -c "$name" bash -lc "$abs_script"
