-- Kanagawa is loaded before the rest of the UI so every plugin starts with stable colors.
return {
  "rebelot/kanagawa.nvim",
  priority = 1000,
  lazy = false,
  opts = {
    compile = false,
    undercurl = true,
    commentStyle = { italic = true },
    keywordStyle = { italic = true },
    statementStyle = { bold = true },
    transparent = false,
    dimInactive = false,
    terminalColors = true,
    theme = "wave",
    background = { dark = "wave", light = "lotus" },
    colors = {
      theme = {
        all = { ui = { bg_gutter = "none" } },
      },
    },
    overrides = function(colors)
      local ui = colors.theme.ui
      return {
        CursorLine = { bg = ui.bg_p1 },
        FloatBorder = { fg = ui.bg_p2, bg = ui.bg_m1 },
        FloatTitle = { fg = ui.special, bg = ui.bg_m1, bold = true },
        NormalFloat = { fg = ui.fg, bg = ui.bg_m1 },
        Pmenu = { fg = ui.fg, bg = ui.bg_p1 },
        PmenuSel = { fg = ui.special, bg = ui.bg_p2, bold = true },
        WinSeparator = { fg = ui.bg_p2 },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    -- habamax is already active as a safe built-in fallback from options.lua.
    pcall(vim.cmd.colorscheme, "kanagawa-wave")
  end,
}
