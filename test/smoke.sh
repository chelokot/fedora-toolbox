#!/usr/bin/env bash
set -euo pipefail

nova help
tsc --version
npm --version
node --version
ts-node --version
docker info
podman-remote --version
gcloud version | head -n1 | grep -q "Google Cloud SDK"

for bin in curl jq git ripgrep fzf make; do
  command -v "$bin" >/dev/null
done

echo "✔ basic tools work"
