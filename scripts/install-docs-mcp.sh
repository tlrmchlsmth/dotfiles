#!/usr/bin/env bash
# Local read-only documentation MCP, independent of inference model installation.
set -euo pipefail
repo=$(cd "$(dirname "$0")/.." && pwd)
runtime="${XDG_DATA_HOME:-$HOME/.local/share}/dotfiles-docs"
command -v uv >/dev/null || { echo 'Install uv first' >&2; exit 1; }
command -v codex >/dev/null || { echo 'Install Codex first' >&2; exit 1; }
mkdir -p "$runtime"
if [[ ! -x "$runtime/.venv/bin/python" ]]; then
  uv venv --python 3.12 "$runtime/.venv"
fi
uv pip install --python "$runtime/.venv/bin/python" 'mcp==2.3.0'
codex mcp add dotfiles-docs -- "$runtime/.venv/bin/python" "$repo/scripts/dotfiles-docs-mcp.py"
echo 'Local dotfiles documentation MCP installed. Restart Codex to load it.'
