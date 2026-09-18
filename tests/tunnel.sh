#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/bin"
export PATH="$test_home/bin:$PATH"
export TUNNEL_TEST_HOME="$test_home"

cat > "$test_home/bin/lsof" <<'EOF'
#!/bin/sh
# Simulate an SSH listener on the requested port that this script did not start.
echo 999999999
EOF
cat > "$test_home/bin/ssh" <<'EOF'
#!/bin/sh
touch "$TUNNEL_TEST_HOME/ssh-called"
EOF
chmod +x "$test_home/bin/lsof" "$test_home/bin/ssh"

if "$repo_root/bin/tunnel.sh" "foreign-test-$$" start example.invalid -D 19999 >"$test_home/output" 2>&1; then
  echo 'start should fail when another SSH listener owns the port' >&2
  exit 1
fi
if [[ -e "$test_home/ssh-called" ]]; then
  echo 'start should not launch SSH over another listener' >&2
  exit 1
fi
if ! rg -q 'refusing to stop it' "$test_home/output"; then
  echo 'start should explain the occupied port' >&2
  exit 1
fi

echo 'tunnel tests passed'
