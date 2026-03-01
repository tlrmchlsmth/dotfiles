-- ~/.config/nvim/lua/core/icons.lua
-- Centralized icon definitions using Unicode escapes for safe editing.
-- All glyphs require a Nerd Font (e.g. Hack Nerd Font).

return {
  -- Lualine separators
  separators = {
    component_left  = "\u{e0b1}",
    component_right = "\u{e0b3}",
    section_left    = "\u{e0b0}",
    section_right   = "\u{e0b2}",
  },

  -- Diagnostic signs (used in gutter and trouble.nvim)
  diagnostic = {
    error       = "\u{f057}",
    warning     = "\u{f071}",
    hint        = "\u{f834}",
    info        = "\u{f05a}",
    other       = "\u{fae0}",
  },

  -- Fold indicators
  fold = {
    open   = "\u{25be}",  -- ▾
    closed = "\u{25b8}",  -- ▸
  },

  -- Mason UI
  mason = {
    installed   = "\u{2713}",  -- ✓
    pending     = "\u{279c}",  -- ➜
    uninstalled = "\u{2717}",  -- ✗
  },

  -- File explorer (nvim-tree)
  file = {
    default      = "\u{f4a5}",
    symlink      = "\u{f481}",
  },

  folder = {
    arrow_closed = "\u{25b8}",  -- ▸
    arrow_open   = "\u{25be}",  -- ▾
    default      = "\u{f115}",
    open         = "\u{f114}",
    empty        = "\u{f115}",
    empty_open   = "\u{f114}",
    symlink      = "\u{f482}",
    symlink_open = "\u{f482}",
  },

  git = {
    unstaged  = "\u{f044}",
    staged    = "\u{2713}",  -- ✓
    unmerged  = "\u{e727}",
    renamed   = "\u{279c}",  -- ➜
    untracked = "U",
    deleted   = "\u{2717}",  -- ✗
    ignored   = "\u{25cc}",  -- ◌
  },
}
