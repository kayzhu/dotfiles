" My .vimrc, built upon the original .vimrc from Nate Soares.
" Author: kayzhu
" Last major update: 2018-07-25

set nocompatible                " Avoid legacy silliness.
set backspace=indent,eol,start  " Make backspace sane.
set hidden                      " Allow buffer backgrounding.
set scrolloff=3                 " Add top/bottom scroll margins.
set ttyfast lazyredraw          " Make drawing faster.
let mapleader="`"               " Default is \, I prefer `.
set nobackup                    " No pesky swp files.
set clipboard=unnamed           " Allow vim to use the X clipboard.
set formatoptions=cqn1j         " See :help fo-table.
set history=1000                " Remember a lot.
set relativenumber number       " Use relative line numbers.
"set number                     " Use absolute line numbers.
set showcmd                     " Show the last command.
set ruler                       " Show coloumn and line in the status line.
"Disabled due to Highlight_Matching_Pair() call slowness in MatchParen.vim
"plugin.
"set showmatch                   " When a bracket is typed show its match.
set noshowmatch                   
let g:loaded_matchparen=1
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

set guioptions+=aAgcMrL     "this one makes the popup message disappear;instead we have console promots
"set guioptions+=rL
"set guioptions-=T

" Highlight current line. Disabled due to slowness.
"set cursorline cursorcolumn         " highlight current line
"hi cursorline guibg=#333333         " highlight bg color of current line
"hi CursorColumn guibg=#333333       " highlight cursor

" Folding. foldmethod=syntax slows everything down for reasons unknown.
"set foldmethod=indent
"set foldnestmax=10
"set nofoldenable
"set foldlevel=2

" Make hidden characters look nice when shown.
set listchars=tab:▷\ ,eol:¬,extends:»,precedes:«

" Type substitution where the pattern is the word under the cursor.
nnoremap <unique> <Leader>s :%s/\<<C-r><C-w>\>/

" Use jk for normal mode switch.
inoremap jk <ESC>
inoremap kj <ESC>

" Move in visual lines.
nnoremap k gk
nnoremap j gj
" Used when jumping precise number of lines .
nnoremap gk k
nnoremap gj j

augroup autodir
  " Automatically change the working path to the path of the current file
  autocmd BufNewFile,BufEnter * silent! lcd %:p:h
augroup END

" Instead of looking up man pages for the word under the cursor, return instead.
nnoremap <s-k> <CR>

" Remove highlights with enter key.
nnoremap <cr> :noh<CR><CR>:<backspace>

"========================="
" Internal Google plugins "
"========================="
source /usr/share/vim/google/google.vim

nnoremap <unique> <leader>cc :CritiqueComments<CR>
nnoremap <unique> <leader>cn :CritiqueNextComment<CR>
nnoremap <unique> <leader>cp :CritiquePreviousComment<CR>
nnoremap <unique> <leader>h :set list!<CR>
nnoremap <unique> <leader>rp :PiperSelectActiveFiles<CR>
nnoremap <unique> <leader>gi :GtImporter<CR>
nnoremap <unique> <leader>gs :GtImporterSort<CR>
nnoremap <unique> <leader>r :RelatedFilesWindow<CR>
nnoremap <unique> <leader>rf :RelatedFilesWindow<CR>
nnoremap <unique> <leader>jd :YcmCompleter GoTo<CR>
nnoremap <unique> <leader>jdd :YcmCompleter GoToDefinition<CR>
nnoremap <unique> <leader>jj :YcmCompleter GoToImprecise<CR>
nnoremap <unique> <leader>jt :YcmCompleter GetType<CR>
nnoremap <unique> <leader>jp :YcmCompleter GetParent<CR>
nnoremap <unique> <leader>jc :YcmCompleter GetDoc<CR>
"Query mode.
nnoremap <unique> <leader>qf :let g:clang_include_fixer_query_mode=1<cr>:pyf /usr/lib/clang-include-fixer/clang-include-fixer.py<cr>
nnoremap <unique> <leader>cr :pyf /google/src/head/depot/google3/third_party/llvm/llvm/tools/clang/tools/extra/clang-rename/tool/clang-rename.py<cr>
nnoremap <unique> <leader>cf :pyf /usr/lib/clang-include-fixer/clang-include-fixer.py<cr>:w<cr>:BlazeDepsUpdate<cr>

