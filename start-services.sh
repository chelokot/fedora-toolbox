#!/usr/bin/env bash
set -euo pipefail

exec OLLAMA_HOST=0.0.0.0:11434 ollama serve
