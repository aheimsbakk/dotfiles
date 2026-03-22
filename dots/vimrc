" --- General Settings ---
set nocompatible
"set number relativenumber  " Hybrid line numbers
"set number                 " Line numbers
set ignorecase smartcase   " Better searching
set hlsearch               " Highlight all search matches
set incsearch              " Highlight matches dynamically as you type
set splitbelow splitright  " Better window splitting
set scrolloff=8            " Scrolloff margin
set updatetime=200
set encoding=utf-8
set mouse=a                " Enable mouse support

" --- System Clipboard Integration ---
if has("mac") || has("macunix")
  set clipboard=unnamed      " Use * register on macOS
else
  set clipboard=unnamedplus  " Use + register on Linux
endif

" --- Formatting ---
set tabstop=2 shiftwidth=2 expandtab autoindent smartindent
set list listchars=nbsp:¬,tab:>\ ,extends:»,precedes:«,trail:•

" --- UI ---
set termguicolors          " Enable true colors
set laststatus=2
set showtabline=2
set noshowmode             " Handled by airline
syntax on

" --- Leader Key (Space) ---
let mapleader = "\<Space>"
let maplocalleader = ','

" --- Plugins ---
" https://github.com/junegunn/vim-plug
" curl -fLo ~/.vim/autoload/plug.vim --create-dirs https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim

call plug#begin('~/.vim/plugged')

  " LSP & Autocomplete
  Plug 'prabirshrestha/vim-lsp'
  Plug 'mattn/vim-lsp-settings'
  Plug 'prabirshrestha/asyncomplete.vim'
  Plug 'prabirshrestha/asyncomplete-lsp.vim'

  " Navigation
  Plug 'preservim/nerdtree'
  Plug 'junegunn/fzf', { 'do': { -> fzf#install() } } " Fuzzy finder
  Plug 'junegunn/fzf.vim'

  " Git
  "Plug 'tpope/vim-fugitive'
  Plug 'airblade/vim-gitgutter'

  " Editing Enhancements
  "Plug 'tpope/vim-commentary' " gcc to comment
  "Plug 'tpope/vim-surround'
  Plug 'jiangmiao/auto-pairs'
  Plug 'sheerun/vim-polyglot' " Better syntax highlighting

  " Visuals
  Plug 'vim-airline/vim-airline'
  Plug 'vim-airline/vim-airline-themes'
  Plug 'rakr/vim-one'
  Plug 'jonathanfilip/vim-lucius'

  " Tools
  Plug 'freitass/todo.txt-vim'
  Plug 'iamcco/markdown-preview.nvim', { 'do': { -> mkdp#util#install() }}

call plug#end()

" let g:mkdp_preview_options = { "uml": { "server": "https://krokiserver/plantuml", "imageFormat": "svg" } }

" --- Theme Config ---
set background=light
"let g:airline_theme='one'
let g:lucius_contrast='high'
let g:lucius_contrast_bg='high'
colorscheme lucius

" --- LSP Configuration (The Brains) ---
let g:lsp_signs_enabled = 1
let g:lsp_diagnostics_echo_cursor = 1

function! s:on_lsp_buffer_enabled() abort
    setlocal omnifunc=lsp#complete
    setlocal signcolumn=yes

    " Mappings
    nmap <buffer> gd <plug>(lsp-definition)
    nmap <buffer> gr <plug>(lsp-references)
    nmap <buffer> K <plug>(lsp-hover)
    nmap <buffer> <leader>rn <plug>(lsp-rename)
    nmap <buffer> <leader>f <plug>(lsp-document-format)
endfunction

augroup lsp_install
    au!
    autocmd User lsp_buffer_enabled call s:on_lsp_buffer_enabled()
augroup END

" --- Folding ---
set foldmethod=expr
  \ foldexpr=lsp#ui#vim#folding#foldexpr()
  \ foldtext=lsp#ui#vim#folding#foldtext()
set nofoldenable " Disable folding on startup (optional)

" --- Useful Mappings ---
" Toggle NERDTree with Ctrl+n
map <C-n> :NERDTreeToggle<CR>
" Find files with Space+p (VS Code style)
nnoremap <leader>p :Files<CR>
" Find text in files with Space+s (Fixed from <leader>f to avoid LSP conflict)
nnoremap <leader>s :Rg<CR>
" Clear search highlights with Space+Space
nnoremap <leader><leader> :nohlsearch<CR>
