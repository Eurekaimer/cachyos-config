-- Markdown presentation: semantic text rendering plus Kitty-native inline images.
return {
  {
    "MeanderingProgrammer/render-markdown.nvim",
    dependencies = { "nvim-treesitter/nvim-treesitter" },
    ft = "markdown",
    opts = {},
  },

  {
    "3rd/image.nvim",
    build = false,
    ft = "markdown",
    cond = function()
      return not vim.g.neovide and vim.env.KITTY_WINDOW_ID ~= nil
    end,
    opts = {
      backend = "kitty",
      processor = "magick_cli",
      integrations = {
        markdown = {
          enabled = true,
          clear_in_insert_mode = false,
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
      window_overlap_clear_enabled = false,
      editor_only_render_when_focused = false,
      hijack_file_patterns = { "*.png", "*.jpg", "*.jpeg", "*.gif", "*.webp", "*.avif" },
    },
  },
}
