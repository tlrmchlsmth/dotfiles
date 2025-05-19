-- ~/.config/nvim/lua/utils/theme.lua

local M = {}

local function perturb_color()
  local normal_hl = vim.api.nvim_get_hl(0, { name = 'Normal', link = false })
  local current_bg_dec = normal_hl.bg -- This is a decimal number

  if not current_bg_dec then
    print('Could not get Normal background color')
    return
  end

  -- Convert decimal to RGB
  local B = math.floor(current_bg_dec % 256)
  local G = math.floor((current_bg_dec / 256) % 256)
  local R = math.floor(current_bg_dec / (256 * 256))

  -- Apply random perturbation (-4 to 4)
  R = math.min(255, math.max(0, R + math.random(-4, 4)))
  G = math.min(255, math.max(0, G + math.random(-4, 4)))
  B = math.min(255, math.max(0, B + math.random(-4, 4)))

  -- Convert RGB back to hex
  local new_bg_hex = string.format('#%02x%02x%02x', R, G, B)

  -- Set the new background color
  vim.api.nvim_set_hl(0, 'Normal', { bg = new_bg_hex })
  -- print('Perturbed Normal background to: ' .. new_bg_hex)
end

-- Function to set up calling the perturb function (e.g., on a timer or command)
function M.setup_perturb()
   -- Example: Create a command to manually perturb
   vim.api.nvim_create_user_command('PerturbBg', perturb_color, { desc = 'Randomly perturb background color' })

   -- Example: Call it once after setup (uncomment if desired)
   -- vim.defer_fn(perturb_color, 500) -- Call after 500ms delay
end


return M
