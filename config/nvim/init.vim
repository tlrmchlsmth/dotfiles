" Use Vim settings, rather then Vi settings
" This must be first, because it changes other options as a side effect.
set nocompatible

"set leader to ,
let mapleader = ","
set showcmd

"Switch between lib and include dirs
let ext = '\.\(c\|h\)pp$'
let dir = 'include/wand\|lib'
nmap <Leader>c :e <C-R>=substitute(substitute(expand("%:p"), ext, ".cpp", ""), dir, "lib", "")<CR><CR>
nmap <Leader>h :e <C-R>=substitute(substitute(expand("%:p"), ext, ".hpp", ""), dir, "include/wand", "")<CR><CR>

"ctags optimization
set autochdir
set tags=tags;

" Return to last edit position when opening files (You want this!)
autocmd BufReadPost *
     \ if line("'\"") > 0 && line("'\"") <= line("$") |
     \   exe "normal! g`\"" |
     \ endif

"Plugins used:
"
if has("nvim")
    if empty(glob('~/.local/share/nvim/site/autoload/plug.vim'))
        silent !curl -fLo ~/.local/share/nvim/site/autoload/plug.vim --create-dirs 
            \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $VIMRC
    endif
else
    if empty(glob('~/.vim/autoload/plug.vim'))
        silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
        \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
        autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
    endif
endif

call plug#begin('~/.local/share/nvim/plugged')
Plug 'tpope/vim-fugitive'
Plug 'tpope/vim-surround'
Plug 'tpope/vim-repeat'
Plug 'tpope/vim-eunuch'

"Plug 'neoclide/coc.nvim', {'branch': 'release'}
Plug 'neovim/nvim-lspconfig'
Plug 'folke/trouble.nvim'
Plug 'kyazdani42/nvim-web-devicons'
Plug 'folke/lsp-colors.nvim'

Plug 'morhetz/gruvbox'

