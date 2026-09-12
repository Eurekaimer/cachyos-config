-- Markdown presentation: semantic text rendering plus Kitty-native inline images.

-- image.nvim's downloader caches the temporary path as soon as curl's stdout
-- closes, without checking its exit status, and throws from the async callback
-- when the transfer fails. A truncated download therefore poisons the URL cache
-- and every later render of that URL fails. Replace the downloader from the
-- configuration so a plugin update cannot silently drop the fix.
local function download_image(url, options, callback, state)
  local from_file = require("image/image").from_file
  local cached = state.remote_cache[url]
  if cached then
    local ok, image = pcall(from_file, cached, options, state)
    if ok and image then
      callback(image)
      return
    end
    -- The cached path is unusable; drop it instead of failing forever.
    state.remote_cache[url] = nil
  end

  -- Concurrent requests must not read or overwrite each other's partial files.
  local path = state.tmp_dir .. "/" .. vim.fn.fnamemodify(vim.fn.tempname(), ":t")
  local function fail(reason)
    vim.fn.delete(path)
    vim.notify(("image: 下载失败 %s\n%s"):format(url, reason), vim.log.levels.ERROR)
    callback(nil)
  end

  local ok, err = pcall(vim.system, {
    "curl",
    "--location",
    "--fail",
    "--silent",
    "--show-error",
    "--connect-timeout", "10",
    "--max-time", "60",
    "--output", path,
    "--", url,
  }, { text = true }, vim.schedule_wrap(function(result)
    if result.code ~= 0 then
      fail(("curl exit %d: %s"):format(result.code, vim.trim(result.stderr or "")))
      return
    end
    local decoded, image = pcall(from_file, path, options, state)
    if not decoded or not image then
      fail(decoded and "响应不是可识别的图片" or tostring(image))
      return
    end
    state.remote_cache[url] = path
    callback(image)
  end))
  if not ok then
    fail(tostring(err))
  end
end

-- Native completion replaces only the keyword under the cursor, but a callout
-- prefix contains '[' and '!' and mini.pairs has already inserted a closing
-- ']'. Supply an explicit edit range and reuse that bracket, so accepting a
-- candidate produces `> [!TYPE]` instead of nested or duplicated brackets.
local function markdown_completions(params)
  local source = require("render-markdown.integ.source")
  local row = params.position.line
  local buf = vim.uri_to_bufnr(params.textDocument.uri)
  local line = vim.api.nvim_buf_get_lines(buf, row, row + 1, false)[1] or ""
  local col = vim.str_byteindex(line, "utf-16", params.position.character, false)
  local items = source.items(buf, row, col)
  if not items or #items == 0 then
    return nil
  end
  local node = source.node(buf, row, col, "markdown")
  local start_col = math.min(node:child_at(0).end_col, col)
  local has_closing_bracket = line:sub(col + 1, col + 1) == "]"
  local range = {
    start = { line = row, character = vim.str_utfindex(line, "utf-16", start_col, false) },
    ["end"] = { line = row, character = params.position.character },
  }
  for _, item in ipairs(items) do
    local text = item.insertText
    if has_closing_bracket then
      text = text:gsub("%](%s*)$", "%1")
    end
    item.textEdit = { range = range, newText = text }
  end
  return { isIncomplete = false, items = items }
end

return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = "markdown",
    config = function(_, opts)
      require("render-markdown.integ.lsp").completions = markdown_completions
      require("render-markdown").setup(opts)
    end,
    opts = {
      completions = { lsp = { enabled = true } },
    },
  },

  {
    "3rd/image.nvim",
    build = false,
    -- `ft` alone never fires for a directly opened image: Neovim detects the
    -- filetype from the file name, and hijack_file_patterns needs an earlier
    -- event to take over the buffer.
    event = "BufReadPre *.png,*.jpg,*.jpeg,*.gif,*.webp,*.avif",
    ft = "markdown",
    cond = function()
      return not vim.g.neovide and vim.env.KITTY_WINDOW_ID ~= nil
    end,
    config = function(_, opts)
      require("image/image").from_url = download_image
      require("image").setup(opts)
    end,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = true,
          download_remote_images = true,
          only_render_image_at_cursor = false,
          floating_windows = false,
          filetypes = { "markdown" },
        },
        asciidoc = { enabled = false },
        neorg = { enabled = false },
        rst = { enabled = false },
        typst = { enabled = false },
        html = { enabled = false },
        css = { enabled = false },
      },
      max_width_window_percentage = 80,
      max_height_window_percentage = 40,
      window_overlap_clear_enabled = true,
      window_overlap_clear_ft_ignore = {
        -- smear-cursor keeps hidden floating windows parked over the editor;
        -- image.nvim treats them as occluders and skips rendering entirely.
        "smear-cursor",
        "cmp_menu",
        "cmp_docs",
        "snacks_notif",
        "snacks_picker_list",
        "snacks_picker_preview",
      },
      editor_only_render_when_focused = true,
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },
}
