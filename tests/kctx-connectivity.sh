#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/bin"
export HOME="$test_home"
export PATH="$test_home/bin:$PATH"
export KCTX_STATUS_CACHE_DIR="$test_home/cache"
export KCTX_CONNECT_HOOK="$test_home/hook"
export KCTX_STATUS_SCRIPT="$repo_root/bin/kctx-connectivity"
script="$KCTX_STATUS_SCRIPT"

cat > "$test_home/bin/kubectl" <<'EOF'
#!/bin/sh
case "$*" in
  "config current-context") cat "$HOME/.current-context" ;;
  "config view --minify -o jsonpath={.contexts[0].context.namespace}") cat "$HOME/.current-namespace" ;;
  "--context secondary --request-timeout=5s get --raw=/readyz")
    if [ -f "$HOME/.secondary-probe-fails" ]; then exit 1; fi
    ;;
  "--context primary --request-timeout=5s get --raw=/readyz")
    if [ -f "$HOME/.probe-delay" ]; then /bin/sleep 2; fi
    if [ -f "$HOME/.probe-always-fails" ]; then exit 1; fi
    if [ -f "$HOME/.probe-until-restart" ] && [ ! -f "$HOME/.hook-restarted" ]; then exit 1; fi
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
cat > "$test_home/hook" <<'EOF'
#!/bin/sh
[ "$1" = primary ] || exit 1
printf '%s %s\n' "$1" "$2" >> "$HOME/.hook-calls"
if [ -f "$HOME/.slow-restart" ]; then /bin/sleep 1; fi
touch "$HOME/.hook-restarted"
EOF
chmod +x "$test_home/bin/kubectl" "$test_home/bin/sleep" "$test_home/hook"
printf 'primary\n' > "$test_home/.current-context"
printf 'app\n' > "$test_home/.current-namespace"
cat > "$test_home/kubeconfig" <<'EOF'
apiVersion: v1
kind: Config
current-context: primary
contexts:
- name: primary
  context:
    cluster: test
    user: test
    namespace: app
clusters:
- name: test
  cluster:
    server: https://example.invalid
users:
- name: test
  user: {}
EOF
export KUBECONFIG="$test_home/kubeconfig"
primary_key=$(printf %s primary | od -An -tx1 | tr -d '[:space:]')
primary_state="$KCTX_STATUS_CACHE_DIR/context-$primary_key"

wait_for_state() {
  local expected="$1" actual="" i
  for i in {1..50}; do
    if [[ -r "$primary_state" ]]; then
      read -r actual _ < "$primary_state"
      [[ "$actual" == "$expected" ]] && return 0
    fi
    /bin/sleep 0.1
  done
  printf 'expected primary state %s, got %s\n' "$expected" "$actual" >&2
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
[[ "$("$script" status)" == ◆app ]]
[[ ! -e "$test_home/.hook-calls" ]]

# Every context gets an independent connectivity result.
printf 'secondary\n' > "$test_home/.current-context"
[[ "$("$script" status)" == ◈app ]]
for i in {1..50}; do
  [[ "$("$script" status)" == ◆app ]] && break
  /bin/sleep 0.1
done
[[ "$("$script" status)" == ◆app ]]
touch "$test_home/.secondary-probe-fails"
"$script" probe secondary
[[ "$("$script" status)" == ◇app ]]
[[ ! -e "$test_home/.hook-calls" ]]
if command -v starship >/dev/null; then
  output=$(STARSHIP_CONFIG="$repo_root/config/starship.toml" starship module custom.kube_connectivity)
  [[ "$output" == *◇app* ]]
fi
printf 'primary\n' > "$test_home/.current-context"
[[ "$("$script" status)" == ◆app ]]

# A stale result shows checking while the background check runs.
printf 'up 1\n' > "$primary_state"
touch "$test_home/.probe-always-fails"
[[ "$("$script" status)" == ◈app ]]
wait_for_state down
[[ "$("$script" status)" == ◇app ]]
rm "$test_home/.probe-always-fails"

# A stale down result runs the local repair hook without another kctx selection.
printf 'down 1\n' > "$primary_state"
touch "$test_home/.probe-until-restart"
rm -f "$test_home/.hook-restarted" "$test_home/.hook-calls"
[[ "$("$script" status)" == ◈app ]]
wait_for_state up
[[ "$(<"$test_home/.hook-calls")" == "primary restart" ]]
rm "$test_home/.probe-until-restart"

# An explicit ensure calls the hook once after a failed probe.
rm -f "$test_home/.hook-restarted" "$test_home/.hook-calls"
touch "$test_home/.probe-fails-once"
"$script" ensure
wait_for_state up
[[ "$(<"$test_home/.hook-calls")" == "primary restart" ]]

# Concurrent selections must not restart over one another's repaired connection.
touch "$test_home/.probe-until-restart" "$test_home/.slow-restart"
rm -f "$test_home/.hook-restarted"
: > "$test_home/.hook-calls"
"$script" ensure & first=$!
/bin/sleep 0.1
"$script" ensure & second=$!
wait "$first"
wait "$second"
wait_for_state up
[[ "$(wc -l < "$test_home/.hook-calls")" -eq 1 ]]
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
  [[ "$output" == *◇app* ]] || {
    printf 'expected Starship to show the primary down glyph, got %s\n' "$output" >&2
    exit 1
  }
  prompt=$(TERM=xterm-256color STARSHIP_CONFIG="$repo_root/config/starship.toml" starship prompt --path "$repo_root")
  [[ "$prompt" == *primary*◇app* ]] && [[ "$prompt" != *☸* ]] && [[ "$prompt" != *'.kube_connectivity'* ]] || {
    printf 'expected a compact Kubernetes prompt, got %s\n' "$prompt" >&2
    exit 1
  }

  # Existing shells may lack the variable set by a newer zshrc.
  mkdir -p "$HOME/.config"
  ln -s "$repo_root/config/starship.toml" "$HOME/.config/starship.toml"
  output=$(env -u KCTX_STATUS_SCRIPT STARSHIP_CONFIG="$HOME/.config/starship.toml" starship module custom.kube_connectivity)
  [[ "$output" == *◇app* ]] || {
    printf 'expected Starship to find the script without KCTX_STATUS_SCRIPT, got %s\n' "$output" >&2
    exit 1
  }
fi

# A cache write failure must not make the checking indicator disappear.
printf 'down 1\n' > "$primary_state"
chmod 500 "$KCTX_STATUS_CACHE_DIR"
[[ "$("$script" status)" == ◈app ]]
chmod 700 "$KCTX_STATUS_CACHE_DIR"

printf 'kctx connectivity tests passed\n'
