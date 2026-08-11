-- General editor lifecycle hooks.
local group = vim.api.nvim_create_augroup("user_autocmds", { clear = true })

vim.api.nvim_create_autocmd("TextYankPost", {
  group = group,
  callback = function()
    vim.highlight.on_yank({ higroup = "IncSearch", timeout = 150 })
  end,
})

vim.api.nvim_create_autocmd("BufReadPost", {
  group = group,
  callback = function(args)
    local mark = vim.api.nvim_buf_get_mark(args.buf, '"')
    local line_count = vim.api.nvim_buf_line_count(args.buf)
    if mark[1] > 0 and mark[1] <= line_count then
      pcall(vim.api.nvim_win_set_cursor, 0, mark)
    end
  end,
})

vim.api.nvim_create_autocmd({ "FocusGained", "TermClose", "TermLeave" }, {
  group = group,
  command = "checktime",
})

-- Keep Normal mode in English while restoring the previous fcitx5 state in Insert mode.
if vim.fn.executable("fcitx5-remote") == 1 then
  local ime_was_active = false
  local function set_ime(argument)
    vim.fn.jobstart({ "fcitx5-remote", argument }, { detach = true })
  end

  vim.api.nvim_create_autocmd("InsertLeave", {
    group = group,
    callback = function()
      ime_was_active = vim.trim(vim.fn.system({ "fcitx5-remote" })) == "2"
      if ime_was_active then
        set_ime("-c")
      end
    end,
  })

  vim.api.nvim_create_autocmd("InsertEnter", {
    group = group,
    callback = function()
      if ime_was_active then
        set_ime("-o")
      end
    end,
  })

  vim.api.nvim_create_autocmd("VimLeavePre", {
    group = group,
    callback = function()
      if ime_was_active then
        set_ime("-o")
      end
    end,
  })
end
