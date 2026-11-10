-- Mermaid diagrams (module: mermaid)
--
-- Renders ```mermaid blocks in markdown as inline images through the snacks.nvim
-- image module (kitty graphics protocol: Ghostty or kitty; tmux needs
-- allow-passthrough, set in .tmux.conf). mmdc (mermaid-cli) draws each diagram
-- with mermaid.json in the nvim config dir: Catppuccin Mocha colors and a
-- Pele-like (pele.run) look — rounded label-sized nodes and smooth edges.
--
-- snacks caches rendered diagrams by source only; after editing mermaid.json,
-- delete ~/.cache/nvim/snacks/image/*chart* to see the change.

if not require("lib.dotfiles").module("mermaid") then
  return {}
end

-- tmux_passthrough — wrap an escape sequence so tmux forwards it to the terminal
local function tmux_passthrough(data)
  return ("\027Ptmux;" .. data:gsub("\027", "\027\027")) .. "\027\\"
end

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      -- Inside tmux, snacks asks tmux for the client terminal only when extended-keys
      -- is "on". With "always" (.tmux.conf) it sends an escape-sequence query whose
      -- reply is typed into the buffer, and Ghostty goes undetected. Pre-fill the
      -- detection result and the passthrough wrapper so the query is never sent.
      if vim.env.TMUX then
        local ok, out = pcall(vim.fn.system, { "tmux", "display-message", "-p", "#{client_termtype}" })
        local term, version = (ok and out or ""):match("^(ghostty)%s*(%S*)")
        if term then
          local terminal = require("snacks.image.terminal")
          terminal._terminal = { terminal = term, version = version }
          terminal.transform = tmux_passthrough
        end
      end

      opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
        enabled = true,
        convert = {
          -- Render at 2x the terminal scale: Ghostty then downscales a sharp image
          -- instead of upscaling a blurry one
          mermaid = function()
            local config = vim.fn.stdpath("config") .. "/mermaid.json"
            local scale = tostring((Snacks.image.terminal.size().scale or 1) * 2)
            return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-c", config, "-s", scale }
          end,
        },
      })
    end,
  },

  -- Draw code fences as thin borders: the default "hide" conceals the closing
  -- fence line, and with it the inline diagram snacks attaches to that line
  {
    "MeanderingProgrammer/render-markdown.nvim",
    opts = {
      code = {
        border = "thin",
      },
    },
  },
}
