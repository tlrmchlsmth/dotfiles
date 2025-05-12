-- ~/.config/nvim/lua/plugins/init.lua

return {
  -- ========== Core Essentials ==========

  { 'tpope/vim-fugitive', cmd = 'Git' }, -- Git commands
  { 'tpope/vim-surround', event = 'VeryLazy' }, -- Surrounding pairs
  { 'tpope/vim-repeat', event = 'VeryLazy' }, -- Repeat plugin actions
  { 'tpope/vim-eunuch', event = 'VeryLazy' }, -- Unix commands

  -- ========== UI & Appearance ==========

  {
    'morhetz/gruvbox',
    priority = 1000, -- Ensure it loads first
    config = function()
      vim.cmd('colorscheme gruvbox')
      -- Optional: Set specific gruvbox options here
      -- vim.g.gruvbox_contrast_dark = 'hard'
      vim.cmd([[
        hi LspDiagnosticsVirtualTextError guifg=Red gui=bold,italic,underline
        hi LspDiagnosticsVirtualTextWarning guifg=Orange gui=bold,italic,underline
        hi LspDiagnosticsVirtualTextInformation guifg=Yellow gui=bold,italic,underline
        hi LspDiagnosticsVirtualTextHint guifg=Green gui=bold,italic,underline
      ]])
       -- Perturb color function (optional - might conflict with theme consistency)
      -- require('utils.theme').setup_perturb()
    end,
  },

  {
    'nvim-lualine/lualine.nvim',
    dependencies = { 'nvim-tree/nvim-web-devicons' }, -- Recommended for icons
    opts = {
      options = {
        theme = 'gruvbox', -- Or auto, gruvbox-material, etc.
        -- theme = 'auto',
        icons_enabled = true,
        component_separators = { left = '', right = ''},
        section_separators = { left = '', right = ''},
        disabled_filetypes = {},
      },
      sections = {
        lualine_a = {'mode'},
        lualine_b = {'branch', 'diff', 'diagnostics'},
        lualine_c = {{'filename', path = 1}}, -- Relative path
        lualine_x = {'encoding', 'fileformat', 'filetype'},
        lualine_y = {'progress'},
        lualine_z = {'location'}
      },
      inactive_sections = {
        lualine_a = {},
        lualine_b = {},
        lualine_c = {{'filename', path = 1}},
        lualine_x = {'location'},
        lualine_y = {},
        lualine_z = {}
      },
      tabline = {},
      extensions = {'fugitive', 'nvim-tree', 'trouble'} -- Enable extensions
    }
  },

  { 'nvim-tree/nvim-web-devicons', lazy = true }, -- Icons

  {
    "folke/trouble.nvim",
    dependencies = { "nvim-tree/nvim-web-devicons" },
    opts = {
      position = "bottom", -- position of the list can be: bottom, top, left, right
      height = 10, -- height of the trouble list when position is top or bottom
      width = 50, -- width of the list when position is left or right
      icons = true, -- use devicons for filenames
      mode = "workspace_diagnostics", -- "workspace_diagnostics", "document_diagnostics", "quickfix", "lsp_references", "loclist"
      fold_open = "▾", -- Use simpler icons if nerd fonts are not guaranteed
      fold_closed = "▸",
      action_keys = {
          close = "q",
          cancel = "<esc>",
          refresh = "r",
          jump = {"<cr>", "<tab>"},
          open_split = { "<c-x>" },
          open_vsplit = { "<c-v>" },
          open_tab = { "<c-t>" },
          jump_close = {"o"},
          toggle_mode = "m",
          toggle_preview = "P",
          hover = "K",
          preview = "p",
          close_folds = {"zM", "zm"},
          open_folds = {"zR", "zr"},
          toggle_fold = {"zA", "za"},
          previous = "k",
          next = "j"
      },
      indent_lines = true,
      auto_open = false,
      auto_close = false,
      auto_preview = true,
      auto_fold = false,
      signs = {
          error = "E", -- Use text signs for broader compatibility
          warning = "W",
          hint = "H",
          information = "I",
          other = "O"
      },
      use_lsp_diagnostic_signs = true -- Use LSP signs if available (often preferred)
    },
    -- Keymaps for trouble are defined in core/keymaps.lua
  },

  -- ========== LSP & Completion ==========
  -- NOTE: For completion (like CoC provided), you'll need a completion plugin.
  -- nvim-cmp is the most popular choice. Add it here if needed.
  -- Example:
  -- {
  --    'hrsh7th/nvim-cmp',
  --    dependencies = {
  --        'hrsh7th/cmp-nvim-lsp',
  --        'hrsh7th/cmp-buffer',
  --        'hrsh7th/cmp-path',
  --        -- Add snippet engine like luasnip if you use snippets
  --        -- 'L3MON4D3/LuaSnip',
  --        -- 'saadparwaiz1/cmp_luasnip',
  --    },
  --    config = function()
  --        -- Setup nvim-cmp (see nvim-cmp docs for full config)
  --        local cmp = require('cmp')
  --        cmp.setup({
  --            -- sources configuration, mapping etc.
  --        })
  --    end
  -- },

  {
    'neovim/nvim-lspconfig',
    event = { "BufReadPre", "BufNewFile" }, -- Load LSP configs early
    dependencies = {
      -- Add nvim-cmp and cmp-nvim-lsp if using nvim-cmp
      -- {'hrsh7th/nvim-cmp'},
      -- {'hrsh7th/cmp-nvim-lsp'},
      -- Mason is recommended for managing LSP servers, linters, formatters
      { 'williamboman/mason.nvim', config = true }, -- Basic config is often enough
      { 'williamboman/mason-lspconfig.nvim' },
      -- Optional: UI enhancements
      -- { 'folke/neodev.nvim', opts = {} }, -- Helps configure Lua LSP for Neovim config
      -- { 'j-hui/fidget.nvim', opts = {} }, -- LSP progress notifications
    },
    config = function()
      local lspconfig = require('lspconfig')
      local capabilities = require('cmp_nvim_lsp').default_capabilities() -- Use this if using nvim-cmp
      -- local capabilities = vim.lsp.protocol.make_client_capabilities() -- Use this without nvim-cmp

      -- Custom on_attach function
      local on_attach = function(client, bufnr)
        print("LSP attached: " .. client.name)
        local map = vim.keymap.set
        local opts = { noremap=true, silent=true, buffer=bufnr }

        -- Standard LSP keymaps (add more as needed)
        map('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
        map('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
        map('n', 'K', '<cmd>lua vim.lsp.buf.hover()<CR>', opts)
        map('n', 'gi', '<cmd>lua vim.lsp.buf.implementation()<CR>', opts)
        map('n', '<leader>sh', '<cmd>lua vim.lsp.buf.signature_help()<CR>', opts)
        map('n', '<leader>wa', '<cmd>lua vim.lsp.buf.add_workspace_folder()<CR>', opts)
        map('n', '<leader>wr', '<cmd>lua vim.lsp.buf.remove_workspace_folder()<CR>', opts)
        map('n', '<leader>wl', '<cmd>lua print(vim.inspect(vim.lsp.buf.list_workspace_folders()))<CR>', opts)
        map('n', '<leader>D', '<cmd>lua vim.lsp.buf.type_definition()<CR>', opts)
        map('n', '<leader>rn', '<cmd>lua vim.lsp.buf.rename()<CR>', opts)
        map('n', '<leader>ca', '<cmd>lua vim.lsp.buf.code_action()<CR>', opts)
        map('n', 'gr', '<cmd>lua vim.lsp.buf.references()<CR>', opts) -- Often mapped to Trouble already
        map('n', '<leader>e', '<cmd>lua vim.diagnostic.open_float()<CR>', opts)
        map('n', '[d', '<cmd>lua vim.diagnostic.goto_prev()<CR>', opts)
        map('n', ']d', '<cmd>lua vim.diagnostic.goto_next()<CR>', opts)
        map('n', '<leader>q', '<cmd>lua vim.diagnostic.setloclist()<CR>', opts)

        -- Add formatting command mapping if client supports it
        if client.supports_method("textDocument/formatting") then
            map({'n', 'v'}, '<leader>lf', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
             -- Or map <C-k> here specifically for LSP format
            -- map({'n', 'v'}, '<C-k>', '<cmd>lua vim.lsp.buf.format({ async = true })<CR>', opts)
        end

         -- Add other buffer-local settings if needed
        -- vim.api.nvim_buf_set_option(bufnr, 'omnifunc', 'v:lua.vim.lsp.omnifunc')
      end

      -- Setup servers using mason-lspconfig
      local servers = { 'clangd', 'pyright', 'rust_analyzer', 'lua_ls' } -- Add lua_ls for Neovim config help
      require('mason-lspconfig').setup({
          ensure_installed = servers,
      })

      require('mason-lspconfig').setup_handlers({
          function(server_name) -- Default handler
              lspconfig[server_name].setup({
                  on_attach = on_attach,
                  capabilities = capabilities,
                   flags = {
                       debounce_text_changes = 150,
                   }
              })
          end,
          -- Custom setup for specific servers if needed
          ['lua_ls'] = function()
             lspconfig.lua_ls.setup({
                 on_attach = on_attach,
                 capabilities = capabilities,
                 settings = { -- Tell lua_ls about Neovim runtime globals
                    Lua = {
                        runtime = { version = 'LuaJIT' },
                        diagnostics = { globals = {'vim'} },
                        workspace = { library = vim.api.nvim_get_runtime_file("", true) },
                    },
                 },
                 flags = { debounce_text_changes = 150 }
             })
          end,
          -- Example: clangd specific settings
          ['clangd'] = function()
              lspconfig.clangd.setup({
                  on_attach = on_attach,
                  capabilities = capabilities,
                  -- cmd = { "clangd", "--background-index", "--pch-storage=memory", "--clang-tidy" }, -- Example custom command
                  flags = { debounce_text_changes = 150 }
              })
          end,
      })

      -- Configure diagnostics (virtual text off, use Trouble)
      vim.diagnostic.config({
        virtual_text = false, -- Disable virtual text diagnostics
        signs = true,
        underline = true,
        update_in_insert = false, -- Don't update diagnostics in insert mode
        severity_sort = true,
      })

      -- Customize diagnostic signs (optional, can use defaults)
      local signs = { Error = "E", Warn = "W", Hint = "H", Info = "I" }
      for type, icon in pairs(signs) do
        local hl = "DiagnosticSign" .. type
        vim.fn.sign_define(hl, { text = icon, texthl = hl, numhl = hl })
      end

    end,
  },

  -- ========== Fuzzy Finding ==========

  {
    'ibhagwan/fzf-lua',
    -- Load fzf-lua dependencies (optional, telescope requires plenary)
    dependencies = {
      'nvim-tree/nvim-web-devicons', -- Recommended for icons
      -- Install 'rg' (ripgrep) and 'fd' (fd-find) for best experience
      -- Install 'bat' for previews
    },
    config = function()
       require('fzf-lua').setup({
           -- Leave empty for defaults or customize:
           -- files = { cmd = 'fd --type f --hidden --follow --exclude .git' }
           -- grep = { cmd = 'rg --vimgrep' }
           -- winopts = { preview = { layout = 'vertical', vertical = 'down:50%' } }
       })
       -- Keymaps are set in core/keymaps.lua
    end
  },

  -- ========== File Explorer ==========

  {
    'nvim-tree/nvim-tree.lua',
    dependencies = { 'nvim-tree/nvim-web-devicons' },
    cmd = 'NvimTreeToggle', -- Load when command is called
    keys = { -- Optional: define keys here too
        {'<leader>e', '<cmd>NvimTreeToggle<CR>', desc = 'Toggle NvimTree'}
    },
    opts = {
      sort_by = "case_sensitive",
      view = {
        width = 30,
        -- side = 'right',
      },
      renderer = {
        group_empty = true,
        icons = {
            glyphs = {
                default = "",
                symlink = "",
                folder = {
                    arrow_closed = "",
                    arrow_open = "",
                    default = "",
                    open = "",
                    empty = "",
                    empty_open = "",
                    symlink = "",
                    symlink_open = "",
                },
                git = {
                    unstaged = "",
                    staged = "S",
                    unmerged = "",
                    renamed = "➜",
                    untracked = "U",
                    deleted = "",
                    ignored = "◌",
                },
            },
        },
      },
      filters = {
        dotfiles = false, -- Show dotfiles
        custom = { ".git", "node_modules", ".cache" }, -- Hide these
      },
      git = {
        enable = true,
        ignore = false, -- Show ignored files by default
      },
       update_focused_file = {
        enable = true,
        update_root = true -- Change root when focus changes
      },
    },
  },

  -- ========== Other Plugins ==========

  {
    'ojroques/vim-oscyank',
    branch = 'main',
    event = 'VeryLazy', -- Load when needed
    -- Keymaps are set in core/keymaps.lua
  },

}
