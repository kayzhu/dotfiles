-- ~/.config/nvim/init.lua
-- Neovim, DEBUG-FIRST config (2026-08): nvim exists in this stack for
-- nvim-dap (stepping through robotics stacks -- Python/ROS 2, local and
-- remote attach). vim (vim/vimrc) remains the daily editor; this config
-- ports the muscle memory, not the whole vimrc. Migrate more only if
-- nvim earns it.
--
-- STACK CONTRACT (CLAUDE.md): NEVER map <C-s> here -- herdr consumes it
-- before the PTY. alt chords belong to AeroSpace/readline. Leader is
-- backtick, same as vim.
--
-- Requires: brew install neovim pyright; debugpy in ~/.virtualenvs/debugpy
-- (uv venv ~/.virtualenvs/debugpy && uv pip install ... debugpy).
-- Plugins auto-install via vim.pack (nvim 0.12 built-in) on first launch.

-- ============================================================
-- Options (ported subset of vim/vimrc)
-- ============================================================
vim.g.mapleader = '`'
vim.o.number = true
vim.o.relativenumber = true
vim.o.signcolumn = 'number'          -- signs share the number column
vim.o.scrolloff = 3
vim.o.colorcolumn = '88'             -- black's line length
vim.o.ignorecase = true
vim.o.smartcase = true
vim.o.splitbelow = true
vim.o.splitright = true
vim.o.clipboard = 'unnamed'          -- macOS pasteboard
vim.o.mouse = 'a'
vim.o.undofile = true                -- undo dir is auto-managed by nvim
vim.o.updatetime = 150               -- CursorHold delay -> diagnostic float
vim.o.termguicolors = true
vim.o.confirm = true
vim.o.timeoutlen = 600
vim.o.ttimeoutlen = 20

-- ============================================================
-- Mappings (ported muscle memory)
-- ============================================================
vim.keymap.set('i', 'jk', '<Esc>')
vim.keymap.set('i', 'kj', '<Esc>')
vim.keymap.set('n', 'j', 'gj')
vim.keymap.set('n', 'k', 'gk')
vim.keymap.set('n', 'gj', 'j')
vim.keymap.set('n', 'gk', 'k')
vim.keymap.set('n', '<Leader>s', [[:%s/\<<C-r><C-w>\>/]])
-- Enter clears search highlight, except quickfix needs Enter to jump.
vim.keymap.set('n', '<CR>', ':noh<CR><CR>:<Backspace>')
vim.api.nvim_create_autocmd('FileType', {
  pattern = 'qf',
  callback = function()
    vim.keymap.set('n', '<CR>', '<CR>', { buffer = true })
  end,
})

