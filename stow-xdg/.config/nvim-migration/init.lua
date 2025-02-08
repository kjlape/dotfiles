-- Bootstrap lazy.nvim
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not vim.loop.fs_stat(lazypath) then
  vim.fn.system({
    "git",
    "clone",
    "--filter=blob:none",
    "https://github.com/folke/lazy.nvim.git",
    "--branch=stable",
    lazypath,
  })
end
vim.opt.rtp:prepend(lazypath)

-- Set leader key (should be before lazy setup)
vim.g.mapleader = " "

-- Plugin specifications
require("lazy").setup({
  -- Linting and formatting
  {
    "nvimtools/none-ls.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
    config = function()
      local null_ls = require("null-ls")
      local formatting = null_ls.builtins.formatting
      local diagnostics = null_ls.builtins.diagnostics

      null_ls.setup({
        sources = {
          -- Formatting
          formatting.prettier.with({
            extra_filetypes = { "vue" },
          }),
          formatting.standardrb,
          formatting.terraform_fmt,
          formatting.rustfmt,
          
          -- Diagnostics
          diagnostics.standardrb,
          diagnostics.reek,
          diagnostics.eslint,
          diagnostics.jq,
          diagnostics.terraform_validate,
          diagnostics.swiftlint,

          -- Remove trailing whitespace and newlines
          formatting.trim_whitespace,
          formatting.trim_newlines,
        },
        -- Autofix on save
        on_attach = function(client, bufnr)
          if client.supports_method("textDocument/formatting") then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = bufnr,
              callback = function()
                vim.lsp.buf.format({ 
                  bufnr = bufnr,
                  filter = function(c)
                    return c.name == "null-ls"
                  end,
                })
              end,
            })
          end
        end,
      })
    end,
  },

  -- Mason for managing LSP servers, linters, and formatters
  {
    "williamboman/mason.nvim",
    build = ":MasonUpdate",
    config = true,
  },
  {
    "williamboman/mason-lspconfig.nvim",
    config = function()
      require("mason-lspconfig").setup({
        ensure_installed = {
          "ruby_ls",
          "standardrb",
        },
      })
    end,
  },
  -- Core plugins
  { "tpope/vim-sensible" },
  { "tpope/vim-commentary" },
  { "tpope/vim-surround" },
  { "tpope/vim-unimpaired" },
  { "tpope/vim-fugitive" },
  { "tpope/vim-rhubarb" },
  { "tpope/vim-abolish" },
  { "tpope/vim-bundler" },
  { "tpope/vim-dispatch" },
  { "tpope/vim-endwise" },
  { "tpope/vim-rails" },
  { "tpope/vim-rbenv" },
  
  -- UI and themes
  { "vim-airline/vim-airline" },
  { "vim-airline/vim-airline-themes" },
  { "alligator/accent.vim" },
  { "jeffkreeftmeijer/vim-dim" },
  { "jaredgorski/fogbell.vim" },
  
  -- Fuzzy finding
  {
    "junegunn/fzf.vim",
    dependencies = {
      "junegunn/fzf",
    },
  },
  
  -- Git integration
  { "airblade/vim-gitgutter" },
  
  -- LSP and completion
  {
    "neovim/nvim-lspconfig",
    dependencies = {
      "hrsh7th/nvim-cmp",
      "hrsh7th/cmp-nvim-lsp",
      "hrsh7th/cmp-buffer",
      "hrsh7th/cmp-path",
    },
  },
  
  -- Treesitter
  {
    "nvim-treesitter/nvim-treesitter",
    build = ":TSUpdate",
  },
  
  -- Telescope
  {
    "nvim-telescope/telescope.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- Language specific
  { "vim-ruby/vim-ruby" },
  { "rust-lang/rust.vim" },
  { "neovimhaskell/haskell-vim" },
  { "urbit/hoon.vim" },
  { "vim-scripts/bats.vim" },
  
  -- Text objects
  {
    "kana/vim-textobj-user",
    dependencies = {
      "nelstrom/vim-textobj-rubyblock",
    },
  },
  
  -- Writing and focus
  {
    "junegunn/goyo.vim",
    dependencies = {
      "junegunn/limelight.vim",
    },
  },
  
  -- Obsidian integration
  {
    "epwalsh/obsidian.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
    },
  },
  
  -- Additional tools
  { "alvan/vim-closetag" },
  { "christoomey/vim-tmux-navigator" },
  { "DataWraith/auto_mkdir" },
  { "danchoi/ri.vim" },
  { "liuchengxu/graphviz.vim" },
  
  -- AI and enhancement tools
  {
    "dense-analysis/neural",
    config = function()
      vim.g.neural = {
        source = {
          openai = {
            api_key = vim.env.OPENAI_API_KEY,
          },
        },
      }
    end,
  },
  {
    "olimorris/codecompanion.nvim",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "stevearc/dressing.nvim",
    },
    config = function()
      require("codecompanion").setup({
        strategies = {
          chat = { adapter = "anthropic" },
          inline = { adapter = "anthropic" },
          agent = { adapter = "anthropic" },
        }
      })
    end,
  },
})

