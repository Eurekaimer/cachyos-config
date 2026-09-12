-- Global key mappings. Space is the leader key.
-- Use map as a shorter name for vim.keymap.set.
-- Usage: map(mode, key, action, options)
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "退出插入模式" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR><Esc>", { desc = "保存文件" })
map("n", "<leader>s", "<cmd>write<CR>", { desc = "保存文件" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })
map({ "n", "v", "o" }, "L", "$", { desc = "跳到当前行行尾" })

-- Completion owns Tab while its menu is visible; otherwise snippets can expand or jump.
local function snippet_forward()
  local luasnip = package.loaded.luasnip
  if luasnip and luasnip.expand_or_locally_jumpable() then
    return "<Plug>luasnip-expand-or-jump"
  end
  if vim.snippet.active({ direction = 1 }) then
    return "<Cmd>lua vim.snippet.jump(1)<CR>"
  end
end

local function snippet_backward()
  local luasnip = package.loaded.luasnip
  if luasnip and luasnip.locally_jumpable(-1) then
    return "<Plug>luasnip-jump-prev"
  end
  if vim.snippet.active({ direction = -1 }) then
    return "<Cmd>lua vim.snippet.jump(-1)<CR>"
  end
end

map({ "i", "s" }, "<Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-n>"
  end
  return snippet_forward() or "<Tab>"
end, { expr = true, silent = true, desc = "补全下一项或展开片段" })
map({ "i", "s" }, "<S-Tab>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-p>"
  end
  return snippet_backward() or "<S-Tab>"
end, { expr = true, silent = true, desc = "补全上一项或返回片段" })
-- A run of empty quote lines (`>` with nothing after it) is how an Obsidian
-- callout ends. Pressing <Enter> on one collapses the whole run into a single
-- blank line and puts the cursor on the line below, so the callout stays tidy
-- and the next paragraph starts outside the quote. Exported at the bottom of
-- this file for the <Cmd> mapping below.
local function blank_quote_line(row)
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1]
  return line ~= nil and line:match("^%s*>%s*$") ~= nil
end

local function collapse_quote_run()
  local row = vim.api.nvim_win_get_cursor(0)[1]
  if not blank_quote_line(row) then
    return
  end

  -- The whole contiguous run counts, not just the lines above the cursor, or a
  -- second empty `>` left below would survive the collapse.
  local first, final = row, row
  while first > 1 and blank_quote_line(first - 1) do
    first = first - 1
  end
  while final < vim.api.nvim_buf_line_count(0) and blank_quote_line(final + 1) do
    final = final + 1
  end

  -- Replace the run with one blank line, then keep a line below for the cursor
  -- so the next paragraph starts outside the quote.
  vim.api.nvim_buf_set_lines(0, first - 1, final, false, { "" })
  if vim.api.nvim_buf_line_count(0) < first + 1 then
    vim.api.nvim_buf_set_lines(0, first, first, false, { "" })
  end
  vim.api.nvim_win_set_cursor(0, { first + 1, 0 })
  vim.cmd("startinsert")
end

map("i", "<CR>", function()
  if vim.fn.pumvisible() == 1 then
    return "<C-y>"
  end
  -- Only Markdown counts as callout territory; other filetypes and any line
  -- holding real text keep the plain newline.
  if vim.bo.filetype == "markdown" and blank_quote_line(vim.api.nvim_win_get_cursor(0)[1]) then
    return "<Cmd>lua require('config.keymaps').collapse_quote_run()<CR>"
  end
  -- Inside a pair registered by mini.pairs this opens an indented block;
  -- otherwise MiniPairs.cr() returns a plain <CR>.
  local ok, pairs = pcall(require, "mini.pairs")
  return ok and pairs.cr() or "<CR>"
end, { expr = true, desc = "确认补全或展开成对括号" })

-- Markdown plugins load by filetype; global guards keep their shortcuts predictable elsewhere.
map("n", "<leader>mr", function()
  if vim.bo.filetype ~= "markdown" then
    vim.notify("Markdown 渲染只在 .md 文件中可用", vim.log.levels.INFO)
    return
  end
  vim.cmd("RenderMarkdown toggle")
end, { desc = "切换 Markdown 渲染" })
map("n", "<leader>mi", function()
  if vim.bo.filetype ~= "markdown" then
    vim.notify("图片显示只在 .md 文件中可用", vim.log.levels.INFO)
    return
  end
  local ok, image = pcall(require, "image")
  if not ok then
    vim.notify("image.nvim 仅在 Kitty 终端中启用", vim.log.levels.WARN)
    return
  end
  if image.is_enabled() then
    image.disable()
  else
    image.enable()
  end
end, { desc = "切换 Markdown 图片" })

-- Switch windows with Ctrl and a direction key.
map("n", "<C-h>", "<C-w>h", { desc = "左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "右侧窗口" })
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "垂直分屏" })
map("n", "<leader>ws", "<cmd>split<CR>", { desc = "水平分屏" })
map("n", "<leader>wd", "<cmd>close<CR>", { desc = "关闭窗口" })
map("n", "<leader>w=", "<C-w>=", { desc = "均分窗口" })

-- Keep buffer navigation available before Snacks loads.
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "下一个文件" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "上一个文件" })

-- Move selected lines up or down and keep them selected.
map("v", "J", ":move '>+1<CR>gv=gv", { desc = "选区下移" })
map("v", "K", ":move '<-2<CR>gv=gv", { desc = "选区上移" })
map("v", "<", "<gv", { desc = "减少缩进" })
map("v", ">", ">gv", { desc = "增加缩进" })

return { collapse_quote_run = collapse_quote_run }
