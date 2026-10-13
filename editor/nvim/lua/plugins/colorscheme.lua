return {
  {
    "catppuccin/nvim",
    name = "catppuccin",
    priority = 1000,
    opts = {
      styles = {
        comments = { "italic" },
        functions = { "italic" },
        types = { "italic" },
      },
      custom_highlights = function(colors)
        return {
          ["@tag.tsx"] = { fg = colors.pink, italic = false },
          ["@tag.javascript"] = { fg = colors.pink, italic = false },
          ["@tag.attribute"] = { italic = false },
          ["@variable.parameter"] = { italic = true },
          ["@lsp.type.parameter"] = { italic = true },
        }
      end,
    },
  },
  {
    "LazyVim/LazyVim",
    opts = { colorscheme = "catppuccin-mocha" },
  },
}
