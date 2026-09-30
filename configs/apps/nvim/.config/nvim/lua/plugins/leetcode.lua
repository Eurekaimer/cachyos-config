-- LeetCode practice, pointed at the mainland endpoint (leetcode.cn).
--
-- picker.provider stays nil so leetcode.nvim resolves the first available
-- provider itself; its order is snacks-picker, fzf-lua, telescope, mini-picker
-- and ui.lua already supplies Snacks, so no second picker is installed.
-- The html parser in plugins/syntax.lua drives the description formatter;
-- without it leetcode.nvim falls back to plain text.
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
      cn = {
        enabled = true,
        translator = true,
        translate_problems = true,
      },
    },
  },
}