"Fuzzy file finder.
Plug 'junegunn/fzf', { 'do': { -> fzf#install() } }
Plug 'junegunn/fzf.vim'

Plug 'scrooloose/nerdtree'
Plug 'vim-airline/vim-airline'
call plug#end()

"more results in ctrlp
let g:ctrlp_match_window = 'results:50'

lua << EOF
require'lspconfig'.clangd.setup{}
EOF

lua << EOF
local nvim_lsp = require('lspconfig')

-- Use an on_attach function to only map the following keys
-- after the language server attaches to the current buffer
local on_attach = function(client, bufnr)
  local function buf_set_keymap(...) vim.api.nvim_buf_set_keymap(bufnr, ...) end
  local function buf_set_option(...) vim.api.nvim_buf_set_option(bufnr, ...) end

  -- Enable completion triggered by <c-x><c-o>
--  buf_set_option('omnifunc', 'v:lua.vim.lsp.omnifunc')

  -- Mappings.
  local opts = { noremap=true, silent=true }

  -- See `:help vim.lsp.*` for documentation on any of the below functions
  buf_set_keymap('n', 'gD', '<cmd>lua vim.lsp.buf.declaration()<CR>', opts)
  buf_set_keymap('n', 'gd', '<cmd>lua vim.lsp.buf.definition()<CR>', opts)
end

-- Use a loop to conveniently call 'setup' on multiple servers and
-- map buffer local keybindings when the language server attaches
local servers = { 'clangd', 'pyright', 'rust_analyzer', 'tsserver' }
for _, lsp in ipairs(servers) do
  nvim_lsp[lsp].setup {
    on_attach = on_attach,
    flags = {
      debounce_text_changes = 150,
    }
  }
end
EOF

lua << EOF
-- Disable inline diagnostics because they are terrible and we use Trouble instead
vim.lsp.handlers["textDocument/publishDiagnostics"] = vim.lsp.with(
    vim.lsp.diagnostic.on_publish_diagnostics, {
        underline = true,
        virtual_text = false,
    }
)
EOF

hi LspDiagnosticsVirtualTextError guifg=red gui=bold,italic,underline
hi LspDiagnosticsVirtualTextWarning guifg=orange gui=bold,italic,underline
hi LspDiagnosticsVirtualTextInformation guifg=yellow gui=bold,italic,underline
hi LspDiagnosticsVirtualTextHint guifg=green gui=bold,italic,underline

lua << EOF
  require("trouble").setup {
    position = "bottom", -- position of the list can be: bottom, top, left, right
    height = 10, -- height of the trouble list when position is top or bottom
    width = 50, -- width of the list when position is left or right
    icons = true, -- use devicons for filenames
    mode = "workspace_diagnostics", -- "lsp_workspace_diagnostics", "lsp_document_diagnostics", "quickfix", "lsp_references", "loclist"
    fold_open = "", -- icon used for open folds
    fold_closed = "", -- icon used for closed folds
    action_keys = { -- key mappings for actions in the trouble list
        -- map to {} to remove a mapping, for example:
        -- close = {},
        close = "q", -- close the list
        cancel = "<esc>", -- cancel the preview and get back to your last window / buffer / cursor
        refresh = "r", -- manually refresh
        jump = {"<cr>", "<tab>"}, -- jump to the diagnostic or open / close folds
        open_split = { "<c-x>" }, -- open buffer in new split
        open_vsplit = { "<c-v>" }, -- open buffer in new vsplit
        open_tab = { "<c-t>" }, -- open buffer in new tab
        jump_close = {"o"}, -- jump to the diagnostic and close the list
        toggle_mode = "m", -- toggle between "workspace" and "document" diagnostics mode
        toggle_preview = "P", -- toggle auto_preview
        hover = "K", -- opens a small popup with the full multiline message
        preview = "p", -- preview the diagnostic location
        close_folds = {"zM", "zm"}, -- close all folds
        open_folds = {"zR", "zr"}, -- open all folds
        toggle_fold = {"zA", "za"}, -- toggle fold of current file
        previous = "k", -- preview item
        next = "j" -- next item
    },
    indent_lines = true, -- add an indent guide below the fold icons
    auto_open = false, -- automatically open the list when you have diagnostics
    auto_close = false, -- automatically close the list when you have no diagnostics
    auto_preview = true, -- automatically preview the location of the diagnostic. <esc> to close preview and go back to last window
    auto_fold = false, -- automatically fold a file trouble list at creation
    signs = {
        -- icons / text used for a diagnostic
        error = "",
        warning = "",
        hint = "",
        information = "",
        other = "﫠"
    },
    use_lsp_diagnostic_signs = false -- enabling this will use the signs defined in your lsp client
}


EOF
nnoremap <leader>xx <cmd>TroubleToggle<cr>
nnoremap <leader>xw <cmd>TroubleToggle lsp_workspace_diagnostics<cr>
nnoremap <leader>xd <cmd>TroubleToggle lsp_document_diagnostics<cr>
nnoremap <leader>xq <cmd>TroubleToggle quickfix<cr>
nnoremap <leader>xl <cmd>TroubleToggle loclist<cr>
nnoremap gR <cmd>TroubleToggle lsp_references<cr>


"COC stuff
"inoremap <silent><expr> <TAB>
"    \ pumvisible() ? "\<C-n>" :
"    \ <SID>check_back_space() ? "\<TAB>" :
"    \ coc#refresh()
"inoremap <expr><S-TAB> pumvisible() ? "\<C-p>" : "\<C-h>"
 
"function! s:check_back_space() abort
"    let col = col('.') - 1
"    return !col || getline('.')[col - 1]  =~# '\s'
"endfunction

"inoremap <silent><expr> <c-space> coc#refresh()

" Use <cr> to confirm completion, `<C-g>u` means break undo chain at current position.
" Coc only does snippet and additional edit on confirm.
"inoremap <expr> <cr> pumvisible() ? "\<C-y>" : "\<C-g>u\<CR>"
" Or use `complete_info` if your vim support it, like:
""inoremap <expr> <cr> complete_info()["selected"] != "-1" ? "\<C-y>" : "\<C-g>u\<CR>"

" Remap keys for gotos and other stuff for coc
"nmap <silent> gd <Plug>(coc-definition)
"nmap <silent> gy <Plug>(coc-type-definition)
"nmap <silent> gi <Plug>(coc-implementation)
"nmap <silent> gr <Plug>(coc-references)
"nmap <leader>rn <Plug>(coc-rename)

" Highlight symbol under cursor on CursorHold (doesn't work?)
"autocmd CursorHold * silent call CocActionAsync('highlight')

" Comments in json files
autocmd FileType json syntax match Comment +\/\/.\+$+

"Tyler's preferences
"
set incsearch
set nohlsearch
set lazyredraw "Makes macros run faster
set tabstop=4 shiftwidth=4 expandtab
filetype plugin indent on
syntax enable
set backspace=indent,eol,start
set autoindent
set cinoptions=g0 
set complete-=i
au BufNewFile, BufRead *.cc, *.proto, set filetype=cpp
au BufNewFile, BufRead *.ml, set nocindent
au BufNewFile, BufRead *.ml, set autoindent
set ruler
set number
set cursorline
set path=$PWD/../../../**5
set splitright
set background=dark
set hidden
colorscheme gruvbox 
set shortmess+=c
set updatetime=100
set cmdheight=2
nmap K <Nop>
set inccommand=nosplit

" Turn off neovim's use of the mouse, so that we can copy with command-c
set mouse=

"search for visually selected text
vnoremap // y/\V<C-R>=escape(@",'/\')<CR><CR>

" insert a single character
nnoremap <silent> s :exec "normal i".nr2char(getchar())."\e"<CR>
nnoremap <silent> S :exec "normal a".nr2char(getchar())."\e"<CR>

"" Make a new block with blank line pads
"nmap <C-j> o<Return><UP>

" Viewport movement
nmap gh <C-w>h
nmap gj <C-w>j
nmap gk <C-w>k
nmap gl <C-w>l
nmap gw <C-w>w

" Tab Navigation
noremap <Leader>tn :tabnew<CR>
noremap <Leader>tl :tabnext<CR>
noremap <Leader>th :tabprevious<CR>
for i in range(0, 9)
    " <Leader>tN switches to tab N
    execute 'noremap <Leader>t' . i . ' :tabnext ' . i . '<CR>'
endfor

" Don't use ctrl
map <Leader>f <C-d>
map <Leader>b <C-u>
map <C-f> <Nop>
map <C-b> <Nop>
map <Leader>r <C-r>
map <Leader>o <C-o>

" Tag stuff
set tags=./tags;/
" build tags of your own project with Ctrl-F12
map <C-F12> :!ctags -R --sort=yes --c++-kinds=+p --fields=+iaS --extra=+q .<CR>

"Autoformat using cntl-k with clang format
function! FormatCppFile()
  let l:lines="all"
  :py3f $HOME/.local/share/nvim/clang-format.py
endfunction
map <C-k> :call FormatCppFile()<cr>
imap <C-k> <c-o>:call FormatCppFile()<cr>

" Put swap files in one directory
set directory^=$HOME/.vim/tmp/

" Set up fuzzy file finder with nicer git repo behavior with leader p
function! FzfFindFileInGitRoot()
    " Find the root directory of the current Git project
    let l:git_root = system('git rev-parse --show-toplevel 2> /dev/null')
    let l:git_root = substitute(l:git_root, '\n\+$', '', '')

    " Define a list of directories to ignore
    let l:ignore_dirs = ['venv']
    let l:rg_ignore = join(map(copy(l:ignore_dirs), '"--glob !".v:val'), ' ')

    " Check if git_root was successfully found
    if v:shell_error == 0 && !empty(l:git_root)
        " Start fzf from the root of the Git project
        call fzf#run(fzf#wrap({'source': 'rg --files '.l:rg_ignore, 'dir': l:git_root}))
    else
        " Fallback to the current directory if not in a Git repo
        call fzf#run(fzf#wrap({'source': 'rg --files '.l:rg_ignore}))
"        execute 'FZF'
    endif
endfunction

" Bind the custom FzfFindFileInGitRoot function to a command
command! FzfGitRoot call FzfFindFileInGitRoot()
nnoremap <leader>p :FzfGitRoot<CR>


function! RandomPerturbColor()
    " Get the current background color
    let l:current_bg = synIDattr(hlID('Normal'), 'bg#')
    if l:current_bg == ""
        echo "No background color is set"
        return
    endif

    " Convert hex to RGB
    let l:R = str2nr(strpart(l:current_bg, 1, 2), 16)
    let l:G = str2nr(strpart(l:current_bg, 3, 2), 16)
    let l:B = str2nr(strpart(l:current_bg, 5, 2), 16)

    " Apply a random perturbation between -4 and 4 to each RGB component
    let l:R = min([255, max([0, l:R + rand() % 8 - 4])])
    let l:G = min([255, max([0, l:G + rand() % 8 - 4])])
    let l:B = min([255, max([0, l:B + rand() % 8 - 4])])

    " Convert RGB back to hex
    let l:new_bg = printf('#%02x%02x%02x', l:R, l:G, l:B)

    " Set the new background color
    exec 'highlight Normal guibg=' . l:new_bg
endfunction

" Call the function to apply changes
call RandomPerturbColor()
