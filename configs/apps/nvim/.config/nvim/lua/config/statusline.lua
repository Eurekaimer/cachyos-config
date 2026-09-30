-- Statusline segment that would otherwise be recomputed on every redraw.
local M = {}

-- Counting characters scans the whole buffer (~3 µs per KiB, measured) and a
-- '%{}' item is re-evaluated on every redraw, so the plain
-- `%{wordcount().chars}` costs 16 ms per keystroke in a 100k-line file and
-- 33 ms at 200k lines. Two things keep the segment affordable:
--   * the result is memoized per 'changedtick', so redraws that do not change
--     the text (cursor movement, scrolling) cost nothing;
--   * buffers past MAX_COUNTED_BYTES skip the count instead of making every
--     edit pay for it, leaving the O(1) Line: part on its own. The threshold
--     matches the size Snacks' bigfile module already treats as large.
local MAX_COUNTED_BYTES = 1.5 * 1024 * 1024

--- Character count of {buf}, reusing the memoized value for its 'changedtick'.
--- The cache is a buffer variable keyed by the tick, so it cannot go stale: any
--- text change, undo, or reload bumps the tick.
---@param buf integer
---@return integer
local function count(buf)
  local tick = vim.api.nvim_buf_get_changedtick(buf)
  local cached = vim.b[buf].statusline_chars
  if cached and cached.tick == tick then
    return cached.count
  end
  local chars = vim.fn.wordcount().chars
  vim.b[buf].statusline_chars = { tick = tick, count = chars }
  return chars
end

--- Statusline item: "  Chars:1234", or empty for a buffer too large to count.
---@return string
function M.chars_segment()
  local buf = vim.api.nvim_get_current_buf()
  -- O(1): the byte offset just past the last line is the buffer size.
  if vim.api.nvim_buf_get_offset(buf, vim.api.nvim_buf_line_count(buf)) > MAX_COUNTED_BYTES then
    return ""
  end
  return "  Chars:" .. count(buf)
end

return M
