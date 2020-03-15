"Basics
set autoread
set backspace=indent,eol,start
set clipboard=unnamed
set colorcolumn=81
set cursorline
set number
set ruler
set scrolloff=1
syntax on
colorscheme darcula

"Tabs
nnoremap H :tabprevious<CR>
nnoremap L :tabnext<CR>
nnoremap T :tabnew<CR>

"Search
set incsearch
set hlsearch
set ignorecase
set smartcase
noremap <C-p> :<C-u>FZF<CR>
if executable('ag')
      let g:ackprg = 'ag --vimgrep'
endif

"Indentation
filetype plugin on
filetype indent on
set autoindent "keeps indentation, even if we don't have filetype recognized
set cindent "C-like indentation
set expandtab
set tabstop=4
set shiftwidth=4

"File Explorer
noremap <C-e> :Lex<CR>
let g:netrw_banner=0
let g:netrw_liststyle=3
let g:netrw_browse_split=0
let g:netrw_altv=1
let g:netrw_winsize=15

"Show C function name
fun! ShowFuncName()
  let lnum = line(".")
  let col = col(".")
  echohl ModeMsg
  echo getline(search("^[^ \t#/]\\{2}.*[^:]\s*$", 'bW'))
  echohl None
  call search("\\%" . lnum . "l" . "\\%" . col . "c")
endfun
map f :call ShowFuncName() <CR>
