# Codex appearance

`gruvbox-dark.theme` is a Codex `codex-theme-v1` import string for Gruvbox
Dark (medium contrast), including the app UI and code highlighting. It uses
the warm `#282828` background, `#ebdbb2` foreground, gold accent, and Gruvbox
green/red diff colors. Fonts use the app defaults and windows are opaque.

## Apply or restore

1. Copy the entire contents of `gruvbox-dark.theme`. On macOS:
   ```sh
   pbcopy < ~/.dotfiles/codex/gruvbox-dark.theme
   ```
2. Open the Codex desktop app, then **Settings → Appearance** (`Cmd+,` on macOS).
3. Set **Theme** to **Dark**.
4. Under **Dark theme**, choose **Import**, paste the string, and confirm.

The import format and `gruvbox-dark-medium` code theme were checked against
the installed app on 2026-09-17. The UI import still needs to be performed
and checked in the app. Theme imports are described in the
[official appearance settings documentation](https://learn.chatgpt.com/docs/reference/settings#appearance).

This file is intentionally separate from `~/.codex/config.toml`: it is a
desktop appearance import, not CLI configuration. `install.sh` does not
apply it automatically; repeat the import when setting up another machine.
