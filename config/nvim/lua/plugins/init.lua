-- ~/.config/nvim/lua/plugins/init.lua

local icons = require('core.icons')

return {
  -- ========== Core Essentials ==========
  { 'tpope/vim-fugitive' },
  { 'tpope/vim-surround', event = 'VeryLazy' },
  { 'tpope/vim-repeat', event = 'VeryLazy' },
  { 'tpope/vim-eunuch', event = 'VeryLazy' },

  -- ========== UI & Appearance ==========
  {
    'morhetz/gruvbox',
    priority = 1000,
    config = function()
      vim.o.background = 'dark'
      vim.cmd('colorscheme gruvbox')
      vim.api.nvim_set_hl(0, 'LspDiagnosticsVirtualTextError', { fg = '#FB4934', bg = 'NONE', bold = true, italic = true, underline = true })
      vim.api.nvim_set_hl(0, 'LspDiagnosticsVirtualTextWarning', { fg = '#FABD2F', bg = 'NONE', bold = true, italic = true, underline = true })
      vim.api.nvim_set_hl(0, 'LspDiagnosticsVirtualTextInformation', { fg = '#83A598', bg = 'NONE', bold = true, italic = true, underline = true })
      vim.api.nvim_set_hl(0, 'LspDiagnosticsVirtualTextHint', { fg = '#B8BB26', bg = 'NONE', bold = true, italic = true, underline = true })
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    event = "VeryLazy",
    opts = {
      options = {
        theme = 'gruvbox',
        icons_enabled = true,
        component_separators = { left = icons.separators.component_left, right = icons.separators.component_right },
        section_separators = { left = icons.separators.section_left, right = icons.separators.section_right },
        disabled_filetypes = { statusline = {}, winbar = {} },
        ignore_focus = {},
        always_divide_middle = true,
        globalstatus = true,
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {{'filename', path = 1}},
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {}, lualine_b = {}, lualine_c = {{'filename', path = 1}},
        lualine_x = {'location'}, lualine_y = {}, lualine_z = {}
      },
      tabline = {}, winbar = {}, inactive_winbar = {},
      extensions = {'fugitive', 'nvim-tree', 'trouble'}
    }
  },

  { 'nvim-tree/nvim-web-devicons', lazy = true },

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    cmd = { "TroubleToggle", "Trouble" },
    opts = {
      position = "bottom", height = 10, width = 50, icons = true,
      mode = "workspace_diagnostics",
      fold_open = icons.fold.open, fold_closed = icons.fold.closed,
      action_keys = {
          close = "q", cancel = "<esc>", refresh = "r",
          jump = {"<cr>", "<tab>"}, open_split = { "<c-x>" },
          open_vsplit = { "<c-v>" }, open_tab = { "<c-t>" },
          jump_close = {"o"}, toggle_mode = "m", toggle_preview = "P",
          hover = "K", preview = "p", close_folds = {"zM", "zm"},
          open_folds = {"zR", "zr"}, toggle_fold = {"zA", "za"},
          previous = "k", next = "j"
      },
      indent_lines = true, auto_open = false, auto_close = false,
      auto_preview = true, auto_fold = false,
      signs = {
        error = icons.diagnostic.error,
        warning = icons.diagnostic.warning,
        hint = icons.diagnostic.hint,
        information = icons.diagnostic.info,
        other = icons.diagnostic.other,
      },
      use_lsp_diagnostic_signs = false
    },
  },

  -- ========== Mason (package manager for LSP servers) ==========
  {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    event = "VeryLazy",
    opts = {
      ui = {
        border = "rounded",
        icons = {
          package_installed = icons.mason.installed,
          package_pending = icons.mason.pending,
          package_uninstalled = icons.mason.uninstalled,
        }
      }
    },
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = { 'williamboman/mason.nvim' },
    opts = {
      ensure_installed = { "lua_ls", "rust_analyzer" },
      automatic_installation = false,
    },
  },

  -- ========== LSP Configuration (Neovim 0.11 native API) ==========
  -- Keymaps are in core/autocmds.lua via LspAttach autocmd
  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" },
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim',
      { 'j-hui/fidget.nvim', tag = "legacy", opts = {} },
    },
    config = function()
      vim.lsp.config('lua_ls', {
        settings = {
          Lua = {
            runtime = { version = 'LuaJIT' },
            diagnostics = { globals = { 'vim' }, disable = {'undefined-global', 'missing-fields'} },
            workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
            completion = { callSnippet = "Replace" },
            telemetry = { enable = false },
          },
        },
      })

      vim.lsp.config('ty', {
        cmd = { 'ty', 'server' },
        filetypes = { 'python' },
        root_markers = { 'pyproject.toml', 'setup.py', 'setup.cfg', '.git' },
      })

      vim.lsp.config('rust_analyzer', {})

      vim.lsp.enable('lua_ls')
      vim.lsp.enable('rust_analyzer')
      if vim.fn.executable('ty') == 1 then
        vim.lsp.enable('ty')
      end

      vim.diagnostic.config({
        virtual_text = false,
        signs = {
          text = {
            [vim.diagnostic.severity.ERROR] = icons.diagnostic.error,
            [vim.diagnostic.severity.WARN]  = icons.diagnostic.warning,
            [vim.diagnostic.severity.HINT]  = icons.diagnostic.hint,
            [vim.diagnostic.severity.INFO]  = icons.diagnostic.info,
          }
        },
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })
    end,
  },

  -- ========== Fuzzy Finding ==========
  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
      local exclude_patterns = {
        ".git", ".venv", ".mypy_cache", "__pycache__",
        ".github", ".deps", ".ruff_cache", "*.so", "*.o"
      }

      local fd_command_parts = {"fd --type f --hidden --follow"}
      for _, pattern in ipairs(exclude_patterns) do
        table.insert(fd_command_parts, "--exclude " .. pattern)
      end
      local fd_command_str = table.concat(fd_command_parts, " ")

      local find_name_conditions = {}
      for _, pattern in ipairs(exclude_patterns) do
        table.insert(find_name_conditions, "-name " .. pattern)
      end

      local find_prune_section = ""
      if #find_name_conditions > 0 then
        find_prune_section = "\\( " .. table.concat(find_name_conditions, " -o ") .. " \\) -prune -o "
      end
      local find_command_str = "find . " .. find_prune_section .. "-type f -print"

      require('fzf-lua').setup({
        winopts = { },
        keymap = {
          default = { ["<c-s>"] = "split", ["<c-v>"] = "vsplit", ["<c-t>"] = "tabedit" },
          fzf = { ["ctrl-d"] = "preview-page-down", ["ctrl-u"] = "preview-page-up" },
        },
        files = {
          cmd = vim.fn.executable("fd") == 1 and fd_command_str or find_command_str,
        },
        live_grep_native = {
          cmd = "rg --color=always --line-number --no-heading --smart-case ''"
        },
      })
    end
  },

  -- ========== File Explorer ==========
  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'NvimTreeToggle',
    keys = { {'<leader>e', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle NvimTree Explorer'} },
    opts = {
      sort_by = "case_sensitive", hijack_netrw = true,
      view = {
        width = 30, side = 'left', preserve_window_proportions = false,
        number = false, relativenumber = false, signcolumn = "yes",
        float = { enable = false },
      },
      renderer = {
        group_empty = true, highlight_git = true, highlight_diagnostics = true,
        indent_markers = { enable = true },
        icons = {
            show = { file = true, folder = true, folder_arrow = true, git = true, diagnostics = true },
            glyphs = {
                default = icons.file.default, symlink = icons.file.symlink,
                folder = {
                  arrow_closed = icons.folder.arrow_closed,
                  arrow_open = icons.folder.arrow_open,
                  default = icons.folder.default,
                  open = icons.folder.open,
                  empty = icons.folder.empty,
                  empty_open = icons.folder.empty_open,
                  symlink = icons.folder.symlink,
                  symlink_open = icons.folder.symlink_open,
                },
                git = {
                  unstaged = icons.git.unstaged,
                  staged = icons.git.staged,
                  unmerged = icons.git.unmerged,
                  renamed = icons.git.renamed,
                  untracked = icons.git.untracked,
                  deleted = icons.git.deleted,
                  ignored = icons.git.ignored,
                },
            },
        },
      },
      filters = { dotfiles = false, custom = { ".git", "node_modules", ".cache", "__pycache__" }, exclude = {} },
      git = { enable = true, ignore = false, timeout = 400 },
      update_focused_file = { enable = true, update_root = false },
      diagnostics = {
        enable = true, show_on_dirs = true,
        icons = {
          hint = icons.diagnostic.hint,
          info = icons.diagnostic.info,
          warning = icons.diagnostic.warning,
          error = icons.diagnostic.error,
        },
      },
      actions = { open_file = { quit_on_open = false, resize_window = true, window_picker = { enable = true, chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", exclude = { filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" }, buftype = { "nofile", "terminal", "help" } } } } },
    },
  },

  -- ========== Other Plugins ==========
  { 'ojroques/vim-oscyank', branch = 'main', event = 'VeryLazy' },

  -- ========== Task Runner ==========
  {
    'stevearc/overseer.nvim',
    cmd = { 'OverseerRun', 'OverseerToggle', 'OverseerOpen', 'OverseerClose', 'OverseerInfo' },
    keys = {
      { '<leader>or', '<cmd>OverseerRun<CR>', desc = 'Overseer Run Task' },
      { '<leader>ot', '<cmd>OverseerToggle<CR>', desc = 'Overseer Toggle' },
    },
    opts = {},
  },
}
