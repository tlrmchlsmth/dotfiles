local M = {}

local function notify(message, level)
  vim.notify(message, level or vim.log.levels.INFO, { title = 'GitHub' })
end

local function open(url)
  local _, err = vim.ui.open(url)
  if err then
    notify('Could not open ' .. url .. ': ' .. err, vim.log.levels.ERROR)
  end
end

local function blame_commit()
  local commit = vim.api.nvim_get_current_line():match('^%^?[*?]*([%x]+)')
  if not commit or commit:match('^0+$') then
    notify('This blame line has no committed revision', vim.log.levels.WARN)
    return nil
  end
  return commit
end

function M.open_blame_pr()
  local commit = blame_commit()
  if not commit then
    return
  end

  if vim.fn.executable('gh') ~= 1 then
    notify('The GitHub CLI (gh) is required to find a pull request', vim.log.levels.ERROR)
    return
  end

  local worktree = vim.fn.FugitiveWorkTree()
  if worktree == '' then
    notify('Could not find the Git worktree', vim.log.levels.ERROR)
    return
  end

  notify('Finding the pull request for ' .. commit .. '...')
  vim.system({
    'gh', 'api', 'repos/{owner}/{repo}/commits/' .. commit .. '/pulls',
  }, { cwd = worktree, text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      local detail = vim.trim(result.stderr or '')
      notify('Could not query GitHub' .. (detail == '' and '' or ': ' .. detail), vim.log.levels.ERROR)
      return
    end

    local ok, pull_requests = pcall(vim.json.decode, result.stdout)
    if not ok or type(pull_requests) ~= 'table' then
      notify('GitHub returned an unexpected response', vim.log.levels.ERROR)
      return
    end

    if #pull_requests == 0 then
      notify('No pull request contains commit ' .. commit, vim.log.levels.WARN)
      return
    end

    if #pull_requests == 1 then
      open(pull_requests[1].html_url)
      return
    end

    vim.ui.select(pull_requests, {
      prompt = 'Open pull request:',
      format_item = function(pr)
        return string.format('#%d %s', pr.number, pr.title)
      end,
    }, function(pr)
      if pr then
        open(pr.html_url)
      end
    end)
  end))
end

return M
