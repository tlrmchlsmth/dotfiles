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
api.nvim_create_autocmd('BufReadPost', {
  pattern = '*',
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line = mark[1]
    local col = mark[2]
    if line > 0 and line <= vim.api.nvim_buf_line_count(args.buf) then
      -- Defer setting cursor position slightly
      vim.defer_fn(function()
         vim.api.nvim_win_set_cursor(0, {line, col})
      end, 10) -- Small delay often helps
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

print('Autocommands loaded')
