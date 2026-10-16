-- LeetCode practice, pointed at the mainland endpoint (leetcode.cn).
--
-- picker.provider stays nil so leetcode.nvim resolves the first available
-- provider itself; its order is snacks-picker, fzf-lua, telescope, mini-picker
-- and ui.lua already supplies Snacks, so no second picker is installed.
-- The html parser in plugins/syntax.lua drives the description formatter;
-- without it leetcode.nvim falls back to plain text.

-- NUI fixes split widths at creation; recompute the pair after terminal resizing.
local function resize_descriptions()
  for _, question in ipairs(_Lc_state.questions) do
    local description = question.description
    if description and description.winid and vim.api.nvim_win_is_valid(description.winid)
      and question.winid and vim.api.nvim_win_is_valid(question.winid) then
      local width = vim.api.nvim_win_get_width(description.winid)
        + vim.api.nvim_win_get_width(question.winid)
      description:update_layout({ size = math.floor(width / 2) })
    end
  end
end

return {
  {
    "kawre/leetcode.nvim",
    cmd = "Leet",
    dependencies = {
      "nvim-lua/plenary.nvim",
      "MunifTanjim/nui.nvim",
    },
    opts = {
      lang = "java",
      description = {
        position = "left",
        width = "50%",
      },
      hooks = {
        question_enter = { resize_descriptions },
        enter = {
          function()
            vim.api.nvim_create_autocmd("VimResized", {
              group = vim.api.nvim_create_augroup("leetcode_equal_split", { clear = true }),
              callback = resize_descriptions,
            })
            resize_descriptions()
          end,
        },
      },
      cn = {
        enabled = true,
        translator = true,
        translate_problems = true,
      },
    },
    config = function(_, opts)
      require("leetcode").setup(opts)
      require("config.leetcode_lists").setup()
    end,
  },
}
