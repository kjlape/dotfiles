scriptencoding utf-8

" vim hardcodes background color erase even if the terminfo file does
" not contain bce (not to mention that libvte based terminals
" incorrectly contain bce in their terminfo files). This causes
" incorrect background rendering when using a color theme with a
" background color.
" let &t_ut=''

" Autoinstall vim-plug
if empty(glob('~/.vim/autoload/plug.vim'))
  silent !curl -fLo ~/.vim/autoload/plug.vim --create-dirs
    \ https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
  augroup vimplug
    autocmd VimEnter * PlugInstall --sync | source $MYVIMRC
  augroup END
endif

if has('nvim')
  call plug#begin('~/.config/nvim/plugged')
else
  call plug#begin('~/.vim/plugged')
endif

  Plug '/usr/local/opt/fzf'
  Plug 'junegunn/fzf' ", { 'do': { -> fzf#install() } }
  Plug 'junegunn/fzf.vim'
  Plug 'junegunn/limelight.vim'
"   Plug 'AndrewRadev/splitjoin.vim'
  Plug 'alligator/accent.vim'
  Plug 'augmentcode/augment.vim'
  Plug 'airblade/vim-gitgutter'
  Plug 'airblade/vim-localorie'
  Plug 'DataWraith/auto_mkdir'
  Plug 'danchoi/ri.vim'
  Plug 'dense-analysis/neural'
  Plug 'muniftanjim/nui.nvim'
  Plug 'elpiloto/significant.nvim'
  " Plug 'digitaltoad/vim-pug'
  Plug 'alvan/vim-closetag'
  Plug 'christoomey/vim-tmux-navigator'
  " Plug 'ElmCast/elm-vim'
  " Plug 'fcpg/vim-waikiki'
  " Plug 'github/copilot.vim'
  " Plug 'jalvesaq/Nvim-R'
  " Plug 'janko-m/vim-test'
  Plug 'jaredgorski/fogbell.vim'
  Plug 'pasky/claude.vim'
  Plug 'pingortle/vim-test', { 'branch': 'teenytest' }
  " Plug 'jremmen/vim-ripgrep'
  Plug 'junegunn/goyo.vim'
  " Plug 'junegunn/vim-emoji'
  Plug 'kana/vim-textobj-user'
  " Plug 'leafOfTree/vim-vue-plugin'
  Plug 'liuchengxu/graphviz.vim'
  " Plug 'mattn/emmet-vim'
  Plug 'nelstrom/vim-textobj-rubyblock'
  Plug 'neovimhaskell/haskell-vim'
  " Plug 'prabirshrestha/vim-lsp'
  Plug 'rust-lang/rust.vim'
  " Plug 'sheerun/vim-polyglot'
  Plug 'tpope/vim-abolish'
  Plug 'tpope/vim-bundler'
  Plug 'tpope/vim-commentary'
  Plug 'tpope/vim-dispatch'
  Plug 'tpope/vim-endwise'
  Plug 'tpope/vim-fugitive'
  Plug 'tpope/vim-rails'
  Plug 'tpope/vim-rbenv'
  Plug 'tpope/vim-rhubarb'
  Plug 'tpope/vim-sensible'
  Plug 'tpope/vim-surround'
  Plug 'tpope/vim-unimpaired'
  Plug 'urbit/hoon.vim'
  Plug 'vim-airline/vim-airline'
  Plug 'vim-ruby/vim-ruby'
  Plug 'vim-scripts/bats.vim'
  " Plug 'w0rp/ale'
  Plug 'zhaozg/vim-diagram'

  Plug 'vim-airline/vim-airline-themes'
  Plug 'jeffkreeftmeijer/vim-dim'

  if has('nvim')
    Plug 'neovim/nvim-lspconfig'

    Plug 'hrsh7th/nvim-cmp' " Optional
    Plug 'hrsh7th/cmp-nvim-lsp'
    Plug 'hrsh7th/cmp-buffer'
    Plug 'hrsh7th/cmp-path'

    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-telescope/telescope.nvim' " Optional
    Plug 'epwalsh/obsidian.nvim'

    Plug 'epwalsh/pomo.nvim'
    Plug 'rcarriga/nvim-notify'

    Plug 'supermaven-inc/supermaven-nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'nvim-treesitter/nvim-treesitter', {'do': ':TSUpdate'}
    Plug 'nvim-telescope/telescope.nvim' " Optional
    Plug 'stevearc/dressing.nvim' " Optional: Improves the default Neovim UI
    Plug 'olimorris/codecompanion.nvim'

    " -- Avante --
    " Deps
    Plug 'stevearc/dressing.nvim'
    Plug 'nvim-lua/plenary.nvim'
    Plug 'MunifTanjim/nui.nvim'

    " Optional deps
    Plug 'nvim-tree/nvim-web-devicons' "or Plug 'echasnovski/mini.icons'
    Plug 'HakonHarnes/img-clip.nvim'
    Plug 'zbirenbaum/copilot.lua'
    Plug 'MeanderingProgrammer/render-markdown.nvim'

    " Yay
    Plug 'yetone/avante.nvim', { 'branch': 'main', 'do': { -> avante#build('source=true') }, 'on': 'AvanteAsk' }
  endif
call plug#end()

if has('nvim')
lua << EOF
  local lspconfig = require("lspconfig")
  lspconfig.sourcekit.setup({
    capabilities = {
      workspace = {
        didChangeWatchedFiles = {
          dynamicRegistration = true
        }
      },
    },
    root_dir = function(filename, _)
      local util = require("lspconfig.util")
      return util.root_pattern("buildServer.json")(filename)
        or util.root_pattern("*.xcodeproj", "*.xcworkspace")(filename)
        or util.find_git_ancestor(filename)
        or util.root_pattern("Package.swift")(filename)
    end,
  })

  local function add_ruby_deps_command(client, bufnr)
    vim.api.nvim_buf_create_user_command(bufnr, "ShowRubyDeps", function(opts)
      local params = vim.lsp.util.make_text_document_params()
      local showAll = opts.args == "all"

      client.request("rubyLsp/workspace/dependencies", params, function(error, result)
        if error then
          print("Error showing deps: " .. error)
          return
        end

        local qf_list = {}
        for _, item in ipairs(result) do
          if showAll or item.dependency then
            table.insert(qf_list, {
              text = string.format("%s (%s) - %s", item.name, item.version, item.dependency),
              filename = item.path
            })
          end
        end

        vim.fn.setqflist(qf_list)
        vim.cmd('copen')
      end, bufnr)
    end,
    {nargs = "?", complete = function() return {"all"} end})
  end

  lspconfig.ruby_lsp.setup({
    init_options = {
      formatter = 'standard',
      linters = { 'standard' },
    },
    on_attach = function(client, bufnr)
      add_ruby_deps_command(client, bufnr)
    end,
  })

  -- https://www.mitchellhanberg.com/modern-format-on-save-in-neovim/
  vim.api.nvim_create_autocmd("LspAttach", {
    group = vim.api.nvim_create_augroup("lsp", { clear = true }),
    callback = function(args)
    -- 2
    vim.api.nvim_create_autocmd("BufWritePre", {
      -- 3
      buffer = args.buf,
      callback = function()
      -- 4 + 5
      vim.lsp.buf.format {async = false, id = args.data.client_id }
      end,
    })
    end
  })

  local cmp = require('cmp')
  local opts = {
    sources = cmp.config.sources({
      { name = 'nvim_lsp' },
      { name = 'buffer' },
      { name = 'path' },
    }),

    mapping = cmp.mapping.preset.insert({
      ['<CR>'] = cmp.mapping.confirm({ select = true })
    }),
  }
  cmp.setup(opts)


  vim.api.nvim_create_autocmd('LspAttach', {
    desc = 'LSP actions',
    callback = function(args)
      vim.keymap.set('n', 'K', vim.lsp.buf.hover, {noremap = true, silent = true})
      vim.keymap.set('n', 'gd', vim.lsp.buf.definition, {noremap = true, silent = true})
    end,
  })

  require("pomo").setup({})

  require("obsidian").setup({
    workspaces = {
      {
          name = "default",
          path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Default"
      }
    }
  })

  require("supermaven-nvim").setup({})
  require("codecompanion").setup({
    strategies = {
      chat = {
        adapter = "anthropic",
      },
      inline = {
        adapter = "anthropic",
      },
      agent = {
        adapter = "anthropic",
      },
    }
  })

  -- deps:
  require('img-clip').setup({
    -- use recommended settings from above
  })
  require('render-markdown').setup({
    file_types = {'markdown', 'Avante'},
  })

  -- require('avante_lib').load()
  -- require('avante').setup({
  --   -- default config
  --   -- see :h avante-config
  -- })
EOF
endif

" " Theme
colorscheme accent
let g:airline_theme = 'minimalist'

function! ReloadMood()
  if !filereadable($home.'/.dev-mood')
    return
  end
  for line in readfile($home.'/.dev-mood', '', 1)
    let &background = line
  endfor
endfunction
call ReloadMood()

function! SetMood(mood)
  silent execute '!bash' '-lc' 'good-'.a:mood
  call ReloadMood()
  execute 'redraw!'
endfunction

command! GoodMorning call SetMood('morning')
command! GoodNight call SetMood('night')
command! ReloadMood call ReloadMood()

" " Plugin Customization
let g:markdown_fenced_languages = ['ruby', 'js=javascript']
let g:markdown_minlines = 150
let g:tmux_navigator_disable_when_zoomed = 1
let g:claude_api_key = $CLAUDE_API_KEY

" " Plugin vim-ruby
let g:ruby_indent_assignment_style = 'variable'
let g:ruby_indent_hanging_elements = 0

" " Plugin vim-test
let test#strategy = 'dispatch'
let test#custom_runners = {'Ruby': ['DHH']}

nnoremap <silent> <cr>t :TestFile<cr>
nnoremap <silent> <cr>n :TestNearest<cr>
nnoremap <silent> <cr><cr> :TestLast<cr>

" " Plugin neural
let g:neural = {
\   'source': {
\       'openai': {
\           'api_key': $OPENAI_API_KEY,
\       },
\   },
\}

" " Plugin vim-closetag
" " filenames like *.xml, *.html, *.xhtml, ...
" " These are the file extensions where this plugin is enabled.

let g:closetag_filenames = '*.html,*.html.erb,*.xhtml,*.phtml'

" " filenames like *.xml, *.xhtml, ...
" " This will make the list of non-closing tags self-closing in the specified files.

let g:closetag_xhtml_filenames = '*.xhtml,*.jsx,*.vue'

" " filetypes like xml, html, xhtml, ...
" " These are the file types where this plugin is enabled.

let g:closetag_filetypes = 'html,xhtml,phtml'

" " filetypes like xml, xhtml, ...
" " This will make the list of non-closing tags self-closing in the specified files.

let g:closetag_xhtml_filetypes = 'xhtml,jsx,vue'

" " integer value [0|1]
" " This will make the list of non-closing tags case-sensitive (e.g. `<Link>` will be closed while `<link>` won't.)

let g:closetag_emptyTags_caseSensitive = 1

" " Shortcut for closing tags, default is '>'

let g:closetag_shortcut = '>'

" " Add > at current position without closing the current tag, default is ''

let g:closetag_close_shortcut = '<leader>>'

set grepprg=rg\ --vimgrep\ --smart-case\ --follow

" Plugin goyo
function! s:goyo_enter()
  if has('gui_running')
    set fullscreen
    " set linespace=16
    set guifont=OpenDyslexicMono:h16
  elseif exists('$TMUX')
    silent !tmux set status off
  endif
endfunction

function! s:goyo_leave()
  if has('gui_running')
    set nofullscreen
    set linespace=0
    set guifont=Monaco:h16
  elseif exists('$TMUX')
    silent !tmux set status on
  endif
endfunction

autocmd! User GoyoEnter nested call <SID>goyo_enter()
autocmd! User GoyoLeave nested call <SID>goyo_leave()

autocmd! User GoyoEnter Limelight
autocmd! User GoyoLeave Limelight!

" " Plugin LSP
" if executable('standardrb')
"   au User lsp_setup call lsp#register_server({
"         \ 'name': 'standardrb',
"         \ 'cmd': ['standardrb', '--lsp'],
"         \ 'allowlist': ['ruby'],
"         \ })
" endif

" " Plugin ALE
let g:ale_linter_aliases = {}
let g:ale_linter_aliases.vue = ['vue', 'javascript']
let g:ale_linter_aliases.json = ['json', 'javascript']

let g:ale_fixers = {}
let g:ale_fixers['*'] = ['remove_trailing_lines', 'trim_whitespace']
let g:ale_fixers.css = ['prettier']
let g:ale_fixers.json = ['prettier', 'jq']
let g:ale_fixers.javascript = ['prettier-standard', 'standard', 'eslint']
let g:ale_fixers.vue = ['prettier', 'eslint']
" let g:ale_fixers.python = ['autopep8']
let g:ale_fixers.ruby = ['standardrb', 'rubocop']
" let g:ale_fixers.rust = ['rustfmt']
let g:ale_fixers.eruby = ['erblint']
let g:ale_fixers.terraform = ['terraform']
let g:ale_fixers.swift = ['swiftlint']

let g:ale_linters = {}
let g:ale_linters['*'] = ['remove_trailing_lines', 'trim_whitespace']
let g:ale_linters.css = ['prettier']
let g:ale_linters.javascript = ['standard']
let g:ale_linters.json = ['jq']
" let g:ale_linters.python = ['flake8']
let g:ale_linters.ruby = ['standardrb', 'reek', 'rubocop']
" let g:ale_linters.rust = ['analyzer']
let g:ale_linters.eruby = ['erblint']
let g:ale_linters.terraform = ['terraform']
let g:ale_linters.swift = ['swiftlint']

let g:ale_ruby_standardrb_executable = 'bundle'

let g:ale_fix_on_save = 1

set completeopt=menu,menuone,preview,noselect,noinsert
let g:ale_completion_enabled = 1

nnoremap <leader>= :ALEFix<cr>
nnoremap <leader>AN :ALENextWrap<cr>
nnoremap <leader>AP :ALEPreviousWrap<cr>
nnoremap <leader>AD :ALEDetail<cr>
nnoremap <leader>A> :ALEGoToDefinition<cr>

" " Whitespace
set expandtab
set shiftwidth=2
set softtabstop=2
set showbreak=↪\

function! DefaultWhitespace()
  set list listchars=tab:\ \ ,precedes:«,extends:»,trail:░,nbsp:☐
endfunction
call DefaultWhitespace()

function! DebugWhitespace()
  call DefaultWhitespace()
  setlocal listchars+=space:⌟,tab:⌞\ ,eol:⏎
endfunction

" " UX
set scrolloff=2
set showcmd
set incsearch
set hlsearch
set ignorecase
set smartcase
set number
set relativenumber
set spelllang=en_us
set complete+=kspell
set nowrap
set splitright
let g:netrw_http_cmd = 'open'

set winheight=5
set winminheight=5
set winheight=999
" set winwidth=5
" set winminwidth=5
" set winwidth=999

set wildcharm=<C-Z>
nnoremap <leader>z :b <C-Z>

" " Easily navigate wrapped lines
noremap <C-p> gk
noremap <C-n> gj

nnoremap <leader>] :set nowrap<cr>
nnoremap <leader>[ :set wrap linebreak<cr>
nnoremap <leader>/ :noh<cr>

" " Follow tag immediately if there is only one match
nnoremap <C-]> g<C-]>

nnoremap <leader>j :m+<cr>==
nnoremap <leader>k :m-2<CR>==
nnoremap <leader>h <<
nnoremap <leader>l >>

nnoremap <leader>g :Git<CR>

nnoremap <leader>f :FZF<CR>
nnoremap <leader>b :Buffers<CR>

" " Shortcut for directory of current buffer's file
cabbr <expr> %% fnamemodify(expand('%:p:h'), ':~:.')

" command! Revim execute "so ~/.vimrc"

call textobj#user#plugin('dash', {
      \   'dash-word': {
      \     'pattern': '\(\w\|-\)\+',
      \     'select': ['adw', 'idw'],
      \   },
      \   'html-comment': {
      \     'pattern': ['<!--', '-->'],
      \     'select-a': 'act',
      \     'select-i': 'ict',
      \   },
      \   'erb': {
      \     'pattern': ['<%', '%>'],
      \     'select-a': 'ace',
      \     'select-i': 'ice',
      \   },
      \ })

