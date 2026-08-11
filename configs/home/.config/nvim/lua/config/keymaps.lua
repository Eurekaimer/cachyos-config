-- Global mappings use Space as the leader and keep Vim defaults intact.
local map = vim.keymap.set

map("i", "jk", "<Esc>", { desc = "退出插入模式" })
map({ "n", "i", "v" }, "<C-s>", "<cmd>write<CR><Esc>", { desc = "保存文件" })
map("n", "<leader>s", "<cmd>write<CR>", { desc = "保存文件" })
map("n", "<Esc>", "<cmd>nohlsearch<CR>", { desc = "清除搜索高亮" })

-- Navigate splits without pressing Ctrl-W first.
map("n", "<C-h>", "<C-w>h", { desc = "左侧窗口" })
map("n", "<C-j>", "<C-w>j", { desc = "下方窗口" })
map("n", "<C-k>", "<C-w>k", { desc = "上方窗口" })
map("n", "<C-l>", "<C-w>l", { desc = "右侧窗口" })
map("n", "<leader>wv", "<cmd>vsplit<CR>", { desc = "垂直分屏" })
map("n", "<leader>ws", "<cmd>split<CR>", { desc = "水平分屏" })
map("n", "<leader>wd", "<cmd>close<CR>", { desc = "关闭窗口" })
map("n", "<leader>w=", "<C-w>=", { desc = "均分窗口" })

-- Keep buffer navigation available even before Snacks loads.
map("n", "<leader>bn", "<cmd>bnext<CR>", { desc = "下一个文件" })
map("n", "<leader>bp", "<cmd>bprevious<CR>", { desc = "上一个文件" })

-- Move selected lines while preserving the selection.
map("v", "J", ":move '>+1<CR>gv=gv", { desc = "选区下移" })
map("v", "K", ":move '<-2<CR>gv=gv", { desc = "选区上移" })
map("v", "<", "<gv", { desc = "减少缩进" })
map("v", ">", ">gv", { desc = "增加缩进" })
