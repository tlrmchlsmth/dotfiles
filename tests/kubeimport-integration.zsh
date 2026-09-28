#!/bin/zsh
# Exercise kubeconfig merging with real kubectl; no cluster access is needed.
set -e
repo_root=${0:A:h:h}
command -v kubectl >/dev/null
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT

for scenario in first-import existing-shell; do
  mkdir -p "$test_home/$scenario"
  env HOME="$test_home/$scenario" KUBECONFIG="" zsh -f -s -- "$repo_root" "$scenario" <<'ZSH'
set -e
repo_root=$1
scenario=$2
mkdir -p "$HOME/.kube"
cat > "$HOME/.kube/config" <<'YAML'
apiVersion: v1
kind: Config
current-context: default/api.example.test:6443/test-user
clusters:
- name: source-cluster
  cluster:
    server: https://example.test
contexts:
- name: default/api.example.test:6443/test-user
  context:
    cluster: source-cluster
    user: source-user
users:
- name: source-user
  user:
    token: fixture-token
YAML
cp "$HOME/.kube/config" "$HOME/source-before"
if [[ $scenario == existing-shell ]]; then
  mkdir -p "$HOME/.kube/configs"
  cp "$HOME/.kube/config" "$HOME/.kube/configs/source.yaml"
fi
set +e
source "$repo_root/zshrc" >/dev/null 2>&1
set -e
# Avoid starting background connectivity checks against the fixture server.
KCTX_STATUS_SCRIPT=/usr/bin/true
previous_shell_context=${_KUBE_SHELL_CONTEXT:-}
kubeimport pirate2
[[ $(kubectl config current-context) == pirate2 ]]
[[ $(kubectl config view --minify -o jsonpath='{.clusters[0].cluster.server}') == https://example.test ]]
[[ ":$KUBECONFIG:" == *":$HOME/.kube/configs/pirate2.yaml:"* ]]
[[ -z $previous_shell_context || ! -e $previous_shell_context ]]
kctx pirate2
[[ $(<"$HOME/.kube/last-context") == pirate2 ]]
[[ $(KUBECONFIG="$HOME/.kube/agent-context:$HOME/.kube/configs/pirate2.yaml" command kubectl config current-context) == pirate2 ]]
cmp "$HOME/source-before" "$HOME/.kube/config"
if [[ $scenario == existing-shell ]]; then
  cmp "$HOME/source-before" "$HOME/.kube/configs/source.yaml"
fi

# A second import in the same shell must also become visible immediately.
kubeimport second-name
[[ $(kubectl config current-context) == second-name ]]
kctx pirate2
kubeimport pirate2
[[ $(kubectl config current-context) == pirate2 ]]

# Activation failure leaves the old shell usable and does not save a stale
# selection for agents or future shells. The exported config remains usable.
previous_kubeconfig=$KUBECONFIG
# Fail only after export, when initialization tries to create its shell file.
mktemp() {
  [[ $1 == "$HOME/.kube/shell.XXXXXX" ]] && return 1
  command mktemp "$@"
}
if kubeimport retry-name >"$HOME/failure-output" 2>&1; then
  print -u2 'expected activation failure'
  exit 1
fi
[[ $KUBECONFIG == $previous_kubeconfig ]]
[[ $(<"$HOME/.kube/last-context") == pirate2 ]]
[[ -f "$HOME/.kube/configs/retry-name.yaml" ]]
unfunction mktemp
_init_kube_shell_context retry-name
[[ $(kubectl config current-context) == retry-name ]]
ZSH
done
print 'kubeimport integration tests passed'
