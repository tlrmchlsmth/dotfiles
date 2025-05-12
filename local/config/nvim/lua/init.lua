-- ~/.config/nvim/init.lua

-- Set leader key BEFORE loading lazy
vim.g.mapleader = ','
vim.g.maplocalleader = ',' -- Optional: Set local leader as well

-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath('data') .. '/lazy/lazy.nvim'
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    'git',
    'clone',
    '--filter=blob:none',
    'https://github.com/folke/lazy.nvim.git',
    '--branch=stable', -- latest stable release
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Load core configuration first
require('core.options')
require('core.autocmds')
require('core.keymaps') -- Load keymaps after options/leader

-- Setup lazy.nvim and load plugins
require('lazy').setup('plugins', {
  -- Configure lazy options if needed, e.g., UI theme
  ui = {
    border = 'rounded',
  },
  change_detection = {
    enabled = true,
    notify = false, -- Don't notify on config change detection
  },
})

-- Load utility functions (optional, place after lazy setup if they depend on plugins)
-- require('utils') -- Example if you create a utils/init.lua

print('Neovim configured with Lua and lazy.nvim!')
