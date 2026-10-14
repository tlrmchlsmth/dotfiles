#!/usr/bin/env bash
set -euo pipefail
repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_dir=$(mktemp -d)
trap 'rm -rf "$test_dir"' EXIT
mkdir -p "$test_dir/bin" "$test_dir/output"
export TEST_CALLS="$test_dir/calls"
cat > "$test_dir/bin/go" <<'SH'
#!/bin/sh
if [ "$1" = version ]; then
    echo 'go version go1.23.0 linux/amd64'
    exit 0
fi
[ "$1" = install ] || exit 1
[ "$GOTOOLCHAIN" = auto ] || exit 1
printf '%s\n' "$2" >> "$TEST_CALLS"
cat > "$GOBIN/kcfg" <<'CLI'
#!/bin/sh
[ "$1" = --help ] || exit 1
printf 'kcfg help\n'
CLI
chmod +x "$GOBIN/kcfg"
SH
cat > "$test_dir/bin/curl" <<'SH'
#!/bin/sh
echo 'unexpected toolchain download' >&2
exit 1
SH
chmod +x "$test_dir/bin/"*
export PATH="$test_dir/bin:$PATH"
TARGET_BIN_DIR="$test_dir/output" KCFG_VERSION=main bash "$repo_root/scripts/install-kcfg.sh"
[[ $(cat "$TEST_CALLS") == github.com/tlrmchlsmth/kcfg/cmd/kcfg@main ]]
: > "$TEST_CALLS"
TARGET_BIN_DIR="$test_dir/output" bash "$repo_root/scripts/install-kcfg.sh"
[[ $(cat "$TEST_CALLS") == github.com/tlrmchlsmth/kcfg/cmd/kcfg@latest ]]

# Exercise bootstrapping without network: a local archive and release metadata.
cp "$test_dir/bin/go" "$test_dir/new-go"
cat > "$test_dir/bin/go" <<'SH'
#!/bin/sh
echo 'go version go1.18.0 linux/amd64'
SH
mkdir -p "$test_dir/archive/go/bin"
cp "$test_dir/new-go" "$test_dir/archive/go/bin/go"
tar -czf "$test_dir/go.tar.gz" -C "$test_dir/archive" go
export TEST_FIXTURES="$test_dir"
python3 - "$test_dir" <<'PY'
import hashlib,json,platform,sys
from pathlib import Path
root=Path(sys.argv[1])
checksum=hashlib.sha256((root/'go.tar.gz').read_bytes()).hexdigest()
osname={'Linux':'linux','Darwin':'darwin'}[platform.system()]
arch={'x86_64':'amd64','aarch64':'arm64','arm64':'arm64'}[platform.machine()]
(root/'releases.json').write_text(json.dumps([{'stable':True,'version':'go1.23.0','files':[{'os':osname,'arch':arch,'kind':'archive','filename':'go-fixture.tar.gz','sha256':checksum}]}]))
PY
cat > "$test_dir/bin/curl" <<'SH'
#!/bin/sh
[ "$1" = -fsSL ] && [ "$3" = -o ] || exit 1
case "$2" in
 'https://go.dev/dl/?mode=json') cp "$TEST_FIXTURES/releases.json" "$4" ;;
 'https://go.dev/dl/go-fixture.tar.gz') cp "$TEST_FIXTURES/go.tar.gz" "$4" ;;
 *) exit 1 ;;
esac
SH
TARGET_BIN_DIR="$test_dir/output" XDG_DATA_HOME="$test_dir/data" bash "$repo_root/scripts/install-kcfg.sh"
# Corrupt archive must never reach extraction/install.
printf corrupt >> "$test_dir/go.tar.gz"
if TARGET_BIN_DIR="$test_dir/output" XDG_DATA_HOME="$test_dir/bad-data" bash "$repo_root/scripts/install-kcfg.sh" >"$test_dir/failure" 2>&1; then
    echo 'checksum mismatch was accepted' >&2
    exit 1
fi
rg -q 'checksum mismatch' "$test_dir/failure"
echo 'kcfg installer tests passed'
