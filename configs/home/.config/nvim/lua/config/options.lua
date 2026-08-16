-- Core editor behavior shared by every filetype.
local opt = vim.opt

-- Expose user-installed toolchain binaries when system packages are unavailable.
for _, directory in ipairs({ "~/.cargo/bin", "~/.cache/.bun/bin" }) do
  local expanded = vim.fn.expand(directory)
  if vim.uv.fs_stat(expanded) then
    vim.env.PATH = expanded .. ":" .. vim.env.PATH
  end
end

opt.number = true
opt.relativenumber = true
opt.cursorline = true
opt.signcolumn = "yes"
opt.scrolloff = 8
-- Soft wrap: display-only; physical lines (and line numbers) never change.
opt.wrap = true
opt.linebreak = true
opt.breakindent = true
opt.showbreak = "↳ "
opt.smoothscroll = true
-- breakat defaults to spaces + ASCII punctuation; add Chinese punctuation.
vim.o.breakat = vim.o.breakat .. "，。！？；：、"

opt.tabstop = 4
opt.shiftwidth = 4
opt.softtabstop = 4
opt.expandtab = true
opt.smartindent = true

opt.ignorecase = true
opt.smartcase = true
opt.incsearch = true
opt.hlsearch = true

opt.mouse = "a"
opt.confirm = true
opt.undofile = true
opt.swapfile = false
opt.splitbelow = true
opt.splitright = true
opt.laststatus = 3
opt.updatetime = 200
opt.timeoutlen = 300
opt.completeopt = "menu,menuone,noselect"
opt.pumheight = 10

opt.list = true
opt.listchars = { tab = "» ", trail = "·", nbsp = "␣" }

-- Use the desktop clipboard only when a supported provider is available.
if vim.fn.executable("wl-copy") == 1 or vim.fn.executable("xclip") == 1 then
  opt.clipboard = "unnamedplus"
end

-- Prefer a bundled colorscheme over a dedicated theme plugin.
vim.cmd.colorscheme("habamax")
