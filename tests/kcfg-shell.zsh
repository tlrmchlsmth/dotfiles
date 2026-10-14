#!/bin/zsh
# Verify dotfiles selects its installed CLI, even with an older Go-installed copy.
set -e
repo_root=${0:A:h:h}
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"
export ZDOTDIR="$test_home"
unset KUBECONFIG KCTX_SESSION
mkdir -p "$HOME/.local/bin" "$HOME/go/bin"
cat > "$HOME/.local/bin/kcfg" <<'SH'
#!/bin/sh
case "$1" in
 init)
  [ "$2" = zsh ] || exit 1
  cat <<'ZSH'
kcfg() { command kcfg "$@"; }
alias kctx='kcfg context'
alias kns='kcfg namespace'
ZSH
  ;;
 *) printf '%s\n' "$@" > "$HOME/call" ;;
esac
SH
cat > "$HOME/go/bin/kcfg" <<'SH'
#!/bin/sh
touch "$HOME/stale-kcfg"
exit 1
SH
chmod +x "$HOME/.local/bin/kcfg" "$HOME/go/bin/kcfg"
# Full zshrc also initializes unrelated optional tools; its final hook may
# return nonzero when there is no virtualenv.
set +e
source "$repo_root/zshrc" >/dev/null 2>&1
set -e
[[ ! -e "$HOME/stale-kcfg" ]]
[[ ${commands[kcfg]} == "$HOME/.local/bin/kcfg" ]]
[[ ${aliases[kctx]} == 'kcfg context' ]]
[[ ${aliases[kns]} == 'kcfg namespace' ]]
kctx fixture-context
[[ $(<"$HOME/call") == $'context\nfixture-context' ]]
kns fixture-namespace
[[ $(<"$HOME/call") == $'namespace\nfixture-namespace' ]]
codex --help
[[ $(<"$HOME/call") == $'exec\ncodex\n--help' ]]
print 'kcfg shell integration tests passed'
