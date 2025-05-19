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

    -- ========== Mason and LSP Setup ==========
  {
    'williamboman/mason.nvim',
    build = ":MasonUpdate",
    event = "VeryLazy", -- Ensures Mason is set up early and available.
    config = function()
      require("mason").setup({
        ui = {
          border = "rounded",
          icons = { package_installed = "✓", package_pending = "➜", package_uninstalled = "✗" }
        }
      })
      -- You can add a vim.notify here if you like to confirm Mason setup, e.g.:
      -- vim.notify("Mason setup complete.", vim.log.levels.INFO, {title = "Plugins"})
    end,
  },

  {
    'williamboman/mason-lspconfig.nvim',
    dependencies = {'williamboman/mason.nvim'},
    -- No explicit event needed here if nvim-lspconfig (which depends on this)
    -- is triggered by an event like "BufReadPre". Lazy.nvim will handle the load order.
    config = function()
      -- Define on_attach and capabilities here, or make them accessible from an outer scope.
      local capabilities = vim.lsp.protocol.make_client_capabilities()
      -- If you use nvim-cmp for completion, integrate its capabilities:
      -- capabilities = require('cmp_nvim_lsp').default_capabilities(capabilities)

      local on_attach = function(client, bufnr)
        -- Optional: Notify which LSP client attached to which buffer.
        vim.notify("LSP attached: " .. client.name .. " to buffer " .. bufnr, vim.log.levels.INFO, { title = "LSP" })

        local map = vim.keymap.set
        local lsp_opts = { noremap = true, silent = true, buffer = bufnr, desc = "LSP" }

        map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Declaration' }))
        map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Definition' }))
        map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Hover' }))
        map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Implementation' }))
        map('n', '<leader>sh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Signature Help' }))
        map('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Add Workspace Folder' }))
        map('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Remove Workspace Folder' }))
        map('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP List Workspace Folders' }))
        map('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Type Definition' }))
        map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Rename' }))
        map({'n', 'v'}, '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Code Action' }))
        map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP References' }))
        map('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float({scope = "line"})<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Line Diagnostics' }))
        map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Prev Diagnostic' }))
        map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Next Diagnostic' }))
        map('n', '<leader>qf', '<cmd>lua vim.diagnostic.setloclist()<CR>', vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Diagnostics to Loclist' }))

        if client.supports_method("textDocument/formatting") then
          map({'n', 'v'}, '<leader>lf', function() vim.lsp.buf.format({ async = true, bufnr = bufnr }) end, vim.tbl_extend('keep', lsp_opts, { desc = 'LSP Format Document' }))
        end
        -- Your C++/Header switching keymaps from core/keymaps.lua should still work independently.
      end

      local lspconfig_pkg = require('lspconfig') -- Get the lspconfig package

      require("mason-lspconfig").setup({
        ensure_installed = {
          "lua_ls",
          "clangd",
          "pyright",
          "rust_analyzer"
        },
        automatic_installation = false, -- Recommended to keep false and manage installs via Mason
        handlers = {
          -- Default handler for servers not explicitly customized below
          function(server_name)
            lspconfig_pkg[server_name].setup({
              on_attach = on_attach,
              capabilities = capabilities,
              flags = { debounce_text_changes = 150 },
            })
          end,
          -- Custom setup for lua_ls
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
          -- Custom setup for clangd (add any specific clangd options here if needed)
          ["clangd"] = function ()
            lspconfig_pkg.clangd.setup({
              on_attach = on_attach,
              capabilities = capabilities,
              flags = { debounce_text_changes = 150 },
              -- cmd = {"clangd", "--query-driver=/usr/bin/g++"} -- Example: if you need to specify compiler
            })
          end,
          -- pyright and rust_analyzer will use the default handler unless specified.
        }
      })
    end,
  },

  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" }, -- This triggers the loading of the LSP ecosystem
    dependencies = {
      'williamboman/mason.nvim',
      'williamboman/mason-lspconfig.nvim', -- Ensures this is loaded and configured
      { 'j-hui/fidget.nvim', tag = "legacy", opts = {} }, -- LSP progress UI
    },
    config = function()
      -- LSP server setups are now primarily handled by mason-lspconfig's handlers.
      -- This block is for global LSP settings, diagnostics, or LSPs not managed by mason-lspconfig.

      -- Configure diagnostic signs and appearance (important)
      vim.diagnostic.config({
        virtual_text = false, -- Consider 'true' or a table for more options if you want inline virtual text
        signs = true,
        underline = true,
        update_in_insert = false,
        severity_sort = true,
      })

      local signs = { Error = "", Warn = "", Hint = "", Info = "" } -- Example: Nerd Font icons
      -- local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" } -- Simpler text signs
      for type, icon in pairs(signs) do
        local hl_group = "DiagnosticSign" .. type
        vim.fn.sign_define(hl_group, { text = icon, texthl = hl_group, numhl = hl_group })
      end
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
         files = {
           -- Modified 'cmd' to exclude .git and .venv
           cmd = vim.fn.executable("fd") == 1 and
                   "fd --type f --hidden --follow --exclude .git --exclude .venv" or
                   "find . \\( -name .git -o -name .venv \\) -prune -o -type f -print",
           -- You can also add --no-ignore to fd if you want to ONLY rely on --exclude
           -- and ignore .gitignore files, but the current setup respects .gitignore
           -- AND adds your explicit excludes.
         },
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

