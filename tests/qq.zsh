#!/bin/zsh
# Ensure qq forwards short prompts to the intended Codex model.
set -e
repo_root=${0:A:h:h}
test_home=$(mktemp -d)
trap 'rm -rf "$test_home"' EXIT
export HOME="$test_home"
export ZDOTDIR="$test_home"
mkdir -p "$HOME/.local/bin"
cat > "$HOME/.local/bin/codex" <<'SH'
#!/bin/sh
printf '%s\n' "$@" > "$HOME/codex-args"
SH
chmod +x "$HOME/.local/bin/codex"
export PATH="$HOME/.local/bin:$PATH"

# The zshrc's optional integrations are unrelated to this test.
set +e
source "$repo_root/zshrc" >/dev/null 2>&1
set -e
qq "summarize this" "in one sentence"
[[ $(<"$HOME/codex-args") == $'exec\n-m\ngpt-5.6-luna\nsummarize this\nin one sentence' ]]
print 'qq shell integration test passed'
