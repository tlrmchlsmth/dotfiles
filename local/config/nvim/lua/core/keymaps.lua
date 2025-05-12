-- ~/.config/nvim/lua/core/keymaps.lua

local map = vim.keymap.set
local opts = { noremap = true, silent = true } -- Default options for most mappings

print('Loading keymaps...')

-- Leader Key is set in init.lua (vim.g.mapleader = ',')

-- Normal Mode Mappings
map('n', '<leader>p', ':FzfLua files<CR>', { noremap = true, silent = false, desc = 'FZF Files (Root)' })
map('n', '<leader>g', ':FzfLua live_grep_native<CR>', { noremap = true, silent = false, desc = 'FZF Live Grep (Root)' }) -- Using native rg is faster if available

map('n', '<leader>xx', '<cmd>TroubleToggle<cr>', { desc = 'Toggle Trouble' })
map('n', '<leader>xw', '<cmd>TroubleToggle lsp_workspace_diagnostics<cr>', { desc = 'Workspace Diagnostics' })
map('n', '<leader>xd', '<cmd>TroubleToggle lsp_document_diagnostics<cr>', { desc = 'Document Diagnostics' })
map('n', '<leader>xq', '<cmd>TroubleToggle quickfix<cr>', { desc = 'Quickfix List in Trouble' })
map('n', '<leader>xl', '<cmd>TroubleToggle loclist<cr>', { desc = 'Location List in Trouble' })
map('n', 'gR', '<cmd>TroubleToggle lsp_references<cr>', { desc = 'LSP References in Trouble' })

-- LSP Mappings (will be attached in lspconfig setup)
-- Note: 'gD', 'gd', 'K', 'gr' are often handled by lspconfig's on_attach function

-- OSCYank Mappings (Clipboard over SSH)
map('n', '<leader>c', '<Plug>OSCYankOperator', { desc = 'OSCYank Operator' })
map('n', '<leader>cc', '<leader>c_', { desc = 'OSCYank Line' })
map('v', '<leader>c', '<Plug>OSCYankVisual', { desc = 'OSCYank Visual' })

-- Single Character Insert
map('n', 's', function() vim.cmd('normal! i' .. vim.fn.nr2char(vim.fn.getchar()) .. '\x1b') end, opts)
map('n', 'S', function() vim.cmd('normal! a' .. vim.fn.nr2char(vim.fn.getchar()) .. '\x1b') end, opts)

-- Viewport/Window Movement
map('n', 'gh', '<C-w>h', opts)
map('n', 'gj', '<C-w>j', opts)
map('n', 'gk', '<C-w>k', opts)
map('n', 'gl', '<C-w>l', opts)
map('n', 'gw', '<C-w>w', opts)

-- Tab Navigation
map('n', '<Leader>tn', ':tabnew<CR>', { desc = 'New Tab' })
map('n', '<Leader>tl', ':tabnext<CR>', { desc = 'Next Tab' })
map('n', '<Leader>th', ':tabprevious<CR>', { desc = 'Previous Tab' })
for i = 1, 9 do
  map('n', '<Leader>t' .. i, ':' .. i .. 'tabnext<CR>', { desc = 'Go to Tab ' .. i })
end
map('n', '<Leader>t0', ':tablast<CR>', { desc = 'Go to Last Tab' }) -- Map <leader>t0 too

-- Page Up/Down remapping
map({'n', 'v'}, '<Leader>f', '<C-d>', { noremap = true, silent = false }) -- Keep default behavior visible
map({'n', 'v'}, '<Leader>b', '<C-u>', { noremap = true, silent = false })
map({'n', 'v'}, '<C-f>', '<Nop>', opts)
map({'n', 'v'}, '<C-b>', '<Nop>', opts)

-- Redo / Jump Back
map('n', '<Leader>r', '<C-r>', opts)
map('n', '<Leader>o', '<C-o>', opts)

-- Tag Generation
map('n', '<C-F12>', ':!ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .<CR>', { desc = 'Generate Ctags' })

-- Formatting (Using LSP)
map({'n', 'v'}, '<C-k>', function()
  -- Check if LSP formatting is available
  local format_supported = false
  for _, client in ipairs(vim.lsp.get_active_clients({ bufnr = 0 })) do
    if client.supports_method("textDocument/formatting") then
      format_supported = true
      break
    end
  end

  if format_supported then
    vim.lsp.buf.format({ async = true })
    print("LSP formatting triggered.")
  else
    print("No active LSP client supports formatting for this buffer.")
    -- Alternative: Try conform.nvim if installed
    -- if require('conform') then require('conform').format({ async = true }) end
  end
end, { desc = "Format Code (LSP)" })

-- Visual Mode Mappings
-- Search for visually selected text
map('v', '//', 'y/\\V<C-R>"<CR>', { noremap = true, silent = false, desc = 'Search Visual Selection' })

-- Disable K (keyword lookup) if not using LSP default or want it free
-- map('n', 'K', '<Nop>', opts)

-- C++/Header switching (moved to utils and called from here)
map('n', '<Leader>c', function() require('utils.file_switch').switch_cpp_header('cpp') end, { desc = 'Switch to C++ Source' })
map('n', '<Leader>h', function() require('utils.file_switch').switch_cpp_header('hpp') end, { desc = 'Switch to C++ Header' })

print('Keymaps loaded')
