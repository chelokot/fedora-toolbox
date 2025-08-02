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

ollama ls | grep -q '^gemma-3n\s' && echo "✔ gemma-3n present"
