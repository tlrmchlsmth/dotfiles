#!/bin/zsh
set -e

repo_root=${0:A:h:h}
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/.local/bin"

cat > "$test_home/.local/bin/kubectl" <<'EOF'
#!/bin/sh
case "$*" in
  "--context vllm-gb200 --request-timeout=5s get --raw=/readyz")
    printf 'probe\n' >> "$HOME/.gb200-probes"
    if [ -f "$HOME/.gb200-probe-always-fails" ]; then
      exit 1
    fi
    if [ -f "$HOME/.gb200-probe-fails-once" ]; then
      rm "$HOME/.gb200-probe-fails-once"
      exit 1
    fi
    ;;
  "config current-context")
    if [ -n "$KUBECONFIG" ] && [ -f "$KUBECONFIG" ]; then
      sed -n 's/^current-context: *//p' "$KUBECONFIG"
    else
      printf '%s\n' source-context
    fi
    ;;
  "config view --minify --raw -o jsonpath={.clusters[0].cluster.server}")
    if [ -n "$KUBECONFIG" ] && [ -f "$KUBECONFIG" ]; then
      sed -n 's/^    server: *//p' "$KUBECONFIG"
    else
      printf '%s\n' https://source.example.test
    fi
    ;;
  "config view --minify --flatten --raw")
    cat <<'YAML'
apiVersion: v1
clusters:
- cluster:
    server: https://source.example.test
  name: source-cluster
kind: Config
current-context: source-context
users:
- name: source-user
  user:
YAML
    printf '    token: %s\n' "${KUBEIMPORT_TEST_TOKEN:-initial-token}"
    ;;
  "config rename-context "*)
    old_context=$3
    new_context=$4
    awk -v old="$old_context" -v new="$new_context" '
      $0 == "current-context: " old { print "current-context: " new; next }
      { print }
    ' "$KUBECONFIG" > "$KUBECONFIG.renamed" && mv "$KUBECONFIG.renamed" "$KUBECONFIG"
    ;;
  "config use-context "*)
    printf '%s\n' "$3" > "$HOME/.kubectl-used-context"
    ;;
  "completion zsh")
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "$test_home/.local/bin/kubectl"

