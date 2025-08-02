#!/usr/bin/env bash
set -euo pipefail

exec ollama serve \
  --host 0.0.0.0 \
  --port 11434
