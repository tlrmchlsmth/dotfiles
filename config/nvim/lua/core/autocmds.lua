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
    local current_buf_name = vim.api.nvim_buf_get_name(args.buf)
    local ft_detected = vim.bo[args.buf].filetype
    local function get_primary_filetype(ft_string)
      if not ft_string or ft_string == '' then
        return ''
      end
      -- Match characters from the beginning (^) that are not a dot (.) or colon (:)
      -- This gives the part before the first dot or colon.
      local primary = string.match(ft_string, "^[^.:]+")
      return primary or ft_string -- Return the matched part, or the original if no separator
    end
    ft = get_primary_filetype(current_buf_name)

    -- If it's a fugitive blame buffer, do nothing and let fugitive handle the cursor
    if ft == 'fugitive' or ft_detected == 'git' then -- Or whatever filetype you confirmed in step 1
      return
    end

    -- Original logic for other buffers
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line = mark[1]
    local col = mark[2]
    if line > 0 and line <= vim.api.nvim_buf_line_count(args.buf) then
      -- Defer setting cursor position slightly
      vim.defer_fn(function()
         vim.api.nvim_win_set_cursor(0, {line, col})
      end, 10) -- Small delay often helps
    else
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
