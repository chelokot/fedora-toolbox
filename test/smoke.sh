#!/usr/bin/env bash
set -euo pipefail

nova help
tsc --version
npm --version
node --version
ts-node --version
gcloud --version

for bin in curl jq git make; do
  command -v "$bin" >/dev/null
done

echo "✔ basic tools work"
