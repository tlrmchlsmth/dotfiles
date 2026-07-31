-- ~/.config/nvim/lua/core/osc52.lua
--
-- Copy to the local system clipboard over SSH via the OSC 52 escape sequence.
-- Wraps Neovim's built-in OSC 52 writer, which base64-encodes in C.

local M = {}

local copy = require('vim.ui.clipboard.osc52').copy('+')

-- Yank the region described by `cmd` into register z without disturbing the
-- unnamed register, the visual marks, or 'selection'.
local function get_text(cmd)
  local register = vim.fn.getreginfo('z')
  local selection = vim.o.selection
  local marks = { vim.fn.getpos("'<"), vim.fn.getpos("'>") }

  vim.o.selection = 'inclusive'
  vim.cmd('keepjumps silent normal! ' .. cmd)
  local text = vim.fn.getreg('z')

  vim.fn.setreg('z', register)
  vim.o.selection = selection
  vim.fn.setpos("'<", marks[1])
  vim.fn.setpos("'>", marks[2])

  return text
end

function M.yank(text)
  copy(vim.split(text, '\n', { plain = true }))
  vim.notify(string.format('[osc52] %d characters copied', #text))
end

-- 'operatorfunc' callback: motion_type is one of 'char', 'line', 'block'.
function M.operator_callback(motion_type)
  local cmd = ({
    char = '`[v`]"zy',
    line = "'[V']\"zy",
    block = '`[' .. vim.keycode('<C-v>') .. '`]"zy',
  })[motion_type]
  M.yank(get_text(cmd))
end

function M.operator()
  vim.o.operatorfunc = "v:lua.require'core.osc52'.operator_callback"
  return 'g@'
end

-- Call this only after leaving visual mode (the mapping uses `:<C-u>`), so that
-- '< and '> are up to date and `gv` reselects the region the user just had.
function M.visual()
  M.yank(get_text('gv"zy'))
end

return M