-- ============================================================
-- Plugins (vim.pack, built into nvim 0.12)
-- ============================================================
vim.pack.add({
  -- fuzzy finding: same fzf + `p/`b/`a muscle memory as vim
  'https://github.com/junegunn/fzf',
  'https://github.com/junegunn/fzf.vim',
  -- the reason this config exists
  'https://github.com/mfussenegger/nvim-dap',
  'https://github.com/nvim-neotest/nvim-nio',
  'https://github.com/rcarriga/nvim-dap-ui',
  'https://github.com/mfussenegger/nvim-dap-python',
  -- visual continuity with vim
  'https://github.com/nanotech/jellybeans.vim',
  -- structural highlighting (the visible upgrade over vim)
  { src = 'https://github.com/nvim-treesitter/nvim-treesitter', version = 'main' },
  -- format-on-save (vim's codefmt counterpart); skips missing formatters
  'https://github.com/stevearc/conform.nvim',
  -- git signs in the number column (vim's gitgutter counterpart)
  'https://github.com/lewis6991/gitsigns.nvim',
})
vim.cmd('silent! colorscheme jellybeans')

-- Treesitter: install parsers (no-op when present), start per filetype.
local ts_fts = { 'python', 'c', 'cpp', 'lua', 'bash', 'yaml', 'toml',
                 'json', 'markdown', 'vim' }
pcall(function() require('nvim-treesitter').install(ts_fts) end)
vim.api.nvim_create_autocmd('FileType', {
  pattern = ts_fts,
  callback = function() pcall(vim.treesitter.start) end,
})

-- Formatting: black / clang-format on save, like the vimrc's codefmt
-- autocmds; \f formats manually (same key as vim's Glaive mapping).
require('conform').setup({
  formatters_by_ft = {
    python = { 'black' },
    c = { 'clang-format' },
    cpp = { 'clang-format' },
  },
  format_on_save = { timeout_ms = 2000, lsp_format = 'never' },
})
vim.keymap.set({ 'n', 'v' }, '\\f', function() require('conform').format() end)

-- Git change signs (number column, same as vim's gitgutter).
require('gitsigns').setup()

-- fzf: project-rooted, same as the vimrc (autodir is not ported, but the
-- root anchor is kept for identical behavior).
local function project_root()
  local out = vim.fn.systemlist({ 'git', '-C', vim.fn.expand('%:p:h'), 'rev-parse', '--show-toplevel' })
  return (vim.v.shell_error == 0 and out[1]) or vim.fn.getcwd()
end
vim.keymap.set('n', '<Leader>p', function()
  vim.fn['fzf#vim#files'](project_root(), vim.fn['fzf#vim#with_preview'](), 0)
end)
vim.keymap.set('n', '<Leader>b', ':Buffers<CR>')
vim.keymap.set('n', '<Leader>m', ':History<CR>')
vim.keymap.set('n', '<Leader>a', function()
  vim.fn['fzf#vim#grep']('rg --column --line-number --no-heading --color=always --smart-case -- ""',
    vim.fn['fzf#vim#with_preview']({ dir = project_root() }), 0)
end)

-- ============================================================
-- LSP (native, nvim 0.11+): pyright + clangd
-- ============================================================
vim.lsp.config('pyright', {
  cmd = { 'pyright-langserver', '--stdio' },
  filetypes = { 'python' },
  root_markers = { 'pyrightconfig.json', 'pyproject.toml', 'setup.py', '.git' },
})
vim.lsp.config('clangd', {
  cmd = { 'clangd' },
  filetypes = { 'c', 'cpp' },
  root_markers = { 'compile_commands.json', '.git' },
})
vim.lsp.enable({ 'pyright', 'clangd' })

-- Diagnostics: same taste as the vimrc -- signs in the number column,
-- float when the cursor rests; nothing painted into the buffer text.
vim.diagnostic.config({ virtual_text = false, severity_sort = true })
vim.api.nvim_create_autocmd('CursorHold', {
  callback = function()
    vim.diagnostic.open_float(nil, { focusable = false, scope = 'line' })
  end,
})

-- LSP keys + native completion, same `j* family as vim.
vim.api.nvim_create_autocmd('LspAttach', {
  callback = function(ev)
    local client = vim.lsp.get_client_by_id(ev.data.client_id)
    if client:supports_method('textDocument/completion') then
      vim.lsp.completion.enable(true, client.id, ev.buf, { autotrigger = true })
    end
    local o = { buffer = ev.buf }
    vim.keymap.set('n', '<Leader>jd', vim.lsp.buf.definition, o)
    vim.keymap.set('n', '<Leader>jt', vim.lsp.buf.type_definition, o)
    vim.keymap.set('n', '<Leader>jc', vim.lsp.buf.hover, o)
    vim.keymap.set('n', '<Leader>jr', vim.lsp.buf.references, o)
    vim.keymap.set('n', '<Leader>rn', vim.lsp.buf.rename, o)
    vim.keymap.set('n', 'K', vim.lsp.buf.hover, o)
    vim.keymap.set('n', '<Leader>t', vim.lsp.buf.workspace_symbol, o)
    vim.keymap.set('n', '[g', function() vim.diagnostic.jump({ count = -1 }) end, o)
    vim.keymap.set('n', ']g', function() vim.diagnostic.jump({ count = 1 }) end, o)
  end,
})
-- Tab/Enter drive the completion popup, as in vim's asyncomplete setup.
vim.keymap.set('i', '<Tab>', function() return vim.fn.pumvisible() == 1 and '<C-n>' or '<Tab>' end, { expr = true })
vim.keymap.set('i', '<S-Tab>', function() return vim.fn.pumvisible() == 1 and '<C-p>' or '<S-Tab>' end, { expr = true })
vim.keymap.set('i', '<CR>', function() return vim.fn.pumvisible() == 1 and '<C-y>' or '<CR>' end, { expr = true })

-- ============================================================
-- DAP -- the point of all this. Python/ROS 2, local + remote attach.
-- ============================================================
local dap = require('dap')
local dapui = require('dapui')
dapui.setup()
dap.listeners.after.event_initialized['dapui'] = function() dapui.open() end
dap.listeners.before.event_terminated['dapui'] = function() dapui.close() end
dap.listeners.before.event_exited['dapui'] = function() dapui.close() end

-- debugpy lives in a dedicated venv; the DEBUGGED python is whatever
-- interpreter the target uses (dap-python separates the two).
require('dap-python').setup(vim.fn.expand('~/.virtualenvs/debugpy/bin/python'))

-- ROS 2 / bazel reality: nodes are started by launch files or bazel run,
-- so ATTACH is the primary workflow. On the target (robot, VM, or local
-- terminal), start the node under debugpy first, e.g.:
--   python3 -m pip install debugpy        (once, on the target)
--   python3 -m debugpy --listen 0.0.0.0:5678 --wait-for-client <script/module>
-- or wrap the node's entry point. Then attach with `dc -> "Attach".
table.insert(dap.configurations.python, {
  type = 'python',
  request = 'attach',
  name = 'Attach remote (robot/VM)',
  connect = function()
    local host = vim.fn.input('Host: ', 'localhost')
    local port = tonumber(vim.fn.input('Port: ', '5678'))
    return { host = host, port = port }
  end,
  -- Map the robot's checkout onto the local one; adjust when they differ.
  pathMappings = {
    { localRoot = '${workspaceFolder}', remoteRoot = '${workspaceFolder}' },
  },
  justMyCode = false,
})

-- `d* family: debug plane, alongside `j* (LSP jumps).
vim.keymap.set('n', '<Leader>db', dap.toggle_breakpoint)
vim.keymap.set('n', '<Leader>dB', function()
  dap.set_breakpoint(vim.fn.input('Condition: '))
end)
vim.keymap.set('n', '<Leader>dc', dap.continue)      -- also starts a session
vim.keymap.set('n', '<Leader>do', dap.step_over)
vim.keymap.set('n', '<Leader>di', dap.step_into)
vim.keymap.set('n', '<Leader>dO', dap.step_out)
vim.keymap.set('n', '<Leader>dr', dap.repl.toggle)
vim.keymap.set('n', '<Leader>du', dapui.toggle)
vim.keymap.set('n', '<Leader>dx', dap.terminate)
vim.keymap.set('n', '<Leader>dk', function() dapui.eval() end)  -- inspect under cursor
