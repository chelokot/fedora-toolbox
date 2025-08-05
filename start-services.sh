#!/usr/bin/env bash
set -euo pipefail

export OLLAMA_HOST=0.0.0.0:11434
exec ollama serve
