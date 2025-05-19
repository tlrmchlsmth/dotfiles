-- ~/.config/nvim/lua/plugins/init.lua

return {
  -- ========== Core Essentials ==========
  { 'tpope/vim-fugitive', cmd = 'Git', ft = 'fugitive' },
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
      -- Optional: Perturb color setup (ensure utils/theme.lua and the function exist)
      -- vim.defer_fn(function()
      --   pcall(function() require('utils.theme').setup_perturb() end)
      -- end, 200)
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
        component_separators = { left = '', right = ''}, -- Nerd Font
        section_separators = { left = '', right = ''}, -- Nerd Font
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
      fold_open = "▾", fold_closed = "▸", -- Nerd Font
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
      signs = { error = "", warning = "", hint = "", information = "", other = "﫠" }, -- Nerd Font
      use_lsp_diagnostic_signs = false
    },
  },

  -- ========== Mason and LSP Setup ==========
  {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    event = "VeryLazy", -- Ensures it loads and configures on startup, available for other plugins.
                       -- Or remove 'event' entirely if you want it to load only when a dependent plugin pulls it in.
                       -- 'VeryLazy' is a good default for foundational plugins.
    config = function()
      vim.notify("[Mason] Attempting setup...", vim.log.levels.INFO, {title = "Plugin Setup"})
      local status_ok, res = pcall(require("mason").setup, {
        ui = {
          border = "rounded",
          icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" }
        }
      })
      if not status_ok then
        vim.notify("[Mason] ERROR setting up: " .. tostring(res), vim.log.levels.ERROR, {title = "Plugin Error"})
      else
        vim.notify("[Mason] Setup complete.", vim.log.levels.INFO, {title = "Plugin Setup"})
      end
    end,
  }, 
  
    {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    event = "VeryLazy", -- This setup was good
    config = function()
      vim.notify("[Mason] Attempting setup...", vim.log.levels.INFO, {title = "Plugin Setup"})
      local status_ok, res = pcall(require("mason").setup, {
        ui = {
          border = "rounded",
          icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" }
        }
      })
      if not status_ok then
        vim.notify("[Mason] ERROR setting up: " .. tostring(res), vim.log.levels.ERROR, {title = "Plugin Error"})
      else
        vim.notify("[Mason] Setup complete.", vim.log.levels.INFO, {title = "Plugin Setup"})
      end
    end,
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {'williamboman/mason.nvim'},
    -- This plugin will now handle the primary setup of LSPs via its 'handlers'.
    -- It should be triggered appropriately, often by nvim-lspconfig's events or by being a dependency.
    -- For safety, you can give it an event too, or rely on nvim-lspconfig pulling it in.
    event = "BufReadPre", -- Or let nvim-lspconfig trigger its load as a dependency
    config = function()
      vim.notify("[MasonLspconfig] Attempting setup with direct handlers...", vim.log.levels.INFO, {title = "Plugin Setup"})

      -- Define on_attach and capabilities INSIDE this config, or ensure they are accessible from an outer scope
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- If you use nvim-cmp, you would integrate its capabilities here:
      -- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      local on_attach = function(client, bufnr)
        vim.notify("LSP attached: " .. client.name .. " to buffer " .. bufnr, vim.log.levels.INFO, {title = "LSP"})
        local map = vim.keymap.set
        local lsp_opts = { noremap=true, silent=true, buffer=bufnr }
        map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', lsp_opts)
        map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', lsp_opts)
        map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', lsp_opts)
        map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', lsp_opts)
        map('n', '<leader>sh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', lsp_opts)
        map('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', lsp_opts)
        map('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', lsp_opts)
        map('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', lsp_opts)
        map('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', lsp_opts)
        map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', lsp_opts)
        map({'n', 'v'}, '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', lsp_opts)
        map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', lsp_opts)
        map('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float({scope = "line"})<CR>', lsp_opts)
        map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', lsp_opts)
        map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', lsp_opts)
        map('n', '<leader>qf', '<cmd>lua vim.diagnostic.setloclist()<CR>', lsp_opts)
        if client.supports_method("textDocument/formatting") then
            map({'n', 'v'}, '<leader>lf', function() vim.lsp.buf.format({ async = true, bufnr = bufnr }) end, lsp_opts)
        end
        -- Your C++/Header switching keymaps should be fine where they are if they don't rely on client object directly here.
      end

      local lspconfig_pkg = require('lspconfig') -- require lspconfig package

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "clangd",
          "pyright",
          "rust_analyzer"
        },
        automatic_installation = false, -- This is fine
        handlers = {
          -- Default handler for servers not explicitly defined below
          function(server_name)
            lspconfig_pkg[server_name].setup({
              on_attach = on_attach,
              capabilities = capabilities,
              flags = { debounce_text_changes = 150 },
            })
          end,
          ["lua_ls"] = function()
            lspconfig_pkg.lua_ls.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              settings = {
                Lua = {
                  runtime = { version = 'LuaJIT' },
                  diagnostics = { globals = { 'vim' }, disable = {'undefined-global', 'missing-fields'} },
                  workspace = { library = vim.api.nvim_get_runtime_file("", true), checkThirdParty = false },
                  completion = { callSnippet = "Replace" },
                  telemetry = { enable = false },
                },
              },
              flags = { debounce_text_changes = 150 },
            })
          end,
          ["clangd"] = function ()
            lspconfig_pkg.clangd.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              flags = { debounce_text_changes = 150 },
              -- You can add specific clangd settings here if needed, e.g., cmd for specific clangd binary
            })
          end,
          -- pyright and rust_analyzer will use the default handler above
          -- unless you define specific handlers for them here.
        }
      })
      vim.notify("[MasonLspconfig] Setup with direct handlers complete.", vim.log.levels.INFO, {title = "Plugin Setup"})
    end,
  },

  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" }, -- Still triggers the LSP ecosystem
    dependencies = {
      'williamboman/mason.nvim',          -- Mason core
      'williamboman/mason-lspconfig.nvim', -- Mason-lspconfig now handles server setup
      { 'j-hui/fidget.nvim', tag = "legacy", opts = {} }, -- LSP progress UI
    },
    config = function()
      vim.notify("[nvim-lspconfig] Main config block running.", vim.log.levels.INFO, {title = "Plugin Setup"})

      -- The main LSP server setups are now handled by mason-lspconfig's handlers.
      -- This block is now primarily for global LSP settings, diagnostics,
      -- or any LSP servers you might set up *manually* without mason-lspconfig.

      -- Global diagnostic configuration (important to keep)
      vim.diagnostic.config({
        virtual_text = false, -- You had this as false, can be true for inline diagnostics
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      -- Define diagnostic signs (important to keep)
      local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" } -- Or your preferred icons
      for type, icon in pairs(signs) do
        local hl_group = "DiagnosticSign" .. type
        vim.fn.sign_define(hl_group, { text = icon, texthl = hl_group, numhl = hl_group })
      end

      vim.notify("[nvim-lspconfig] Global diagnostic settings applied.", vim.log.levels.INFO, {title = "Plugin Setup"})
    end,
  },

  -- ========== Fuzzy Finding ==========
  {
    'ibhagwan/fzf-lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    config = function()
       require('fzf-lua').setup({
         winopts = { },
         keymap = {
           default = { ["<c-s>"] = "split", ["<c-v>"] = "vsplit", ["<c-t>"] = "tabedit" },
           fzf = { ["ctrl-d"] = "preview-page-down", ["ctrl-u"] = "preview-page-up" },
         },
         files = { cmd = vim.fn.executable("fd") == 1 and "fd --type f --hidden --follow --exclude .git" or "find . -type f -print" },
         live_grep_native = { cmd = "rg --color=always --line-number --no-heading --smart-case ''" },
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
                default = "", symlink = "",
                folder = { arrow_closed = "▸", arrow_open = "▾", default = "", open = "", empty = "", empty_open = "", symlink = "", symlink_open = "" },
                git = { unstaged = "", staged = "✓", unmerged = "", renamed = "➜", untracked = "U", deleted = "✗", ignored = "◌" },
                diagnostics = { error = "", warning = "", info = "", hint = "" }
            },
        },
      },
      filters = { dotfiles = false, custom = { ".git", "node_modules", ".cache", "__pycache__" }, exclude = {} },
      git = { enable = true, ignore = false, timeout = 400 },
      update_focused_file = { enable = true, update_root = false, ignore_cb_helpers = false },
      diagnostics = { enable = true, show_on_dirs = true, icons = { hint = "", info = "", warning = "", error = "" } },
      actions = { open_file = { quit_on_open = false, resize_window = true, window_picker = { enable = true, chars = "ABCDEFGHIJKLMNOPQRSTUVWXYZ1234567890", exclude = { filetype = { "notify", "packer", "qf", "diff", "fugitive", "fugitiveblame" }, buftype = { "nofile", "terminal", "help" } } } } },
    },
  },

  -- ========== Other Plugins ==========
  { 'ojroques/vim-oscyank', branch = 'main', event = 'VeryLazy' },
}

