-- ---- Bootstrap lazy.nvim ----
local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

-- ---- Plugin specs ----
-- Order matters: LazyVim core, then extras (lazyvim.json + NVIM_EXTRAS),
-- then this config's plugins, then untracked local plugins.
local dotfiles = require("lib.dotfiles")

local spec = { { "LazyVim/LazyVim", import = "lazyvim.plugins" } }
vim.list_extend(spec, dotfiles.optional_specs())
table.insert(spec, { import = "plugins" })
vim.list_extend(spec, dotfiles.local_specs())

require("lazy").setup({
  spec = spec,
  defaults = {
    -- Only LazyVim's own plugins are lazy-loaded; plugins here load at startup
    lazy = false,
    -- Track plugin HEADs; lazy-lock.json pins the exact commits on install
    version = false,
  },
  -- Theme used while plugins install on the first start
  install = { colorscheme = { "catppuccin", "habamax" } },
  -- Check for plugin updates in the background without notifications
  checker = { enabled = true, notify = false },
  performance = {
    rtp = {
      -- Built-in plugins this setup never uses
      disabled_plugins = { "gzip", "tarPlugin", "tohtml", "tutor", "zipPlugin" },
    },
  },
})
