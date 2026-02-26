#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
DOTFILES_DIR="$(dirname "$SCRIPT_DIR")"
IMAGE_NAME="dotfiles-vllm-dev"

echo "Building dev container..."
docker build -t "$IMAGE_NAME" -f "$SCRIPT_DIR/Dockerfile" "$DOTFILES_DIR"

echo "Starting dev container..."
exec docker run -it --rm \
  --gpus all \
  -v "$(pwd):/workspace" \
  -w /workspace \
  "$IMAGE_NAME"