call textobj#user#plugin('md', {
      \   'md-strikethrough': {
      \     'pattern': ['\~', '\~'],
      \     'select-a': 'a~',
      \     'select-i': 'i~',
      \   },
      \ })

" " Turn on spelling for prosey files
augroup vimrc
  autocmd FileType markdown setlocal spell
  autocmd FileType gitcommit setlocal spell
augroup END

" " TIL stuff
nnoremap <leader>??? "=strftime("%x")<CR>P^i# <C-[>o
command! TIL execute "tabe" strftime("%Y-%m-%d.md")
nnoremap <leader>p :execute 'tabe' strftime("$MYDEV/notes/%Y-%m-%d.md")<CR>
command! DTtime :call setline(line('.'), strftime('%H:%M') . getline('.'))
command! DTdate :call setline(line('.'), strftime('%m/%d/%Y') . getline('.'))
command! DTzk :call setline(line('.'), strftime("%Y%m%d:%s") . getline('.'))

command! MDLineBold :call SurroundLine('**')
command! MDLineStrike :call SurroundLine('~~')
command! MDLineHeader :call setline(line('.'), '#' . getline('.'))

nnoremap <leader>mmb :MDLineBold<cr>
nnoremap <leader>mms :MDLineStrike<cr>
nnoremap <leader>mmh :MDLineHeader<cr>

