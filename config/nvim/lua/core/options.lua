-- ~/.config/nvim/lua/core/options.lua

local opt = vim.opt -- Alias for convenience

-- General
opt.mouse = '' -- Disable mouse
opt.clipboard = 'unnamedplus' -- Use system clipboard (recommended)
opt.swapfile = false -- Consider disabling swapfile if using modern fs/git
opt.backup = false -- Disable backup files
opt.undofile = true -- Enable persistent undo

-- Construct the path as a Lua string
local undodir_path = vim.fn.stdpath('data') .. '/undodir'
opt.undodir = undodir_path -- Set the Neovim option
if vim.fn.isdirectory(undodir_path) == 0 then -- Check if directory exists
  vim.fn.mkdir(undodir_path, 'p') -- Create undodir if it doesn't exist using the string path
end

-- Construct the path as a Lua string
local swapdir_path = vim.fn.stdpath('data') .. '/swap//' -- Centralized swap files (double slash matters)
opt.directory = swapdir_path -- Set the Neovim option
if vim.fn.isdirectory(swapdir_path) == 0 then -- Check if directory exists
  vim.fn.mkdir(swapdir_path, 'p', 0700) -- Create swapdir using the string path, with permissions
end


-- Appearance
opt.number = true -- Show line numbers
-- opt.relativenumber = true -- Show relative line numbers (optional, common preference)
opt.cursorline = true -- Highlight the current line
opt.termguicolors = true -- Enable true color support (Required for many themes)
opt.background = 'dark' -- Set background (gruvbox might override this)
opt.signcolumn = 'yes' -- Always show the sign column
opt.showcmd = true -- Show command in bottom bar
opt.ruler = true -- Show cursor position
opt.splitright = true -- Open vertical splits to the right
opt.splitbelow = true -- Open horizontal splits below
opt.cmdheight = 1 -- Command line height (1 is often enough with noice.nvim or similar)
opt.laststatus = 3 -- Global statusline

-- Behavior
opt.hidden = true -- Allow buffer switching without saving
opt.lazyredraw = true -- Makes macros run faster
opt.incsearch = true -- Incremental search
opt.hlsearch = false -- Don't highlight all search matches persistently
opt.ignorecase = true -- Ignore case in search patterns
opt.smartcase = true -- Override ignorecase if pattern has uppercase letters
opt.updatetime = 100 -- Faster update time for CursorHold events, etc.
opt.shortmess:append('c') -- Don't show redundant messages from completion
opt.inccommand = 'nosplit' -- Live preview for :s commands

-- Indentation
opt.tabstop = 2
opt.shiftwidth = 2
opt.expandtab = true
opt.autoindent = true
opt.smartindent = true -- Use smart indentation

-- Completion
opt.completeopt = 'menuone,noselect,preview' -- Completion options

-- Files & Paths
opt.path = './../../../**5,**' -- Set search path relative to cwd, include default recursive
opt.tags = './tags;,tags;' -- Set tags file path (relative and global)
opt.autochdir = false -- WARNING: autochdir can cause issues with LSP/plugins. Consider removing or using project-specific solutions.

-- Folding (optional basic settings)
-- opt.foldmethod = 'indent'
-- opt.foldlevel = 99
-- opt.foldenable = true

-- Other
opt.cinoptions = 'g0' -- C indent options
opt.complete:remove('i') -- Remove 'i' (scanning included files) from completion sources

-- Set filetype stuff (better handled by autocmds or ftplugins)
vim.filetype.add({
  extension = {
    cc = 'cpp',
    proto = 'cpp',
    -- Add other mappings if needed
  },
})

-- Global statusline requires this after plugins are potentially loaded
vim.defer_fn(function()
  vim.opt.laststatus = 3
end, 100) -- Defer setting laststatus to ensure plugins like lualine take over correctly
