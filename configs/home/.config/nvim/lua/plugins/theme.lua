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
      local palette = colors.palette
      return {
        CursorLine = { bg = ui.bg_p1 },
        FloatBorder = { fg = ui.bg_p2, bg = ui.bg_m1 },
        FloatTitle = { fg = ui.special, bg = ui.bg_m1, bold = true },
        NormalFloat = { fg = ui.fg, bg = ui.bg_m1 },
        Pmenu = { fg = ui.fg, bg = ui.bg_p1 },
        PmenuSel = { fg = ui.special, bg = ui.bg_p2, bold = true },
        WinSeparator = { fg = ui.bg_p2 },
        -- One hue per nesting level for rainbow-delimiters.nvim, drawn from the
        -- Kanagawa palette so deeper brackets stay tellable apart without
        -- leaving the theme. RainbowDelimiter* groups are applied in the plugin's
        -- default order: Red, Yellow, Blue, Orange, Green, Violet, Cyan.
        RainbowDelimiterRed = { fg = palette.waveRed },
        RainbowDelimiterYellow = { fg = palette.carpYellow },
        RainbowDelimiterBlue = { fg = palette.crystalBlue },
        RainbowDelimiterOrange = { fg = palette.roninYellow },
        RainbowDelimiterGreen = { fg = palette.springGreen },
        RainbowDelimiterViolet = { fg = palette.oniViolet },
        RainbowDelimiterCyan = { fg = palette.waveAqua2 },
      }
    end,
  },
  config = function(_, opts)
    require("kanagawa").setup(opts)
    -- habamax is already active as a safe built-in fallback from options.lua.
    pcall(vim.cmd.colorscheme, "kanagawa-wave")
  end,
}
