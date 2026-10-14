#!/usr/bin/env bash
# Install the standalone CLI without depending on a developer checkout.
set -euo pipefail

target_bin=${TARGET_BIN_DIR:-$HOME/.local/bin}
kcfg_module=github.com/tlrmchlsmth/kcfg
kcfg_ref=${KCFG_VERSION:-latest}
go_cmd=$(command -v go || true)

# Older distro Go packages cannot build the module or fetch newer toolchains.
if [[ -z "$go_cmd" ]] || ! "$go_cmd" version | python3 -c '
import re, sys
m = re.search(r"go(\d+)\.(\d+)", sys.stdin.read())
sys.exit(0 if m and tuple(map(int, m.groups())) >= (1, 23) else 1)
'; then
    case $(uname -s) in
        Linux) go_os=linux ;;
        Darwin) go_os=darwin ;;
        *) echo 'kcfg: unsupported OS' >&2; exit 1 ;;
    esac
    case $(uname -m) in
        x86_64|amd64) go_arch=amd64 ;;
        aarch64|arm64) go_arch=arm64 ;;
        *) echo 'kcfg: unsupported architecture' >&2; exit 1 ;;
    esac
    stage=$(mktemp -d)
    trap 'rm -rf "$stage"' EXIT
    curl -fsSL 'https://go.dev/dl/?mode=json' -o "$stage/releases.json"
    metadata=$(python3 - "$stage/releases.json" "$go_os" "$go_arch" <<'PY'
import json, sys
with open(sys.argv[1]) as f:
    releases = json.load(f)
for release in releases:
    if release['stable']:
        for file in release['files']:
            if (file['os'], file['arch'], file['kind']) == (sys.argv[2], sys.argv[3], 'archive'):
                print(file['filename'], file['sha256'], release['version'])
                sys.exit(0)
raise SystemExit('No stable Go archive for this platform')
PY
)
    read -r archive checksum version <<< "$metadata"
    go_dir="${XDG_DATA_HOME:-$HOME/.local/share}/kcfg/toolchains/$version"
    go_cmd="$go_dir/go/bin/go"
    if [[ ! -x "$go_cmd" ]]; then
        echo "Installing $version for kcfg..."
        curl -fsSL "https://go.dev/dl/$archive" -o "$stage/go.tar.gz"
        python3 - "$stage/go.tar.gz" "$checksum" <<'PY'
import hashlib, sys
with open(sys.argv[1], 'rb') as f:
    actual = hashlib.sha256(f.read()).hexdigest()
if actual != sys.argv[2]:
    raise SystemExit('Go archive checksum mismatch')
PY
        tar -xzf "$stage/go.tar.gz" -C "$stage"
        mkdir -p "$go_dir"
        mv "$stage/go" "$go_dir/go"
    fi
fi

mkdir -p "$target_bin"
echo "Installing kcfg ($kcfg_ref)..."
GOBIN="$target_bin" GOTOOLCHAIN=auto "$go_cmd" install "$kcfg_module/cmd/kcfg@$kcfg_ref"
"$target_bin/kcfg" --help
