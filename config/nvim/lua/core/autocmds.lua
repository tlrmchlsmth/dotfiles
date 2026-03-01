-- ~/.config/nvim/lua/core/autocmds.lua

local api = vim.api

-- Highlight yanked text
api.nvim_create_autocmd('TextYankPost', {
  pattern = '*',
  callback = function()
    vim.highlight.on_yank({ higroup = 'IncSearch', timeout = 200 })
  end,
  desc = 'Highlight yanked text',
})


-- Return to last edit position
vim.api.nvim_create_autocmd('BufReadPost', {
  callback = function(args)
    local buftype = vim.bo[args.buf].buftype
    if buftype ~= '' then
      return  -- skip special buffers like fugitive, help, etc.
    end

    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line = mark[1]
    local col = mark[2]
    if line > 0 and line <= vim.api.nvim_buf_line_count(args.buf) then
      vim.defer_fn(function()
        vim.api.nvim_win_set_cursor(0, {line, col})
      end, 10)
    end
  end,
  desc = 'Restore cursor position on buffer load',
})

-- Autocommands for specific file types (alternative to ftplugins for simple settings)
api.nvim_create_autocmd({'BufNewFile', 'BufRead'}, {
    pattern = {'*.ml'},
    callback = function ()
        vim.opt_local.cindent = false
        vim.opt_local.autoindent = true
    end,
    desc = "OCaml indentation settings"
})

api.nvim_create_autocmd('FileType', {
    pattern = 'json',
    command = 'syntax match Comment +\\/\\/.\\+$+',
    desc = "Allow // comments in JSON"
})

-- LSP keymaps on attach (Neovim 0.11+ style)
api.nvim_create_autocmd('LspAttach', {
  callback = function(args)
    local client = vim.lsp.get_client_by_id(args.data.client_id)
    if client then
      vim.notify("LSP attached: " .. client.name .. " to buffer " .. args.buf, vim.log.levels.INFO, { title = "LSP" })
    end

    local map = vim.keymap.set
    local opts = { noremap = true, silent = true, buffer = args.buf }

    map('n', 'gD', vim.lsp.buf.declaration, vim.tbl_extend('keep', opts, { desc = 'LSP Declaration' }))
    map('n', 'gd', vim.lsp.buf.definition, vim.tbl_extend('keep', opts, { desc = 'LSP Definition' }))
    map('n', 'K', vim.lsp.buf.hover, vim.tbl_extend('keep', opts, { desc = 'LSP Hover' }))
    map('n', 'gi', vim.lsp.buf.implementation, vim.tbl_extend('keep', opts, { desc = 'LSP Implementation' }))
    map('n', '<leader>sh', vim.lsp.buf.signature_help, vim.tbl_extend('keep', opts, { desc = 'LSP Signature Help' }))
    map('n', '<leader>wa', vim.lsp.buf.add_workspace_folder, vim.tbl_extend('keep', opts, { desc = 'LSP Add Workspace Folder' }))
    map('n', '<leader>wr', vim.lsp.buf.remove_workspace_folder, vim.tbl_extend('keep', opts, { desc = 'LSP Remove Workspace Folder' }))
    map('n', '<leader>wl', function() print(vim.inspect(vim.lsp.buf.list_workspace_folders())) end, vim.tbl_extend('keep', opts, { desc = 'LSP List Workspace Folders' }))
    map('n', '<leader>D', vim.lsp.buf.type_definition, vim.tbl_extend('keep', opts, { desc = 'LSP Type Definition' }))
    map('n', '<leader>rn', vim.lsp.buf.rename, vim.tbl_extend('keep', opts, { desc = 'LSP Rename' }))
    map({'n', 'v'}, '<leader>ca', vim.lsp.buf.code_action, vim.tbl_extend('keep', opts, { desc = 'LSP Code Action' }))
    map('n', 'gr', vim.lsp.buf.references, vim.tbl_extend('keep', opts, { desc = 'LSP References' }))
    map('n', '<leader>e', function() vim.diagnostic.open_float({scope = "line"}) end, vim.tbl_extend('keep', opts, { desc = 'LSP Line Diagnostics' }))
    map('n', '[d', vim.diagnostic.goto_prev, vim.tbl_extend('keep', opts, { desc = 'LSP Prev Diagnostic' }))
    map('n', ']d', vim.diagnostic.goto_next, vim.tbl_extend('keep', opts, { desc = 'LSP Next Diagnostic' }))
    map('n', '<leader>qf', vim.diagnostic.setloclist, vim.tbl_extend('keep', opts, { desc = 'LSP Diagnostics to Loclist' }))

    if client and client.supports_method("textDocument/formatting") then
      map({'n', 'v'}, '<leader>lf', function() vim.lsp.buf.format({ async = true, bufnr = args.buf }) end, vim.tbl_extend('keep', opts, { desc = 'LSP Format Document' }))
    end
  end,
  desc = 'LSP keymaps on attach',
})