Glug blaze plugin[mappings]='<leader>b'
Glug blazedeps
Glug critique
Glug relatedfiles
Glug youcompleteme-google
Glug googlepaths

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
  Plugin 'VundleVim/Vundle.vim'

  " Install plugins that come from github.  Once Vundle is installed, these can be
  " installed with :PluginInstall
  Plugin 'scrooloose/nerdcommenter'
  Plugin 'scrooloose/nerdtree'
  Plugin 'Valloric/MatchTagAlways'
  Plugin 'vim-scripts/a.vim'
  Plugin 'tpope/vim-sensible'
  Plugin 'tpope/vim-surround'
  Plugin 'tpope/vim-eunuch'
  Plugin 'flazz/vim-colorschemes'
  Plugin 'ctrlpvim/ctrlp.vim'
  "Plugin 'vim-airline/vim-airline'  TOO SLOW
  Plugin 'mechatroner/rainbow_csv'
  Plugin 'dracula/vim',{'name':'dracula'}

  call vundle#end()
else
  echomsg 'Vundle is not installed. You can install Vundle from'
      \ 'https://github.com/VundleVim/Vundle.vim'
endif

" Colorscheme settings, must have Plugin 'flazz/vim-colorschemes' installed.
colorscheme jelleybeans


" NERDTree settings.
nnoremap <unique> <leader>n :NERDTreeToggle<CR>
nnoremap <unique> <leader>nb :NERDTreeFind<CR>
augroup nerdtree
  autocmd bufenter * if (winnr("$") == 1 && exists("b:NERDTreeType") && b:NERDTreeType == "primary") | q | endif
augroup END
let g:NERDTreeChDirMode=2
let NERDTreeIgnore = ['\.pyc$']
let NERDTreeMapOpenInTab = '<c-t>'

" Ctrl-P settings.
"
" Let CtrlP not go all the way up to the root of the client. Instead, consider a
" METADATA file to delimit a project.
"let g:ctrlp_root_markers = ['METADATA']
let g:ctrlp_map = '<leader>p'
nnoremap <unique> <leader>m = :CtrlPMRU<cr>
nnoremap <unique> <leader>mm = :CtrlPMixed<cr>
nnoremap <unique> <leader>t = :CtrlPTag<cr>
set wildignore+=*/tmp/*,*.so,*.swp,*.zip     " MacOSX/Linux
set wildignore+=*\\tmp\\*,*.swp,*.zip,*.exe  " Windows
let g:ctrlp_custom_ignore = '\v[\/]\.(git|hg|svn)$'
let g:ctrlp_custom_ignore = {
  \ 'dir':  '\v[\/]\.(git|hg|svn)$',
  \ 'file': '\v\.(exe|so|dll)$',
  \ 'link': 'some_bad_symbolic_links',
  \ }
" Ignore files in .gitignore
let g:ctrlp_user_command = ['.git', 'cd %s && git ls-files -co --exclude-standard']
" Use AG for CtrlP
if executable('ag')
  " Use ag over grep
  set grepprg=ag\ --nogroup\ --nocolor

  " Use ag in CtrlP for listing files. Lightning fast and respects .gitignore
  let g:ctrlp_user_command = '/usr/bin/ag %s -i --nocolor --nogroup --hidden
    \ --ignore .git
    \ --ignore .svn
    \ --ignore .hg
    \ --ignore .DS_Store
    \ --ignore "**/*.pyc"
    \ --ignore .git5_specs
    \ --ignore review
    \ -g ""'

  " ag is fast enough that CtrlP doesn't need to cache
  let g:ctrlp_use_caching = 0
else
  echomsg 'silversearcher-ag is not installed. It will be faster for CtrlP.'
endif
" Use sensible <c-n> and <c-p> for up and down selection instead of the default
" <c-j> and <c-k>.
let g:ctrlp_prompt_mappings = {
   \ 'PrtSelectMove("j")':   ['<c-n>', '<down>'],
   \ 'PrtSelectMove("k")':   ['<c-p>', '<up>'],
   \ 'PrtHistory(-1)':       ['<c-j>'],
   \ 'PrtHistory(1)':        ['<c-k>'],
   \ }



" Turn plugins on.
filetype plugin indent on
syntax enable

" Must be added after syntax is enabled since colorscheme will change its color.
hi ColorColumn ctermbg=Blue guibg=Blue