function! SurroundLine(surrounding)
  call setline(line('.'), a:surrounding . getline('.') . a:surrounding)
endfunction

" " Session
function! GitDir()
  let git_path = substitute(system('git rev-parse --show-toplevel 2>/dev/null'), '\n\+$', '', '')
  return git_path . '/.git'
endfunction

function! GitBranch()
  return substitute(system("git rev-parse --abbrev-ref HEAD"), '\n\+$', '', '')
endfunction

function! SaveSession(path)
  let dir = fnamemodify(a:path, ":h")
  if !isdirectory(dir)
    call mkdir(dir, "p")
  endif
  execute 'mksession! ' . a:path
endfunction

function! SafeLoadVimfile(path)
  if filereadable(expand(a:path))
    execute 'source '.expand(a:path)
  endif
endfunction

nnoremap <leader>w :wa<CR>:call SaveSession(GitDir().'/.vim-sessions/'.GitBranch().'.vim')<CR>

command! GitBranchNote execute 'e' GitDir().'/notes/'.GitBranch().'.md'

command! Terminal execute "Dispatch open -a Terminal ."
command! ChmodX execute "Dispatch chmod +x %"
nnoremap <cr><space> :Dispatch<cr>
nnoremap <leader>#! ggI#!/usr/bin/env
nnoremap <leader>#!! ggI#!/usr/bin/env bash<cr><cr>set -euo pipefail<cr><cr>

nnoremap <leader>rg :Rg <C-r><C-w>

command! WUPS execute 'let @*=@"'
command! PBTestLastCommand execute 'let @*=g:test#last_command'
command! PBBufferFullPath execute 'let @*=expand("%:p")'
command! PBBufferRelativePath execute 'let @*=fnamemodify(expand("%"), ":~:.")'

command! ZKMode execute 'setf markdown'
command! ZKSave execute 'w' strftime("%Y%m%d-".@z.".md")

command! GUIScreenshare execute 'set guifont=Monaco:h33'
command! GUIUnshare execute 'set guifont=Monaco:h16'

" Go to next location in list
nnoremap <leader>cn :cnext<cr>
nnoremap <leader>cp :cprevious<cr>

nnoremap <leader><cr> :<c-p><cr>
nnoremap <silent> <leader>gf :let mycurf=expand("<cfile>")<cr><c-w>p:execute("e ".mycurf)<cr>

" " Leave this at the end so projects get an opportunity to override things.
" " TODO: Add a boilerplate .vimrc to the git template
silent! call SafeLoadVimfile(GitDir().'/.vimrc')