for agent in codex claude hermes; do
cat > "$test_home/.local/bin/$agent" <<'EOF'
#!/bin/sh
agent=${0##*/}
printf '%s\n' "$KUBECONFIG" > "$HOME/.$agent-kubeconfig"
EOF
chmod +x "$test_home/.local/bin/$agent"
done

export HOME=$test_home
set +e
source "$repo_root/zshrc" >/dev/null 2>&1
set -e
if ! whence kubeimport >/dev/null; then
  print -u2 "zshrc did not define kubeimport"
  exit 1
fi
printf 'friendly-name\n' | kubeimport >/dev/null

expected="$test_home/.kube/configs/friendly-name.yaml"
if [[ ! -f "$expected" ]]; then
  print -u2 "expected interactive name to create $expected"
  exit 1
fi
if [[ "$(sed -n 's/^current-context: *//p' "$expected")" != friendly-name ]]; then
  print -u2 "expected imported context to be named friendly-name"
  exit 1
fi
if [[ "$(<"$test_home/.kube/last-context")" != friendly-name ]]; then
  print -u2 "expected imported context to be saved for new shells"
  exit 1
fi
if [[ "$(<"$test_home/.kubectl-used-context")" != friendly-name ]]; then
  print -u2 "expected imported context to be activated in the current shell"
  exit 1
fi
if [[ "$(sed -n 's/^current-context: *//p' "$test_home/.kube/agent-context")" != friendly-name ]]; then
  print -u2 "expected imported context to be saved for agents"
  exit 1
fi

# Saving an unchanged context should not create or replace any files.
integer mktemp_calls=0
mktemp() {
  (( mktemp_calls++ ))
  return 1
}
_save_kube_context friendly-name
if (( mktemp_calls != 0 )); then
  print -u2 "expected an unchanged agent context to avoid mktemp"
  exit 1
fi
unfunction mktemp

# Successful initialization should prepend a valid per-shell context file.
(
  unset KUBECONFIG
  _init_kube_shell_context
  shell_context="${KUBECONFIG%%:*}"
  if [[ ! -f "$shell_context" ]]; then
    print -u2 "expected kube context initialization to create a per-shell config"
    exit 1
  fi
  if [[ "$(sed -n 's/^current-context: *//p' "$shell_context")" != friendly-name ]]; then
    print -u2 "expected per-shell config to use the saved context"
    exit 1
  fi
  _init_kube_shell_context
  if [[ -e "$shell_context" ]]; then
    print -u2 "expected reinitialization to remove the previous per-shell config"
    exit 1
  fi
)

# A failed per-shell temp file must preserve the caller's KUBECONFIG.
(
  export KUBECONFIG=existing-kubeconfig
  mktemp() { return 1 }
  if _init_kube_shell_context 2>/dev/null; then
    print -u2 "expected kube context initialization to report mktemp failure"
    exit 1
  fi
  if [[ "$KUBECONFIG" != existing-kubeconfig ]]; then
    print -u2 "expected failed kube context initialization to preserve KUBECONFIG"
    exit 1
  fi
)

expected_kubeconfig="$test_home/.kube/agent-context:$test_home/.kube/configs/friendly-name.yaml"
for agent in codex claude hermes; do
  "$agent"
  actual_kubeconfig="$(<"$test_home/.$agent-kubeconfig")"
  if [[ "$actual_kubeconfig" != "$expected_kubeconfig" ]]; then
    print -u2 "expected $agent to use the persistent context and managed kubeconfigs"
    exit 1
  fi
done

kctx another-context >/dev/null
if [[ "$(sed -n 's/^current-context: *//p' "$test_home/.kube/agent-context")" != another-context ]]; then
  print -u2 "expected kctx to update the agent context"
  exit 1
fi

cat > "$test_home/kctx-status" <<'EOF'
#!/bin/sh
printf '%s\n' "$1" >> "$HOME/.kctx-status-calls"
EOF
chmod +x "$test_home/kctx-status"
export KCTX_STATUS_SCRIPT="$test_home/kctx-status"
touch "$test_home/.gb200-probe-always-fails"
kctx vllm-gb200 >/dev/null
if [[ "$(<"$test_home/.kctx-status-calls")" != connect ]] ||
   [[ -e "$test_home/.gb200-probes" ]] ||
   [[ "$(<"$test_home/.kubectl-used-context")" != vllm-gb200 ]] ||
   [[ "$(sed -n 's/^current-context: *//p' "$test_home/.kube/agent-context")" != vllm-gb200 ]]; then
  print -u2 "expected kctx to switch immediately and queue a background GB200 check"
  exit 1
fi

KUBEIMPORT_TEST_TOKEN=refreshed-token kubeimport friendly-name >/dev/null
if ! grep -q 'token: refreshed-token' "$expected"; then
  print -u2 "expected importing the same context to refresh $expected"
  exit 1
fi

cat > "$test_home/.kube/configs/collision.yaml" <<'EOF'
apiVersion: v1
kind: Config
current-context: source-context
clusters:
- cluster:
    server: https://other.example.test
  name: other-cluster
EOF
if kubeimport collision >/dev/null 2>&1; then
  print -u2 "expected a different existing cluster to require -f"
  exit 1
fi

kubeimport positional-name >/dev/null
expected="$test_home/.kube/configs/positional-name.yaml"
if [[ ! -f "$expected" ]]; then
  print -u2 "expected positional name to create $expected"
  exit 1
fi

printf '\n' | kubeimport >/dev/null
expected="$test_home/.kube/configs/source-context.yaml"
if [[ ! -f "$expected" ]]; then
  print -u2 "expected empty input to use current context at $expected"
  exit 1
fi

print 'kubeimport tests passed'