-- Basic settings
vim.opt.expandtab = true
vim.opt.shiftwidth = 2
vim.opt.softtabstop = 2
vim.opt.scrolloff = 2
vim.opt.number = true
vim.opt.relativenumber = true
vim.opt.spelllang = "en_us"
vim.opt.wrap = false
vim.opt.splitright = true
vim.opt.ignorecase = true
vim.opt.smartcase = true
vim.opt.grepprg = "rg --vimgrep --smart-case --follow"

-- Theme configuration
vim.cmd.colorscheme("accent")
vim.g.airline_theme = "minimalist"

-- Plugin configurations
-- vim-closetag
vim.g.closetag_filenames = "*.html,*.html.erb,*.xhtml,*.phtml"
vim.g.closetag_xhtml_filenames = "*.xhtml,*.jsx,*.vue"
vim.g.closetag_filetypes = "html,xhtml,phtml"
vim.g.closetag_xhtml_filetypes = "xhtml,jsx,vue"
vim.g.closetag_emptyTags_caseSensitive = 1
vim.g.closetag_shortcut = ">"
vim.g.closetag_close_shortcut = "<leader>>"

-- vim-test configuration
vim.g["test#strategy"] = "dispatch"
vim.g["test#custom_runners"] = { Ruby = { "DHH" } }

-- Keymaps
local function map(mode, lhs, rhs, opts)
  local options = { noremap = true, silent = true }
  if opts then options = vim.tbl_extend("force", options, opts) end
  vim.keymap.set(mode, lhs, rhs, options)
end

-- Test mappings
map("n", "<cr>t", ":TestFile<CR>")
map("n", "<cr>n", ":TestNearest<CR>")
map("n", "<cr><cr>", ":TestLast<CR>")

-- FZF mappings
map("n", "<leader>f", ":FZF<CR>")
map("n", "<leader>b", ":Buffers<CR>")

-- LSP configuration
local lspconfig = require("lspconfig")

-- Sourcekit setup
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

-- Ruby LSP setup
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

-- Completion setup
local cmp = require('cmp')
cmp.setup({
  sources = cmp.config.sources({
    { name = 'nvim_lsp' },
    { name = 'buffer' },
    { name = 'path' },
  }),
  mapping = cmp.mapping.preset.insert({
    ['<CR>'] = cmp.mapping.confirm({ select = true })
  }),
})

-- Obsidian setup
require("obsidian").setup({
  workspaces = {
    {
      name = "default",
      path = "~/Library/Mobile Documents/iCloud~md~obsidian/Documents/Default"
    }
  }
})

-- Format on save
vim.api.nvim_create_autocmd("LspAttach", {
  group = vim.api.nvim_create_augroup("lsp", { clear = true }),
  callback = function(args)
    vim.api.nvim_create_autocmd("BufWritePre", {
      buffer = args.buf,
      callback = function()
        vim.lsp.buf.format {async = false, id = args.data.client_id }
      end,
    })
  end
})

-- Add %% mapping for current buffer's directory
vim.keymap.set("c", "%%", function()
  if vim.fn.getcmdtype() == ':' then
    return vim.fn.expand('%:h') .. '/'
  else
    return '%%'
  end
end, { expr = true })

-- LSP keybindings
vim.api.nvim_create_autocmd('LspAttach', {
  desc = 'LSP actions',
  callback = function()
    map('n', 'K', vim.lsp.buf.hover)
    map('n', 'gd', vim.lsp.buf.definition)
  end,
})

-- Autocommands
vim.api.nvim_create_autocmd("FileType", {
  pattern = { "markdown", "gitcommit" },
  callback = function()
    vim.opt_local.spell = true
  end,
})

-- Custom commands
vim.api.nvim_create_user_command('TIL', function()
  vim.cmd('tabe ' .. os.date('%Y-%m-%d.md'))
end, {})

vim.api.nvim_create_user_command('MDLineBold', function()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line('**' .. line .. '**')
end, {})

vim.api.nvim_create_user_command('MDLineStrike', function()
  local line = vim.api.nvim_get_current_line()
  vim.api.nvim_set_current_line('~~' .. line .. '~~')
end, {})
