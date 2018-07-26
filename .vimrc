" My .vimrc, built upon the original .vimrc from Nate Soares.
" Author: kayzhu
" Last major update: 2018-07-25

set nocompatible                " Avoid legacy silliness.
set backspace=indent,eol,start  " Make backspace sane.
set hidden                      " Allow buffer backgrounding.
set scrolloff=3                 " Add top/bottom scroll margins.
set ttyfast lazyredraw          " Make drawing faster.
let mapleader="`"               " Default is \, I prefer `.
set backup                      " Be safe.
set clipboard=unnamed           " Allow vim to use the X clipboard.
set formatoptions=cqn1j         " See :help fo-table.
set history=1000                " Remember a lot.
"set relativenumber number      " Use relative line numbers.
set number                      " Use absolute line numbers.
set showcmd                     " Show the last command.
set showmatch                   " When a bracket is typed show its match.
set hlsearch                    " Highlight search.
set incsearch                   " Search incrementally as I type.
set ignorecase                  " Ignore case when searching.
set smartcase                   " ..except when there's at least one capital letter.
set smarttab                    " Only respect shiftwidth for code indents.
set splitbelow splitright       " Windows are created in the direction I read.
set undofile                    " Saves undo history across sessions.
set viewoptions=cursor,folds    " Save cursor position and folds.
set wildmenu                    " Enhanced completion.
set wildmode=list:longest       " Act like shell completion.
set laststatus=2                " Always show the statusline.
set confirm                     " Confirm overwrites etc w/o having to use '!'.
set colorcolumn=80              " Highlight overlength of 80.
set t_Co=256                    " Use 256 colors

" Highlight current line. Disabled due to slowness.
"set cursorline cursorcolumn         " highlight current line
"hi cursorline guibg=#333333         " highlight bg color of current line
"hi CursorColumn guibg=#333333       " highlight cursor

" Folding
set foldmethod=syntax
set foldnestmax=10
set nofoldenable
set foldlevel=2

" Make hidden characters look nice when shown.
set listchars=tab:▷\ ,eol:¬,extends:»,precedes:«

" Use jk for normal mode switch.
inoremap jk <ESC>
inoremap kj <ESC>

" Move in visual lines.
nnoremap k gk
nnoremap j gj
" Used when jumping precise number of lines .
nnoremap gk k
nnoremap gj j

" Automatically change the working path to the path of the current file
autocmd BufNewFile,BufEnter * silent! lcd %:p:h

" Instead of looking up man pages for the word under the cursor, return instead.
nnoremap <s-k> <CR>

"========================="
" Internal Google plugins "
"========================="
source /usr/share/vim/google/google.vim

nnoremap <unique> <leader>cc :CritiqueComments<CR>
nnoremap <unique> <leader>cn :CritiqueNextComment<CR>
nnoremap <unique> <leader>cp :CritiquePreviousComment<CR>
nnoremap <unique> <leader>h :set list!<CR>
nnoremap <unique> <leader>p :PiperSelectActiveFiles<CR>
nnoremap <unique> <leader>gi :GtImporter<CR>
nnoremap <unique> <leader>gs :GtImporterSort<CR>
nnoremap <unique> <leader>r :RelatedFilesWindow<CR>
nnoremap <unique> <leader>rf :RelatedFilesWindow<CR>
nnoremap <unique> <leader>jd :YcmCompleter GoTo<CR>
"Query mode.
nnoremap <unique> <leader>qf :let g:clang_include_fixer_query_mode=1<cr>:pyf /usr/lib/clang-include-fixer/clang-include-fixer.py<cr>
nnoremap <unique> <leader>cr :pyf /google/src/head/depot/google3/third_party/llvm/llvm/tools/clang/tools/extra/clang-rename/tool/clang-rename.py<cr>
nnoremap <unique> <leader>cf :pyf /usr/lib/clang-include-fixer/clang-include-fixer.py<cr>:w<cr>:BlazeDepsUpdate<cr>

Glug blaze
Glug blazedeps
Glug critique
Glug relatedfiles
Glug youcompleteme-google

Glug codefmt plugin[mappings]='\f'
Glug codefmt-google
augroup autoformat_settings
  autocmd FileType borg,gcl,patchpanel AutoFormatBuffer gclfmt
  autocmd FileType bzl AutoFormatBuffer buildifier
  autocmd FileType c,cpp,proto,javascript AutoFormatBuffer clang-format
  autocmd FileType dart AutoFormatBuffer dartfmt
  autocmd FileType java AutoFormatBuffer google-java-format
  autocmd FileType jslayout AutoFormatBuffer jslfmt
  autocmd FileType go AutoFormatBuffer gofmt
  autocmd FileType python AutoFormatBuffer pyformat
  autocmd FileType markdown AutoFormatBuffer mdformat
  autocmd FileType ncl AutoFormatBuffer nclfmt
augroup END

Glug corpweb !plugin[mappings_gx]
" search for the word under the cursor
nnoremap <unique> <leader>ws :CorpWebCs <cword> <Cr>
" search for the current file
nnoremap <unique> <leader>wf :CorpWebCsFile<CR>

"======================"
" Vundle configuration "
"======================"

filetype off
set rtp+=~/.vim/bundle/Vundle.vim
if isdirectory(expand('$HOME/.vim/bundle/Vundle.vim'))
  call vundle#begin()
  " Required
  Plugin 'gmarik/vundle'

  " Install plugins that come from github.  Once Vundle is installed, these can be
  " installed with :PluginInstall
  Plugin 'scrooloose/nerdcommenter'
  Plugin 'scrooloose/nerdtree'
  Plugin 'Valloric/MatchTagAlways'
  Plugin 'vim-scripts/netrw.vim'
  Plugin 'vim-scripts/a.vim'
  Plugin 'tpope/vim-sensible'
  Plugin 'tpope/vim-surround'
  Plugin 'flazz/vim-colorschemes'

  call vundle#end()
else
  echomsg 'Vundle is not installed. You can install Vundle from'
      \ 'https://github.com/VundleVim/Vundle.vim'
endif

" Colorscheme settings, must have Plugin 'flazz/vim-colorschemes' installed.
colorscheme jelleybeans


" NERDTree settings
nnoremap <leader>n :NERDTreeToggle<CR>
nnoremap <leader>b :NERDTreeFind<CR>
autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
let g:NERDTreeChDirMode=2
let NERDTreeIgnore = ['\.pyc$']
let NERDTreeMapOpenInTab = '<c-t>'

" Turn plugins on.
filetype plugin indent on
syntax enable

" Must be added after syntax is enabled since colorscheme will change its color.
hi ColorColumn ctermbg=Blue guibg=Blue
