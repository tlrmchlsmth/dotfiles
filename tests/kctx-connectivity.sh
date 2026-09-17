#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/bin"
export HOME="$test_home"
export PATH="$test_home/bin:$PATH"
export KCTX_STATUS_CACHE_DIR="$test_home/cache"
export KCTX_GB200_TUNNEL_SCRIPT="$test_home/tunnel"
export KCTX_STATUS_SCRIPT="$repo_root/bin/kctx-connectivity"
script="$KCTX_STATUS_SCRIPT"

cat > "$test_home/bin/kubectl" <<'EOF'
#!/bin/sh
case "$*" in
  "config current-context") cat "$HOME/.current-context" ;;
  "config view --minify -o jsonpath={.contexts[0].context.namespace}") cat "$HOME/.current-namespace" ;;
  "--context pirate --request-timeout=5s get --raw=/readyz")
    if [ -f "$HOME/.pirate-probe-fails" ]; then exit 1; fi
    ;;
  "--context vllm-gb200 --request-timeout=5s get --raw=/readyz")
    if [ -f "$HOME/.probe-delay" ]; then /bin/sleep 2; fi
    if [ -f "$HOME/.probe-always-fails" ]; then exit 1; fi
    if [ -f "$HOME/.probe-until-restart" ] && [ ! -f "$HOME/.tunnel-restarted" ]; then exit 1; fi
    if [ -f "$HOME/.probe-fails-once" ]; then
      rm "$HOME/.probe-fails-once"
      exit 1
    fi
    ;;
  *) exit 1 ;;
esac
EOF
cat > "$test_home/bin/sleep" <<'EOF'
#!/bin/sh
exit 0
EOF
cat > "$test_home/tunnel" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >> "$HOME/.tunnel-calls"
if [ -f "$HOME/.slow-restart" ]; then /bin/sleep 1; fi
touch "$HOME/.tunnel-restarted"
EOF
chmod +x "$test_home/bin/kubectl" "$test_home/bin/sleep" "$test_home/tunnel"
printf 'vllm-gb200\n' > "$test_home/.current-context"
printf 'vllm\n' > "$test_home/.current-namespace"
cat > "$test_home/kubeconfig" <<'EOF'
apiVersion: v1
kind: Config
current-context: vllm-gb200
contexts:
- name: vllm-gb200
  context:
    cluster: test
    user: test
    namespace: vllm
clusters:
- name: test
  cluster:
    server: https://example.invalid
users:
- name: test
  user: {}
EOF
export KUBECONFIG="$test_home/kubeconfig"

wait_for_state() {
  local expected="$1" actual="" i
  for i in {1..50}; do
    if [[ -r "$KCTX_STATUS_CACHE_DIR/gb200" ]]; then
      read -r actual _ < "$KCTX_STATUS_CACHE_DIR/gb200"
      [[ "$actual" == "$expected" ]] && return 0
    fi
    /bin/sleep 0.1
  done
  printf 'expected GB200 state %s, got %s\n' "$expected" "$actual" >&2
  return 1
}

# Queueing an ensure must return before the slow API probe finishes.
touch "$test_home/.probe-delay"
start=$(date +%s)
"$script" connect
elapsed=$(( $(date +%s) - start ))
if (( elapsed >= 2 )); then
  printf 'connect waited for the API probe\n' >&2
  exit 1
fi
wait_for_state up
rm "$test_home/.probe-delay"
[[ "$("$script" status)" == ◆vllm ]]
[[ ! -e "$test_home/.tunnel-calls" ]]

# Every context gets an independent connectivity result.
printf 'pirate\n' > "$test_home/.current-context"
[[ "$("$script" status)" == ◈vllm ]]
for i in {1..50}; do
  [[ "$("$script" status)" == ◆vllm ]] && break
  /bin/sleep 0.1
done
[[ "$("$script" status)" == ◆vllm ]]
touch "$test_home/.pirate-probe-fails"
"$script" probe pirate
[[ "$("$script" status)" == ◇vllm ]]
[[ ! -e "$test_home/.tunnel-calls" ]]
if command -v starship >/dev/null; then
  output=$(STARSHIP_CONFIG="$repo_root/config/starship.toml" starship module custom.kube_connectivity)
  [[ "$output" == *◇vllm* ]]
fi
printf 'vllm-gb200\n' > "$test_home/.current-context"
[[ "$("$script" status)" == ◆vllm ]]

# A stale prompt result refreshes in the background without restarting SSH.
printf 'up 1\n' > "$KCTX_STATUS_CACHE_DIR/gb200"
touch "$test_home/.probe-always-fails"
[[ "$("$script" status)" == ◈vllm ]]
wait_for_state down
[[ ! -e "$test_home/.tunnel-calls" ]]
[[ "$("$script" status)" == ◇vllm ]]

# An explicit ensure restarts the tunnel once after a failed probe.
rm "$test_home/.probe-always-fails"
touch "$test_home/.probe-fails-once"
"$script" ensure
wait_for_state up
[[ "$(<"$test_home/.tunnel-calls")" == restart ]]

# Concurrent selections must not restart over one another's new tunnel.
touch "$test_home/.probe-until-restart" "$test_home/.slow-restart"
rm -f "$test_home/.tunnel-restarted"
: > "$test_home/.tunnel-calls"
"$script" ensure & first=$!
/bin/sleep 0.1
"$script" ensure & second=$!
wait "$first"
wait "$second"
wait_for_state up
[[ "$(wc -l < "$test_home/.tunnel-calls")" -eq 1 ]]
rm "$test_home/.probe-until-restart" "$test_home/.slow-restart"

# A persistent failure stays visible as down.
touch "$test_home/.probe-always-fails"
if "$script" ensure; then
  printf 'expected ensure to fail when the API stays unreachable\n' >&2
  exit 1
fi
wait_for_state down

if command -v starship >/dev/null; then
  output=$(STARSHIP_CONFIG="$repo_root/config/starship.toml" starship module custom.kube_connectivity)
  [[ "$output" == *◇vllm* ]] || {
    printf 'expected Starship to show the GB200 down glyph, got %s\n' "$output" >&2
    exit 1
  }
  prompt=$(TERM=xterm-256color STARSHIP_CONFIG="$repo_root/config/starship.toml" starship prompt --path "$repo_root")
  [[ "$prompt" == *vllm-gb200*◇vllm* ]] && [[ "$prompt" != *☸* ]] && [[ "$prompt" != *'.kube_connectivity'* ]] || {
    printf 'expected a compact Kubernetes prompt, got %s\n' "$prompt" >&2
    exit 1
  }
fi

printf 'kctx connectivity tests passed\n'
