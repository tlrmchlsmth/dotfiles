#!/usr/bin/env bash
# Opt-in: installs a model and enables its login service on Apple Silicon.
set -euo pipefail
[[ $(uname -s) == Darwin && $(uname -m) == arm64 ]] || { echo 'Apple Silicon macOS required' >&2; exit 1; }
repo=$(cd "$(dirname "$0")/.." && pwd)
runtime=$(python3 "$repo/scripts/local-ai.py" home)
uv_cmd=$(command -v uv || true)
[[ -n "$uv_cmd" ]] || { echo 'Install uv first (brew install uv)' >&2; exit 1; }
mkdir -p "$runtime/cache/uv" "$runtime/artifacts"
export UV_CACHE_DIR="$runtime/cache/uv"
export UV_PYTHON_INSTALL_DIR="$runtime/python"
export HF_HOME="$runtime/cache/huggingface"
if [[ ! -x "$runtime/.venv/bin/vllm" ]]; then
  "$uv_cmd" venv --python 3.12 "$runtime/.venv"
  "$uv_cmd" pip install --python "$runtime/.venv/bin/python" \
    'https://github.com/vllm-project/vllm/releases/download/v0.31.0/vllm-0.31.0%2Bcpu-cp312-cp312-macosx_11_0_arm64.whl' \
    'https://github.com/vllm-project/vllm-metal/releases/download/v0.31.0/vllm_metal-0.31.0-cp312-cp312-macosx_15_0_arm64.whl'
fi
"$runtime/.venv/bin/python" - "$repo/config/local-ai.json" "$HOME/.config/local-ai.local.json" <<'PY'
import json,sys
from pathlib import Path
from huggingface_hub import snapshot_download
cfg=json.loads(Path(sys.argv[1]).read_text())
override=Path(sys.argv[2])
if override.exists(): cfg.update(json.loads(override.read_text()))
snapshot_download(cfg['model'],revision=cfg['revision'])
PY
mkdir -p "$HOME/.local/bin"
ln -sfn "$repo/bin/local-ai" "$HOME/.local/bin/local-ai"
python3 "$repo/scripts/local-ai.py" install
python3 "$repo/scripts/local-ai.py" restart
echo 'Optional memorable hostname: sudo python3 '"$repo/scripts/local-ai.py"' hosts'
