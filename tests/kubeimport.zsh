#!/bin/zsh
set -e

repo_root=${0:A:h:h}
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
mkdir -p "$test_home/.local/bin"

cat > "$test_home/.local/bin/kubectl" <<'EOF'
#!/bin/sh
case "$*" in
  "config current-context")
    printf '%s\n' source-context
    ;;
  "config view --minify --flatten --raw")
    cat <<'YAML'
apiVersion: v1
kind: Config
current-context: source-context
YAML
    ;;
  "completion zsh")
    ;;
  *)
    exit 1
    ;;
esac
EOF
chmod +x "$test_home/.local/bin/kubectl"

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
